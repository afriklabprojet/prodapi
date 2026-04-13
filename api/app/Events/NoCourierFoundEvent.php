<?php

namespace App\Events;

use App\Models\DeliveryOffer;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class NoCourierFoundEvent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public DeliveryOffer $offer;

    public function __construct(DeliveryOffer $offer)
    {
        $this->offer = $offer;
    }

    /**
     * Broadcast sur le canal admin pour alerter l'équipe dispatch.
     */
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('admin.dispatch'),
            new PrivateChannel("order.{$this->offer->order_id}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'delivery.no_courier_found';
    }

    public function broadcastWith(): array
    {
        $order = $this->offer->order;
        $pharmacy = $order->pharmacy ?? null;

        return [
            'offer_id' => $this->offer->id,
            'order_id' => $this->offer->order_id,
            'broadcast_level' => $this->offer->broadcast_level,
            'total_notified' => $this->offer->targetedCouriers()->count(),
            'pharmacy' => $pharmacy?->name ?? 'Pharmacie inconnue',
            'delivery_address' => $order->delivery_address,
            'created_at' => $this->offer->created_at?->toIso8601String(),
        ];
    }
}
