<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CourierShift extends Model
{
    use HasFactory;

    protected $fillable = [
        'courier_id',
        'slot_id',
        'zone_id',
        'date',
        'start_time',
        'end_time',
        'actual_start_time',
        'actual_end_time',
        'guaranteed_bonus',
        'earned_bonus',
        'status',
        'deliveries_completed',
        'violations_count',
        'violations',
    ];

    protected $casts = [
        'date' => 'date',
        'start_time' => 'datetime:H:i',
        'end_time' => 'datetime:H:i',
        'actual_start_time' => 'datetime:H:i',
        'actual_end_time' => 'datetime:H:i',
        'guaranteed_bonus' => 'integer',
        'earned_bonus' => 'integer',
        'deliveries_completed' => 'integer',
        'violations_count' => 'integer',
        'violations' => 'array',
    ];

    // ──────────────────────────────────────────
    // CONSTANTES
    // ──────────────────────────────────────────

    const STATUS_CONFIRMED = 'confirmed';
    const STATUS_IN_PROGRESS = 'in_progress';
    const STATUS_COMPLETED = 'completed';
    const STATUS_CANCELLED = 'cancelled';
    const STATUS_NO_SHOW = 'no_show';

    const VIOLATION_NOT_ACTIVE = 'not_active';
    const VIOLATION_GPS_STALE = 'gps_stale';
    const VIOLATION_OUT_OF_ZONE = 'out_of_zone';
    const VIOLATION_LOW_ACCEPTANCE = 'low_acceptance';

    // ──────────────────────────────────────────
    // RELATIONS
    // ──────────────────────────────────────────

    /**
     * Livreur
     */
    public function courier(): BelongsTo
    {
        return $this->belongsTo(Courier::class);
    }

    /**
     * Créneau réservé
     */
    public function slot(): BelongsTo
    {
        return $this->belongsTo(CourierShiftSlot::class, 'slot_id');
    }

    // ──────────────────────────────────────────
    // ACCESSORS
    // ──────────────────────────────────────────

    /**
     * Durée du shift en minutes
     */
    public function getDurationMinutesAttribute(): int
    {
        if (!$this->actual_start_time || !$this->actual_end_time) {
            return 0;
        }
        return $this->actual_start_time->diffInMinutes($this->actual_end_time);
    }

    /**
     * Le shift est-il actif maintenant?
     */
    public function getIsActiveAttribute(): bool
    {
        return $this->status === self::STATUS_IN_PROGRESS;
    }

    /**
     * Bonus effectivement gagné
     */
    public function getCalculatedBonusAttribute(): int
    {
        // Si trop de violations, pas de bonus
        if ($this->violations_count >= 3) {
            return 0;
        }

        // Réduction de 50% si 2 violations
        if ($this->violations_count >= 2) {
            return (int) ($this->guaranteed_bonus * 0.5);
        }

        // Réduction de 25% si 1 violation
        if ($this->violations_count >= 1) {
            return (int) ($this->guaranteed_bonus * 0.75);
        }

        return $this->guaranteed_bonus;
    }

    // ──────────────────────────────────────────
    // SCOPES
    // ──────────────────────────────────────────

    /**
     * Shifts d'un livreur
     */
    public function scopeForCourier($query, int $courierId)
    {
        return $query->where('courier_id', $courierId);
    }

    /**
     * Shifts actifs
     */
    public function scopeActive($query)
    {
        return $query->where('status', self::STATUS_IN_PROGRESS);
    }

    /**
     * Shifts d'aujourd'hui
     */
    public function scopeToday($query)
    {
        return $query->whereDate('date', today());
    }

    /**
     * Shifts d'une zone
     */
    public function scopeInZone($query, string $zoneId)
    {
        return $query->where('zone_id', $zoneId);
    }

    /**
     * Shifts confirmés devant commencer bientôt
     */
    public function scopeStartingSoon($query, int $minutesAhead = 30)
    {
        return $query->where('status', self::STATUS_CONFIRMED)
            ->whereDate('date', today())
            ->whereTime('start_time', '<=', now()->addMinutes($minutesAhead)->format('H:i'))
            ->whereTime('start_time', '>=', now()->format('H:i'));
    }

    // ──────────────────────────────────────────
    // MÉTHODES
    // ──────────────────────────────────────────

    /**
     * Démarrer le shift
     */
    public function start(): void
    {
        $this->update([
            'status' => self::STATUS_IN_PROGRESS,
            'actual_start_time' => now()->format('H:i:s'),
        ]);
    }

    /**
     * Terminer le shift
     */
    public function complete(): void
    {
        $this->update([
            'status' => self::STATUS_COMPLETED,
            'actual_end_time' => now()->format('H:i:s'),
            'earned_bonus' => $this->calculated_bonus,
        ]);
    }

    /**
     * Annuler le shift
     */
    public function cancel(): void
    {
        $this->update(['status' => self::STATUS_CANCELLED]);
        $this->slot?->release();
    }

    /**
     * Marquer comme no-show
     */
    public function markNoShow(): void
    {
        $this->update(['status' => self::STATUS_NO_SHOW]);
    }

    /**
     * Ajouter une violation
     */
    public function addViolation(string $type, ?string $details = null): void
    {
        $violations = $this->violations ?? [];
        $violations[] = [
            'type' => $type,
            'details' => $details,
            'timestamp' => now()->toIso8601String(),
        ];

        $this->update([
            'violations' => $violations,
            'violations_count' => count($violations),
        ]);
    }

    /**
     * Incrémenter le compteur de livraisons
     */
    public function incrementDeliveries(): void
    {
        $this->increment('deliveries_completed');
    }
}
