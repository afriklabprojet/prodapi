<?php

namespace App\Events;

use App\Models\Order;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Event critique : changement de statut d'une commande.
 *
 * Architecture :
 * - Firestore = stockage durable (positions GPS, historique tracking)
 * - Pusher = events critiques temps réel (statut, ETA, offres)
 *
 * Channel : order.{orderId} (privé, le client s'abonne après auth)
 * Event   : order.status.changed
 */
class OrderStatusChanged implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public int $orderId;
    public string $oldStatus;
    public string $newStatus;
    public ?string $changedAt;

    public function __construct(Order $order, string $oldStatus, string $newStatus)
    {
        $this->orderId = $order->id;
        $this->oldStatus = $oldStatus;
        $this->newStatus = $newStatus;
        $this->changedAt = now()->toIso8601String();
    }

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("order.{$this->orderId}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'order.status.changed';
    }

    public function broadcastWith(): array
    {
        return [
            'order_id' => $this->orderId,
            'old_status' => $this->oldStatus,
            'new_status' => $this->newStatus,
            'changed_at' => $this->changedAt,
        ];
    }
}
