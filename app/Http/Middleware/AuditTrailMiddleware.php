<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

/**
 * Middleware d'audit trail pour les actions admin.
 * 
 * Log toutes les actions modifiantes (POST, PUT, PATCH, DELETE) dans admin_audit_logs.
 * Installé sur les routes admin et Filament.
 */
class AuditTrailMiddleware
{
    /**
     * Méthodes HTTP qui modifient des données.
     */
    private const MUTABLE_METHODS = ['POST', 'PUT', 'PATCH', 'DELETE'];

    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        // Logger uniquement les actions modifiantes qui ont réussi
        if (
            in_array($request->method(), self::MUTABLE_METHODS)
            && $response->getStatusCode() < 400
            && $request->user()
        ) {
            $this->logAction($request, $response);
        }

        return $response;
    }

    private function logAction(Request $request, Response $response): void
    {
        try {
            // Masquer les données sensibles
            $requestData = $request->except([
                'password', 'password_confirmation', 'pin', 'old_pin', 'new_pin',
                'token', 'secret', 'credit_card', 'cvv',
            ]);

            DB::table('admin_audit_logs')->insert([
                'user_id' => $request->user()->id,
                'user_name' => $request->user()->name,
                'action' => $request->method(),
                'url' => $request->path(),
                'route' => $request->route()?->getName(),
                'request_data' => json_encode($requestData, JSON_UNESCAPED_UNICODE),
                'response_status' => $response->getStatusCode(),
                'ip_address' => $request->ip(),
                'user_agent' => substr($request->userAgent() ?? '', 0, 500),
                'created_at' => now(),
            ]);
        } catch (\Throwable $e) {
            // Ne jamais bloquer la requête si l'audit échoue
            report($e);
        }
    }
}
