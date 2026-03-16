<?php

namespace App\Http\Controllers\Api\Pharmacy;

use App\Http\Controllers\Controller;
use App\Models\Prescription;
use App\Http\Resources\PrescriptionResource;
use App\Services\PrescriptionOcrService;
use App\Services\ProductMatchingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

class PrescriptionController extends Controller
{
    /**
     * Display a listing of the prescriptions.
     */
    public function index(Request $request)
    {
        // For MVP, show all prescriptions. In real app, maybe filter by location or assignment.
        $prescriptions = Prescription::with('customer')
            ->latest()
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => PrescriptionResource::collection($prescriptions)
        ]);
    }

    /**
     * Display the specified prescription.
     */
    public function show($id)
    {
        $prescription = Prescription::with('customer')->find($id);

        if (!$prescription) {
            return response()->json([
                'status' => 'error',
                'message' => 'Prescription not found'
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => new PrescriptionResource($prescription)
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
        $prescription = Prescription::with('pharmacy')->find($id);

        if (!$prescription) {
            return response()->json([
                'status' => 'error',
                'message' => 'Ordonnance non trouvée'
            ], 404);
        }

        // Vérifier si déjà analysée
        if ($prescription->analysis_status === 'completed' && !$request->boolean('force')) {
            return response()->json([
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
            // Récupérer les images de l'ordonnance
            $images = $prescription->images ?? [];
            if (empty($images)) {
                throw new \Exception('Aucune image d\'ordonnance à analyser');
            }

            // Utiliser la première image pour l'OCR
            $imagePath = is_array($images) ? $images[0] : $images;
            
            // Vérifier si c'est une URL ou un chemin de fichier local
            if (filter_var($imagePath, FILTER_VALIDATE_URL)) {
                $imageUrl = $imagePath;
            } else {
                // Construire l'URL complète pour l'image stockée
                $imageUrl = Storage::disk('public')->url($imagePath);
            }

            // Analyser avec le service OCR
            $ocrService = new PrescriptionOcrService();
            $ocrResult = $ocrService->analyzeImage($imageUrl);

            if (!$ocrResult['success']) {
                throw new \Exception($ocrResult['error'] ?? 'Échec de l\'analyse OCR');
            }

            // Extraire les médicaments
            $medications = $ocrResult['medications'] ?? [];
            
            if (empty($medications)) {
                // Aucun médicament détecté, marquer pour révision manuelle
                $prescription->analysis_status = 'manual_review';
                $prescription->analysis_error = 'Aucun médicament détecté dans l\'ordonnance';
                $prescription->ocr_raw_text = $ocrResult['raw_text'] ?? '';
                $prescription->analyzed_at = now();
                $prescription->save();

                return response()->json([
                    'status' => 'warning',
                    'message' => 'Aucun médicament détecté - révision manuelle requise',
                    'data' => [
                        'prescription' => new PrescriptionResource($prescription),
                        'raw_text' => $ocrResult['raw_text'] ?? '',
                        'is_prescription' => $ocrResult['is_prescription'] ?? false,
                    ]
                ]);
            }

            // Matcher avec le stock
            $pharmacyId = $prescription->pharmacy_id;
            $matchingService = new ProductMatchingService();
            $matchResult = $matchingService->matchMedications($medications, $pharmacyId);

            // Mettre à jour l'ordonnance
            $prescription->extracted_medications = $medications;
            $prescription->matched_products = $matchResult['matched'];
            $prescription->unmatched_medications = array_merge(
                $matchResult['not_found'], 
                $matchResult['out_of_stock']
            );
            $prescription->ocr_confidence = $ocrResult['confidence'] ?? 0;
            $prescription->analyzed_at = now();
            $prescription->analysis_status = 'completed';
            $prescription->ocr_raw_text = $ocrResult['raw_text'] ?? '';
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
        $pharmacyId = $request->user()->pharmacy_id;

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
}
