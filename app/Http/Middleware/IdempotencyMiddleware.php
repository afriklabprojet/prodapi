<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

/**
 * Idempotency Middleware — empêche les double-soumissions (paiement, commande, retrait).
 *
 * Le client envoie un header `Idempotency-Key: <uuid>`.
 *   - Même clé + même payload  → on renvoie la réponse mise en cache.
 *   - Même clé + payload différent → 409 (réutilisation incorrecte de la clé).
 *   - Première requête en cours → 409 (lock).
 *
 * Usage : ->middleware('idempotent')                 (TTL 24h, scope global)
 *         ->middleware('idempotent:payment,86400')   (scope + ttl custom)
 */
class IdempotencyMiddleware
{
    private const CACHE_PREFIX = 'idempotency:';
    private const TTL_SECONDS = 86400; // 24 h
    private const KEY_MIN = 8;
    private const KEY_MAX = 128;

    public function handle(Request $request, Closure $next, string $scope = 'default', ?int $ttl = null): Response
    {
        // N'appliquer que sur les mutations
        if (! in_array($request->method(), ['POST', 'PUT', 'PATCH', 'DELETE'])) {
            return $next($request);
        }

        $key = $request->header('Idempotency-Key') ?? $request->header('X-Idempotency-Key');

        if (! $key) {
            return $next($request);
        }

        $key = trim($key);
        $len = strlen($key);
        if ($len < self::KEY_MIN || $len > self::KEY_MAX) {
            return response()->json([
                'success' => false,
                'message' => 'Idempotency-Key invalide (8 à 128 caractères)',
                'error_code' => 'IDEMPOTENCY_KEY_INVALID',
            ], 400);
        }

        $userId = $request->user()?->id ?? 'anon';
        $cacheKey = self::CACHE_PREFIX . md5("{$scope}:{$userId}:{$key}");
        $payloadHash = $this->hashPayload($request);
        $effectiveTtl = $ttl ?? self::TTL_SECONDS;

        // Vérifier si déjà traité
        $cached = Cache::get($cacheKey);
        if ($cached !== null) {
            // Sécurité : la clé doit être réutilisée avec EXACTEMENT le même payload.
            if (($cached['payload_hash'] ?? null) !== $payloadHash) {
                Log::warning('[Idempotency] clé réutilisée avec un payload différent', [
                    'scope' => $scope,
                    'user_id' => $userId,
                ]);
                return response()->json([
                    'success' => false,
                    'message' => 'Idempotency-Key déjà utilisée avec un autre payload',
                    'error_code' => 'IDEMPOTENCY_KEY_REUSED',
                ], 409);
            }

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
                'success' => false,
                'message' => 'Requête en cours de traitement, veuillez patienter',
                'error_code' => 'IDEMPOTENCY_IN_FLIGHT',
            ], 409);
        }

        try {
            /** @var Response $response */
            $response = $next($request);

            // Mettre en cache : 2xx (succès) ET 4xx (erreurs métier déterministes
            // comme stock insuffisant, paiement déjà en cours...). Pas les 5xx.
            if ($response->getStatusCode() < 500) {
                $body = json_decode($response->getContent(), true) ?? $response->getContent();
                Cache::put($cacheKey, [
                    'payload_hash' => $payloadHash,
                    'body' => $body,
                    'status' => $response->getStatusCode(),
                    'headers' => ['Content-Type' => 'application/json'],
                ], $effectiveTtl);
            }

            return $response;
        } finally {
            $lock->release();
        }
    }

    private function hashPayload(Request $request): string
    {
        return hash('sha256', json_encode([
            'method' => $request->method(),
            'path'   => $request->path(),
            'body'   => $request->all(),
        ], JSON_UNESCAPED_SLASHES));
    }
}
