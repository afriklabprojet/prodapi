<?php

namespace App\Jobs;

use App\Models\Delivery;
use App\Notifications\OrderStatusNotification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Détecte et traite les livraisons bloquées.
 *
 * - Livraisons en "assigned/accepted" depuis >2h sans pickup → relance livreur
 * - Livraisons en "picked_up/in_transit" depuis >24h → alerte admin
 * - Livraisons bloquées >48h → annulation automatique
 *
 * Exécuté toutes les 30 minutes.
 */
class CheckStuckDeliveriesJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public int $timeout = 120;

    private const PICKUP_TIMEOUT_HOURS = 2;
    private const ALERT_THRESHOLD_HOURS = 24;
    private const AUTO_CANCEL_THRESHOLD_HOURS = 48;

    public function middleware(): array
    {
        return [new WithoutOverlapping('check-stuck-deliveries')];
    }

    public function handle(): void
    {
        $stats = [
            'reminded' => 0,
            'alerted' => 0,
            'cancelled' => 0,
        ];

        // 1. Livraisons assignées/acceptées mais jamais récupérées (>2h)
        $unpickedDeliveries = Delivery::whereIn('status', ['assigned', 'accepted'])
            ->where('assigned_at', '<', now()->subHours(self::PICKUP_TIMEOUT_HOURS))
            ->whereNull('picked_up_at')
            ->with(['courier.user', 'order'])
            ->limit(50)
            ->get();

        foreach ($unpickedDeliveries as $delivery) {
            try {
                if ($delivery->courier?->user) {
                    $delivery->courier->user->notify(new OrderStatusNotification(
                        $delivery->order,
                        'reminder',
                        "Rappel : la commande {$delivery->order->reference} vous attend depuis " .
                        now()->diffInMinutes($delivery->assigned_at) . " minutes. Merci de la récupérer."
                    ));
                    $stats['reminded']++;
                }
            } catch (\Throwable $e) {
                Log::debug('CheckStuckDeliveries: reminder failed', [
                    'delivery_id' => $delivery->id,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        // 2. Livraisons en transit depuis >24h → log warning
        $stuckInTransit = Delivery::whereIn('status', ['picked_up', 'in_transit'])
            ->where('picked_up_at', '<', now()->subHours(self::ALERT_THRESHOLD_HOURS))
            ->with(['courier.user', 'order.customer'])
            ->limit(50)
            ->get();

        foreach ($stuckInTransit as $delivery) {
            $stats['alerted']++;
            Log::warning('CheckStuckDeliveries: delivery stuck >24h', [
                'delivery_id' => $delivery->id,
                'order_reference' => $delivery->order?->reference,
                'courier' => $delivery->courier?->name,
                'picked_up_at' => $delivery->picked_up_at,
                'hours_stuck' => now()->diffInHours($delivery->picked_up_at),
            ]);
        }

        // 3. Livraisons bloquées >48h → annulation automatique
        $zombieDeliveries = Delivery::whereIn('status', ['assigned', 'accepted', 'picked_up', 'in_transit'])
            ->where(function ($q) {
                $q->where(function ($sub) {
                    $sub->whereNotNull('picked_up_at')
                        ->where('picked_up_at', '<', now()->subHours(self::AUTO_CANCEL_THRESHOLD_HOURS));
                })->orWhere(function ($sub) {
                    $sub->whereNull('picked_up_at')
                        ->whereNotNull('assigned_at')
                        ->where('assigned_at', '<', now()->subHours(self::AUTO_CANCEL_THRESHOLD_HOURS));
                });
            })
            ->with(['courier', 'order.customer'])
            ->limit(20)
            ->get();

        foreach ($zombieDeliveries as $delivery) {
            try {
                $this->autoCancelDelivery($delivery);
                $stats['cancelled']++;
            } catch (\Throwable $e) {
                Log::warning('CheckStuckDeliveries: auto-cancel failed', [
                    'delivery_id' => $delivery->id,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        if (array_sum($stats) > 0) {
            Log::info('CheckStuckDeliveries: complete', $stats);
        }
    }

    private function autoCancelDelivery(Delivery $delivery): void
    {
        DB::beginTransaction();
        try {
            $reason = "Annulation automatique : livraison bloquée depuis plus de " . self::AUTO_CANCEL_THRESHOLD_HOURS . "h";

            $delivery->update([
                'status' => 'failed',
                'failure_reason' => $reason,
                'auto_cancelled_at' => now(),
            ]);

            if ($delivery->order) {
                $delivery->order->update([
                    'status' => 'cancelled',
                    'cancellation_reason' => $reason,
                    'cancelled_at' => now(),
                ]);
            }

            if ($delivery->courier) {
                $delivery->courier->update(['status' => 'available']);
            }

            DB::commit();

            // Notifier le client
            try {
                if ($delivery->order?->customer) {
                    $delivery->order->customer->notify(new OrderStatusNotification(
                        $delivery->order,
                        'cancelled',
                        "Votre commande {$delivery->order->reference} a été annulée en raison d'un problème de livraison. Veuillez nous contacter."
                    ));
                }
            } catch (\Throwable) {
                // Notification silencieuse
            }

            Log::info('CheckStuckDeliveries: auto-cancelled', [
                'delivery_id' => $delivery->id,
                'order_reference' => $delivery->order?->reference,
            ]);
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }
    }

    public function failed(\Throwable $exception): void
    {
        Log::error('CheckStuckDeliveriesJob failed', [
            'error' => $exception->getMessage(),
        ]);
    }
}
