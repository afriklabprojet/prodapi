<?php

namespace App\Jobs;

use App\Models\Product;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Désactive les promotions de produits dont la date de fin est dépassée.
 *
 * Logique :
 * - Cherche les produits avec discount_price non nul ET promotion_end_date < now()
 * - Remet discount_price à null et efface promotion_end_date
 * - Évite que des prix soldés restent actifs indéfiniment
 *
 * Fréquence recommandée : toutes les heures
 */
class DeactivateExpiredPromotionsJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public array $backoff = [60, 120, 300];
    public int $timeout = 120;

    public function middleware(): array
    {
        return [new WithoutOverlapping('deactivate-expired-promotions')];
    }

    public function handle(): void
    {
        $expired = Product::whereNotNull('discount_price')
            ->whereNotNull('promotion_end_date')
            ->where('promotion_end_date', '<', now())
            ->get();

        if ($expired->isEmpty()) {
            return;
        }

        $count = 0;
        foreach ($expired as $product) {
            $product->update([
                'discount_price'     => null,
                'promotion_end_date' => null,
            ]);
            $count++;
        }

        Log::info("DeactivateExpiredPromotionsJob: {$count} promotion(s) expirée(s) désactivée(s)");
    }
}
