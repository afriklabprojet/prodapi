<?php

namespace App\Jobs;

use App\Models\JekoPayment;
use App\Services\JekoPaymentService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Traite un webhook JEKO de manière asynchrone.
 * Idempotent : vérifie `webhook_processed` avant traitement.
 * Retry-safe : les échecs de traitement sont retentés automatiquement.
 */
class ProcessJekoWebhookJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 5;
    public array $backoff = [5, 15, 60, 300, 900];
    public int $timeout = 60;
    public int $maxExceptions = 3;

    public function __construct(
        private readonly array $payload,
        private readonly string $signature,
        private readonly string $webhookId,
    ) {}

    /**
     * Empêcher le traitement parallèle du même webhook.
     */
    public function middleware(): array
    {
        return [
            (new WithoutOverlapping($this->webhookId))
                ->releaseAfter(30)
                ->expireAfter(300),
        ];
    }

    public function handle(JekoPaymentService $jekoService): void
    {
        Log::info('ProcessJekoWebhook: start', [
            'webhook_id' => $this->webhookId,
            'attempt' => $this->attempts(),
        ]);

        $result = $jekoService->handleWebhook($this->payload, $this->signature);

        if (!$result) {
            Log::warning('ProcessJekoWebhook: handleWebhook returned false', [
                'webhook_id' => $this->webhookId,
            ]);
            // Ne pas retenter si la signature est invalide ou le paiement introuvable
            // Le service log déjà la raison
        }

        Log::info('ProcessJekoWebhook: complete', [
            'webhook_id' => $this->webhookId,
            'result' => $result,
        ]);
    }

    public function failed(\Throwable $exception): void
    {
        Log::critical('ProcessJekoWebhook: FAILED permanently', [
            'webhook_id' => $this->webhookId,
            'payload_keys' => array_keys($this->payload),
            'error' => $exception->getMessage(),
            'trace' => $exception->getTraceAsString(),
        ]);
    }

    public function uniqueId(): string
    {
        return $this->webhookId;
    }
}
