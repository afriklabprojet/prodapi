<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Session de chat persistante pharmacie ↔ client.
 *
 * Contrairement aux messages liés à une livraison (DeliveryMessage),
 * une ChatSession est indépendante et peut accueillir plusieurs échanges
 * dans le temps (support, conseil, suivi d'ordonnance, etc.).
 *
 * @property int         $id
 * @property int         $pharmacy_id
 * @property string      $client_type     'customer' | 'pharmacy_user'
 * @property int         $client_id
 * @property string      $status          'active' | 'closed' | 'archived'
 * @property \Carbon\Carbon|null $last_message_at
 * @property \Carbon\Carbon      $created_at
 * @property \Carbon\Carbon      $updated_at
 */
class ChatSession extends Model
{
    protected $fillable = [
        'pharmacy_id',
        'client_type',
        'client_id',
        'status',
        'last_message_at',
    ];

    protected $casts = [
        'last_message_at' => 'datetime',
    ];

    // ── Relations ──────────────────────────────────────────────────────────

    public function pharmacy(): BelongsTo
    {
        return $this->belongsTo(Pharmacy::class);
    }

    public function messages(): HasMany
    {
        return $this->hasMany(ChatSessionMessage::class, 'session_id');
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    public function isActive(): bool
    {
        return $this->status === 'active';
    }

    /**
     * Vérifie qu'un acteur peut accéder à cette session.
     *
     * @param array $user ['type' => 'pharmacy', 'id' => 1]
     */
    public function isParticipant(array $user): bool
    {
        if ($user['type'] === 'pharmacy' || $user['type'] === 'pharmacy_user') {
            return (int) $user['pharmacy_id'] === $this->pharmacy_id
                || (int) $user['id'] === $this->pharmacy_id;
        }

        return $user['type'] === $this->client_type
            && (int) $user['id'] === $this->client_id;
    }

    /**
     * Scope: sessions actives d'une pharmacie.
     */
    public function scopeForPharmacy($query, int $pharmacyId)
    {
        return $query->where('pharmacy_id', $pharmacyId);
    }
}
