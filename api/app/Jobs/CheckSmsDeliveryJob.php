<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Vérifie le statut de livraison d'un SMS Infobip après envoi.
 *
 * Remplace le usleep(1.5s) bloquant par un job asynchrone
 * qui poll le delivery report à intervalles croissants.
 * Détecte les rejets tardifs (NOT_ENOUGH_CREDITS, REJECTED, etc.)
 */
class CheckSmsDeliveryJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public array $backoff = [5, 30, 120]; // 5s, 30s, 2min
    public int $timeout = 15;

    public function __construct(
        private readonly string $messageId,
        private readonly string $phone,
        private readonly ?string $bulkId = null,
    ) {}

    public function handle(): void
    {
        $baseUrl = config('sms.infobip.base_url');
        $apiKey = config('sms.infobip.api_key');

        if (!$baseUrl || !$apiKey) {
            Log::warning('CheckSmsDelivery: Infobip not configured', [
                'messageId' => $this->messageId,
            ]);
            return;
        }

        try {
            $response = Http::withHeaders([
                'Authorization' => "App {$apiKey}",
            ])->timeout(10)->get("{$baseUrl}/sms/1/reports", [
                'messageId' => $this->messageId,
                'limit' => 1,
            ]);

            if (!$response->ok()) {
                Log::warning('CheckSmsDelivery: API error', [
                    'messageId' => $this->messageId,
                    'status' => $response->status(),
                ]);
                // Retry via backoff
                $this->release($this->backoff[$this->attempts() - 1] ?? 120);
                return;
            }

            $results = $response->json('results', []);

            if (empty($results)) {
                // Pas encore de rapport — retry si tentatives restantes
                if ($this->attempts() < $this->tries) {
                    $this->release($this->backoff[$this->attempts() - 1] ?? 120);
                    return;
                }
                Log::info('CheckSmsDelivery: no report after all attempts', [
                    'messageId' => $this->messageId,
                    'phone' => $this->phone,
                ]);
                return;
            }

            $report = $results[0];
            $statusGroup = $report['status']['groupName'] ?? 'UNKNOWN';
            $statusName = $report['status']['name'] ?? 'UNKNOWN';
            $statusDesc = $report['status']['description'] ?? '';

            // Mettre à jour le cache
            Cache::put("sms_msg_{$this->messageId}", [
                'phone' => $this->phone,
                'sent_at' => $report['sentAt'] ?? now()->toIso8601String(),
                'done_at' => $report['doneAt'] ?? null,
                'status' => $statusGroup,
                'status_name' => $statusName,
            ], now()->addHours(48));

            $rejectedGroups = ['REJECTED', 'UNDELIVERABLE'];
            $isRejected = in_array($statusGroup, $rejectedGroups)
                || str_starts_with($statusName, 'REJECTED_');

            if ($isRejected) {
                Log::error('CheckSmsDelivery: SMS rejeté (async)', [
                    'phone' => $this->phone,
                    'messageId' => $this->messageId,
                    'bulkId' => $this->bulkId,
                    'status' => $statusName,
                    'description' => $statusDesc,
                ]);
                return;
            }

            if ($statusGroup === 'DELIVERED') {
                Log::info('CheckSmsDelivery: SMS livré', [
                    'phone' => $this->phone,
                    'messageId' => $this->messageId,
                ]);
                return;
            }

            // PENDING/EXPIRED — retry si tentatives restantes
            if (in_array($statusGroup, ['PENDING', 'UNKNOWN']) && $this->attempts() < $this->tries) {
                $this->release($this->backoff[$this->attempts() - 1] ?? 120);
                return;
            }

            if ($statusGroup === 'EXPIRED') {
                Log::warning('CheckSmsDelivery: SMS expiré', [
                    'phone' => $this->phone,
                    'messageId' => $this->messageId,
                    'description' => $statusDesc,
                ]);
            }

        } catch (\Exception $e) {
            Log::warning('CheckSmsDelivery: exception', [
                'messageId' => $this->messageId,
                'error' => $e->getMessage(),
            ]);
            throw $e; // Let queue retry
        }
    }

    public function tags(): array
    {
        return ['sms', 'infobip', "message:{$this->messageId}"];
    }
}
