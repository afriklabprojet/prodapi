<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\KycValidationService;
use App\Services\LivenessService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

/**
 * Contrôleur pour la vérification de vivacité (Active Liveness)
 * 
 * Flow:
 * 1. POST /liveness/start - Démarrer une session avec challenges
 * 2. POST /liveness/validate - Valider chaque challenge avec une image
 * 3. GET /liveness/status/{sessionId} - Vérifier le statut de la session
 */
class LivenessController extends Controller
{
    public function __construct(
        private LivenessService $livenessService,
        private KycValidationService $kycService,
    ) {}

    /**
     * Démarrer une nouvelle session de vérification liveness
     * 
     * @OA\Post(
     *     path="/api/liveness/start",
     *     summary="Démarrer la vérification de vivacité",
     *     tags={"Liveness"},
     *     @OA\Response(
     *         response=200,
     *         description="Session créée avec challenges",
     *         @OA\JsonContent(
     *             @OA\Property(property="session_id", type="string"),
     *             @OA\Property(property="challenges", type="array", @OA\Items(type="object")),
     *             @OA\Property(property="current_challenge", type="object"),
     *             @OA\Property(property="total_challenges", type="integer"),
     *             @OA\Property(property="expires_in", type="integer")
     *         )
     *     )
     * )
     */
    public function start(Request $request): JsonResponse
    {
        $user = $request->user();
        $userId = $user ? $user->id : $request->ip();
        
        try {
            $session = $this->livenessService->startSession($userId);
            
            return response()->json([
                'success' => true,
                'data' => $session,
                'instructions' => [
                    'fr' => 'Suivez les instructions à l\'écran. Placez votre visage dans le cadre et effectuez les actions demandées.',
                    'en' => 'Follow the on-screen instructions. Place your face in the frame and perform the requested actions.',
                ],
            ]);
            
        } catch (\RuntimeException $e) {
            // Service Vision non disponible → signaler au client d'utiliser le fallback selfie
            Log::warning('Liveness start: service unavailable', ['user_id' => $userId, 'error' => $e->getMessage()]);
            
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'fallback' => true,
                'error' => 'service_unavailable',
            ], 503);
        } catch (\Exception $e) {
            Log::error('Liveness start error: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'message' => 'Impossible de démarrer la vérification. Veuillez réessayer.',
            ], 500);
        }
    }

    /**
     * Valider un challenge avec une image capturée
     * 
     * @OA\Post(
     *     path="/api/liveness/validate",
     *     summary="Valider un challenge liveness",
     *     tags={"Liveness"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             @OA\Property(property="session_id", type="string", description="ID de la session liveness"),
     *             @OA\Property(property="image", type="string", description="Image en base64 ou URL")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Résultat de la validation",
     *         @OA\JsonContent(
     *             @OA\Property(property="success", type="boolean"),
     *             @OA\Property(property="completed", type="boolean"),
     *             @OA\Property(property="next_challenge", type="object")
     *         )
     *     )
     * )
     */
    public function validate(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'session_id' => 'required|string|uuid',
            'image' => 'required|string', // base64 ou URL
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Paramètres invalides',
                'errors' => $validator->errors(),
            ], 422);
        }
        
        $sessionId = $request->input('session_id');
        $image = $request->input('image');
        
        try {
            // Décoder l'image si c'est du base64
            $imageContent = $image;
            
            // Si c'est une URL, télécharger l'image
            if (filter_var($image, FILTER_VALIDATE_URL)) {
                $imageContent = file_get_contents($image);
                if ($imageContent === false) {
                    return response()->json([
                        'success' => false,
                        'message' => 'Impossible de télécharger l\'image',
                    ], 400);
                }
            }
            
            $result = $this->livenessService->validateChallenge($sessionId, $imageContent);
            
            $statusCode = $result['success'] ? 200 : 400;
            
            // Si session expirée, retourner 410 Gone
            if (isset($result['error']) && $result['error'] === 'session_expired') {
                $statusCode = 410;
            }
            
            return response()->json($result, $statusCode);
            
        } catch (\Exception $e) {
            Log::error('Liveness validation error: ' . $e->getMessage(), [
                'session_id' => $sessionId,
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la validation. Veuillez réessayer.',
                'retry' => true,
            ], 500);
        }
    }

    /**
     * Vérifier le statut d'une session liveness
     * 
     * @OA\Get(
     *     path="/api/liveness/status/{sessionId}",
     *     summary="Vérifier le statut d'une session",
     *     tags={"Liveness"},
     *     @OA\Parameter(
     *         name="sessionId",
     *         in="path",
     *         required=true,
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Statut de la session",
     *         @OA\JsonContent(
     *             @OA\Property(property="valid", type="boolean"),
     *             @OA\Property(property="is_complete", type="boolean"),
     *             @OA\Property(property="completed_challenges", type="integer")
     *         )
     *     )
     * )
     */
    public function status(string $sessionId): JsonResponse
    {
        if (!preg_match('/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i', $sessionId)) {
            return response()->json([
                'success' => false,
                'message' => 'ID de session invalide',
            ], 400);
        }
        
        $status = $this->livenessService->isSessionValid($sessionId);
        
        return response()->json([
            'success' => true,
            'data' => $status,
        ]);
    }

    /**
     * Annuler/invalider une session liveness
     * 
     * @OA\Delete(
     *     path="/api/liveness/cancel/{sessionId}",
     *     summary="Annuler une session liveness",
     *     tags={"Liveness"}
     * )
     */
    public function cancel(string $sessionId): JsonResponse
    {
        if (!preg_match('/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i', $sessionId)) {
            return response()->json([
                'success' => false,
                'message' => 'ID de session invalide',
            ], 400);
        }
        
        $this->livenessService->invalidateSession($sessionId);
        
        return response()->json([
            'success' => true,
            'message' => 'Session annulée',
        ]);
    }

    /**
     * Endpoint pour valider avec upload de fichier (multipart/form-data)
     */
    public function validateWithFile(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'session_id' => 'required|string|uuid',
            'image' => 'required|file|image|max:10240', // Max 10MB
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Paramètres invalides',
                'errors' => $validator->errors(),
            ], 422);
        }
        
        $sessionId = $request->input('session_id');
        $file = $request->file('image');
        
        try {
            $imageContent = file_get_contents($file->getRealPath());
            
            $result = $this->livenessService->validateChallenge($sessionId, $imageContent);
            
            $statusCode = $result['success'] ? 200 : 400;
            
            if (isset($result['error']) && $result['error'] === 'session_expired') {
                $statusCode = 410;
            }
            
            return response()->json($result, $statusCode);
            
        } catch (\Exception $e) {
            Log::error('Liveness file validation error: ' . $e->getMessage());
            
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la validation. Veuillez réessayer.',
                'retry' => true,
            ], 500);
        }
    }

    /**
     * Diagnostic endpoint pour vérifier l'état du service Vision API
     * Accessible uniquement en local ou par un admin
     */
    public function diagnostics(Request $request): JsonResponse
    {
        // Sécurité : uniquement en local, ou avec le bon header secret
        $secret = config('services.google_vision.diagnostic_secret', 'dr-pharma-diag-2024');
        if (!app()->isLocal() && $request->header('X-Diagnostic-Secret') !== $secret) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        return response()->json([
            'success' => true,
            'liveness_service' => $this->livenessService->getDiagnostics(),
            'kyc_service' => $this->kycService->getDiagnostics(),
            'server' => [
                'php_version' => PHP_VERSION,
                'grpc_loaded' => extension_loaded('grpc'),
                'base_path' => base_path(),
                'os' => PHP_OS,
            ],
        ]);
    }
}
