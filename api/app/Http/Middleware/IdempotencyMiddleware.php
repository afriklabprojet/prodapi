<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Symfony\Component\HttpFoundation\Response;

/**
 * Idempotency Middleware — empêche les double-soumissions (paiement, commande, retrait).
 *
 * Le client envoie un header `Idempotency-Key: <uuid>`.
 * Si la même clé est rejouée dans le TTL, on renvoie la réponse mise en cache.
 */
class IdempotencyMiddleware
{
    private const CACHE_PREFIX = 'idempotency:';
    private const TTL_SECONDS = 86400; // 24 h

    public function handle(Request $request, Closure $next): Response
    {
        // N'appliquer que sur les mutations
        if (! in_array($request->method(), ['POST', 'PUT', 'PATCH', 'DELETE'])) {
            return $next($request);
        }

        $key = $request->header('Idempotency-Key') ?? $request->header('X-Idempotency-Key');

        if (! $key) {
            return $next($request);
        }

        $cacheKey = self::CACHE_PREFIX . md5($key . ':' . $request->user()?->id);

        // Vérifier si déjà traité
        $cached = Cache::get($cacheKey);
        if ($cached !== null) {
            return response()->json(
                $cached['body'],
                $cached['status'],
                array_merge($cached['headers'] ?? [], ['X-Idempotent-Replay' => 'true'])
            );
        }

        // Poser un lock pour empêcher le traitement en parallèle
        $lock = Cache::lock($cacheKey . ':lock', 30);

        if (! $lock->get()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Requête en cours de traitement, veuillez patienter',
            ], 409);
        }

        try {
            /** @var Response $response */
            $response = $next($request);

            // Mettre en cache uniquement les réponses de succès (2xx)
            if ($response->isSuccessful()) {
                $body = json_decode($response->getContent(), true) ?? $response->getContent();
                Cache::put($cacheKey, [
                    'body' => $body,
                    'status' => $response->getStatusCode(),
                    'headers' => ['Content-Type' => 'application/json'],
                ], self::TTL_SECONDS);
            }

            return $response;
        } finally {
            $lock->release();
        }
    }
}
