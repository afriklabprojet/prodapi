<?php

namespace App\Jobs;

use App\Models\Product;
use App\Models\Pharmacy;
use App\Notifications\LowStockAlertNotification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Rapport hebdomadaire de stocks bas envoyé à chaque pharmacie concernée.
 *
 * Logique :
 * - Récupère tous les produits disponibles sous leur seuil low_stock_threshold
 * - Groupe par pharmacie
 * - Envoie un LowStockAlertNotification à l'utilisateur principal de la pharmacie
 *
 * Fréquence recommandée : chaque lundi à 08h00
 */
class PharmacyLowStockWeeklyAlertJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public array $backoff = [120, 300];
    public int $timeout = 180;

    public function middleware(): array
    {
        return [new WithoutOverlapping('pharmacy-low-stock-weekly')];
    }

    public function handle(): void
    {
        $alertsSent = 0;
        $totalProducts = 0;

        // Produits disponibles ET sous leur seuil (scope lowStock du modèle)
        $lowStockProducts = Product::lowStock()
            ->where('is_available', true)
            ->with('pharmacy.user')
            ->get()
            ->groupBy('pharmacy_id');

        foreach ($lowStockProducts as $pharmacyId => $products) {
            $pharmacy = $products->first()?->pharmacy;

            if (!$pharmacy) {
                continue;
            }

            $owner = $pharmacy->user;

            if (!$owner) {
                Log::debug("PharmacyLowStockWeeklyAlertJob: pharmacie #{$pharmacyId} sans utilisateur principal, ignorée");
                continue;
            }

            // Format attendu par LowStockAlertNotification
            $payload = $products->map(fn ($p) => [
                'name'      => $p->name,
                'quantity'  => $p->stock_quantity,
                'threshold' => $p->low_stock_threshold,
            ])->values()->all();

            try {
                $owner->notify(new LowStockAlertNotification($payload));
                $alertsSent++;
                $totalProducts += count($payload);
            } catch (\Throwable $e) {
                Log::warning("PharmacyLowStockWeeklyAlertJob: notification échouée pour pharmacie #{$pharmacyId}: {$e->getMessage()}");
            }
        }

        if ($alertsSent > 0) {
            Log::info("PharmacyLowStockWeeklyAlertJob: {$alertsSent} pharmacie(s) alertée(s) pour {$totalProducts} produit(s) en stock bas");
        }
    }
}
