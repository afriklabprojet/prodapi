<?php

namespace App\Services;

use App\Models\Courier;
use App\Models\Delivery;
use App\Models\DeliveryTrackingPoint;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Log;

class DeliveryTrackingService
{
    /**
     * Enregistrer une mise à jour de position GPS
     */
    public function recordLocation(
        Delivery $delivery,
        float $latitude,
        float $longitude,
        ?float $speed = null,
        ?int $heading = null,
        ?int $accuracy = null
    ): DeliveryTrackingPoint {
        $point = DeliveryTrackingPoint::createLocationUpdate(
            $delivery,
            $latitude,
            $longitude,
            $speed,
            $heading,
            $accuracy
        );

        // Mettre à jour la position du livreur
        if ($delivery->courier) {
            $delivery->courier->updateLocation($latitude, $longitude);
        }

        return $point;
    }

    /**
     * Enregistrer un événement de tracking (pickup, dropoff, pause, resume)
     */
    public function recordEvent(
        Delivery $delivery,
        string $eventType,
        float $latitude,
        float $longitude
    ): DeliveryTrackingPoint {
        return DeliveryTrackingPoint::createEvent(
            $delivery,
            $eventType,
            $latitude,
            $longitude
        );
    }

    /**
     * Obtenir l'historique de tracking d'une livraison
     */
    public function getTrackingHistory(Delivery $delivery): Collection
    {
        return $delivery->trackingPoints()
            ->chronological()
            ->get();
    }

    /**
     * Obtenir les points récents (dernières X minutes)
     */
    public function getRecentPoints(Delivery $delivery, int $minutes = 30): Collection
    {
        return $delivery->trackingPoints()
            ->recent($minutes)
            ->chronological()
            ->get();
    }

    /**
     * Calculer la distance totale parcourue (en km)
     */
    public function calculateTotalDistance(Delivery $delivery): float
    {
        $points = $delivery->trackingPoints()
            ->chronological()
            ->get(['latitude', 'longitude']);

        if ($points->count() < 2) {
            return 0;
        }

        $totalDistance = 0;

        for ($i = 1; $i < $points->count(); $i++) {
            $totalDistance += $this->haversineDistance(
                $points[$i - 1]->latitude,
                $points[$i - 1]->longitude,
                $points[$i]->latitude,
                $points[$i]->longitude
            );
        }

        return round($totalDistance, 2);
    }

    /**
     * Obtenir la position actuelle estimée du livreur pour une livraison
     */
    public function getCurrentPosition(Delivery $delivery): ?array
    {
        $lastPoint = $delivery->trackingPoints()
            ->chronological()
            ->latest('recorded_at')
            ->first();

        if (!$lastPoint) {
            return null;
        }

        return [
            'latitude' => $lastPoint->latitude,
            'longitude' => $lastPoint->longitude,
            'speed' => $lastPoint->speed,
            'heading' => $lastPoint->heading,
            'accuracy' => $lastPoint->accuracy,
            'recorded_at' => $lastPoint->recorded_at,
            'is_stale' => $lastPoint->recorded_at->diffInMinutes(now()) > 5,
        ];
    }

    /**
     * Obtenir les positions de tous les livreurs en livraison active
     */
    public function getActiveDeliveryPositions(): Collection
    {
        return Delivery::inProgress()
            ->with(['courier.user', 'order.pharmacy'])
            ->get()
            ->map(function (Delivery $delivery) {
                $position = $this->getCurrentPosition($delivery);

                if (!$position) {
                    // Fallback sur la position du livreur
                    $courier = $delivery->courier;
                    if ($courier && $courier->last_latitude && $courier->last_longitude) {
                        $position = [
                            'latitude' => $courier->last_latitude,
                            'longitude' => $courier->last_longitude,
                            'speed' => null,
                            'heading' => null,
                            'accuracy' => null,
                            'recorded_at' => $courier->last_location_update,
                            'is_stale' => $courier->last_location_update?->diffInMinutes(now()) > 5,
                        ];
                    }
                }

                return [
                    'delivery_id' => $delivery->id,
                    'courier_id' => $delivery->courier_id,
                    'courier_name' => $delivery->courier?->user?->name ?? 'N/A',
                    'order_id' => $delivery->order_id,
                    'status' => $delivery->status,
                    'pickup_pharmacy' => $delivery->order?->pharmacy?->name ?? 'N/A',
                    'position' => $position,
                ];
            })
            ->filter(fn ($item) => $item['position'] !== null);
    }

    /**
     * Calculer la vitesse moyenne d'une livraison (km/h)
     */
    public function calculateAverageSpeed(Delivery $delivery): float
    {
        $points = $delivery->trackingPoints()
            ->whereNotNull('speed')
            ->where('speed', '>', 0)
            ->pluck('speed');

        if ($points->isEmpty()) {
            return 0;
        }

        return round($points->average(), 1);
    }

    /**
     * Calculer l'ETA restant basé sur la position actuelle
     */
    public function estimateRemainingEta(Delivery $delivery): ?int
    {
        $position = $this->getCurrentPosition($delivery);

        if (!$position || $position['is_stale']) {
            return null;
        }

        $destinationLat = $delivery->delivery_latitude ?? $delivery->dropoff_latitude;
        $destinationLng = $delivery->delivery_longitude ?? $delivery->dropoff_longitude;

        if (!$destinationLat || !$destinationLng) {
            return null;
        }

        $remainingDistance = $this->haversineDistance(
            $position['latitude'],
            $position['longitude'],
            $destinationLat,
            $destinationLng
        );

        // Vitesse moyenne estimée : 25 km/h en ville
        $avgSpeed = max($this->calculateAverageSpeed($delivery), 25);

        // ETA en minutes
        return (int) ceil(($remainingDistance / $avgSpeed) * 60);
    }

    /**
     * Calcul de distance Haversine (en km)
     */
    protected function haversineDistance(
        float $lat1,
        float $lon1,
        float $lat2,
        float $lon2
    ): float {
        $earthRadius = 6371;

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
            cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
            sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }
}
