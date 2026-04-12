<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryMessage extends Model
{
    protected $fillable = [
        'delivery_id',
        'sender_type',
        'sender_id',
        'receiver_type',
        'receiver_id',
        'message',
        'read_at',
    ];

    protected $casts = [
        'read_at' => 'datetime',
    ];

    /**
     * Livraison associée
     */
    public function delivery(): BelongsTo
    {
        return $this->belongsTo(Delivery::class);
    }

    /**
     * Destinataire (résolution manuelle car types non-standard)
     */
    public function receiver()
    {
        return match ($this->receiver_type) {
            'courier' => \App\Models\Courier::find($this->receiver_id),
            'pharmacy' => \App\Models\Pharmacy::find($this->receiver_id),
            'client' => \App\Models\User::find($this->receiver_id),
            default => null,
        };
    }

    /**
     * Expéditeur (résolution manuelle car types non-standard)
     */
    public function sender()
    {
        return match ($this->sender_type) {
            'courier' => \App\Models\Courier::find($this->sender_id),
            'pharmacy' => \App\Models\Pharmacy::find($this->sender_id),
            'client' => \App\Models\User::find($this->sender_id),
            default => null,
        };
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
}
