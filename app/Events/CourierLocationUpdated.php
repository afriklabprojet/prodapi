<?php

namespace App\Events;

use App\Models\Delivery;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Broadcast la position GPS du coursier vers le canal de la commande.
 * Permet au client de voir le livreur se déplacer en temps réel.
 *
 * Canal: order.{orderId}
 * Event: courier.location.updated
 */
class CourierLocationUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public Delivery $delivery,
        public float $latitude,
        public float $longitude,
    ) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("order.{$this->delivery->order_id}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'courier.location.updated';
    }

    public function broadcastWith(): array
    {
        $courier = $this->delivery->courier;

        return [
            'delivery_id' => $this->delivery->id,
            'order_id' => $this->delivery->order_id,
            'courier' => [
                'id' => $courier?->id,
                'name' => $courier?->name,
                'latitude' => $this->latitude,
                'longitude' => $this->longitude,
            ],
            'updated_at' => now()->toIso8601String(),
        ];
    }

    /**
     * Ne pas mettre en queue — broadcast synchrone pour réactivité GPS.
     */
    public function broadcastQueue(): string
    {
        return 'high';
    }
}
