<?php

namespace App\Events;

use App\Models\DeliveryOffer;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Événement diffusé quand une offre de livraison est acceptée par un livreur.
 * Notifie les autres livreurs que l'offre n'est plus disponible.
 */
class DeliveryOfferTaken implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public DeliveryOffer $offer;
    public array $excludedCourierId;
    public int $acceptedByCourierId;

    /**
     * Create a new event instance.
     */
    public function __construct(DeliveryOffer $offer, array $notifiedCourierIds, int $acceptedByCourierId)
    {
        $this->offer = $offer;
        // Exclure le livreur qui a accepté
        $this->excludedCourierId = array_filter($notifiedCourierIds, fn($id) => $id !== $acceptedByCourierId);
        $this->acceptedByCourierId = $acceptedByCourierId;
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        // Créer un canal privé pour chaque livreur (sauf celui qui a accepté)
        return collect($this->excludedCourierId)
            ->map(fn($id) => new PrivateChannel("courier.{$id}"))
            ->toArray();
    }

    /**
     * The event's broadcast name.
     */
    public function broadcastAs(): string
    {
        return 'delivery.offer.taken';
    }

    /**
     * Get the data to broadcast.
     */
    public function broadcastWith(): array
    {
        return [
            'offer_id' => $this->offer->id,
            'order_id' => $this->offer->order_id,
            'accepted_by' => $this->acceptedByCourierId,
            'accepted_at' => now()->toIso8601String(),
            'message' => 'Cette offre a été acceptée par un autre livreur',
        ];
    }

    /**
     * Determine if this event should broadcast.
     */
    public function broadcastWhen(): bool
    {
        // Ne broadcaster que s'il y a des livreurs à notifier
        return count($this->excludedCourierId) > 0;
    }
}
