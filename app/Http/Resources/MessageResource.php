<?php

namespace App\Http\Resources;

use App\Enums\MessageType;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MessageResource extends JsonResource
{
    private ?array $currentUser = null;

    public function setCurrentUser(array $currentUser): self
    {
        $this->currentUser = $currentUser;
        return $this;
    }

    public function toArray(Request $request): array
    {
        $isMine = $this->currentUser
            ? ($this->sender_type === $this->currentUser['type'] && $this->sender_id === $this->currentUser['id'])
            : false;

        $senderLabel = $this->getSenderLabel();

        return [
            'id'          => $this->id,
            'delivery_id' => $this->delivery_id,

            // Contenu
            'message'  => $this->message,
            'type'     => $this->type ?? 'text',
            'metadata' => $this->when($this->metadata, $this->metadata),

            // ── Champs plats (compat Flutter SDK v1) ──────────────────────
            'sender_type'   => $this->sender_type,
            'sender_id'     => $this->sender_id,
            'sender_name'   => $senderLabel,
            'sender_label'  => $senderLabel,
            'receiver_type' => $this->receiver_type,
            'receiver_id'   => $this->receiver_id,

            // ── Objet imbriqué (API v2) ────────────────────────────────────
            'sender' => [
                'type'  => $this->sender_type,
                'id'    => $this->sender_id,
                'label' => $senderLabel,
                'name'  => $senderLabel,
            ],
            'receiver' => [
                'type' => $this->receiver_type,
                'id'   => $this->receiver_id,
            ],

            // État
            'is_mine'    => $isMine,
            'is_read'    => $this->read_at !== null,
            'read_at'    => $this->read_at?->toIso8601String(),
            'is_deleted' => $this->deleted_at !== null,

            // Timestamps
            'created_at'       => $this->created_at->toIso8601String(),
            'created_at_human' => $this->created_at->diffForHumans(),
        ];
    }

    private function getSenderLabel(): string
    {
        return match ($this->sender_type) {
            'courier'  => 'Livreur',
            'pharmacy' => 'Pharmacie',
            'client'   => 'Client',
            'system'   => 'Système',
            default    => 'Utilisateur',
        };
    }
}
