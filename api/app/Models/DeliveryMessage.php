<?php

namespace App\Models;

use App\Enums\MessageType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class DeliveryMessage extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'delivery_id',
        'sender_type',
        'sender_id',
        'receiver_type',
        'receiver_id',
        'message',
        'type',
        'metadata',
        'read_at',
    ];

    protected $casts = [
        'read_at' => 'datetime',
        'metadata' => 'array',
        'type' => MessageType::class,
    ];

    /**
     * Livraison associée (avec eager loading optimisé)
     */
    public function delivery(): BelongsTo
    {
        return $this->belongsTo(Delivery::class);
    }

    /**
     * Scope: messages d'une conversation entre deux participants
     */
    public function scopeForConversation($query, int $deliveryId, string $userType, int $userId, string $participantType, int $participantId)
    {
        return $query->where('delivery_id', $deliveryId)
            ->where(function ($q) use ($userType, $userId, $participantType, $participantId) {
                $q->where(function ($q2) use ($userType, $userId, $participantType, $participantId) {
                    $q2->where('sender_type', $userType)
                        ->where('sender_id', $userId)
                        ->where('receiver_type', $participantType)
                        ->where('receiver_id', $participantId);
                })->orWhere(function ($q2) use ($userType, $userId, $participantType, $participantId) {
                    $q2->where('sender_type', $participantType)
                        ->where('sender_id', $participantId)
                        ->where('receiver_type', $userType)
                        ->where('receiver_id', $userId);
                });
            });
    }

    /**
     * Scope: messages non lus pour un utilisateur
     */
    public function scopeUnreadFor($query, string $type, int $id)
    {
        return $query->where('receiver_type', $type)
            ->where('receiver_id', $id)
            ->whereNull('read_at');
    }

    /**
     * Scope: messages d'une livraison
     */
    public function scopeForDelivery($query, int $deliveryId)
    {
        return $query->where('delivery_id', $deliveryId);
    }

    /**
     * Vérifier si le message est lu
     */
    public function isRead(): bool
    {
        return $this->read_at !== null;
    }

    /**
     * Vérifier si c'est un message système
     */
    public function isSystemMessage(): bool
    {
        return $this->type === MessageType::SYSTEM || $this->sender_type === 'system';
    }

    /**
     * Obtenir le label du type d'expéditeur
     */
    public function getSenderLabelAttribute(): string
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
