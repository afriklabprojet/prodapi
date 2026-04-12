<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryTrackingPoint extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'delivery_id',
        'latitude',
        'longitude',
        'speed',
        'heading',
        'accuracy',
        'event_type',
        'recorded_at',
    ];

    protected $casts = [
        'latitude' => 'decimal:7',
        'longitude' => 'decimal:7',
        'speed' => 'integer',
        'heading' => 'integer',
        'accuracy' => 'integer',
        'recorded_at' => 'datetime',
    ];

    // ──────────────────────────────────────────
    // CONSTANTES
    // ──────────────────────────────────────────

    const EVENT_LOCATION_UPDATE = 'location_update';
    const EVENT_PICKUP = 'pickup';
    const EVENT_DROPOFF = 'dropoff';
    const EVENT_PAUSE = 'pause';
    const EVENT_RESUME = 'resume';

    // ──────────────────────────────────────────
    // RELATIONS
    // ──────────────────────────────────────────

    /**
     * Livraison associée
     */
    public function delivery(): BelongsTo
    {
        return $this->belongsTo(Delivery::class);
    }

    // ──────────────────────────────────────────
    // SCOPES
    // ──────────────────────────────────────────

    /**
     * Points d'une livraison ordonnés chronologiquement
     */
    public function scopeChronological($query)
    {
        return $query->orderBy('recorded_at');
    }

    /**
     * Points récents (dernières X minutes)
     */
    public function scopeRecent($query, int $minutes = 30)
    {
        return $query->where('recorded_at', '>=', now()->subMinutes($minutes));
    }

    /**
     * Points d'un type d'événement
     */
    public function scopeOfType($query, string $eventType)
    {
        return $query->where('event_type', $eventType);
    }

    // ──────────────────────────────────────────
    // MÉTHODES STATIQUES
    // ──────────────────────────────────────────

    /**
     * Créer un point de localisation
     */
    public static function createLocationUpdate(
        Delivery $delivery,
        float $latitude,
        float $longitude,
        ?int $speed = null,
        ?int $heading = null,
        ?int $accuracy = null
    ): self {
        return self::create([
            'delivery_id' => $delivery->id,
            'latitude' => $latitude,
            'longitude' => $longitude,
            'speed' => $speed,
            'heading' => $heading,
            'accuracy' => $accuracy,
            'event_type' => self::EVENT_LOCATION_UPDATE,
            'recorded_at' => now(),
        ]);
    }

    /**
     * Créer un point d'événement (pickup, dropoff, etc.)
     */
    public static function createEvent(
        Delivery $delivery,
        string $eventType,
        float $latitude,
        float $longitude
    ): self {
        return self::create([
            'delivery_id' => $delivery->id,
            'latitude' => $latitude,
            'longitude' => $longitude,
            'event_type' => $eventType,
            'recorded_at' => now(),
        ]);
    }
}
