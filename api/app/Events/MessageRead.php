<?php

namespace App\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Diffusé quand le destinataire lit un message.
 * Permet l'affichage des accusés de réception (✔✔ bleu style WhatsApp).
 *
 * Canaux :
 * - private-delivery.{deliveryId}.chat  (pour tous les participants)
 * - private-chat-session.{sessionId}    (pour les sessions persistantes)
 */
class MessageRead implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    /**
     * @param int         $messageId  ID du dernier message lu (cursor-based)
     * @param int|null    $deliveryId Canal livraison (optionnel si sessionId fourni)
     * @param int|null    $sessionId  Canal session (optionnel si deliveryId fourni)
     * @param array       $reader     ['type' => 'pharmacy', 'id' => 1, 'name' => '...']
     * @param string      $readAt     ISO 8601
     */
    public function __construct(
        public readonly int $messageId,
        public readonly ?int $deliveryId,
        public readonly ?int $sessionId,
        public readonly array $reader,
        public readonly string $readAt,
    ) {}

    public function broadcastOn(): array
    {
        $channels = [];

        if ($this->deliveryId) {
            $channels[] = new PrivateChannel("delivery.{$this->deliveryId}.chat");
        }

        if ($this->sessionId) {
            $channels[] = new PrivateChannel("chat-session.{$this->sessionId}");
        }

        return $channels;
    }

    public function broadcastAs(): string
    {
        return 'message.read';
    }

    public function broadcastWith(): array
    {
        return [
            'message_id' => $this->messageId,
            'reader'     => $this->reader,
            'read_at'    => $this->readAt,
        ];
    }
}
