<?php

namespace App\Jobs;

use App\Models\Delivery;
use App\Models\Setting;
use App\Notifications\DeliveryTimeoutCancelledNotification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class CheckWaitingDeliveryTimeouts implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * Execute the job.
     * 
     * Vérifie toutes les livraisons en attente et annule automatiquement
     * celles qui ont dépassé le délai maximum configuré.
     */
    public function handle(): void
    {
        $timeoutMinutes = Setting::get('waiting_timeout_minutes', 10);
        $feePerMinute = Setting::get('waiting_fee_per_minute', 100);
        $freeMinutes = Setting::get('waiting_free_minutes', 2);
        
        // Trouver toutes les livraisons en attente qui ont dépassé le timeout
        $expiredDeliveries = Delivery::whereNotNull('waiting_started_at')
            ->whereNull('waiting_ended_at')
            ->whereNull('auto_cancelled_at')
            ->where('status', 'in_transit') // Livreur arrivé, en attente du client
            ->where('waiting_started_at', '<=', Carbon::now()->subMinutes($timeoutMinutes))
            ->with(['order.customer', 'courier.user'])
            ->get();

        foreach ($expiredDeliveries as $delivery) {
            $this->cancelDeliveryWithTimeout($delivery, $timeoutMinutes, $feePerMinute, $freeMinutes);
        }

        // Mettre à jour les frais d'attente pour les livraisons toujours en cours
        $this->updateWaitingFees($feePerMinute, $freeMinutes);

        if ($expiredDeliveries->count() > 0) {
            Log::info('CheckWaitingDeliveryTimeouts: Annulé ' . $expiredDeliveries->count() . ' livraison(s) pour timeout');
        }
    }

    /**
     * Annuler une livraison qui a dépassé le délai d'attente
     */
    private function cancelDeliveryWithTimeout(
        Delivery $delivery,
        int $timeoutMinutes,
        int $feePerMinute,
        int $freeMinutes
    ): void {
        $now = Carbon::now();
        $waitingStarted = Carbon::parse($delivery->waiting_started_at);
        $waitingMinutes = $waitingStarted->diffInMinutes($now);
        
        // Calculer les frais d'attente (minutes facturables = total - gratuites)
        $billableMinutes = max(0, $waitingMinutes - $freeMinutes);
        $waitingFee = $billableMinutes * $feePerMinute;

        // Mettre à jour la livraison
        $delivery->update([
            'status' => 'cancelled',
            'waiting_ended_at' => $now,
            'waiting_fee' => $waitingFee,
            'auto_cancelled_at' => $now,
            'cancellation_reason' => "Annulation automatique: client non disponible après {$timeoutMinutes} minutes d'attente",
        ]);

        // Mettre à jour le statut de la commande
        $delivery->order->update([
            'status' => 'cancelled',
        ]);

        // Libérer le livreur
        if ($delivery->courier) {
            $delivery->courier->update(['status' => 'available']);
        }

        // Notifier le client
        if ($delivery->order->customer) {
            $delivery->order->customer->notify(new DeliveryTimeoutCancelledNotification(
                $delivery,
                $waitingMinutes,
                $waitingFee,
                'customer'
            ));
        }

        // Notifier le livreur
        if ($delivery->courier?->user) {
            $delivery->courier->user->notify(new DeliveryTimeoutCancelledNotification(
                $delivery,
                $waitingMinutes,
                $waitingFee,
                'courier'
            ));
        }

        Log::info('Livraison annulée par timeout', [
            'delivery_id' => $delivery->id,
            'order_id' => $delivery->order->id,
            'waiting_minutes' => $waitingMinutes,
            'waiting_fee' => $waitingFee,
        ]);
    }

    /**
     * Mettre à jour les frais d'attente pour les livraisons en cours
     */
    private function updateWaitingFees(int $feePerMinute, int $freeMinutes): void
    {
        $activeWaitingDeliveries = Delivery::whereNotNull('waiting_started_at')
            ->whereNull('waiting_ended_at')
            ->whereNull('auto_cancelled_at')
            ->where('status', 'in_transit')
            ->get();

        foreach ($activeWaitingDeliveries as $delivery) {
            $waitingStarted = Carbon::parse($delivery->waiting_started_at);
            $waitingMinutes = $waitingStarted->diffInMinutes(Carbon::now());
            
            // Calculer les frais d'attente actuels
            $billableMinutes = max(0, $waitingMinutes - $freeMinutes);
            $waitingFee = $billableMinutes * $feePerMinute;
            
            // Mettre à jour seulement si le montant a changé
            if ($delivery->waiting_fee !== $waitingFee) {
                $delivery->update(['waiting_fee' => $waitingFee]);
            }
        }
    }
}
