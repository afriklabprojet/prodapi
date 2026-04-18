<?php

namespace App\Jobs;

use App\Models\InventoryBatch;
use App\Models\Pharmacy;
use App\Notifications\LowStockAlertNotification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;

/**
 * Alerte les pharmacies pour les lots (DLC) arrivant à expiration.
 *
 * Seuils :
 * - 30 jours : avertissement (planifier une commande de remplacement)
 * - 7 jours : alerte urgente (retirer du circuit de vente imminente)
 *
 * Fréquence recommandée : quotidien 9h
 */
class InventoryBatchExpiryAlertJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public array $backoff = [60, 300, 600];
    public int $timeout = 180;

    public function middleware(): array
    {
        return [new WithoutOverlapping('inventory-batch-expiry-alert')];
    }

    public function handle(): void
    {
        // Lots expirant dans ≤ 30 jours (non encore expirés)
        $batches = InventoryBatch::with(['product', 'pharmacy.user'])
            ->whereNotNull('expiry_date')
            ->where('expiry_date', '>', now())
            ->where('expiry_date', '<=', now()->addDays(30))
            ->where('quantity', '>', 0)
            ->get();

        if ($batches->isEmpty()) {
            return;
        }

        // Grouper par pharmacie
        $byPharmacy = $batches->groupBy('pharmacy_id');

        $totalAlerts = 0;

        foreach ($byPharmacy as $pharmacyId => $pharmacyBatches) {
            $pharmacy = $pharmacyBatches->first()->pharmacy;

            if (! $pharmacy || ! $pharmacy->user) {
                continue;
            }

            $urgent = [];    // ≤ 7 jours
            $warning = [];   // 8-30 jours

            foreach ($pharmacyBatches as $batch) {
                $daysLeft = (int) now()->diffInDays($batch->expiry_date);
                $item = [
                    'name'       => $batch->product?->name ?? "Lot #{$batch->id}",
                    'lot_number' => $batch->lot_number ?? $batch->batch_number,
                    'quantity'   => $batch->quantity,
                    'expiry_date'=> $batch->expiry_date->format('d/m/Y'),
                    'days_left'  => $daysLeft,
                ];

                if ($daysLeft <= 7) {
                    $urgent[] = $item;
                } else {
                    $warning[] = $item;
                }
            }

            try {
                $products = array_merge($urgent, $warning);
                $pharmacy->user->notify(new \App\Notifications\InventoryBatchExpiryNotification(
                    $urgent,
                    $warning
                ));
                $totalAlerts++;
            } catch (\Throwable $e) {
                Log::warning("InventoryBatchExpiryAlertJob: échec notification pharmacie #{$pharmacyId}", [
                    'error' => $e->getMessage(),
                ]);
            }
        }

        Log::info("InventoryBatchExpiryAlertJob: {$totalAlerts} pharmacie(s) alertée(s), {$batches->count()} lot(s) concerné(s)");
    }
}
