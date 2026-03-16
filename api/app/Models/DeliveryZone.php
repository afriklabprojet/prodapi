<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Cache;

class DeliveryZone extends Model
{
    protected $fillable = [
        'pharmacy_id',
        'name',
        'polygon',
        'radius_km',
        'is_active',
    ];

    protected $casts = [
        'polygon' => 'array',
        'radius_km' => 'float',
        'is_active' => 'boolean',
    ];

    /**
     * Pharmacie propriétaire de la zone
     */
    public function pharmacy(): BelongsTo
    {
        return $this->belongsTo(Pharmacy::class);
    }

    /**
     * Nombre de points du polygone
     */
    public function getPointsCountAttribute(): int
    {
        return is_array($this->polygon) ? count($this->polygon) : 0;
    }

    /**
     * Vérifier si un point (lat, lng) est dans cette zone
     */
    public function containsPoint(float $lat, float $lng): bool
    {
        if (!$this->is_active || empty($this->polygon)) {
            return true; // Zone inactive ou vide = pas de restriction
        }

        return self::pointInPolygon($lat, $lng, $this->polygon);
    }

    /**
     * Vérifier si une adresse est dans la zone de livraison d'une pharmacie (statique, cachée)
     */
    public static function isInDeliveryZone(int $pharmacyId, float $lat, float $lng): bool
    {
        $zone = Cache::remember("delivery_zone:{$pharmacyId}", 3600, function () use ($pharmacyId) {
            return self::where('pharmacy_id', $pharmacyId)
                ->where('is_active', true)
                ->first();
        });

        if (!$zone) {
            return true; // Pas de zone définie = livraison partout
        }

        return $zone->containsPoint($lat, $lng);
    }

    /**
     * Invalider le cache lors de la sauvegarde
     */
    protected static function booted(): void
    {
        static::saved(function (DeliveryZone $zone) {
            Cache::forget("delivery_zone:{$zone->pharmacy_id}");
        });

        static::deleted(function (DeliveryZone $zone) {
            Cache::forget("delivery_zone:{$zone->pharmacy_id}");
        });
    }

    /**
     * Algorithme ray-casting pour vérifier si un point est dans un polygone
     */
    private static function pointInPolygon(float $lat, float $lng, array $polygon): bool
    {
        $n = count($polygon);
        $inside = false;

        for ($i = 0, $j = $n - 1; $i < $n; $j = $i++) {
            $xi = $polygon[$i]['lat'];
            $yi = $polygon[$i]['lng'];
            $xj = $polygon[$j]['lat'];
            $yj = $polygon[$j]['lng'];

            $intersect = (($yi > $lng) != ($yj > $lng))
                && ($lat < ($xj - $xi) * ($lng - $yi) / ($yj - $yi) + $xi);

            if ($intersect) {
                $inside = !$inside;
            }
        }

        return $inside;
    }
}
