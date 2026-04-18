<?php

namespace App\Jobs;

use App\Models\Courier;
use App\Models\Delivery;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Recalcule quotidiennement les métriques de fiabilité des livreurs.
 *
 * Métriques recalculées (sur les 30 derniers jours) :
 * - acceptance_rate  : offres acceptées / offres reçues
 * - completion_rate  : livraisons terminées / livraisons acceptées
 * - on_time_rate     : livraisons dans les délais / livraisons terminées
 * - reliability_score: moyenne pondérée (40% completion + 30% acceptance + 30% on_time)
 * - tier             : bronze/silver/gold/platinum selon XP total
 *
 * Fréquence recommandée : quotidien 1h30 du matin
 */
class RecalcCourierMetricsJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public array $backoff = [120, 300];
    public int $timeout = 300;

    private const WINDOW_DAYS = 30;

    public function middleware(): array
    {
        return [new WithoutOverlapping('recalc-courier-metrics')];
    }

    public function handle(): void
    {
        $since = now()->subDays(self::WINDOW_DAYS);
        $updated = 0;

        // Traitement par chunks pour éviter l'OOM
        Courier::whereNotNull('user_id')->chunk(100, function ($couriers) use ($since, &$updated) {
            foreach ($couriers as $courier) {
                try {
                    $this->recalcForCourier($courier, $since);
                    $updated++;
                } catch (\Throwable $e) {
                    Log::warning("RecalcCourierMetricsJob: échec livreur #{$courier->id}", [
                        'error' => $e->getMessage(),
                    ]);
                }
            }
        });

        Log::info("RecalcCourierMetricsJob: {$updated} livreur(s) mis à jour");
    }

    private function recalcForCourier(Courier $courier, \Carbon\Carbon $since): void
    {
        $deliveries = Delivery::where('courier_id', $courier->id)
            ->where('assigned_at', '>=', $since)
            ->get();

        $totalAssigned  = $deliveries->count();
        $totalAccepted  = $deliveries->whereNotNull('accepted_at')->count();
        $totalCompleted = $deliveries->where('status', 'delivered')->count();

        // Livraison "dans les délais" = livrée dans les 90 min après pickup
        $onTime = $deliveries->where('status', 'delivered')
            ->whereNotNull('picked_up_at')
            ->whereNotNull('delivered_at')
            ->filter(function ($d) {
                return $d->picked_up_at->diffInMinutes($d->delivered_at) <= 90;
            })
            ->count();

        $acceptanceRate = $totalAssigned > 0
            ? round(($totalAccepted / $totalAssigned) * 100, 2)
            : 0;

        $completionRate = $totalAccepted > 0
            ? round(($totalCompleted / $totalAccepted) * 100, 2)
            : 0;

        $onTimeRate = $totalCompleted > 0
            ? round(($onTime / $totalCompleted) * 100, 2)
            : 0;

        // Score pondéré : completion 40%, acceptance 30%, on_time 30%
        $reliabilityScore = round(
            ($completionRate * 0.40) + ($acceptanceRate * 0.30) + ($onTimeRate * 0.30),
            2
        );

        // Tier basé sur XP total
        $tier = $this->computeTier($courier->total_xp ?? 0);

        $courier->update([
            'acceptance_rate'   => $acceptanceRate,
            'completion_rate'   => $completionRate,
            'on_time_rate'      => $onTimeRate,
            'reliability_score' => $reliabilityScore,
            'tier'              => $tier,
        ]);
    }

    private function computeTier(int $xp): string
    {
        if ($xp >= Courier::TIER_XP_THRESHOLDS[Courier::TIER_PLATINUM]) {
            return Courier::TIER_PLATINUM;
        }
        if ($xp >= Courier::TIER_XP_THRESHOLDS[Courier::TIER_GOLD]) {
            return Courier::TIER_GOLD;
        }
        if ($xp >= Courier::TIER_XP_THRESHOLDS[Courier::TIER_SILVER]) {
            return Courier::TIER_SILVER;
        }

        return Courier::TIER_BRONZE;
    }
}
