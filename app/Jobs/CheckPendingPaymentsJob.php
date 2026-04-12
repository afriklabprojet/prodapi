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
use Illuminate\Support\Facades\Log;

/**
 * Vérifie les paiements JEKO en attente et met à jour leur statut.
 * Exécuté toutes les 2 minutes via le scheduler.
 * Idempotent et retry-safe.
 */
class CheckPendingPaymentsJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public array $backoff = [30, 60, 120];
    public int $timeout = 120;

    public function middleware(): array
    {
        return [new WithoutOverlapping('check-pending-payments')];
    }

    public function handle(JekoPaymentService $jekoService): void
    {
        $pendingPayments = JekoPayment::whereIn('status', ['pending', 'processing'])
            ->where('created_at', '>=', now()->subHours(2))
            ->where('created_at', '<=', now()->subMinutes(2))
            ->whereNotNull('jeko_payment_request_id')
            ->limit(50)
            ->get();

        $checked = 0;
        $updated = 0;

        foreach ($pendingPayments as $payment) {
            try {
                $oldStatus = $payment->status;
                $jekoService->checkPaymentStatus($payment);
                $payment->refresh();

                if ($payment->status !== $oldStatus) {
                    $updated++;
                    Log::info('CheckPendingPayments: status changed', [
                        'reference' => $payment->reference,
                        'old_status' => $oldStatus->value ?? $oldStatus,
                        'new_status' => $payment->status->value ?? $payment->status,
                    ]);
                }
                $checked++;
            } catch (\Throwable $e) {
                Log::warning('CheckPendingPayments: check failed', [
                    'reference' => $payment->reference,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        // Auto-expire très anciens (>2h en pending)
        $expired = JekoPayment::whereIn('status', ['pending', 'processing'])
            ->where('created_at', '<', now()->subHours(2))
            ->update([
                'status' => 'expired',
                'error_message' => 'Auto-expired: timeout 2h',
                'completed_at' => now(),
            ]);

        // Mettre à jour les commandes liées aux paiements expirés
        if ($expired > 0) {
            $expiredPayments = JekoPayment::where('status', 'expired')
                ->where('completed_at', '>=', now()->subMinutes(5))
                ->where('payable_type', 'App\\Models\\Order')
                ->pluck('payable_id');

            if ($expiredPayments->isNotEmpty()) {
                \App\Models\Order::whereIn('id', $expiredPayments)
                    ->where('payment_status', 'unpaid')
                    ->where('status', 'pending')
                    ->update(['status' => 'cancelled', 'cancellation_reason' => 'Paiement expiré automatiquement', 'cancelled_at' => now()]);
            }
        }

        if ($checked > 0 || $expired > 0) {
            Log::info('CheckPendingPayments: complete', compact('checked', 'updated', 'expired'));
        }
    }

    public function failed(\Throwable $exception): void
    {
        Log::error('CheckPendingPaymentsJob failed', [
            'error' => $exception->getMessage(),
        ]);
    }
}
