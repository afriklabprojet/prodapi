<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Models\Prescription;
use App\Http\Resources\PrescriptionResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class PrescriptionController extends Controller
{
    /**
     * Get customer prescriptions
     */
    public function index(Request $request)
    {
        $prescriptions = $request->user()->prescriptions()
            ->with('order:id,reference,status') // Charger la commande associée
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => PrescriptionResource::collection($prescriptions),
        ]);
    }

    /**
     * Upload a new prescription
     */
    public function upload(Request $request)
    {
        try {
            $request->validate([
                'images' => 'required|array|min:1',
                'images.*' => 'required|image|mimes:jpeg,png,jpg,gif,webp|max:10240', // 10MB max per image
                'notes' => 'nullable|string|max:500',
                'source' => 'nullable|in:upload,checkout', // Source de l'ordonnance
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation échouée',
                'errors' => $e->errors(),
            ], 422);
        }

        $imagePaths = [];

        try {
            foreach ($request->file('images') as $image) {
                $filename = Str::uuid() . '.' . $image->getClientOriginalExtension();
                // Store prescriptions in private storage for security
                $path = $image->storeAs('prescriptions/' . $request->user()->id, $filename, 'private');
                $imagePaths[] = $path;
            }
        } catch (\Exception $e) {
            \Log::error('Prescription upload error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'enregistrement des images',
            ], 500);
        }

        $prescription = Prescription::create([
            'customer_id' => $request->user()->id,
            'images' => $imagePaths,
            'notes' => $request->notes,
            'status' => 'pending',
            'source' => $request->input('source', 'upload'), // Par défaut 'upload'
        ]);

        // Ne notifier les pharmacies que pour les uploads directs (pas checkout)
        // Les ordonnances de checkout sont déjà liées à une commande
        if ($prescription->source === Prescription::SOURCE_UPLOAD) {
            try {
                // Limiter aux pharmacies approuvées (max 20) pour éviter de spammer
                $pharmacyUsers = \App\Models\User::where('role', 'pharmacy')
                    ->whereHas('pharmacies', fn($q) => $q->where('status', 'approved'))
                    ->limit(20)
                    ->get();

                foreach($pharmacyUsers as $pharmacyUser) {
                     $pharmacyUser->notify(new \App\Notifications\NewPrescriptionNotification($prescription));
                }
            } catch (\Exception $e) {
                // Notification failure shouldn't block the upload
                \Log::warning('Prescription notification error: ' . $e->getMessage());
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Prescription uploaded successfully',
            'data' => new PrescriptionResource($prescription),
        ], 201);
    }

    /**
     * Get prescription details
     */
    public function show(Request $request, $id)
    {
        $prescription = $request->user()->prescriptions()->with('order')->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => new PrescriptionResource($prescription),
        ]);
    }

    /**
     * Pay for a quoted prescription.
     */
    public function pay(Request $request, string $id)
    {
        $prescription = \App\Models\Prescription::where('customer_id', $request->user()->id)->findOrFail($id);

        if ($prescription->status !== 'quoted') {
            return response()->json(['message' => 'Cette ordonnance n\'a pas de devis validé.'], 400);
        }

        // 1. Create Order from Prescription
        // In a real app, you might want to create the Order first, then Payment.
        // For this MVP, we simulate a direct transformation.
        
        // Résoudre la pharmacie qui a validé le devis
        $pharmacyUser = \App\Models\User::find($prescription->validated_by);
        $pharmacyIdToUse = null;

        if ($pharmacyUser) {
            if ($pharmacyUser->pharmacy_id) {
                $pharmacyIdToUse = $pharmacyUser->pharmacy_id;
            } elseif (method_exists($pharmacyUser, 'pharmacies') && $pharmacyUser->pharmacies->isNotEmpty()) {
                $pharmacyIdToUse = $pharmacyUser->pharmacies->first()->id;
            }
        }

        // SECURITY: Ne JAMAIS fallback sur un pharmacy_id arbitraire
        if (!$pharmacyIdToUse) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible d\'identifier la pharmacie. Veuillez contacter le support.',
            ], 400);
        }

        $order = \App\Models\Order::create([
            'reference' => 'ORD-' . strtoupper(uniqid()),
            'pharmacy_id' => $pharmacyIdToUse,
            'customer_id' => $request->user()->id,
            'status' => 'paid', // Immediately paid for this flow
            'payment_mode' => $request->input('payment_method', 'mobile_money'),
            'subtotal' => $prescription->quote_amount,
            'delivery_fee' => 0, // Simplified
            'total_amount' => $prescription->quote_amount,
            'customer_notes' => $prescription->notes,
            'pharmacy_notes' => $prescription->pharmacy_notes,
            'delivery_address' => $request->input('delivery_address', 'Retrait en pharmacie'), // Default or from request
            // Use raw images method to get relative path, not the absolute URL from accessor
            'prescription_image' => ($prescription->getRawImages()[0] ?? null),
        ]);

        // 2. Create Payment Record
        \App\Models\Payment::create([
            'order_id' => $order->id,
            'provider' => 'jeko',
            'reference' => 'PAY-' . strtoupper(uniqid()),
            'amount' => $prescription->quote_amount,
            'status' => 'SUCCESS',
            'confirmed_at' => now(),
            'payment_method' => $request->input('payment_method', 'mobile_money'),
        ]);

        // 3. Update Prescription Status
        $prescription->update(['status' => 'paid']);

        // 4. Notification? (Optional but good)

        return response()->json([
            'message' => 'Paiement effectué avec succès',
            'order' => $order,
            'prescription_status' => 'paid'
        ]);
    }
}
