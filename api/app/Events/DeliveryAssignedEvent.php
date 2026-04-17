<?php

namespace App\Events;

use App\Models\Delivery;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Événement diffusé au livreur dès qu'une livraison lui est assignée.
 * Permet au client mobile de rafraîchir instantanément sa liste active
 * sans attendre le polling HTTP.
 */
class DeliveryAssignedEvent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public Delivery $delivery;

    public function __construct(Delivery $delivery)
    {
        $this->delivery = $delivery;
    }

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("courier.{$this->delivery->courier_id}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'delivery.assigned';
    }

    public function broadcastWith(): array
    {
        return [
            'delivery_id' => $this->delivery->id,
            'order_id' => $this->delivery->order_id,
            'status' => $this->delivery->status,
            'pickup_address' => $this->delivery->pickup_address,
            'delivery_address' => $this->delivery->delivery_address,
            'delivery_fee' => (float) $this->delivery->delivery_fee,
            'assigned_at' => now()->toIso8601String(),
        ];
    }
}
