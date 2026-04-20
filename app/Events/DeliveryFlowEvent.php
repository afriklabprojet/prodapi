<?php

namespace App\Events;

use App\Models\Delivery;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Broadcasts delivery flow state changes to all interested parties:
 * - courier.{courierId} → driver app
 * - order.{orderId} → customer app
 *
 * Events: accepted, en_route_pickup, arrived_pickup, picked_up,
 *         en_route_delivery, arrived_client, delivered
 */
class DeliveryFlowEvent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public Delivery $delivery,
        public string $flowState,
        public int $courierId,
    ) {}

    public function broadcastOn(): array
    {
        $channels = [
            new PrivateChannel("courier.{$this->courierId}"),
        ];

        // Also broadcast to customer channel
        if ($this->delivery->order_id) {
            $channels[] = new PrivateChannel("order.{$this->delivery->order_id}");
        }

        return $channels;
    }

    public function broadcastAs(): string
    {
        return 'delivery.flow';
    }

    public function broadcastWith(): array
    {
        $order = $this->delivery->order;

        return [
            'delivery_id' => $this->delivery->id,
            'order_id' => $this->delivery->order_id,
            'flow_state' => $this->flowState,
            'courier_id' => $this->courierId,
            'timestamp' => now()->toIso8601String(),
            'pharmacy' => [
                'name' => $order->pharmacy->name ?? 'Pharmacie',
                'latitude' => (float) ($this->delivery->pickup_latitude ?? 0),
                'longitude' => (float) ($this->delivery->pickup_longitude ?? 0),
            ],
            'customer' => [
                'name' => $order->customer->name ?? 'Client',
                'latitude' => (float) ($this->delivery->dropoff_latitude ?? 0),
                'longitude' => (float) ($this->delivery->dropoff_longitude ?? 0),
            ],
            'delivery_fee' => (float) ($order->delivery_fee ?? 0),
        ];
    }
}
