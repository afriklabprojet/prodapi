<?php

namespace App\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Diffusé quand un utilisateur est en train d'écrire.
 * Côté Flutter, géré comme événement client (client-typing) sur le canal Pusher.
 * Cette version serveur sert si on veut broadcaster l'indicateur de frappe
 * depuis une action API (ex: endpoint POST /typing).
 *
 * Le client Flutter émet déjà `client-typing` directement via Pusher
 * (`sendTyping()` dans ChatRealtimeDatasource). Cet event est donc optionnel :
 * utile si le canal est présence ou si on veut logguer les indicateurs.
 */
class UserTyping implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public readonly ?int $deliveryId,
        public readonly ?int $sessionId,
        public readonly array $typer, // ['type' => 'pharmacy', 'id' => 1, 'name' => '...']
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
        return 'user.typing';
    }

    public function broadcastWith(): array
    {
        return [
            'typer' => $this->typer,
        ];
    }

    /**
     * Ne pas mettre en queue — les indicateurs de frappe doivent être
     * instantanés ou ignorés.
     */
    public function broadcastWhen(): bool
    {
        return true;
    }
}
