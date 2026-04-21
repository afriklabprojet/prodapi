<?php

namespace App\Http\Controllers\Api\Customer;

use App\Enums\JekoPaymentMethod;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Prescription;
use App\Http\Resources\PrescriptionResource;
use App\Services\JekoPaymentService;
use App\Services\PerceptualHashService;
use App\Services\PrescriptionOcrService;
use App\Services\ProductMatchingService;
use App\Services\WalletService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class PrescriptionController extends Controller
{
    public function __construct(private JekoPaymentService $jekoService) {}
    /**
     * Get customer prescriptions
     */
    public function index(Request $request)
    {
        $prescriptions = $request->user()->prescriptions()
            ->with([
                'order:id,reference,status',
                'pharmacy:id,name,address,latitude,longitude',
            ])
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
            Log::error('Prescription upload error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'enregistrement des images',
            ], 500);
        }

        // Détection de doublons : SHA-256 (exact) + multi-hash perceptuel (re-photos manuscrites)
        $imageHashes = $this->computeImageHashes($imagePaths[0] ?? null);
        $duplicate = $this->findDuplicatePrescription(
            customerId: $request->user()->id,
            hashes: $imageHashes,
        );

        // 🔒 BLOQUER les doublons exacts et similaires (2+ hashes correspondent)
        // Raison : prévention fraude médicamenteuse, substances contrôlées
        // Pour les ordonnances manuscrites au BIC : on compare 3 hashes différents
        if ($duplicate) {
            $isBlockedDuplicate = $duplicate['match'] === 'exact' 
                || $duplicate['match'] === 'similar';
            
            if ($isBlockedDuplicate) {
                // Supprimer les images uploadées (nettoyage)
                foreach ($imagePaths as $path) {
                    Storage::disk('private')->delete($path);
                }
                
                Log::warning('[PRESCRIPTION-DUPLICATE] Ordonnance bloquée', [
                    'customer_id' => $request->user()->id,
                    'existing_id' => $duplicate['prescription']->id,
                    'match_type' => $duplicate['match'],
                    'hash_matches' => $duplicate['hash_matches'] ?? 0,
                    'details' => $duplicate['details'] ?? [],
                ]);
                
                return response()->json([
                    'success' => false,
                    'message' => 'Cette ordonnance a déjà été soumise. Vous ne pouvez pas réutiliser la même ordonnance.',
                    'error_code' => 'DUPLICATE_PRESCRIPTION',
                    'existing_prescription_id' => $duplicate['prescription']->id,
                    'existing_status' => $duplicate['prescription']->status,
                    'existing_created_at' => $duplicate['prescription']->created_at,
                    'match_type' => $duplicate['match'],
                ], 409); // 409 Conflict
            }
        }

        $prescription = Prescription::create([
            'customer_id' => $request->user()->id,
            'images' => $imagePaths,
            'notes' => $request->notes,
            'status' => 'pending',
            'source' => $request->input('source', 'upload'),
            'image_hash' => $imageHashes['sha256'],
            'image_phash' => $imageHashes['dhash'],
            'image_ahash' => $imageHashes['ahash'],
            'image_shash' => $imageHashes['shash'],
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
                Log::warning('Prescription notification error: ' . $e->getMessage());
            }
        }

        return response()->json([
            'success' => true,
            'message' => $duplicate
                ? 'Attention : cette ordonnance semble avoir déjà été soumise.'
                : 'Prescription uploaded successfully',
            'data' => new PrescriptionResource($prescription),
            'is_duplicate' => (bool) $duplicate,
            'duplicate_match' => $duplicate['match'] ?? null,            // 'exact' | 'similar'
            'duplicate_distance' => $duplicate['distance'] ?? null,       // 0..64 si similar
            'existing_prescription_id' => $duplicate['prescription']->id ?? null,
            'existing_status' => $duplicate['prescription']->status ?? null,
            'existing_created_at' => $duplicate['prescription']->created_at ?? null,
        ], 201);
    }

    /**
     * Vérifie si une image est un doublon AVANT de l'uploader.
     * Utilisé par le module "scan caméra" du client : on envoie juste l'image,
     * on récupère immédiatement si elle correspond à une ordonnance déjà envoyée
     * (sans rien créer en base).
     */
    public function checkDuplicate(Request $request)
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
            $binary = file_get_contents($request->file('image')->getRealPath());
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => 'Image illisible'], 422);
        }

        // Calculer les 3 hashes perceptuels + SHA-256
        $svc = app(PerceptualHashService::class);
        $hashes = [
            'sha256' => hash('sha256', $binary),
            'dhash' => $svc->dhash($binary),
            'ahash' => $svc->ahash($binary),
            'shash' => $svc->structureHash($binary),
        ];

        $duplicate = $this->findDuplicatePrescription(
            customerId: $request->user()->id,
            hashes: $hashes,
        );

        return response()->json([
            'success' => true,
            'is_duplicate' => (bool) $duplicate,
            'match' => $duplicate['match'] ?? null,
            'hash_matches' => $duplicate['hash_matches'] ?? 0,
            'details' => $duplicate['details'] ?? [],
            'existing_prescription' => $duplicate
                ? [
                    'id' => $duplicate['prescription']->id,
                    'status' => $duplicate['prescription']->status,
                    'quote_amount' => $duplicate['prescription']->quote_amount,
                    'created_at' => $duplicate['prescription']->created_at,
                    'validated_at' => $duplicate['prescription']->validated_at,
                ]
                : null,
        ]);
    }

    /**
     * Calcule SHA-256 + 3 hashes perceptuels (dHash, aHash, sHash) de la première image.
     * Les 3 hashes combinés permettent de détecter les ordonnances manuscrites re-photographiées.
     * 
     * @return array{sha256:?string, dhash:?string, ahash:?string, shash:?string}
     */
    private function computeImageHashes(?string $storedPath): array
    {
        $empty = ['sha256' => null, 'dhash' => null, 'ahash' => null, 'shash' => null];
        
        if (!$storedPath) {
            return $empty;
        }
        try {
            $disk = Storage::disk('private');
            if (!$disk->exists($storedPath)) {
                return $empty;
            }
            $binary = $disk->get($storedPath);
            $sha = hash('sha256', $binary);
            
            // Calculer les 3 hashes perceptuels
            $svc = app(PerceptualHashService::class);
            $hashes = $svc->computeAllHashes($binary);
            
            return [
                'sha256' => $sha,
                'dhash' => $hashes['dhash'],
                'ahash' => $hashes['ahash'],
                'shash' => $hashes['shash'],
            ];
        } catch (\Throwable $e) {
            Log::warning('Image hash calculation failed: ' . $e->getMessage());
            return $empty;
        }
    }

    /**
     * Cherche un doublon parmi les ordonnances actives du client.
     * 
     * Détection multi-couches pour ordonnances manuscrites (BIC) :
     * 1) Match exact SHA-256 → match='exact'
     * 2) Au moins 2 des 3 hashes perceptuels correspondent → match='similar'
     *
     * @return array{prescription:Prescription,match:string,distance:int,details:array}|null
     */
    private function findDuplicatePrescription(int $customerId, array $hashes): ?array
    {
        $activeStatuses = ['pending', 'analyzed', 'quoted', 'paid', 'in_progress', 'validated'];
        $sha256 = $hashes['sha256'] ?? null;

        // 1) Match exact SHA-256
        if ($sha256) {
            $exact = Prescription::where('customer_id', $customerId)
                ->where('image_hash', $sha256)
                ->whereIn('status', $activeStatuses)
                ->latest()
                ->first();
            if ($exact) {
                return ['prescription' => $exact, 'match' => 'exact', 'distance' => 0, 'details' => []];
            }
        }

        // 2) Match multi-hash (au moins 2 sur 3 hashes correspondent)
        // Récupérer les ordonnances récentes avec au moins un hash
        $candidates = Prescription::where('customer_id', $customerId)
            ->where(function ($q) {
                $q->whereNotNull('image_phash')
                  ->orWhereNotNull('image_ahash')
                  ->orWhereNotNull('image_shash');
            })
            ->whereIn('status', $activeStatuses)
            ->where('created_at', '>=', now()->subDays(90))
            ->orderByDesc('id')
            ->limit(200)
            ->get(['id', 'image_phash', 'image_ahash', 'image_shash', 'status', 'quote_amount', 'created_at', 'validated_at']);

        if ($candidates->isEmpty()) {
            return null;
        }

        $svc = app(PerceptualHashService::class);
        $bestMatch = null;
        $bestScore = 0;

        foreach ($candidates as $candidate) {
            $candidateHashes = [
                'dhash' => $candidate->image_phash,
                'ahash' => $candidate->image_ahash,
                'shash' => $candidate->image_shash,
            ];

            $comparison = $svc->areSimilar($hashes, $candidateHashes);

            // Si au moins 2 hashes correspondent
            if ($comparison['is_similar'] && $comparison['matches'] > $bestScore) {
                $bestScore = $comparison['matches'];
                $minDistance = collect($comparison['details'])
                    ->filter(fn($d) => $d['match'] ?? false)
                    ->min('distance') ?? 0;
                    
                $bestMatch = [
                    'prescription' => $candidate,
                    'match' => 'similar',
                    'distance' => $minDistance,
                    'details' => $comparison['details'],
                    'hash_matches' => $comparison['matches'],
                ];

                // Si les 3 hashes correspondent, on a trouvé le meilleur
                if ($bestScore === 3) {
                    break;
                }
            }
        }

        return $bestMatch;
    }

    /**
     * Get prescription details
     */
    public function show(Request $request, $id)
    {
        $prescription = $request->user()->prescriptions()
            ->with([
                'order',
                'pharmacy:id,name,address,latitude,longitude',
            ])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => new PrescriptionResource($prescription),
        ]);
    }

    /**
     * Pay for a quoted prescription — initie un vrai paiement Jeko.
     */
    public function pay(Request $request, string $id)
    {
        $prescription = Prescription::where('customer_id', $request->user()->id)->findOrFail($id);

        if ($prescription->status !== 'quoted') {
            return response()->json(['message' => 'Cette ordonnance n\'a pas de devis validé.'], 400);
        }

        $validated = $request->validate([
            'payment_method'    => ['required', Rule::in(JekoPaymentMethod::values())],
            'delivery_address'  => 'required|string|max:500',
            'delivery_latitude' => 'nullable|numeric',
            'delivery_longitude' => 'nullable|numeric',
            'customer_phone'    => 'nullable|string|max:20',
        ]);

        // Résoudre la pharmacie qui a validé le devis
        $pharmacyUser    = \App\Models\User::find($prescription->validated_by);
        $pharmacyIdToUse = null;

        if ($pharmacyUser) {
            $pharmacyIdToUse = $pharmacyUser->pharmacy_id
                ?? ($pharmacyUser->pharmacies()->first()?->id ?? null);
        }

        if (!$pharmacyIdToUse) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible d\'identifier la pharmacie. Veuillez contacter le support.',
            ], 400);
        }

        // Calculer les frais de livraison selon la distance pharmacie → client
        $deliveryFee = $this->calculatePrescriptionDeliveryFee(
            $pharmacyIdToUse,
            $validated['delivery_latitude'] ?? null,
            $validated['delivery_longitude'] ?? null
        );

        // 1. Créer la commande en état pending
        $order = Order::create([
            'reference'          => Order::generateReference(),
            'pharmacy_id'        => $pharmacyIdToUse,
            'customer_id'        => $request->user()->id,
            'status'             => 'pending',
            'payment_mode'       => 'mobile_money',
            'subtotal'           => $prescription->quote_amount,
            'delivery_fee'       => $deliveryFee,
            'total_amount'       => $prescription->quote_amount + $deliveryFee,
            'currency'           => 'XOF',
            'customer_notes'     => $prescription->notes,
            'delivery_address'   => $validated['delivery_address'],
            'delivery_latitude'  => $validated['delivery_latitude'] ?? null,
            'delivery_longitude' => $validated['delivery_longitude'] ?? null,
            'customer_phone'     => $validated['customer_phone'] ?? $request->user()->phone,
            'prescription_image' => ($prescription->getRawImages()[0] ?? null),
        ]);

        // 2. Lier la prescription à la commande
        $prescription->update([
            'order_id' => $order->id,
            'status'   => 'processing',
        ]);

        // 3. Initier le vrai paiement Jeko
        try {
            $method      = JekoPaymentMethod::from($validated['payment_method']);
            $amountCents = (int) ($order->total_amount * 100);

            $jekoPayment = $this->jekoService->createRedirectPayment(
                $order,
                $amountCents,
                $method,
                $request->user(),
                "Paiement ordonnance #{$prescription->id}"
            );
        } catch (\Exception $e) {
            // Rollback : supprimer l'order créé et remettre la prescription en quoted
            $prescription->update(['order_id' => null, 'status' => 'quoted']);
            $order->forceDelete();

            Log::error('Prescription pay: Jeko initiation failed', [
                'prescription_id' => $prescription->id,
                'error'           => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Échec de l\'initialisation du paiement. ' . $e->getMessage(),
            ], 502);
        }

        return response()->json([
            'success' => true,
            'message' => 'Paiement initié. Suivez le lien pour compléter.',
            'data'    => [
                'order_id'        => $order->id,
                'order_reference' => $order->reference,
                'redirect_url'    => $jekoPayment->redirect_url,
                'reference'       => $jekoPayment->reference,
            ],
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
            Log::error('OCR analysis error: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString(),
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de l\'analyse de l\'ordonnance',
            ], 500);
        }
    }

    /**
     * Calculer les frais de livraison pour une prescription.
     */
    private function calculatePrescriptionDeliveryFee(int $pharmacyId, ?float $deliveryLat, ?float $deliveryLng): int
    {
        if ($deliveryLat === null || $deliveryLng === null) {
            return WalletService::getDeliveryFeeMin();
        }

        $pharmacy = \App\Models\Pharmacy::find($pharmacyId);
        if (!$pharmacy || !$pharmacy->latitude || !$pharmacy->longitude) {
            return WalletService::getDeliveryFeeMin();
        }

        $earthRadius = 6371;
        $dLat = deg2rad($deliveryLat - $pharmacy->latitude);
        $dLng = deg2rad($deliveryLng - $pharmacy->longitude);
        $a = sin($dLat / 2) ** 2 +
             cos(deg2rad($pharmacy->latitude)) * cos(deg2rad($deliveryLat)) *
             sin($dLng / 2) ** 2;
        $distanceKm = $earthRadius * 2 * atan2(sqrt($a), sqrt(1 - $a));

        return WalletService::calculateDeliveryFee($distanceKm);
    }
}
