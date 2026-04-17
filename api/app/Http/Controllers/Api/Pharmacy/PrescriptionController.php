<?php

namespace App\Http\Controllers\Api\Pharmacy;

use App\Http\Controllers\Controller;
use App\Models\Prescription;
use App\Models\PrescriptionDispensing;
use App\Http\Resources\PrescriptionResource;
use App\Services\PrescriptionOcrService;
use App\Services\ProductMatchingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

class PrescriptionController extends Controller
{
    /**
     * Display a listing of the prescriptions.
     */
    public function index(Request $request)
    {
        $prescriptions = Prescription::with(['customer', 'dispensings', 'dispensings.dispensedBy'])
            ->latest()
            ->get();

        // Collecter tous les image_hash non-null pour détecter les doublons en un seul query
        $hashes = $prescriptions->pluck('image_hash')->filter()->unique()->values()->all();
        $duplicateHashes = [];
        if (!empty($hashes)) {
            $duplicateHashes = Prescription::whereIn('image_hash', $hashes)
                ->where('fulfillment_status', '!=', 'none')
                ->pluck('image_hash')
                ->unique()
                ->all();
        }

        // Ajouter le flag is_duplicate à chaque prescription
        $data = PrescriptionResource::collection($prescriptions)->resolve();
        foreach ($data as &$item) {
            $prescription = $prescriptions->firstWhere('id', $item['id'] ?? null);
            $item['is_duplicate'] = $prescription
                && $prescription->image_hash
                && in_array($prescription->image_hash, $duplicateHashes)
                && $prescription->fulfillment_status === 'none';
        }

        return response()->json([
            'status' => 'success',
            'data' => $data,
        ]);
    }

    /**
     * Display the specified prescription.
     */
    public function show($id)
    {
        $prescription = Prescription::with(['customer', 'dispensings', 'dispensings.dispensedBy'])->find($id);

        if (!$prescription) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Prescription not found'
            ], 404);
        }

        // Vérifier si c'est un doublon (même image_hash sur une autre prescription)
        $duplicateInfo = null;
        if ($prescription->image_hash) {
            $duplicate = Prescription::where('image_hash', $prescription->image_hash)
                ->where('id', '!=', $prescription->id)
                ->where('fulfillment_status', '!=', 'none')
                ->with('dispensings')
                ->first();

            if ($duplicate) {
                $duplicateInfo = [
                    'prescription_id' => $duplicate->id,
                    'status' => $duplicate->status,
                    'fulfillment_status' => $duplicate->fulfillment_status,
                    'first_dispensed_at' => $duplicate->first_dispensed_at?->toIso8601String(),
                    'dispensing_count' => $duplicate->dispensing_count,
                    'created_at' => $duplicate->created_at?->toIso8601String(),
                ];
            }
        }

        return response()->json([
            'success' => true,
            'status' => 'success',
            'data' => new PrescriptionResource($prescription),
            'duplicate_info' => $duplicateInfo,
        ]);
    }

    /**
     * Update the prescription status (Validate/Reject).
     */
    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:validated,rejected,pending,quoted',
            'admin_notes' => 'nullable|string',
            'quote_amount' => 'nullable|numeric|min:0',
            'pharmacy_notes' => 'nullable|string',
        ]);

        $prescription = Prescription::find($id);

        if (!$prescription) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Prescription not found'
            ], 404);
        }

        $prescription->status = $request->status;
        
        if ($request->has('admin_notes')) {
            $prescription->admin_notes = $request->admin_notes;
        }

        if ($request->has('pharmacy_notes')) {
            $prescription->pharmacy_notes = $request->pharmacy_notes;
        }

        if ($request->has('quote_amount')) {
            $prescription->quote_amount = $request->quote_amount;
        }
        
        if ($request->status === 'validated' || $request->status === 'quoted') {
            $prescription->validated_at = now();
            $prescription->validated_by = $request->user()->id; 
        }

        $prescription->save();

        // Notify Customer
        if ($prescription->customer) {
            $prescription->customer->notify(new \App\Notifications\PrescriptionStatusNotification($prescription, $request->status));
        }

        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'Prescription status updated successfully',
            'data' => new PrescriptionResource($prescription)
        ]);
    }

    /**
     * Analyse automatique d'une ordonnance par OCR
     */
    public function analyze(Request $request, $id)
    {
        $prescription = Prescription::with('customer')->find($id);

        if (!$prescription) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Ordonnance non trouvée'
            ], 404);
        }

        // Vérifier si déjà analysée
        if ($prescription->analysis_status === 'completed' && !$request->boolean('force')) {
            return response()->json([
                'success' => true,
                'status' => 'success',
                'message' => 'Ordonnance déjà analysée',
                'data' => [
                    'prescription' => new PrescriptionResource($prescription),
                    'extracted_medications' => $prescription->extracted_medications,
                    'matched_products' => $prescription->matched_products,
                    'unmatched_medications' => $prescription->unmatched_medications,
                    'confidence' => $prescription->ocr_confidence,
                ]
            ]);
        }

        // Marquer comme en cours d'analyse
        $prescription->analysis_status = 'analyzing';
        $prescription->save();

        try {
            // Récupérer les chemins bruts des images (sans transformation URL)
            $rawImages = $prescription->getRawImages();
            if (empty($rawImages)) {
                $prescription->analysis_status = 'failed';
                $prescription->analysis_error = 'Aucune image d\'ordonnance à analyser';
                $prescription->save();

                return response()->json([
                    'success' => false,
                    'status' => 'error',
                    'message' => 'Aucune image d\'ordonnance à analyser',
                ], 422);
            }

            // Utiliser la première image pour l'OCR (chemin brut dans le storage)
            $imagePath = $rawImages[0];

            // Analyser avec le service OCR
            $ocrService = app(PrescriptionOcrService::class);
            $ocrResult = $ocrService->analyzeImage($imagePath);

            if (!$ocrResult['success']) {
                $errorMsg = $ocrResult['error'] ?? 'Échec de l\'analyse OCR';
                $prescription->analysis_status = 'failed';
                $prescription->analysis_error = $errorMsg;
                $prescription->save();

                return response()->json([
                    'success' => false,
                    'status' => 'error',
                    'message' => 'Échec de l\'analyse: ' . $errorMsg,
                ], 502);
            }

            // Extraire les médicaments
            $medications = $ocrResult['medications'] ?? [];
            
            // Sauvegarder les données OCR brutes
            $prescription->ocr_raw_text = $ocrResult['raw_text'] ?? '';
            $prescription->ocr_confidence = $ocrResult['confidence'] ?? 0;
            $prescription->analyzed_at = now();
            $prescription->extracted_medications = $medications;

            // Matcher avec le stock si pharmacy_id existe et medications trouvées
            $matchResult = ['matched' => [], 'not_found' => [], 'out_of_stock' => [], 'alternatives' => [], 'stats' => [], 'total_estimated_price' => 0];
            
            if (!empty($medications) && $prescription->pharmacy_id) {
                $matchingService = app(ProductMatchingService::class);
                $matchResult = $matchingService->matchMedications($medications, $prescription->pharmacy_id);
            }

            $prescription->matched_products = $matchResult['matched'];
            $prescription->unmatched_medications = array_merge(
                $matchResult['not_found'] ?? [], 
                $matchResult['out_of_stock'] ?? []
            );
            $prescription->analysis_status = empty($medications) ? 'manual_review' : 'completed';
            $prescription->save();

            // Calculer les alertes
            $alerts = [];
            
            if (!empty($matchResult['out_of_stock'])) {
                $alerts[] = [
                    'type' => 'stock_alert',
                    'message' => count($matchResult['out_of_stock']) . ' médicament(s) en rupture de stock',
                    'items' => $matchResult['out_of_stock'],
                ];
            }

            if (!empty($matchResult['not_found'])) {
                $alerts[] = [
                    'type' => 'not_found_alert',
                    'message' => count($matchResult['not_found']) . ' médicament(s) non trouvé(s)',
                    'items' => $matchResult['not_found'],
                ];
            }

            return response()->json([
                'success' => true,
                'status' => 'success',
                'message' => 'Ordonnance analysée avec succès',
                'data' => [
                    'prescription' => new PrescriptionResource($prescription),
                    'extracted_medications' => $medications,
                    'matched_products' => $matchResult['matched'],
                    'unmatched' => $prescription->unmatched_medications,
                    'alternatives' => $matchResult['alternatives'],
                    'stats' => $matchResult['stats'],
                    'estimated_total' => $matchResult['total_estimated_price'],
                    'confidence' => $ocrResult['confidence'] ?? 0,
                    'raw_text' => $ocrResult['raw_text'] ?? '',
                    'alerts' => $alerts,
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Prescription analysis failed', [
                'prescription_id' => $id,
                'error' => $e->getMessage(),
            ]);

            $prescription->analysis_status = 'failed';
            $prescription->analysis_error = $e->getMessage();
            $prescription->save();

            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Échec de l\'analyse: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtenir les statistiques d'analyse des ordonnances
     */
    public function analysisStats(Request $request)
    {
        $pharmacyId = $request->user()->pharmacies()->first()?->id;

        $stats = Prescription::query()
            ->when($pharmacyId, fn($q) => $q->where('pharmacy_id', $pharmacyId))
            ->selectRaw("
                COUNT(*) as total,
                SUM(CASE WHEN analysis_status = 'completed' THEN 1 ELSE 0 END) as analyzed,
                SUM(CASE WHEN analysis_status = 'pending' THEN 1 ELSE 0 END) as pending,
                SUM(CASE WHEN analysis_status = 'failed' THEN 1 ELSE 0 END) as failed,
                SUM(CASE WHEN analysis_status = 'manual_review' THEN 1 ELSE 0 END) as manual_review,
                AVG(ocr_confidence) as avg_confidence
            ")
            ->first();

        return response()->json([
            'status' => 'success',
            'data' => $stats
        ]);
    }

    /**
     * Dispenser des médicaments d'une ordonnance.
     * Crée les lignes de dispensation et met à jour le fulfillment_status.
     */
    public function dispense(Request $request, $id)
    {
        $request->validate([
            'medications' => 'required|array|min:1',
            'medications.*.medication_name' => 'required|string|max:255',
            'medications.*.product_id' => 'nullable|integer|exists:products,id',
            'medications.*.quantity_prescribed' => 'required|integer|min:1',
            'medications.*.quantity_dispensed' => 'required|integer|min:1',
        ]);

        $prescription = Prescription::with('dispensings')->find($id);

        if (!$prescription) {
            return response()->json([
                'success' => false,
                'message' => 'Ordonnance non trouvée',
            ], 404);
        }

        // Vérifier si déjà entièrement délivrée
        if ($prescription->fulfillment_status === 'full') {
            return response()->json([
                'success' => false,
                'message' => 'Cette ordonnance a déjà été entièrement délivrée.',
                'fulfillment_status' => 'full',
            ], 409);
        }

        $pharmacyUser = $request->user();
        $pharmacy = $pharmacyUser->pharmacies()->first();

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Pharmacie non trouvée',
            ], 403);
        }

        DB::beginTransaction();
        try {
            $dispensings = [];

            foreach ($request->medications as $med) {
                // Vérifier si ce médicament a déjà été dispensé pour cette ordonnance
                $existingQty = PrescriptionDispensing::where('prescription_id', $prescription->id)
                    ->where('medication_name', $med['medication_name'])
                    ->sum('quantity_dispensed');

                $remainingQty = $med['quantity_prescribed'] - $existingQty;

                if ($remainingQty <= 0) {
                    continue; // Déjà entièrement dispensé
                }

                $qtyToDispense = min($med['quantity_dispensed'], $remainingQty);

                $dispensing = PrescriptionDispensing::create([
                    'prescription_id' => $prescription->id,
                    'pharmacy_id' => $pharmacy->id,
                    'order_id' => $prescription->order_id,
                    'medication_name' => $med['medication_name'],
                    'product_id' => $med['product_id'] ?? null,
                    'quantity_prescribed' => $med['quantity_prescribed'],
                    'quantity_dispensed' => $qtyToDispense,
                    'dispensed_at' => now(),
                    'dispensed_by' => $pharmacyUser->id,
                ]);

                $dispensings[] = $dispensing;
            }

            // Recalculate fulfillment
            $prescription->recalculateFulfillment();

            DB::commit();

            // Reload with dispensings
            $prescription->load(['dispensings', 'dispensings.dispensedBy', 'customer']);

            return response()->json([
                'success' => true,
                'message' => $prescription->fulfillment_status === 'full'
                    ? 'Ordonnance entièrement délivrée.'
                    : 'Médicaments dispensés avec succès.',
                'data' => new PrescriptionResource($prescription),
                'dispensed_count' => count($dispensings),
                'fulfillment_status' => $prescription->fulfillment_status,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Prescription dispensing failed', [
                'prescription_id' => $id,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la dispensation: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Obtenir l'historique de dispensation d'une ordonnance.
     */
    public function dispensingHistory($id)
    {
        $prescription = Prescription::find($id);

        if (!$prescription) {
            return response()->json([
                'success' => false,
                'message' => 'Ordonnance non trouvée',
            ], 404);
        }

        $dispensings = PrescriptionDispensing::where('prescription_id', $id)
            ->with(['dispensedBy:id,name', 'pharmacy:id,name'])
            ->orderBy('dispensed_at', 'desc')
            ->get()
            ->map(function ($d) {
                return [
                    'id' => $d->id,
                    'medication_name' => $d->medication_name,
                    'product_id' => $d->product_id,
                    'quantity_prescribed' => $d->quantity_prescribed,
                    'quantity_dispensed' => $d->quantity_dispensed,
                    'dispensed_at' => $d->dispensed_at->toIso8601String(),
                    'dispensed_by' => $d->dispensedBy?->name,
                    'pharmacy_name' => $d->pharmacy?->name,
                ];
            });

        // Résumé par médicament
        $summary = PrescriptionDispensing::where('prescription_id', $id)
            ->selectRaw('medication_name, SUM(quantity_dispensed) as total_dispensed, MAX(quantity_prescribed) as quantity_prescribed')
            ->groupBy('medication_name')
            ->get()
            ->map(function ($row) {
                return [
                    'medication_name' => $row->medication_name,
                    'quantity_prescribed' => (int) $row->quantity_prescribed,
                    'total_dispensed' => (int) $row->total_dispensed,
                    'remaining' => max(0, (int) $row->quantity_prescribed - (int) $row->total_dispensed),
                    'fully_dispensed' => (int) $row->total_dispensed >= (int) $row->quantity_prescribed,
                ];
            });

        return response()->json([
            'success' => true,
            'data' => [
                'fulfillment_status' => $prescription->fulfillment_status,
                'dispensing_count' => $prescription->dispensing_count,
                'first_dispensed_at' => $prescription->first_dispensed_at?->toIso8601String(),
                'summary' => $summary,
                'history' => $dispensings,
            ],
        ]);
    }
}
