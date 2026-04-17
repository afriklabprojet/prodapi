<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CourierShiftSlot extends Model
{
    use HasFactory;

    protected $fillable = [
        'zone_id',
        'date',
        'shift_type',
        'start_time',
        'end_time',
        'capacity',
        'booked_count',
        'bonus_amount',
        'status',
    ];

    protected $casts = [
        'date' => 'date',
        'start_time' => 'datetime:H:i',
        'end_time' => 'datetime:H:i',
        'capacity' => 'integer',
        'booked_count' => 'integer',
        'bonus_amount' => 'integer',
    ];

    // ──────────────────────────────────────────
    // CONSTANTES
    // ──────────────────────────────────────────

    const SHIFT_TYPES = [
        'morning' => ['start' => '06:00', 'end' => '12:00', 'bonus' => 0],
        'lunch' => ['start' => '11:00', 'end' => '15:00', 'bonus' => 100],
        'afternoon' => ['start' => '14:00', 'end' => '19:00', 'bonus' => 0],
        'dinner' => ['start' => '18:00', 'end' => '23:00', 'bonus' => 150],
        'night' => ['start' => '22:00', 'end' => '02:00', 'bonus' => 200],
    ];

    const STATUS_OPEN = 'open';
    const STATUS_FULL = 'full';
    const STATUS_CLOSED = 'closed';

    // ──────────────────────────────────────────
    // RELATIONS
    // ──────────────────────────────────────────

    /**
     * Shifts réservés sur ce créneau
     */
    public function shifts(): HasMany
    {
        return $this->hasMany(CourierShift::class, 'slot_id');
    }

    // ──────────────────────────────────────────
    // ACCESSORS
    // ──────────────────────────────────────────

    /**
     * Places restantes
     */
    public function getAvailableSpotsAttribute(): int
    {
        return max(0, $this->capacity - $this->booked_count);
    }

    /**
     * Taux de remplissage en pourcentage
     */
    public function getFillRateAttribute(): int
    {
        if ($this->capacity === 0) return 100;
        return (int) round(($this->booked_count / $this->capacity) * 100);
    }

    /**
     * Label lisible du type de shift
     */
    public function getShiftLabelAttribute(): string
    {
        return match ($this->shift_type) {
            'morning' => 'Matin',
            'lunch' => 'Déjeuner',
            'afternoon' => 'Après-midi',
            'dinner' => 'Dîner',
            'night' => 'Nuit',
            default => $this->shift_type,
        };
    }

    // ──────────────────────────────────────────
    // SCOPES
    // ──────────────────────────────────────────

    /**
     * Créneaux ouverts
     */
    public function scopeOpen($query)
    {
        return $query->where('status', self::STATUS_OPEN);
    }

    /**
     * Créneaux d'une zone
     */
    public function scopeInZone($query, string $zoneId)
    {
        return $query->where('zone_id', $zoneId);
    }

    /**
     * Créneaux d'une date
     */
    public function scopeOnDate($query, $date)
    {
        return $query->whereDate('date', $date);
    }

    /**
     * Créneaux à venir
     */
    public function scopeUpcoming($query)
    {
        return $query->where('date', '>=', today());
    }

    /**
     * Créneaux avec places disponibles
     */
    public function scopeAvailable($query)
    {
        return $query->where('status', self::STATUS_OPEN)
            ->whereColumn('booked_count', '<', 'capacity');
    }

    // ──────────────────────────────────────────
    // MÉTHODES
    // ──────────────────────────────────────────

    /**
     * Réserver une place
     */
    public function book(): bool
    {
        if ($this->booked_count >= $this->capacity) {
            return false;
        }

        $this->increment('booked_count');

        if ($this->booked_count >= $this->capacity) {
            $this->update(['status' => self::STATUS_FULL]);
        }

        return true;
    }

    /**
     * Libérer une place
     */
    public function release(): void
    {
        if ($this->booked_count > 0) {
            $this->decrement('booked_count');
            
            if ($this->status === self::STATUS_FULL) {
                $this->update(['status' => self::STATUS_OPEN]);
            }
        }
    }

    /**
     * Fermer le créneau
     */
    public function close(): void
    {
        $this->update(['status' => self::STATUS_CLOSED]);
    }
}
