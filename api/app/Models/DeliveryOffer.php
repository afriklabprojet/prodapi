<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class DeliveryOffer extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'accepted_by_courier_id',
        'status',
        'broadcast_level',
        'base_fee',
        'bonus_fee',
        'expires_at',
        'accepted_at',
    ];

    protected $casts = [
        'broadcast_level' => 'integer',
        'base_fee' => 'integer',
        'bonus_fee' => 'integer',
        'expires_at' => 'datetime',
        'accepted_at' => 'datetime',
    ];

    // ──────────────────────────────────────────
    // CONSTANTES
    // ──────────────────────────────────────────

    const STATUS_PENDING = 'pending';
    const STATUS_ACCEPTED = 'accepted';
    const STATUS_EXPIRED = 'expired';
    const STATUS_NO_COURIER = 'no_courier_found';
    const STATUS_CANCELLED = 'cancelled';

    // ──────────────────────────────────────────
    // RELATIONS
    // ──────────────────────────────────────────

    /**
     * Commande associée
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * Livreur qui a accepté
     */
    public function acceptedByCourier(): BelongsTo
    {
        return $this->belongsTo(Courier::class, 'accepted_by_courier_id');
    }

    /**
     * Livreurs ciblés par cette offre (alias)
     */
    public function couriers(): BelongsToMany
    {
        return $this->targetedCouriers();
    }

    /**
     * Livreurs ciblés par cette offre
     */
    public function targetedCouriers(): BelongsToMany
    {
        return $this->belongsToMany(Courier::class, 'delivery_offer_courier')
            ->withPivot(['status', 'notified_at', 'viewed_at', 'responded_at', 'rejection_reason'])
            ->withTimestamps();
    }

    /**
     * Livreurs qui ont refusé
     */
    public function rejectedCouriers(): BelongsToMany
    {
        return $this->belongsToMany(Courier::class, 'delivery_offer_courier')
            ->wherePivot('status', 'rejected')
            ->withPivot(['rejection_reason', 'responded_at']);
    }

    // ──────────────────────────────────────────
    // ACCESSORS
    // ──────────────────────────────────────────

    /**
     * Montant total de l'offre (base + bonus)
     */
    public function getTotalFeeAttribute(): int
    {
        return $this->base_fee + $this->bonus_fee;
    }

    /**
     * Vérifier si l'offre est expirée
     */
    public function getIsExpiredAttribute(): bool
    {
        return $this->expires_at && $this->expires_at->isPast();
    }

    /**
     * Temps restant en secondes
     */
    public function getRemainingSecondsAttribute(): int
    {
        if (!$this->expires_at || $this->expires_at->isPast()) {
            return 0;
        }
        return $this->expires_at->diffInSeconds(now());
    }

    // ──────────────────────────────────────────
    // SCOPES
    // ──────────────────────────────────────────

    /**
     * Offres en attente
     */
    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    /**
     * Offres expirées à traiter
     */
    public function scopeExpiredPending($query)
    {
        return $query->where('status', self::STATUS_PENDING)
            ->where('expires_at', '<', now());
    }

    /**
     * Offres pour un livreur spécifique
     */
    public function scopeForCourier($query, int $courierId)
    {
        return $query->whereHas('targetedCouriers', function ($q) use ($courierId) {
            $q->where('courier_id', $courierId);
        });
    }

    // ──────────────────────────────────────────
    // MÉTHODES
    // ──────────────────────────────────────────

    /**
     * Marquer comme acceptée par un livreur
     */
    public function accept(Courier $courier): bool
    {
        if ($this->status !== self::STATUS_PENDING) {
            return false;
        }

        $this->update([
            'status' => self::STATUS_ACCEPTED,
            'accepted_by_courier_id' => $courier->id,
            'accepted_at' => now(),
        ]);

        // Mettre à jour le pivot
        $this->targetedCouriers()->updateExistingPivot($courier->id, [
            'status' => 'accepted',
            'responded_at' => now(),
        ]);

        return true;
    }

    /**
     * Marquer un refus pour un livreur
     */
    public function reject(Courier $courier, ?string $reason = null): void
    {
        $this->targetedCouriers()->updateExistingPivot($courier->id, [
            'status' => 'rejected',
            'responded_at' => now(),
            'rejection_reason' => $reason,
        ]);
    }

    /**
     * Marquer comme vue par un livreur
     */
    public function markAsViewed(Courier $courier): void
    {
        $pivot = $this->targetedCouriers()->where('courier_id', $courier->id)->first();
        
        if ($pivot && !$pivot->pivot->viewed_at) {
            $this->targetedCouriers()->updateExistingPivot($courier->id, [
                'status' => 'viewed',
                'viewed_at' => now(),
            ]);
        }
    }

    /**
     * Marquer comme expirée
     */
    public function markAsExpired(): void
    {
        $this->update(['status' => self::STATUS_EXPIRED]);

        // Marquer tous les pivots notifiés comme expirés
        $this->targetedCouriers()
            ->wherePivotIn('status', ['notified', 'viewed'])
            ->each(function ($courier) {
                $this->targetedCouriers()->updateExistingPivot($courier->id, [
                    'status' => 'expired',
                ]);
            });
    }
}
