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
use Illuminate\Support\Facades\Log;

/**
 * Maintient les streaks (séries consécutives) des livreurs chaque nuit.
 *
 * Règles :
 * - Un livreur "actif" aujourd'hui = au moins 1 livraison status='delivered' hier
 * - Si actif hier → streak+1 (max 365), last_active_date = hier, +XP bonus
 * - Si inactif hier → streak reset à 0
 * - Bonus XP : 7j=+50, 14j=+100, 30j=+250, 60j=+500, 100j=+1000
 *
 * Fréquence recommandée : quotidien 00h05 (juste après minuit)
 */
class CourierStreakJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public array $backoff = [120, 300];
    public int $timeout = 300;

    // Jalons de streak et bonus XP associés
    private const STREAK_MILESTONES = [
        7   => 50,
        14  => 100,
        30  => 250,
        60  => 500,
        100 => 1000,
    ];

    public function middleware(): array
    {
        return [new WithoutOverlapping('courier-streak-maintenance')];
    }

    public function handle(): void
    {
        $yesterday = now()->subDay()->toDateString();
        $streakReset  = 0;
        $streakIncrease = 0;
        $milestoneBonus = 0;

        Courier::whereNotNull('user_id')
            ->where('kyc_status', 'approved')
            ->chunk(100, function ($couriers) use ($yesterday, &$streakReset, &$streakIncrease, &$milestoneBonus) {
                foreach ($couriers as $courier) {
                    $wasActiveYesterday = Delivery::where('courier_id', $courier->id)
                        ->where('status', 'delivered')
                        ->whereDate('delivered_at', $yesterday)
                        ->exists();

                    if ($wasActiveYesterday) {
                        $newStreak = $courier->current_streak_days + 1;
                        $xpBonus   = self::STREAK_MILESTONES[$newStreak] ?? 0;
                        $newXp     = $courier->total_xp + $xpBonus;

                        $courier->update([
                            'current_streak_days' => $newStreak,
                            'last_active_date'    => $yesterday,
                            'total_xp'            => $newXp,
                        ]);

                        $streakIncrease++;

                        if ($xpBonus > 0) {
                            $milestoneBonus++;
                            // Notification bonus milestone
                            try {
                                $user = $courier->user;
                                if ($user && $user->fcm_token) {
                                    $user->notify(new \App\Notifications\OrderStatusNotification(
                                        null,
                                        'streak_milestone',
                                        "🔥 {$newStreak} jours de streak ! +{$xpBonus} XP bonus. Continuez comme ça !"
                                    ));
                                }
                            } catch (\Throwable $e) {
                                // Silently ignore
                            }
                        }
                    } else {
                        // Streak cassé → reset
                        if ($courier->current_streak_days > 0) {
                            $courier->update(['current_streak_days' => 0]);
                            $streakReset++;
                        }
                    }
                }
            });

        Log::info("CourierStreakJob: {$streakIncrease} streak(s) augmenté(s), {$streakReset} reset(s), {$milestoneBonus} bonus milestone(s)");
    }
}
