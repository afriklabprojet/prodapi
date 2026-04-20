<?php

namespace App\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Broadcast realtime pressure data to a specific courier.
 * Payload: nearby_orders, nearby_drivers, demand_ratio, pressure_level, urgency_message.
 */
class NearbyPressureBroadcast implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public int $courierId;
    public array $pressureData;

    public function __construct(int $courierId, array $pressureData)
    {
        $this->courierId = $courierId;
        $this->pressureData = $pressureData;
    }

    public function broadcastOn(): array
    {
        return [new PrivateChannel("courier.{$this->courierId}")];
    }

    public function broadcastAs(): string
    {
        return 'nearby.pressure';
    }

    public function broadcastWith(): array
    {
        return $this->pressureData;
    }
}
