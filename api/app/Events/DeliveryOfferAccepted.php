<?php

namespace App\Events;

use App\Models\DeliveryOffer;
use App\Models\Courier;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class DeliveryOfferAccepted implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public DeliveryOffer $offer;
    public Courier $courier;

    /**
     * Create a new event instance.
     */
    public function __construct(DeliveryOffer $offer, Courier $courier)
    {
        $this->offer = $offer;
        $this->courier = $courier;
    }

    /**
     * Get the channels the event should broadcast on.
     */
    public function broadcastOn(): array
    {
        $channels = [];

        // Canal de la commande (pour le client et la pharmacie)
        $channels[] = new PrivateChannel("order.{$this->offer->order_id}");

        // Notifier les autres livreurs que l'offre n'est plus disponible
        $otherCouriers = $this->offer->couriers()
            ->where('courier_id', '!=', $this->courier->id)
            ->pluck('courier_id');

        foreach ($otherCouriers as $courierId) {
            $channels[] = new PrivateChannel("courier.{$courierId}");
        }

        return $channels;
    }

    /**
     * The event's broadcast name.
     */
    public function broadcastAs(): string
    {
        return 'delivery.offer.accepted';
    }

    /**
     * Get the data to broadcast.
     */
    public function broadcastWith(): array
    {
        return [
            'offer_id' => $this->offer->id,
            'order_id' => $this->offer->order_id,
            'courier_id' => $this->courier->id,
            'courier_name' => $this->courier->name,
            'accepted_at' => now()->toIso8601String(),
        ];
    }
}
