<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Models\Prescription;
use App\Http\Resources\PrescriptionResource;
use App\Services\PrescriptionOcrService;
use App\Services\ProductMatchingService;
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

        // Calculer le hash SHA-256 de la première image pour détection de doublons
        $imageHash = null;
        try {
            $firstImagePath = $imagePaths[0];
            $disk = Storage::disk('private');
            if ($disk->exists($firstImagePath)) {
                $imageHash = hash('sha256', $disk->get($firstImagePath));
            }
        } catch (\Exception $e) {
            \Log::warning('Image hash calculation failed: ' . $e->getMessage());
        }

        // Vérifier si une ordonnance identique existe déjà pour ce client
        $isDuplicate = false;
        $existingPrescription = null;
        if ($imageHash) {
            $existingPrescription = Prescription::where('image_hash', $imageHash)
                ->where('customer_id', $request->user()->id)
                ->latest()
                ->first();

            if ($existingPrescription) {
                $isDuplicate = true;
            }
        }

        $prescription = Prescription::create([
            'customer_id' => $request->user()->id,
            'images' => $imagePaths,
            'notes' => $request->notes,
            'status' => 'pending',
            'source' => $request->input('source', 'upload'),
            'image_hash' => $imageHash,
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
            'message' => $isDuplicate
                ? 'Attention : cette ordonnance semble avoir déjà été soumise.'
                : 'Prescription uploaded successfully',
            'data' => new PrescriptionResource($prescription),
            'is_duplicate' => $isDuplicate,
            'existing_prescription_id' => $existingPrescription?->id,
            'existing_status' => $existingPrescription?->status,
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

    /**
     * Analyse une image d'ordonnance via OCR et match les produits
     */
    public function ocr(Request $request, PrescriptionOcrService $ocrService, ProductMatchingService $matchingService)
    {
        try {
            $request->validate([
                'image' => 'required|image|mimes:jpeg,png,jpg,gif,webp|max:10240',
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation échouée',
                'errors' => $e->errors(),
            ], 422);
        }

        try {
            // Store the image temporarily
            $image = $request->file('image');
            $filename = 'ocr_' . Str::uuid() . '.' . $image->getClientOriginalExtension();
            $path = $image->storeAs('temp/ocr', $filename, 'public');

            // Run OCR analysis
            $ocrResult = $ocrService->analyzeImage($path);

            if (!$ocrResult['success']) {
                // Clean up temp file
                Storage::disk('public')->delete($path);
                return response()->json([
                    'success' => false,
                    'message' => $ocrResult['error'] ?? 'Erreur lors de l\'analyse OCR',
                ], 400);
            }

            // Match medications with products
            $medications = $ocrResult['medications'] ?? [];
            $matchResult = $matchingService->matchMedications($medications);

            // Build response with matched products
            $matchedProducts = collect($matchResult['matched'])->map(function ($match) {
                return [
                    'name' => $match['medication'],
                    'dosage' => null, // Could be parsed from medication name
                    'frequency' => null,
                    'quantity' => 1,
                    'confidence' => $match['match_score'] ?? 0,
                    'product_id' => $match['product_id'],
                    'product_name' => $match['product_name'],
                    'price' => $match['price'],
                    'pharmacy_name' => $match['pharmacy_name'],
                ];
            })->toArray();

            // Unmatched = not_found + out_of_stock
            $unmatchedMedications = collect($matchResult['not_found'])
                ->pluck('medication')
                ->merge(collect($matchResult['out_of_stock'])->pluck('medication'))
                ->unique()
                ->values()
                ->toArray();

            // Clean up temp file
            Storage::disk('public')->delete($path);

            return response()->json([
                'success' => true,
                'matched_products' => $matchedProducts,
                'unmatched_medications' => $unmatchedMedications,
                'confidence' => $ocrResult['confidence'] ?? 0,
                'raw_text' => $ocrResult['raw_text'] ?? '',
                'is_prescription' => $ocrResult['is_prescription'] ?? false,
                'stats' => $matchResult['stats'] ?? null,
            ]);

        } catch (\Exception $e) {
            \Log::error('OCR analysis error: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString(),
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'analyse de l\'ordonnance',
            ], 500);
        }
    }
}
