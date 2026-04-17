<?php

namespace App\Events;

use App\Models\Delivery;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class DeliveryEtaUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public Delivery $delivery;
    public int $newEtaSeconds;
    public ?string $reason;

    /**
     * Create a new event instance.
     */
    public function __construct(Delivery $delivery, int $newEtaSeconds, ?string $reason = null)
    {
        $this->delivery = $delivery;
        $this->newEtaSeconds = $newEtaSeconds;
        $this->reason = $reason;
    }

    /**
     * Get the channels the event should broadcast on.
     */
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("order.{$this->delivery->order_id}"),
            new PrivateChannel("delivery.{$this->delivery->id}"),
        ];
    }

    /**
     * The event's broadcast name.
     */
    public function broadcastAs(): string
    {
        return 'delivery.eta.updated';
    }

    /**
     * Get the data to broadcast.
     */
    public function broadcastWith(): array
    {
        $courier = $this->delivery->courier;

        return [
            'delivery_id' => $this->delivery->id,
            'order_id' => $this->delivery->order_id,
            'new_eta_seconds' => $this->newEtaSeconds,
            'new_eta_minutes' => round($this->newEtaSeconds / 60),
            'estimated_arrival' => now()->addSeconds($this->newEtaSeconds)->toIso8601String(),
            'reason' => $this->reason,
            'courier' => $courier ? [
                'id' => $courier->id,
                'name' => $courier->name,
                'latitude' => (float) $courier->latitude,
                'longitude' => (float) $courier->longitude,
            ] : null,
            'updated_at' => now()->toIso8601String(),
        ];
    }
}
