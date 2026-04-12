<?php

namespace App\Services;

use App\Models\Courier;
use App\Models\DeliveryOffer;
use App\Models\Order;
use App\Models\OrderBatch;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class OrderBatchingService
{
    /**
     * Configuration du batching
     */
    const MAX_ORDERS_PER_BATCH = 4;
    const MAX_DETOUR_PERCENT = 30; // Max 30% de détour
    const MAX_BATCH_DISTANCE_KM = 3; // Distance max entre ordres
    const BATCH_BONUS_PER_ORDER = 150; // FCFA par commande supplémentaire

    protected EtaService $etaService;

    public function __construct(EtaService $etaService)
    {
        $this->etaService = $etaService;
    }

    /**
     * Trouver des ordres compatibles pour le batching
     */
    public function findBatchableOrders(Order $primaryOrder): Collection
    {
        // Ordres en attente de la même pharmacie
        $samePharmacyOrders = Order::where('pharmacy_id', $primaryOrder->pharmacy_id)
            ->where('id', '!=', $primaryOrder->id)
            ->where('status', 'confirmed')
            ->whereNull('courier_id')
            ->get();

        // Ordres proches géographiquement (destinations similaires)
        $nearbyOrders = Order::where('id', '!=', $primaryOrder->id)
            ->where('status', 'confirmed')
            ->whereNull('courier_id')
            ->get()
            ->filter(function ($order) use ($primaryOrder) {
                return $this->areOrdersCompatible($primaryOrder, $order);
            });

        return $samePharmacyOrders->merge($nearbyOrders)
            ->unique('id')
            ->take(self::MAX_ORDERS_PER_BATCH - 1);
    }

    /**
     * Vérifier si deux ordres sont compatibles pour le batching
     */
    public function areOrdersCompatible(Order $order1, Order $order2): bool
    {
        // Vérifier la distance entre les destinations
        $distance = $this->calculateDistance(
            $order1->delivery_latitude,
            $order1->delivery_longitude,
            $order2->delivery_latitude,
            $order2->delivery_longitude
        );

        return $distance <= self::MAX_BATCH_DISTANCE_KM;
    }

    /**
     * Créer un lot de commandes
     */
    public function createBatch(array $orderIds, ?Courier $courier = null, ?DeliveryOffer $offer = null): ?OrderBatch
    {
        $orders = Order::whereIn('id', $orderIds)->get();

        if ($orders->count() < 2) {
            return null;
        }

        return DB::transaction(function () use ($orders, $courier, $offer) {
            // Optimiser l'ordre de livraison
            $optimizedOrders = $this->optimizeDeliverySequence($orders);
            
            // Calculer la route optimisée
            $routeData = $this->calculateOptimizedRoute($optimizedOrders);

            // Calculer les frais totaux et bonus
            $totalFee = $orders->sum('delivery_fee');
            $batchBonus = ($orders->count() - 1) * self::BATCH_BONUS_PER_ORDER;

            // Créer le lot
            $batch = OrderBatch::create([
                'courier_id' => $courier?->id,
                'delivery_offer_id' => $offer?->id,
                'status' => $courier ? OrderBatch::STATUS_ASSIGNED : OrderBatch::STATUS_PENDING,
                'total_orders' => $orders->count(),
                'total_fee' => $totalFee,
                'batch_bonus' => $batchBonus,
                'optimized_route' => $routeData['coordinates'],
                'total_distance' => $routeData['distance'],
                'estimated_total_time' => $routeData['duration'],
            ]);

            // Attacher les ordres avec leur séquence
            foreach ($optimizedOrders as $sequence => $order) {
                $eta = $this->etaService->calculateEtaForSequence($optimizedOrders, $sequence);
                
                $batch->orders()->attach($order->id, [
                    'sequence' => $sequence + 1,
                    'estimated_arrival' => now()->addSeconds($eta),
                    'status' => 'pending',
                ]);

                // Marquer l'ordre comme faisant partie d'un batch
                $order->update(['order_batch_id' => $batch->id]);
            }

            Log::info("OrderBatching: Created batch {$batch->id} with " . $orders->count() . " orders");

            return $batch;
        });
    }

    /**
     * Optimiser la séquence de livraison (Nearest Neighbor Algorithm)
     */
    public function optimizeDeliverySequence(Collection $orders): Collection
    {
        if ($orders->count() <= 2) {
            return $orders;
        }

        $optimized = collect();
        $remaining = $orders->all();

        // Commencer par le premier ordre (ou celui de la même pharmacie)
        $current = array_shift($remaining);
        $optimized->push($current);

        while (!empty($remaining)) {
            $nearest = null;
            $minDistance = PHP_INT_MAX;
            $nearestKey = null;

            foreach ($remaining as $key => $order) {
                $distance = $this->calculateDistance(
                    $current->delivery_latitude,
                    $current->delivery_longitude,
                    $order->delivery_latitude,
                    $order->delivery_longitude
                );

                if ($distance < $minDistance) {
                    $minDistance = $distance;
                    $nearest = $order;
                    $nearestKey = $key;
                }
            }

            $optimized->push($nearest);
            $current = $nearest;
            unset($remaining[$nearestKey]);
        }

        return $optimized;
    }

    /**
     * Calculer la route optimisée
     */
    protected function calculateOptimizedRoute(Collection $orders): array
    {
        $coordinates = $orders->map(function ($order) {
            return [
                'lat' => $order->delivery_latitude,
                'lng' => $order->delivery_longitude,
                'order_id' => $order->id,
            ];
        })->toArray();

        // Calculer la distance totale
        $totalDistance = 0;
        for ($i = 0; $i < count($coordinates) - 1; $i++) {
            $totalDistance += $this->calculateDistance(
                $coordinates[$i]['lat'],
                $coordinates[$i]['lng'],
                $coordinates[$i + 1]['lat'],
                $coordinates[$i + 1]['lng']
            );
        }

        // Estimation du temps (30 km/h en ville + 3 min par arrêt)
        $avgSpeedKmh = 30;
        $stopTimeMinutes = 3;
        $travelTimeMinutes = ($totalDistance / $avgSpeedKmh) * 60;
        $totalTimeMinutes = $travelTimeMinutes + (count($coordinates) * $stopTimeMinutes);

        return [
            'coordinates' => $coordinates,
            'distance' => round($totalDistance, 2),
            'duration' => (int) ceil($totalTimeMinutes * 60), // En secondes
        ];
    }

    /**
     * Vérifier le détour ajouté par un ordre supplémentaire
     */
    public function calculateDetourPercent(OrderBatch $batch, Order $newOrder): float
    {
        $currentDistance = $batch->total_distance;
        
        // Simuler l'ajout de l'ordre
        $orders = $batch->orders->push($newOrder);
        $optimized = $this->optimizeDeliverySequence($orders);
        $newRoute = $this->calculateOptimizedRoute($optimized);
        
        if ($currentDistance == 0) {
            return 0;
        }

        $addedDistance = $newRoute['distance'] - $currentDistance;
        return ($addedDistance / $currentDistance) * 100;
    }

    /**
     * Proposer d'ajouter un ordre à un batch existant
     */
    public function suggestAddToBatch(Order $newOrder): ?OrderBatch
    {
        // Trouver les batches en cours qui pourraient accepter cet ordre
        $compatibleBatches = OrderBatch::inProgress()
            ->where('total_orders', '<', self::MAX_ORDERS_PER_BATCH)
            ->whereHas('courier', function ($q) use ($newOrder) {
                // Le livreur doit être proche de la pharmacie de l'ordre
                $q->nearLocation(
                    $newOrder->pharmacy->latitude,
                    $newOrder->pharmacy->longitude,
                    2 // 2km
                );
            })
            ->get()
            ->filter(function ($batch) use ($newOrder) {
                $detour = $this->calculateDetourPercent($batch, $newOrder);
                return $detour <= self::MAX_DETOUR_PERCENT;
            })
            ->sortBy(function ($batch) use ($newOrder) {
                return $this->calculateDetourPercent($batch, $newOrder);
            });

        return $compatibleBatches->first();
    }

    /**
     * Ajouter un ordre à un batch existant
     */
    public function addOrderToBatch(OrderBatch $batch, Order $order): bool
    {
        if ($batch->total_orders >= self::MAX_ORDERS_PER_BATCH) {
            return false;
        }

        $detour = $this->calculateDetourPercent($batch, $order);
        if ($detour > self::MAX_DETOUR_PERCENT) {
            return false;
        }

        // Recalculer la route optimisée
        $allOrders = $batch->orders->push($order);
        $optimized = $this->optimizeDeliverySequence($allOrders);
        $routeData = $this->calculateOptimizedRoute($optimized);

        DB::transaction(function () use ($batch, $order, $optimized, $routeData) {
            // Ajouter l'ordre au batch
            $sequence = $optimized->search($order) + 1;
            $eta = $this->etaService->calculateEtaForSequence($optimized, $sequence - 1);

            $batch->orders()->attach($order->id, [
                'sequence' => $sequence,
                'estimated_arrival' => now()->addSeconds($eta),
                'status' => 'pending',
            ]);

            // Mettre à jour le batch
            $batch->update([
                'total_orders' => $batch->total_orders + 1,
                'total_fee' => $batch->total_fee + $order->delivery_fee,
                'batch_bonus' => ($batch->total_orders) * self::BATCH_BONUS_PER_ORDER,
                'optimized_route' => $routeData['coordinates'],
                'total_distance' => $routeData['distance'],
                'estimated_total_time' => $routeData['duration'],
            ]);

            // Re-séquencer tous les ordres
            foreach ($optimized as $seq => $ord) {
                $batch->orders()->updateExistingPivot($ord->id, [
                    'sequence' => $seq + 1,
                ]);
            }

            $order->update(['order_batch_id' => $batch->id]);
        });

        Log::info("OrderBatching: Added order {$order->id} to batch {$batch->id}");

        return true;
    }

    /**
     * Calculer la distance entre deux points (Haversine)
     */
    protected function calculateDistance(
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
}
