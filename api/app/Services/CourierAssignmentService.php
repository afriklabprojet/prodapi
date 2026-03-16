<?php

namespace App\Services;

use App\Models\Courier;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Pharmacy;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CourierAssignmentService
{
    /**
     * Assigner automatiquement un livreur à une commande
     * Basé sur la proximité GPS et la disponibilité
     */
    public function assignCourier(Order $order): ?Delivery
    {
        try {
            return DB::transaction(function () use ($order) {
                // Vérifier que la commande n'a pas déjà une livraison
                if ($order->delivery()->exists()) {
                    Log::info("Order {$order->reference} already has a delivery assigned");
                    return $order->delivery;
                }

                // Récupérer la pharmacie pour obtenir sa position
                $pharmacy = $order->pharmacy;
                
                if (!$pharmacy->latitude || !$pharmacy->longitude) {
                    Log::warning("Pharmacy {$pharmacy->id} has no GPS coordinates");
                    return null;
                }

                // Trouver le livreur le plus proche disponible
                $courier = $this->findNearestAvailableCourier(
                    $pharmacy->latitude,
                    $pharmacy->longitude,
                    $maxDistance = 20, // Distance augmentée à 20 km
                    $order // Passage de la commande pour vérifier compatibilité type véhicule
                );

                if (!$courier) {
                    Log::warning("No available courier found near pharmacy {$pharmacy->id}");
                    return null;
                }

                // Créer la livraison
                $delivery = Delivery::create([
                    'order_id' => $order->id,
                    'courier_id' => $courier->id,
                    'pickup_address' => $pharmacy->address,
                    'pickup_latitude' => $pharmacy->latitude,
                    'pickup_longitude' => $pharmacy->longitude,
                    'delivery_address' => $order->delivery_address,
                    'delivery_latitude' => $order->delivery_latitude,
                    'delivery_longitude' => $order->delivery_longitude,
                    'status' => 'pending',
                    'delivery_fee' => $order->delivery_fee,
                ]);

                Log::info("Delivery {$delivery->id} created for order {$order->reference} with courier {$courier->id}");

                // Notifier le livreur
                try {
                    $courier->user->notify(new \App\Notifications\DeliveryAssignedNotification($delivery));
                } catch (\Exception $e) {
                    Log::error("Failed to send notification to courier {$courier->id}: " . $e->getMessage());
                }

                return $delivery;
            });
        } catch (\Exception $e) {
            Log::error("Failed to assign courier to order {$order->id}: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Trouver le livreur disponible le plus proche
     */
    public function findNearestAvailableCourier(
        float $latitude,
        float $longitude,
        float $maxDistance = 20,
        ?Order $order = null
    ): ?Courier {
        // Récupérer tous les livreurs disponibles avec une position
        $query = Courier::available()
            ->whereNotNull('latitude')
            ->whereNotNull('longitude');

        // Si la commande est volumineuse, préférer les voitures/camions si possible
        // (Logique à affiner selon les données réelles du `vehicle_type`)
        
        $couriers = $query->get();

        // Filtrer et trier par distance + score intelligent
        $nearestCourier = $couriers->map(function ($courier) use ($latitude, $longitude) {
            $distance = $this->calculateDistance(
                $latitude, 
                $longitude, 
                $courier->latitude, 
                $courier->longitude
            );
            
            $courier->distance = $distance;
            
            // SCORE D'ASSIGNATION
            // Plus le score est bas, meilleur est le candidat
            // Base: Distance en KM
            $score = $distance;
            
            // Malus si note faible (max 2km de pénalité virtuelle)
            $ratingMalus = (5 - min($courier->rating, 5)) * 0.5;
            $score += $ratingMalus;
            
            // Bonus pour les livreurs expérimentés (max 1km de bonus virtuel)
            // ex: 1000 livraisons = -1km sur le score
            $experienceBonus = min($courier->completed_deliveries, 1000) / 1000;
            $score -= $experienceBonus;
            
            $courier->assignment_score = $score;
            
            return $courier;
        })
        ->filter(function ($courier) use ($maxDistance) {
            return $courier->distance <= $maxDistance;
        })
        ->sortBy('assignment_score') // Tri par le score calculé au lieu de juste la distance distance brute
        ->first();

        return $nearestCourier;
    }

    /**
     * Assigner manuellement un livreur spécifique
     */
    public function assignSpecificCourier(Order $order, Courier $courier): ?Delivery
    {
        try {
            return DB::transaction(function () use ($order, $courier) {
                // Vérifier que le livreur est disponible
                if ($courier->status !== 'available') {
                    Log::warning("Courier {$courier->id} is not available (status: {$courier->status})");
                    return null;
                }

                // Vérifier que la commande n'a pas déjà une livraison
                if ($order->delivery()->exists()) {
                    Log::info("Order {$order->reference} already has a delivery assigned");
                    return $order->delivery;
                }

                $pharmacy = $order->pharmacy;

                // Créer la livraison
                $delivery = Delivery::create([
                    'order_id' => $order->id,
                    'courier_id' => $courier->id,
                    'pickup_address' => $pharmacy->address,
                    'pickup_latitude' => $pharmacy->latitude,
                    'pickup_longitude' => $pharmacy->longitude,
                    'delivery_address' => $order->delivery_address,
                    'delivery_latitude' => $order->delivery_latitude,
                    'delivery_longitude' => $order->delivery_longitude,
                    'status' => 'pending',
                    'delivery_fee' => $order->delivery_fee,
                ]);

                Log::info("Delivery {$delivery->id} manually assigned to courier {$courier->id}");

                return $delivery;
            });
        } catch (\Exception $e) {
            Log::error("Failed to manually assign courier {$courier->id} to order {$order->id}: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Réassigner une livraison à un autre livreur
     */
    public function reassignDelivery(Delivery $delivery): ?Courier
    {
        try {
            return DB::transaction(function () use ($delivery) {
                // Ne peut réassigner que si status = pending
                if ($delivery->status !== 'pending') {
                    Log::warning("Cannot reassign delivery {$delivery->id} with status {$delivery->status}");
                    return null;
                }

                $oldCourierId = $delivery->courier_id;

                // Trouver un nouveau livreur (exclure l'ancien)
                // Note: Using PHP calculation instead of SQL scope to support SQLite testing
                // and consistent behavior with findNearestCourier
                $candidates = Courier::available()
                    ->where('id', '!=', $oldCourierId)
                    ->whereNotNull('latitude')
                    ->whereNotNull('longitude')
                    ->get();

                $newCourier = $candidates->map(function ($courier) use ($delivery) {
                    $courier->distance = $this->calculateDistance(
                        $delivery->pickup_latitude,
                        $delivery->pickup_longitude,
                        $courier->latitude,
                        $courier->longitude
                    );
                    return $courier;
                })
                ->filter(function ($courier) {
                    return $courier->distance <= 15;
                })
                ->sortBy('distance')
                ->first();

                if (!$newCourier) {
                    Log::warning("No alternative courier found for delivery {$delivery->id}");
                    return null;
                }

                $delivery->update(['courier_id' => $newCourier->id]);

                Log::info("Delivery {$delivery->id} reassigned from courier {$oldCourierId} to {$newCourier->id}");

                return $newCourier;
            });
        } catch (\Exception $e) {
            Log::error("Failed to reassign delivery {$delivery->id}: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Obtenir les livreurs disponibles dans un rayon
     */
    public function getAvailableCouriersInRadius(
        float $latitude,
        float $longitude,
        float $radius = 15
    ): \Illuminate\Database\Eloquent\Collection {
        return Courier::available()
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->nearLocation($latitude, $longitude)
            ->having('distance', '<=', $radius)
            ->orderBy('distance')
            ->get();
    }

    /**
     * Calculer la distance entre deux points GPS (Haversine)
     */
    public function calculateDistance(
        float $lat1,
        float $lon1,
        float $lat2,
        float $lon2
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
     * Estimer le temps de livraison en minutes
     * Basé sur la distance et une vitesse moyenne
     */
    public function estimateDeliveryTime(
        float $pharmacyLat,
        float $pharmacyLon,
        float $customerLat,
        float $customerLon,
        string $vehicleType = 'motorcycle'
    ): int {
        $distance = $this->calculateDistance(
            $pharmacyLat,
            $pharmacyLon,
            $customerLat,
            $customerLon
        );

        // Vitesse moyenne selon le type de véhicule (km/h)
        $speeds = [
            'motorcycle' => 30,
            'bicycle' => 15,
            'car' => 25,
            'walking' => 5,
        ];

        $speed = $speeds[$vehicleType] ?? 25;

        // Temps en minutes + 10 min de préparation
        return (int) ceil(($distance / $speed) * 60) + 10;
    }
}
