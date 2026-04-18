<?php

namespace App\Http\Controllers\Api\Courier;

use App\Http\Controllers\Controller;
use App\Services\KycValidationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class KycController extends Controller
{
    protected $kycService;

    public function __construct(KycValidationService $kycService)
    {
        $this->kycService = $kycService;
    }

    /**
     * Get KYC status and current documents
     */
    public function status(Request $request)
    {
        $user = $request->user();
        
        if ($user->role !== 'courier') {
            return response()->json([
                'success' => false,
                'message' => 'Accès non autorisé',
            ], 403);
        }
        
        $courier = $user->courier;
        
        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil coursier non trouvé',
            ], 404);
        }
        
        return response()->json([
            'success' => true,
            'data' => [
                'kyc_status' => $courier->kyc_status,
                'kyc_rejection_reason' => $courier->kyc_rejection_reason,
                'kyc_verified_at' => $courier->kyc_verified_at?->toIso8601String(),
                'documents' => [
                    'id_card_front' => !empty($courier->id_card_front_document),
                    'id_card_back' => !empty($courier->id_card_back_document),
                    'selfie' => !empty($courier->selfie_document),
                    'driving_license_front' => !empty($courier->driving_license_front_document),
                    'driving_license_back' => !empty($courier->driving_license_back_document),
                    'vehicle_registration' => !empty($courier->vehicle_registration_document),
                ],
            ],
        ]);
    }
    
    /**
     * Resoumettre des documents KYC
     */
    public function resubmit(Request $request)
    {
        $user = $request->user();
        
        if ($user->role !== 'courier') {
            return response()->json([
                'success' => false,
                'message' => 'Accès non autorisé',
            ], 403);
        }
        
        $courier = $user->courier;
        
        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil coursier non trouvé',
            ], 404);
        }
        
        // Seuls les statuts incomplete ou rejected peuvent resoumettre
        if (!in_array($courier->kyc_status, ['incomplete', 'rejected'])) {
            return response()->json([
                'success' => false,
                'message' => 'Vous ne pouvez pas resoumettre de documents dans votre état actuel.',
            ], 400);
        }
        
        $request->validate([
            'id_card_front_document' => 'nullable|file|mimetypes:image/jpeg,image/png,application/pdf|max:5120',
            'id_card_back_document' => 'nullable|file|mimetypes:image/jpeg,image/png,application/pdf|max:5120',
            'selfie_document' => 'nullable|file|mimetypes:image/jpeg,image/png|max:5120',
            'driving_license_front_document' => 'nullable|file|mimetypes:image/jpeg,image/png,application/pdf|max:5120',
            'driving_license_back_document' => 'nullable|file|mimetypes:image/jpeg,image/png,application/pdf|max:5120',
            'vehicle_registration_document' => 'nullable|file|mimetypes:image/jpeg,image/png,application/pdf|max:5120',
        ]);
        
        // Validation KYC via Google Vision (si activé)
        $kycErrors = [];
        $kycDetails = [];
        
        if ($request->hasFile('selfie_document')) {
            $result = $this->kycService->validateSelfie($request->file('selfie_document')->getRealPath());
            $kycDetails['selfie'] = $result;
            if (!$result['valid'] && !($result['skipped'] ?? false)) {
                $kycErrors['selfie_document'] = [$result['reason']];
            }
        }
        
        if ($request->hasFile('id_card_front_document')) {
            $result = $this->kycService->validateIdCard($request->file('id_card_front_document')->getRealPath());
            $kycDetails['id_card_front'] = $result;
            if (!$result['valid'] && !($result['skipped'] ?? false)) {
                $kycErrors['id_card_front_document'] = [$result['reason']];
            }
        }
        
        if ($request->hasFile('id_card_back_document')) {
            $result = $this->kycService->validateIdCardBack($request->file('id_card_back_document')->getRealPath());
            $kycDetails['id_card_back'] = $result;
            if (!$result['valid'] && !($result['skipped'] ?? false)) {
                $kycErrors['id_card_back_document'] = [$result['reason']];
            }
        }
        
        if (!empty($kycErrors)) {
            return response()->json([
                'success' => false,
                'message' => 'Les documents soumis ne sont pas valides.',
                'errors' => $kycErrors,
                'validation_details' => $kycDetails,
            ], 422);
        }
        
        $updates = [];
        $uploadedCount = 0;
        
        // Traiter chaque document uploadé
        $documentFields = [
            'id_card_front_document',
            'id_card_back_document',
            'selfie_document',
            'driving_license_front_document',
            'driving_license_back_document',
            'vehicle_registration_document',
        ];
        
        foreach ($documentFields as $field) {
            if ($request->hasFile($field)) {
                // Supprimer l'ancien fichier si présent
                if (!empty($courier->$field)) {
                    Storage::disk('private')->delete($courier->$field);
                }
                
                // Stocker le nouveau fichier
                $path = $request->file($field)->store(
                    "courier-documents/{$user->id}", 
                    'private'
                );
                
                $updates[$field] = $path;
                $uploadedCount++;
            }
        }
        
        if ($uploadedCount === 0) {
            return response()->json([
                'success' => false,
                'message' => 'Veuillez télécharger au moins un document.',
            ], 400);
        }
        
        // Mettre à jour les documents
        $courier->update($updates);
        
        // Vérifier si les documents obligatoires sont présents
        $hasRequiredDocs = !empty($courier->id_card_front_document) 
            && !empty($courier->id_card_back_document) 
            && !empty($courier->selfie_document);
        
        // Mettre à jour le statut KYC
        if ($hasRequiredDocs) {
            $courier->update([
                'kyc_status' => 'pending_review',
                'kyc_rejection_reason' => null,
            ]);
            
            $message = 'Documents soumis avec succès. Votre dossier est maintenant en cours de vérification.';
        } else {
            $message = 'Documents partiellement téléchargés. Veuillez soumettre tous les documents obligatoires (CNI recto/verso et selfie).';
        }
        
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => [
                'kyc_status' => $courier->kyc_status,
                'documents_uploaded' => $uploadedCount,
                'has_required_docs' => $hasRequiredDocs,
            ],
        ]);
    }
}
