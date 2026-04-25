<?php

namespace App\Jobs;

use App\Models\Order;
use App\Services\BroadcastDispatchService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Dispatche une offre de livraison aux coursiers disponibles après création de commande.
 * Utilise le système multi-niveaux de BroadcastDispatchService (rayon croissant,
 * bonus croissant, escalade automatique via ExpireDeliveryOffer).
 */
class DispatchDeliveryJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 10;

    public function __construct(
        public Order $order,
        public int $level = 1,
    ) {}

    public function handle(BroadcastDispatchService $dispatchService): void
    {
        // Recharger l'ordre depuis la DB pour avoir les relations fraîches
        $order = $this->order->fresh();

        if (!$order) {
            Log::warning('DispatchDeliveryJob: Order not found', ['order_id' => $this->order->id]);
            return;
        }

        // Ne pas dispatcher si déjà assigné ou terminé
        if (in_array($order->status, ['cancelled', 'delivered', 'failed'])) {
            Log::info('DispatchDeliveryJob: Order in terminal state, skipping', [
                'order_id' => $order->id,
                'status' => $order->status,
            ]);
            return;
        }

        // Vérifier qu'il n'y a pas déjà une offre active
        $existingOffer = $order->deliveryOffers()
            ->whereIn('status', ['pending', 'broadcasted'])
            ->exists();

        if ($existingOffer) {
            Log::info('DispatchDeliveryJob: Active offer already exists, skipping', [
                'order_id' => $order->id,
            ]);
            return;
        }

        Log::info('DispatchDeliveryJob: Creating delivery offer', [
            'order_id' => $order->id,
            'level' => $this->level,
        ]);

        $offer = $dispatchService->createOffer($order, $this->level);

        if (!$offer) {
            Log::warning('DispatchDeliveryJob: No offer created (no couriers available?)', [
                'order_id' => $order->id,
                'level' => $this->level,
            ]);
        }
    }
}
