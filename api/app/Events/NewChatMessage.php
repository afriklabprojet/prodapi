<?php

namespace App\Events;

use App\Models\DeliveryMessage;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class NewChatMessage implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public DeliveryMessage $message,
        public array $sender
    ) {}

    /**
     * Canaux de diffusion
     * - Canal privé pour la livraison (tous les participants)
     * - Canal privé pour le destinataire spécifique
     */
    public function broadcastOn(): array
    {
        return [
            // Canal pour tous les participants de la livraison
            new PrivateChannel("delivery.{$this->message->delivery_id}.chat"),
            
            // Canal spécifique au destinataire
            new PrivateChannel(
                "chat.{$this->message->receiver_type}.{$this->message->receiver_id}"
            ),
        ];
    }

    /**
     * Nom de l'événement broadcast
     */
    public function broadcastAs(): string
    {
        return 'message.new';
    }

    /**
     * Données envoyées via WebSocket
     */
    public function broadcastWith(): array
    {
        return [
            'id' => $this->message->id,
            'delivery_id' => $this->message->delivery_id,
            'message' => $this->message->message,
            'type' => $this->message->type ?? 'text',
            'metadata' => $this->message->metadata,
            'sender' => [
                'type' => $this->message->sender_type,
                'id' => $this->message->sender_id,
                'name' => $this->sender['name'],
            ],
            'receiver' => [
                'type' => $this->message->receiver_type,
                'id' => $this->message->receiver_id,
            ],
            'created_at' => $this->message->created_at->toIso8601String(),
        ];
    }

    /**
     * Condition de diffusion
     */
    public function broadcastWhen(): bool
    {
        // Ne pas diffuser les messages supprimés
        return $this->message->deleted_at === null;
    }
}
