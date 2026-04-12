<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Jobs\ProcessJekoWebhookJob;
use App\Models\WebhookLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

/**
 * Endpoint webhook JEKO — bulletproof.
 *
 * Principes :
 *  1. Répondre 200 IMMÉDIATEMENT (Jeko retente sinon)
 *  2. Vérification IP whitelist + signature
 *  3. Déduplication par webhook_id (anti-replay)
 *  4. Dispatch vers job asynchrone pour traitement
 */
class JekoWebhookController extends Controller
{
    /**
     * POST /api/webhooks/jeko
     */
    public function handle(Request $request): JsonResponse
    {
        $startTime = microtime(true);

        // 1. IP Whitelist — OBLIGATOIRE en production
        $allowedIps = config('services.jeko.webhook_allowed_ips', []);
        if (!empty($allowedIps)) {
            if (!in_array($request->ip(), $allowedIps)) {
                Log::warning('JEKO Webhook: IP non autorisée', [
                    'ip' => $request->ip(),
                    'allowed' => $allowedIps,
                ]);
                return response()->json(['error' => 'Forbidden'], 403);
            }
        } elseif (app()->environment('production', 'staging')) {
            // SÉCURITÉ: En production, REFUSER si la whitelist n'est pas configurée
            Log::critical('JEKO Webhook: REJETÉ — IP whitelist non configurée en production. '
                . 'IP appelante: ' . $request->ip()
                . ' — Ajoutez JEKO_WEBHOOK_IPS=' . $request->ip() . ' dans .env');
            return response()->json(['error' => 'Service unavailable'], 503);
        } else {
            // En local/testing uniquement : accepter avec avertissement
            Log::notice('JEKO Webhook: IP whitelist non configurée (env=' . app()->environment()
                . '). IP appelante: ' . $request->ip());
        }

        $payload = $request->all();
        $signature = $request->header('Jeko-Signature') ?? '';

        // 2. Générer un ID unique pour ce webhook (déduplication)
        $apiDetails = $payload['apiTransactionableDetails'] ?? [];
        $webhookId = $payload['id']
            ?? $apiDetails['id']
            ?? md5(json_encode($payload));

        // 3. Anti-replay : si ce webhook a déjà été reçu, ACK sans traiter
        $dedupeKey = 'jeko_webhook_received:' . $webhookId;
        if (Cache::has($dedupeKey)) {
            Log::info('JEKO Webhook: duplicate ignored', ['webhook_id' => $webhookId]);
            return response()->json(['status' => 'ok', 'duplicate' => true]);
        }

        // Marquer comme reçu (TTL 48h)
        Cache::put($dedupeKey, true, 172800);

        // 4. Log le payload brut (audit)
        Log::info('JEKO Webhook: received', [
            'webhook_id' => $webhookId,
            'status' => $payload['status'] ?? 'unknown',
            'reference' => $apiDetails['reference'] ?? null,
            'ip' => $request->ip(),
            'processing_time_ms' => round((microtime(true) - $startTime) * 1000, 2),
        ]);

        // 5. Persist webhook log for audit trail
        try {
            if (\Illuminate\Support\Facades\Schema::hasTable('webhook_logs')) {
                WebhookLog::create([
                    'provider' => 'jeko',
                    'webhook_id' => $webhookId,
                    'event_type' => $payload['status'] ?? 'unknown',
                    'reference' => $apiDetails['reference'] ?? null,
                    'status' => $payload['status'] ?? null,
                    'payload' => $payload,
                    'ip_address' => $request->ip(),
                    'processed' => false,
                ]);
            }
        } catch (\Throwable $e) {
            // Ne jamais bloquer le webhook à cause du logging
            Log::warning('WebhookLog: persist failed', ['error' => $e->getMessage()]);
        }

        // 6. Dispatch le traitement en async (le webhook est retry-safe)
        ProcessJekoWebhookJob::dispatch($payload, $signature, $webhookId)
            ->onQueue('payments');

        // 7. ACK immédiat — JEKO ne retente pas si 200
        return response()->json([
            'status' => 'ok',
            'message' => 'Webhook received',
        ]);
    }

    /**
     * GET /api/webhooks/jeko/health
     */
    public function health(): JsonResponse
    {
        return response()->json([
            'status' => 'ok',
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
