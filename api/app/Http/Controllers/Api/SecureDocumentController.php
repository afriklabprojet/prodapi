<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Courier;
use App\Models\Delivery;
use App\Models\Prescription;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

/**
 * Sert les documents sécurisés avec vérification d'autorisation.
 * 
 * SECURITY: Chaque type de document a ses propres règles d'accès.
 */
class SecureDocumentController extends Controller
{
    private const ALLOWED_TYPES = [
        'kyc',
        'prescriptions',
        'delivery-proofs',
        'support-attachments',
    ];

    public function serve(Request $request, string $type, string $filename): StreamedResponse|JsonResponse
    {
        if (!in_array($type, self::ALLOWED_TYPES, true)) {
            return response()->json(['success' => false, 'message' => 'Type de document invalide'], 404);
        }

        // Sécurité : empêcher la traversée de répertoire (path traversal)
        $filename = str_replace(['..', '\\'], '', $filename);
        $filename = ltrim($filename, '/');
        
        // Valider que le chemin ne contient que des caractères sûrs
        if (!preg_match('/^[a-zA-Z0-9\/_\-\.]+$/', $filename)) {
            return response()->json(['success' => false, 'message' => 'Chemin invalide'], 400);
        }

        $path = "{$type}/{$filename}";

        if (!Storage::disk('private')->exists($path)) {
            return response()->json(['success' => false, 'message' => 'Document introuvable'], 404);
        }

        // SECURITY: Vérifier l'autorisation d'accès selon le type de document
        $this->authorizeDocumentAccess($request, $type, $filename);

        /** @var \Illuminate\Filesystem\FilesystemAdapter $disk */
        $disk = Storage::disk('private');
        $mimeType = $disk->mimeType($path);

        return $disk->response($path, null, [
            'Content-Type' => $mimeType,
            'Cache-Control' => 'private, max-age=3600',
        ]);
    }

    public function getTemporaryUrl(Request $request, string $type, string $filename): JsonResponse
    {
        if (!in_array($type, self::ALLOWED_TYPES, true)) {
            return response()->json(['success' => false, 'message' => 'Type de document invalide'], 404);
        }

        // Sécurité : empêcher la traversée de répertoire (path traversal)
        $filename = str_replace(['..', '\\'], '', $filename);
        $filename = ltrim($filename, '/');
        
        if (!preg_match('/^[a-zA-Z0-9\/_\-\.]+$/', $filename)) {
            return response()->json(['success' => false, 'message' => 'Chemin invalide'], 400);
        }

        $path = "{$type}/{$filename}";

        if (!Storage::disk('private')->exists($path)) {
            return response()->json(['success' => false, 'message' => 'Document introuvable'], 404);
        }

        // SECURITY: Vérifier l'autorisation d'accès selon le type de document
        $this->authorizeDocumentAccess($request, $type, $filename);

        $url = route('secure.document', ['type' => $type, 'filename' => $filename]);

        return response()->json([
            'success' => true,
            'data' => ['url' => $url],
        ]);
    }

    /**
     * Vérifie l'autorisation d'accès à un document selon son type.
     * 
     * @throws AccessDeniedHttpException
     */
    private function authorizeDocumentAccess(Request $request, string $type, string $filename): void
    {
        $user = $request->user();

        if (!$user) {
            throw new AccessDeniedHttpException('Authentification requise');
        }

        // Admin a accès à tout
        if ($user->isAdmin()) {
            return;
        }

        switch ($type) {
            case 'kyc':
                $this->authorizeKycAccess($user, $filename);
                break;

            case 'prescriptions':
                $this->authorizePrescriptionAccess($user, $filename);
                break;

            case 'delivery-proofs':
                $this->authorizeDeliveryProofAccess($user, $filename);
                break;

            case 'support-attachments':
                $this->authorizeSupportAttachmentAccess($user, $filename);
                break;

            default:
                throw new AccessDeniedHttpException('Type de document non autorisé');
        }
    }

    /**
     * KYC: Seul le livreur propriétaire ou admin peut voir ses documents KYC.
     */
    private function authorizeKycAccess($user, string $filename): void
    {
        // Format typique: kyc/{courier_id}/document.pdf
        $parts = explode('/', $filename);
        
        if (count($parts) >= 1) {
            $courierId = (int) $parts[0];
            
            // Vérifier si l'utilisateur est le propriétaire du profil courier
            $courier = $user->courier;
            
            if ($courier && $courier->id === $courierId) {
                return; // Autorisé
            }
        }

        Log::warning('KYC access denied', [
            'user_id' => $user->id,
            'filename' => $filename,
        ]);
        
        throw new AccessDeniedHttpException('Vous n\'êtes pas autorisé à accéder à ce document KYC');
    }

    /**
     * Prescriptions: Client propriétaire ou utilisateur pharmacien.
     * 
     * Format du path stocké : prescriptions/{customer_id}/{filename}
     * Le paramètre $filename reçu ici = "{customer_id}/{filename}" (sans le préfixe "prescriptions/")
     */
    private function authorizePrescriptionAccess($user, string $filename): void
    {
        // Les utilisateurs avec le rôle pharmacy ont accès à toutes les images
        // (leurs routes API sont déjà protégées par le middleware pharmacy)
        if ($user->role === 'pharmacy') {
            return;
        }

        // Pour les clients : le path commence par leur propre customer_id
        // Format: {customer_id}/{uuid}.jpg
        $parts = explode('/', $filename);
        if (count($parts) >= 1 && (int) $parts[0] === $user->id) {
            return;
        }

        // Fallback : recherche dans le champ JSON 'images' (pour anciens formats)
        $fullPath = 'prescriptions/' . $filename;
        $prescription = Prescription::where('images', 'LIKE', '%' . $filename . '%')->first();

        if ($prescription && $prescription->customer_id === $user->id) {
            return;
        }

        Log::warning('Prescription access denied', [
            'user_id'  => $user->id,
            'role'     => $user->role,
            'filename' => $filename,
            'path'     => $fullPath,
        ]);

        throw new AccessDeniedHttpException('Vous n\'êtes pas autorisé à accéder à cette ordonnance');
    }

    /**
     * Delivery Proofs: Participants de la livraison (client, pharmacie, livreur).
     */
    private function authorizeDeliveryProofAccess($user, string $filename): void
    {
        // Format typique: delivery-proofs/{delivery_id}/proof.jpg
        $parts = explode('/', $filename);
        
        if (count($parts) >= 1) {
            $deliveryId = (int) $parts[0];
            
            $delivery = Delivery::with(['order.customer', 'order.pharmacy', 'courier'])->find($deliveryId);
            
            if ($delivery) {
                // Client peut accéder
                if ($delivery->order && $delivery->order->customer_id === $user->id) {
                    return;
                }
                
                // Pharmacie peut accéder
                if ($delivery->order && $user->pharmacies()->where('pharmacies.id', $delivery->order->pharmacy_id)->exists()) {
                    return;
                }
                
                // Livreur peut accéder
                $courier = $user->courier;
                if ($courier && $delivery->courier_id === $courier->id) {
                    return;
                }
            }
        }

        Log::warning('Delivery proof access denied', [
            'user_id' => $user->id,
            'filename' => $filename,
        ]);
        
        throw new AccessDeniedHttpException('Vous n\'êtes pas autorisé à accéder à cette preuve de livraison');
    }

    /**
     * Support Attachments: Créateur du ticket ou agent support.
     */
    private function authorizeSupportAttachmentAccess($user, string $filename): void
    {
        // Format typique: support-attachments/{ticket_id}/file.jpg ou support-attachments/{user_id}/...
        $parts = explode('/', $filename);
        
        if (count($parts) >= 1) {
            // Vérifier si c'est un ticket ID ou un user ID
            $firstPart = (int) $parts[0];
            
            // Si c'est l'ID de l'utilisateur, autoriser
            if ($firstPart === $user->id) {
                return;
            }
            
            // Si l'utilisateur a le rôle support, autoriser
            if ($user->role === 'support' || $user->isAdmin()) {
                return;
            }
        }

        Log::warning('Support attachment access denied', [
            'user_id' => $user->id,
            'filename' => $filename,
        ]);
        
        throw new AccessDeniedHttpException('Vous n\'êtes pas autorisé à accéder à ce document');
    }
}
