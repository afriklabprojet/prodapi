<?php

namespace App\Services;

use App\Models\Courier;
use App\Models\Delivery;
use App\Models\DeliveryTrackingPoint;
use App\Models\Order;
use App\Models\Pharmacy;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class EtaService
{
    /**
     * Vitesses moyennes par type de véhicule (km/h) selon les conditions
     */
    const VEHICLE_SPEEDS = [
        'scooter' => [
            'normal' => 35,
            'traffic' => 25,
            'heavy_traffic' => 18,
        ],
        'motorcycle' => [
            'normal' => 40,
            'traffic' => 30,
            'heavy_traffic' => 20,
        ],
        'car' => [
            'normal' => 45,
            'traffic' => 20,
            'heavy_traffic' => 12,
        ],
        'bicycle' => [
            'normal' => 15,
            'traffic' => 15,
            'heavy_traffic' => 15,
        ],
    ];

    // Temps fixes
    const PICKUP_TIME_SECONDS = 180; // 3 min pour récupérer la commande
    const DROPOFF_TIME_SECONDS = 120; // 2 min pour livrer

    /**
     * Calculer l'ETA initial pour une commande
     */
    public function calculateInitialEta(Order $order, Courier $courier): array
    {
        $pharmacy = $order->pharmacy;
        
        // Distance livreur → pharmacie
        $pickupDistance = $this->calculateDistance(
            $courier->latitude, $courier->longitude,
            $pharmacy->latitude, $pharmacy->longitude
        );

        // Distance pharmacie → client
        $deliveryDistance = $this->calculateDistance(
            $pharmacy->latitude, $pharmacy->longitude,
            $order->delivery_latitude, $order->delivery_longitude
        );

        // Facteur de vitesse du livreur (basé sur son historique)
        $speedFactor = $courier->avg_delivery_speed_factor ?? 1.0;
        
        // Conditions de trafic
        $trafficCondition = $this->getTrafficCondition(
            $pharmacy->latitude,
            $pharmacy->longitude
        );

        // Vitesse effective
        $vehicleType = $courier->vehicle_type ?? 'scooter';
        $baseSpeed = self::VEHICLE_SPEEDS[$vehicleType][$trafficCondition] 
            ?? self::VEHICLE_SPEEDS['scooter']['normal'];
        $effectiveSpeed = $baseSpeed * $speedFactor;

        // Calcul du temps
        $pickupTimeSeconds = ($pickupDistance / $effectiveSpeed) * 3600;
        $deliveryTimeSeconds = ($deliveryDistance / $effectiveSpeed) * 3600;

        $totalSeconds = (int) ceil(
            $pickupTimeSeconds + 
            self::PICKUP_TIME_SECONDS + 
            $deliveryTimeSeconds + 
            self::DROPOFF_TIME_SECONDS
        );

        return [
            'pickup_distance_km' => round($pickupDistance, 2),
            'delivery_distance_km' => round($deliveryDistance, 2),
            'total_distance_km' => round($pickupDistance + $deliveryDistance, 2),
            'pickup_eta_seconds' => (int) ceil($pickupTimeSeconds),
            'delivery_eta_seconds' => $totalSeconds,
            'estimated_arrival' => now()->addSeconds($totalSeconds),
            'traffic_condition' => $trafficCondition,
            'speed_factor' => $speedFactor,
        ];
    }

    /**
     * Estimer l'ETA de pickup pour une offre
     */
    public function estimatePickupEta(Courier $courier, Pharmacy $pharmacy): int
    {
        $distance = $this->calculateDistance(
            $courier->latitude, $courier->longitude,
            $pharmacy->latitude, $pharmacy->longitude
        );

        $vehicleType = $courier->vehicle_type ?? 'scooter';
        $speed = self::VEHICLE_SPEEDS[$vehicleType]['normal'];
        
        return (int) ceil(($distance / $speed) * 3600) + self::PICKUP_TIME_SECONDS;
    }

    /**
     * Calculer l'ETA pour un ordre dans une séquence (batching)
     */
    public function calculateEtaForSequence(Collection $orders, int $sequenceIndex): int
    {
        if ($sequenceIndex < 0 || $sequenceIndex >= $orders->count()) {
            return 0;
        }

        $totalTime = 0;

        for ($i = 0; $i <= $sequenceIndex; $i++) {
            $currentOrder = $orders[$i];
            
            if ($i === 0) {
                // Premier ordre: temps depuis la pharmacie
                // Supposer 10 minutes pour le premier pickup
                $totalTime += 600;
            } else {
                // Distance depuis l'ordre précédent
                $previousOrder = $orders[$i - 1];
                $distance = $this->calculateDistance(
                    $previousOrder->delivery_latitude,
                    $previousOrder->delivery_longitude,
                    $currentOrder->delivery_latitude,
                    $currentOrder->delivery_longitude
                );
                
                // 30 km/h en ville
                $travelTime = ($distance / 30) * 3600;
                $totalTime += $travelTime + self::DROPOFF_TIME_SECONDS;
            }
        }

        return (int) ceil($totalTime);
    }

    /**
     * Mettre à jour l'ETA en temps réel basé sur la position actuelle
     */
    public function updateLiveEta(Delivery $delivery, float $latitude, float $longitude): array
    {
        $order = $delivery->order;
        $courier = $delivery->courier;

        // Enregistrer le point de tracking
        DeliveryTrackingPoint::createLocationUpdate(
            $delivery,
            $latitude,
            $longitude
        );

        // Calculer la distance restante selon le statut
        if ($delivery->status === 'assigned' || $delivery->status === 'heading_to_pharmacy') {
            // Vers la pharmacie
            $remainingDistance = $this->calculateDistance(
                $latitude, $longitude,
                $order->pharmacy->latitude, $order->pharmacy->longitude
            );
            $phase = 'pickup';
        } else {
            // Vers le client
            $remainingDistance = $this->calculateDistance(
                $latitude, $longitude,
                $order->delivery_latitude, $order->delivery_longitude
            );
            $phase = 'delivery';
        }

        // Vitesse récente (basée sur les derniers points)
        $recentSpeed = $this->calculateRecentSpeed($delivery);
        
        // Calculer le temps restant
        if ($recentSpeed > 0) {
            $remainingSeconds = (int) ceil(($remainingDistance / $recentSpeed) * 3600);
        } else {
            // Fallback sur la vitesse moyenne
            $vehicleType = $courier->vehicle_type ?? 'scooter';
            $defaultSpeed = self::VEHICLE_SPEEDS[$vehicleType]['normal'];
            $remainingSeconds = (int) ceil(($remainingDistance / $defaultSpeed) * 3600);
        }

        // Ajouter les temps fixes restants
        if ($phase === 'pickup') {
            $remainingSeconds += self::PICKUP_TIME_SECONDS;
            // Ajouter le temps de livraison
            $deliveryDistance = $this->calculateDistance(
                $order->pharmacy->latitude, $order->pharmacy->longitude,
                $order->delivery_latitude, $order->delivery_longitude
            );
            $vehicleType = $courier->vehicle_type ?? 'scooter';
            $speed = $recentSpeed > 0 ? $recentSpeed : self::VEHICLE_SPEEDS[$vehicleType]['normal'];
            $remainingSeconds += (int) ceil(($deliveryDistance / $speed) * 3600);
            $remainingSeconds += self::DROPOFF_TIME_SECONDS;
        } else {
            $remainingSeconds += self::DROPOFF_TIME_SECONDS;
        }

        // Mettre à jour la livraison
        $delivery->update([
            'current_eta_seconds' => $remainingSeconds,
        ]);

        return [
            'current_eta_seconds' => $remainingSeconds,
            'estimated_arrival' => now()->addSeconds($remainingSeconds),
            'remaining_distance_km' => round($remainingDistance, 2),
            'current_speed_kmh' => round($recentSpeed, 1),
            'phase' => $phase,
        ];
    }

    /**
     * Calculer la vitesse récente du livreur
     */
    protected function calculateRecentSpeed(Delivery $delivery): float
    {
        $recentPoints = DeliveryTrackingPoint::where('delivery_id', $delivery->id)
            ->where('event_type', DeliveryTrackingPoint::EVENT_LOCATION_UPDATE)
            ->where('recorded_at', '>=', now()->subMinutes(5))
            ->orderBy('recorded_at', 'desc')
            ->limit(10)
            ->get();

        if ($recentPoints->count() < 2) {
            return 0;
        }

        $totalDistance = 0;
        $totalTime = 0;

        for ($i = 0; $i < $recentPoints->count() - 1; $i++) {
            $point1 = $recentPoints[$i];
            $point2 = $recentPoints[$i + 1];

            $distance = $this->calculateDistance(
                $point1->latitude, $point1->longitude,
                $point2->latitude, $point2->longitude
            );
            
            $time = $point2->recorded_at->diffInSeconds($point1->recorded_at);

            $totalDistance += $distance;
            $totalTime += $time;
        }

        if ($totalTime === 0) {
            return 0;
        }

        // Convertir en km/h
        return ($totalDistance / $totalTime) * 3600;
    }

    /**
     * Obtenir les conditions de trafic
     */
    protected function getTrafficCondition(float $latitude, float $longitude): string
    {
        // TODO: Intégrer une API de trafic (Google Maps, HERE, TomTom)
        // Pour l'instant, utiliser des heuristiques basées sur l'heure
        
        $hour = (int) now()->format('H');
        $dayOfWeek = (int) now()->format('N');
        
        // Week-end: trafic normal
        if ($dayOfWeek >= 6) {
            return 'normal';
        }

        // Heures de pointe
        if (($hour >= 7 && $hour <= 9) || ($hour >= 17 && $hour <= 19)) {
            return 'heavy_traffic';
        }

        // Heures de bureau
        if ($hour >= 12 && $hour <= 14) {
            return 'traffic';
        }

        return 'normal';
    }

    /**
     * Générer le polyline de la route
     */
    public function getRoutePolyline(
        float $startLat, float $startLng,
        float $endLat, float $endLng
    ): ?string {
        // TODO: Intégrer une API de routing (OSRM, Google Directions)
        // Pour l'instant, retourner null
        return null;
    }

    /**
     * Calculer la distance entre deux points (Haversine)
     */
    public function calculateDistance(
        float $lat1, float $lon1,
        float $lat2, float $lon2
    ): float {
        $earthRadius = 6371; // km

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }

    /**
     * Mettre à jour le speed factor du livreur après une livraison
     */
    public function updateCourierSpeedFactor(Courier $courier, Delivery $delivery): void
    {
        // Comparer ETA initial vs temps réel
        if (!$delivery->original_eta_seconds || !$delivery->completed_at) {
            return;
        }

        $actualSeconds = $delivery->assigned_at->diffInSeconds($delivery->completed_at);
        $predictedSeconds = $delivery->original_eta_seconds;

        if ($predictedSeconds === 0) {
            return;
        }

        // Calculer le facteur de ce trajet
        $tripFactor = $predictedSeconds / $actualSeconds;
        
        // Moyenne mobile exponentielle avec le facteur existant
        $alpha = 0.2; // Poids du nouveau sample
        $currentFactor = $courier->avg_delivery_speed_factor ?? 1.0;
        $newFactor = ($alpha * $tripFactor) + ((1 - $alpha) * $currentFactor);

        // Limiter entre 0.5 et 1.5
        $newFactor = max(0.5, min(1.5, $newFactor));

        $courier->update(['avg_delivery_speed_factor' => round($newFactor, 2)]);
    }
}
