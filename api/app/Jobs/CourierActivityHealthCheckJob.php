<?php

namespace App\Jobs;

use App\Models\Courier;
use App\Notifications\OrderStatusNotification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Vérifie l'activité des livreurs et nettoie les statuts incohérents.
 *
 * - Livreurs "available" sans mise à jour de position depuis >2h → passe offline
 * - Livreurs inactifs depuis >7 jours → notification de relance
 * - Livreurs "busy" sans livraison active → passe available
 *
 * Exécuté tous les jours à 1h du matin.
 */
class CourierActivityHealthCheckJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public int $timeout = 120;

    private const LOCATION_STALE_HOURS = 2;
    private const INACTIVE_DAYS = 7;

    public function middleware(): array
    {
        return [new WithoutOverlapping('courier-activity-health-check')];
    }

    public function handle(): void
    {
        $stats = [
            'forced_offline' => 0,
            'freed_busy' => 0,
            'inactive_reminded' => 0,
        ];

        // 1. Livreurs "available" sans position récente → offline
        $staleCouriers = Courier::where('status', 'available')
            ->where(function ($q) {
                $q->where('last_location_update', '<', now()->subHours(self::LOCATION_STALE_HOURS))
                    ->orWhereNull('last_location_update');
            })
            ->get();

        foreach ($staleCouriers as $courier) {
            $courier->update(['status' => 'offline']);
            $stats['forced_offline']++;
        }

        // 2. Livreurs "busy" sans livraison active → available
        $busyCouriers = Courier::where('status', 'busy')
            ->whereDoesntHave('deliveries', function ($q) {
                $q->whereIn('status', ['assigned', 'accepted', 'picked_up', 'in_transit']);
            })
            ->get();

        foreach ($busyCouriers as $courier) {
            $courier->update(['status' => 'available']);
            $stats['freed_busy']++;

            Log::info('CourierHealthCheck: freed stuck busy courier', [
                'courier_id' => $courier->id,
                'name' => $courier->name,
            ]);
        }

        // 3. Livreurs KYC validés mais inactifs >7 jours → rappel
        $inactiveCouriers = Courier::where('kyc_status', 'verified')
            ->whereIn('status', ['available', 'offline'])
            ->whereDoesntHave('deliveries', function ($q) {
                $q->where('created_at', '>', now()->subDays(self::INACTIVE_DAYS));
            })
            ->whereHas('user')
            ->with('user')
            ->limit(50)
            ->get();

        foreach ($inactiveCouriers as $courier) {
            try {
                $courier->user->notify(new OrderStatusNotification(
                    null,
                    'reminder',
                    "Vous n'avez pas effectué de livraison depuis plus de " . self::INACTIVE_DAYS .
                    " jours. Connectez-vous pour recevoir des commandes !"
                ));
                $stats['inactive_reminded']++;
            } catch (\Throwable $e) {
                Log::debug('CourierHealthCheck: reminder notification failed', [
                    'courier_id' => $courier->id,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        if (array_sum($stats) > 0) {
            Log::info('CourierActivityHealthCheck: complete', $stats);
        }
    }

    public function failed(\Throwable $exception): void
    {
        Log::error('CourierActivityHealthCheckJob failed', [
            'error' => $exception->getMessage(),
        ]);
    }
}
