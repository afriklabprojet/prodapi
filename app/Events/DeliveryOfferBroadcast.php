<?php

namespace App\Events;

use App\Models\DeliveryOffer;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class DeliveryOfferBroadcast implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public DeliveryOffer $offer;
    public array $courierIds;

    /**
     * Create a new event instance.
     */
    public function __construct(DeliveryOffer $offer, array $courierIds)
    {
        $this->offer = $offer;
        $this->courierIds = $courierIds;
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        // Créer un canal privé pour chaque livreur
        return collect($this->courierIds)
            ->map(fn($id) => new PrivateChannel("courier.{$id}"))
            ->toArray();
    }

    /**
     * The event's broadcast name.
     */
    public function broadcastAs(): string
    {
        return 'delivery.offer';
    }

    /**
     * Get the data to broadcast.
     */
    public function broadcastWith(): array
    {
        $order = $this->offer->order;
        $pharmacy = $order->pharmacy ?? null;

        return [
            'offer_id' => $this->offer->id,
            'order_id' => $this->offer->order_id,
            'expires_at' => $this->offer->expires_at?->toIso8601String(),
            'seconds_remaining' => $this->offer->expires_at?->diffInSeconds(now()),
            'broadcast_level' => $this->offer->broadcast_level,
            'order' => [
                'id' => $order->id,
                'pickup' => [
                    'name' => $pharmacy?->name ?? 'Pharmacie',
                    'address' => $pharmacy?->address,
                    'latitude' => (float) ($pharmacy?->latitude ?? 0),
                    'longitude' => (float) ($pharmacy?->longitude ?? 0),
                ],
                'dropoff' => [
                    'address' => $order->delivery_address,
                    'latitude' => (float) $order->delivery_latitude,
                    'longitude' => (float) $order->delivery_longitude,
                ],
                'estimated_price' => $order->delivery_fee ?? 0,
                'items_count' => $order->items?->count() ?? 0,
            ],
        ];
    }
}
