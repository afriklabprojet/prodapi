<?php

namespace App\Http\Resources;

use App\Enums\MessageType;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MessageResource extends JsonResource
{
    /**
     * L'utilisateur courant pour déterminer is_mine
     */
    private ?array $currentUser = null;

    /**
     * Définir l'utilisateur courant
     */
    public function setCurrentUser(array $currentUser): self
    {
        $this->currentUser = $currentUser;
        return $this;
    }

    /**
     * Transform the resource into an array.
     */
    public function toArray(Request $request): array
    {
        $isMine = $this->currentUser 
            ? ($this->sender_type === $this->currentUser['type'] && $this->sender_id === $this->currentUser['id'])
            : false;

        return [
            'id' => $this->id,
            'delivery_id' => $this->delivery_id,
            
            // Contenu
            'message' => $this->message,
            'type' => $this->type ?? 'text',
            'metadata' => $this->when($this->metadata, $this->metadata),
            
            // Expéditeur
            'sender' => [
                'type' => $this->sender_type,
                'id' => $this->sender_id,
                'label' => $this->getSenderLabel(),
            ],
            
            // Destinataire
            'receiver' => [
                'type' => $this->receiver_type,
                'id' => $this->receiver_id,
            ],
            
            // État
            'is_mine' => $isMine,
            'is_read' => $this->read_at !== null,
            'read_at' => $this->read_at?->toIso8601String(),
            'is_deleted' => $this->deleted_at !== null,
            
            // Timestamps
            'created_at' => $this->created_at->toIso8601String(),
            'created_at_human' => $this->created_at->diffForHumans(),
        ];
    }

    /**
     * Label lisible pour le type d'expéditeur
     */
    private function getSenderLabel(): string
    {
        return match ($this->sender_type) {
            'courier' => 'Livreur',
            'pharmacy' => 'Pharmacie',
            'client' => 'Client',
            'system' => 'Système',
            default => 'Utilisateur',
        };
    }
}
