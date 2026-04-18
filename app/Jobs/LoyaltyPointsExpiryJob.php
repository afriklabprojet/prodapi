<?php

namespace App\Jobs;

use App\Models\CustomerLoyaltyPoint;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Expire les points de fidélité non utilisés depuis plus de 12 mois.
 *
 * Stratégie :
 * - Calcule le solde net par user (earned - redeemed)
 * - Cible les lignes "earned" dont le created_at > 12 mois
 * - Insère une ligne "expired" pour remettre le solde à zéro
 * - Envoie une notification push au client 30 jours avant expiration (avertissement)
 *
 * Fréquence recommandée : hebdomadaire (lundi 5h)
 */
class LoyaltyPointsExpiryJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public array $backoff = [120, 300];
    public int $timeout = 300;

    private const EXPIRY_MONTHS = 12;
    private const WARNING_DAYS  = 30; // Avertir 30 jours avant

    public function middleware(): array
    {
        return [new WithoutOverlapping('loyalty-points-expiry')];
    }

    public function handle(): void
    {
        $expiryDate  = now()->subMonths(self::EXPIRY_MONTHS);
        $warningDate = now()->subMonths(self::EXPIRY_MONTHS)->addDays(self::WARNING_DAYS);

        // ── 1. Expirer les points gagnés il y a > 12 mois ──────────────────
        $expiredCount  = 0;
        $expiredUsers  = 0;

        // Grouper par user les points "earned" > 12 mois non encore expirés
        $rows = DB::table('customer_loyalty_points')
            ->select('user_id', DB::raw('SUM(points) as total_earned'))
            ->where('type', 'earned')
            ->where('created_at', '<', $expiryDate)
            ->whereNotExists(function ($q) {
                // Pas déjà une ligne expired postérieure
                $q->from('customer_loyalty_points as e')
                    ->whereColumn('e.user_id', 'customer_loyalty_points.user_id')
                    ->where('e.type', 'expired')
                    ->whereRaw('e.created_at > customer_loyalty_points.created_at');
            })
            ->groupBy('user_id')
            ->having('total_earned', '>', 0)
            ->get();

        foreach ($rows as $row) {
            // Solde actuel du user (earned - redeemed - expired)
            $balance = CustomerLoyaltyPoint::where('user_id', $row->user_id)
                ->selectRaw("
                    SUM(CASE WHEN type = 'earned' THEN points ELSE 0 END) -
                    SUM(CASE WHEN type IN ('redeemed','expired') THEN ABS(points) ELSE 0 END) as balance
                ")
                ->value('balance') ?? 0;

            if ($balance <= 0) {
                continue;
            }

            DB::transaction(function () use ($row, $balance) {
                CustomerLoyaltyPoint::create([
                    'user_id'     => $row->user_id,
                    'points'      => -abs($balance),
                    'type'        => 'expired',
                    'source'      => 'system',
                    'description' => 'Points expirés — inactivité > '.self::EXPIRY_MONTHS.' mois',
                ]);
            });

            $expiredCount += $balance;
            $expiredUsers++;
        }

        // ── 2. Avertir les clients dont les points expirent dans ~30 jours ─
        $warnedCount = 0;

        $soonExpiring = DB::table('customer_loyalty_points')
            ->select('user_id', DB::raw('SUM(points) as points'))
            ->where('type', 'earned')
            ->whereBetween('created_at', [
                $expiryDate->subDays(self::WARNING_DAYS + 5),
                $expiryDate->addDays(5),
            ])
            ->groupBy('user_id')
            ->having('points', '>', 0)
            ->get();

        foreach ($soonExpiring as $row) {
            try {
                $user = User::find($row->user_id);
                if ($user && $user->fcm_token) {
                    $user->notify(new \App\Notifications\OrderStatusNotification(
                        null,
                        'loyalty_expiry_warning',
                        "⚠️ Vos {$row->points} points de fidélité expirent dans ".self::WARNING_DAYS." jours. Utilisez-les vite !"
                    ));
                    $warnedCount++;
                }
            } catch (\Throwable $e) {
                Log::debug('LoyaltyPointsExpiryJob: warn notification failed', ['user_id' => $row->user_id]);
            }
        }

        if ($expiredUsers > 0 || $warnedCount > 0) {
            Log::info("LoyaltyPointsExpiryJob: {$expiredCount} points expirés ({$expiredUsers} users), {$warnedCount} avertissement(s) envoyé(s)");
        }
    }
}
