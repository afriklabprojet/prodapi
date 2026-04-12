<?php

namespace App\Jobs;

use App\Models\Order;
use App\Services\CommissionService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Détecte et calcule les commissions manquantes pour les commandes livrées.
 * 
 * Cible les commandes avec status = 'delivered' et payment_status = 'paid'
 * qui n'ont pas encore de commission calculée.
 *
 * Exécuté tous les jours à 4h du matin.
 */
class ProcessMissingCommissionsJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public int $timeout = 180;

    public function middleware(): array
    {
        return [new WithoutOverlapping('process-missing-commissions')];
    }

    public function handle(CommissionService $commissionService): void
    {
        // Commandes livrées et payées sans commission
        $ordersWithoutCommission = Order::where('status', 'delivered')
            ->where('payment_status', 'paid')
            ->whereDoesntHave('commission')
            ->where('delivered_at', '<', now()->subHours(1)) // Laisser 1h de marge
            ->where('delivered_at', '>', now()->subDays(90)) // Pas plus de 90 jours
            ->with(['pharmacy', 'delivery.courier'])
            ->limit(100)
            ->get();

        if ($ordersWithoutCommission->isEmpty()) {
            return;
        }

        $processed = 0;
        $failed = 0;

        foreach ($ordersWithoutCommission as $order) {
            try {
                $commissionService->calculateAndDistribute($order);
                $processed++;

                Log::info('ProcessMissingCommissions: commission created', [
                    'order_id' => $order->id,
                    'reference' => $order->reference,
                    'total_amount' => $order->total_amount,
                ]);
            } catch (\Throwable $e) {
                $failed++;
                Log::warning('ProcessMissingCommissions: failed', [
                    'order_id' => $order->id,
                    'reference' => $order->reference,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        Log::info('ProcessMissingCommissions: complete', [
            'found' => $ordersWithoutCommission->count(),
            'processed' => $processed,
            'failed' => $failed,
        ]);
    }

    public function failed(\Throwable $exception): void
    {
        Log::error('ProcessMissingCommissionsJob failed', [
            'error' => $exception->getMessage(),
        ]);
    }
}
