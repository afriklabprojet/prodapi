<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;

/**
 * Trait pour des réponses API uniformes et cohérentes.
 * 
 * Format standard:
 * {
 *   "success": true|false,
 *   "message": "...",
 *   "data": {...},
 *   "meta": {...},       // pagination, etc.
 *   "error_code": "...", // uniquement sur erreur
 *   "errors": {...}      // validation errors
 * }
 */
trait ApiResponder
{
    protected function success($data = null, string $message = 'Opération réussie', int $code = 200, array $meta = []): JsonResponse
    {
        $response = [
            'success' => true,
            'message' => $message,
        ];

        if ($data !== null) {
            $response['data'] = $data;
        }

        if (!empty($meta)) {
            $response['meta'] = $meta;
        }

        return response()->json($response, $code);
    }

    protected function created($data = null, string $message = 'Ressource créée avec succès'): JsonResponse
    {
        return $this->success($data, $message, 201);
    }

    protected function error(
        string $message = 'Une erreur est survenue',
        int $code = 400,
        ?string $errorCode = null,
        $errors = null,
        ?string $details = null,
        ?array $action = null,
    ): JsonResponse {
        $response = [
            'success' => false,
            'message' => $message,
        ];

        if ($errorCode) {
            $response['error_code'] = $errorCode;
        }

        if ($details) {
            $response['details'] = $details;
        }

        if ($errors) {
            $response['errors'] = $errors;
        }

        // Action suggérée côté mobile (retry, redirect, contact_support, etc.)
        if ($action) {
            $response['action'] = $action;
        }

        return response()->json($response, $code);
    }

    protected function notFound(string $message = 'Ressource non trouvée', ?string $errorCode = null): JsonResponse
    {
        return $this->error($message, 404, $errorCode ?? 'NOT_FOUND');
    }

    protected function forbidden(string $message = 'Accès refusé', ?string $errorCode = null): JsonResponse
    {
        return $this->error($message, 403, $errorCode ?? 'FORBIDDEN');
    }

    protected function unauthorized(string $message = 'Non authentifié', ?string $errorCode = null): JsonResponse
    {
        return $this->error($message, 401, $errorCode ?? 'UNAUTHENTICATED');
    }

    protected function conflict(string $message = 'Conflit détecté', ?string $errorCode = null, $data = null): JsonResponse
    {
        $response = [
            'success' => false,
            'message' => $message,
            'error_code' => $errorCode ?? 'CONFLICT',
        ];

        if ($data) {
            $response['data'] = $data;
        }

        return response()->json($response, 409);
    }

    protected function validationError(string $message = 'Données invalides', $errors = null): JsonResponse
    {
        return $this->error($message, 422, 'VALIDATION_ERROR', $errors);
    }

    protected function serverError(string $message = 'Erreur interne du serveur'): JsonResponse
    {
        return $this->error($message, 500, 'INTERNAL_ERROR');
    }

    protected function paymentError(string $message, ?string $errorCode = null, $data = null): JsonResponse
    {
        $response = [
            'success' => false,
            'message' => $message,
            'error_code' => $errorCode ?? 'PAYMENT_ERROR',
        ];

        if ($data) {
            $response['data'] = $data;
        }

        // Suggérer une action de retry pour les erreurs de paiement
        $response['action'] = [
            'type' => 'retry',
            'message' => 'Vous pouvez réessayer le paiement',
        ];

        return response()->json($response, 400);
    }

    /**
     * Réponse paginée standardisée
     */
    protected function paginated($paginator, $data = null, string $message = 'Liste récupérée'): JsonResponse
    {
        return $this->success(
            $data ?? $paginator->items(),
            $message,
            200,
            [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
            ]
        );
    }
}
