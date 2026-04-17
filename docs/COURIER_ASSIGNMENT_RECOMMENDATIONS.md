# 🚀 Recommandations Système d'Assignation - Niveau Glovo/Uber Eats

> **Objectif** : Transformer le système d'assignation actuel en une plateforme de dispatch intelligente comparable aux leaders du marché.

---

## 📊 Analyse du Système Actuel

### ✅ Points Forts
- Calcul de distance Haversine fonctionnel
- Score d'assignation (distance + rating + expérience)
- Système de réassignation
- Historique de localisation
- Frais d'attente (waiting_fee)

### ❌ Manques Critiques par Rapport à Glovo/Uber

| Fonctionnalité | Glovo/Uber | DR-PHARMA Actuel |
|----------------|------------|------------------|
| Broadcast multi-livreurs | ✅ | ❌ |
| Auto-scaling du rayon | ✅ | ❌ |
| Surge pricing dynamique | ✅ | ❌ |
| Batching (multi-commandes) | ✅ | ❌ |
| ETA temps réel | ✅ | Basique |
| Machine Learning prédictif | ✅ | ❌ |
| Système de shifts/planning | ✅ | ❌ |
| Heatmaps zones chaudes | ✅ | ❌ |
| Incentives dynamiques | ✅ | ❌ |
| Fallback cascade | ✅ | ❌ |

---

## 🎯 PHASE 1 : Dispatch Intelligent (Priorité Haute)

### 1.1 Système de Broadcast avec Timeout

**Problème actuel** : Assignation directe au premier livreur = pas de concurrence

**Solution Glovo-style** :

```php
<?php
// app/Services/BroadcastDispatchService.php

namespace App\Services;

use App\Models\Order;
use App\Models\Courier;
use App\Models\DeliveryOffer;
use App\Events\DeliveryOfferBroadcast;
use App\Jobs\ExpireDeliveryOffer;
use Illuminate\Support\Facades\Cache;

class BroadcastDispatchService
{
    /**
     * Configuration des niveaux de broadcast
     */
    private array $broadcastLevels = [
        ['radius' => 3, 'timeout' => 30, 'max_couriers' => 5],   // Niveau 1: 3km, 30s
        ['radius' => 7, 'timeout' => 45, 'max_couriers' => 10],  // Niveau 2: 7km, 45s  
        ['radius' => 15, 'timeout' => 60, 'max_couriers' => 20], // Niveau 3: 15km, 60s
        ['radius' => 25, 'timeout' => 90, 'max_couriers' => 50], // Niveau 4: 25km, 90s (désespéré)
    ];

    /**
     * Broadcaster une offre de livraison à plusieurs livreurs
     */
    public function broadcastDeliveryOffer(Order $order): DeliveryOffer
    {
        $pharmacy = $order->pharmacy;
        
        // Créer l'offre
        $offer = DeliveryOffer::create([
            'order_id' => $order->id,
            'status' => 'pending',
            'broadcast_level' => 0,
            'expires_at' => now()->addSeconds($this->broadcastLevels[0]['timeout']),
            'base_fee' => $order->delivery_fee,
            'bonus_fee' => 0,
        ]);
        
        // Premier niveau de broadcast
        $this->broadcastToLevel($offer, 0);
        
        // Programmer l'expiration
        ExpireDeliveryOffer::dispatch($offer)
            ->delay($this->broadcastLevels[0]['timeout']);
        
        return $offer;
    }

    /**
     * Broadcaster à un niveau spécifique
     */
    protected function broadcastToLevel(DeliveryOffer $offer, int $level): void
    {
        $config = $this->broadcastLevels[$level];
        $order = $offer->order;
        $pharmacy = $order->pharmacy;
        
        // Trouver les livreurs dans le rayon
        $couriers = $this->findEligibleCouriers(
            $pharmacy->latitude,
            $pharmacy->longitude,
            $config['radius'],
            $config['max_couriers'],
            $offer
        );
        
        // Enregistrer les livreurs ciblés
        foreach ($couriers as $courier) {
            $offer->targetedCouriers()->attach($courier->id, [
                'notified_at' => now(),
                'status' => 'notified',
            ]);
        }
        
        // Envoyer les notifications push en masse
        event(new DeliveryOfferBroadcast($offer, $couriers));
        
        // Log pour analytics
        Log::channel('dispatch')->info("Broadcast level {$level}", [
            'offer_id' => $offer->id,
            'order_id' => $order->id,
            'couriers_count' => $couriers->count(),
            'radius' => $config['radius'],
        ]);
    }

    /**
     * Escalader au niveau suivant si personne n'accepte
     */
    public function escalateOffer(DeliveryOffer $offer): void
    {
        $nextLevel = $offer->broadcast_level + 1;
        
        if ($nextLevel >= count($this->broadcastLevels)) {
            // Plus de niveaux - activer mode manuel admin
            $offer->update(['status' => 'no_courier_found']);
            event(new NoCourierFoundEvent($offer));
            return;
        }
        
        // Ajouter un bonus pour attirer les livreurs
        $bonusIncrement = $nextLevel * 200; // +200 FCFA par niveau
        
        $offer->update([
            'broadcast_level' => $nextLevel,
            'bonus_fee' => $offer->bonus_fee + $bonusIncrement,
            'expires_at' => now()->addSeconds($this->broadcastLevels[$nextLevel]['timeout']),
        ]);
        
        $this->broadcastToLevel($offer, $nextLevel);
        
        // Reprogrammer l'expiration
        ExpireDeliveryOffer::dispatch($offer)
            ->delay($this->broadcastLevels[$nextLevel]['timeout']);
    }

    /**
     * Trouver les livreurs éligibles avec scoring intelligent
     */
    protected function findEligibleCouriers(
        float $lat,
        float $lng,
        float $radius,
        int $maxCouriers,
        DeliveryOffer $offer
    ): Collection {
        return Courier::available()
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            // Exclure les livreurs déjà notifiés
            ->whereNotIn('id', $offer->targetedCouriers->pluck('id'))
            // Exclure ceux qui ont refusé
            ->whereNotIn('id', $offer->rejectedCouriers->pluck('id'))
            // Avec token FCM valide
            ->whereHas('user', fn($q) => $q->whereNotNull('fcm_token'))
            ->get()
            ->map(function ($courier) use ($lat, $lng) {
                $courier->distance = $this->calculateDistance($lat, $lng, $courier->latitude, $courier->longitude);
                $courier->dispatch_score = $this->calculateDispatchScore($courier);
                return $courier;
            })
            ->filter(fn($c) => $c->distance <= $radius)
            ->sortBy('dispatch_score')
            ->take($maxCouriers);
    }

    /**
     * Score de dispatch intelligent (plus bas = meilleur)
     */
    protected function calculateDispatchScore(Courier $courier): float
    {
        $score = $courier->distance * 1.0; // Base: distance
        
        // Malus de note (0-2 points)
        $score += (5 - min($courier->rating ?? 5, 5)) * 0.4;
        
        // Bonus d'expérience (-1 max)
        $score -= min($courier->completed_deliveries, 500) / 500;
        
        // Bonus de fraîcheur du GPS (-0.5 si < 2min)
        if ($courier->last_location_update && $courier->last_location_update->diffInMinutes(now()) < 2) {
            $score -= 0.5;
        }
        
        // Malus si beaucoup de refus récents (+1 max)
        $recentRejections = Cache::get("courier:{$courier->id}:rejections_1h", 0);
        $score += min($recentRejections, 5) * 0.2;
        
        // Bonus si accepte vite habituellement (-0.5 max)
        $avgResponseTime = $courier->avg_response_time_seconds ?? 60;
        if ($avgResponseTime < 20) $score -= 0.5;
        
        return max(0, $score);
    }
}
```

### 1.2 Migration pour DeliveryOffer

```php
<?php
// database/migrations/xxxx_create_delivery_offers_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('delivery_offers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->onDelete('cascade');
            $table->foreignId('accepted_by_courier_id')->nullable()->constrained('couriers');
            $table->enum('status', ['pending', 'accepted', 'expired', 'no_courier_found', 'cancelled']);
            $table->unsignedTinyInteger('broadcast_level')->default(0);
            $table->integer('base_fee')->default(0);
            $table->integer('bonus_fee')->default(0);
            $table->timestamp('expires_at');
            $table->timestamp('accepted_at')->nullable();
            $table->timestamps();
            
            $table->index(['status', 'expires_at']);
        });

        Schema::create('delivery_offer_courier', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delivery_offer_id')->constrained()->onDelete('cascade');
            $table->foreignId('courier_id')->constrained()->onDelete('cascade');
            $table->enum('status', ['notified', 'viewed', 'accepted', 'rejected', 'expired']);
            $table->timestamp('notified_at');
            $table->timestamp('viewed_at')->nullable();
            $table->timestamp('responded_at')->nullable();
            $table->string('rejection_reason')->nullable();
            
            $table->unique(['delivery_offer_id', 'courier_id']);
            $table->index(['courier_id', 'status']);
        });
    }
};
```

---

## 🎯 PHASE 2 : Batching Multi-Commandes (Glovo Stack)

### 2.1 Système de Batching Intelligent

**Concept** : Permettre à un livreur de prendre plusieurs commandes sur un même trajet.

```php
<?php
// app/Services/OrderBatchingService.php

namespace App\Services;

use App\Models\Order;
use App\Models\OrderBatch;
use Illuminate\Support\Collection;

class OrderBatchingService
{
    /**
     * Configuration du batching
     */
    const MAX_ORDERS_PER_BATCH = 4;
    const MAX_DETOUR_PERCENT = 30; // Maximum 30% de détour
    const MAX_DELAY_MINUTES = 15;  // Maximum 15 min de retard acceptable
    
    /**
     * Trouver des commandes combinables avec une commande principale
     */
    public function findBatchableOrders(Order $primaryOrder): Collection
    {
        $pharmacy = $primaryOrder->pharmacy;
        
        // Commandes de la même pharmacie ou pharmacies très proches (< 500m)
        return Order::where('status', 'ready')
            ->where('id', '!=', $primaryOrder->id)
            ->whereNull('delivery_id')
            ->where(function ($query) use ($pharmacy) {
                // Même pharmacie
                $query->where('pharmacy_id', $pharmacy->id)
                    // OU pharmacie dans un rayon de 500m
                    ->orWhereHas('pharmacy', function ($q) use ($pharmacy) {
                        $q->whereRaw("
                            ST_Distance_Sphere(
                                POINT(longitude, latitude),
                                POINT(?, ?)
                            ) < 500
                        ", [$pharmacy->longitude, $pharmacy->latitude]);
                    });
            })
            ->get()
            ->filter(function ($order) use ($primaryOrder) {
                return $this->canBeBatched($primaryOrder, $order);
            })
            ->sortBy(function ($order) use ($primaryOrder) {
                return $this->calculateDetourDistance($primaryOrder, $order);
            })
            ->take(self::MAX_ORDERS_PER_BATCH - 1);
    }

    /**
     * Vérifier si deux commandes peuvent être combinées
     */
    protected function canBeBatched(Order $primary, Order $secondary): bool
    {
        // Calculer le détour
        $directDistance = $this->calculateDistance(
            $primary->pharmacy->latitude, $primary->pharmacy->longitude,
            $primary->delivery_latitude, $primary->delivery_longitude
        );
        
        $batchedDistance = $this->calculateBatchedRouteDistance($primary, $secondary);
        
        $detourPercent = (($batchedDistance - $directDistance) / $directDistance) * 100;
        
        return $detourPercent <= self::MAX_DETOUR_PERCENT;
    }

    /**
     * Calculer la distance optimale pour un batch
     */
    protected function calculateBatchedRouteDistance(Order $primary, Order $secondary): float
    {
        // Utiliser Google Maps Directions API pour le trajet optimal
        $service = app(GoogleMapsService::class);
        
        $waypoints = [
            ['lat' => $primary->pharmacy->latitude, 'lng' => $primary->pharmacy->longitude],
            ['lat' => $primary->delivery_latitude, 'lng' => $primary->delivery_longitude],
            ['lat' => $secondary->delivery_latitude, 'lng' => $secondary->delivery_longitude],
        ];
        
        return $service->getOptimizedRouteDistance($waypoints);
    }

    /**
     * Créer un batch de commandes
     */
    public function createBatch(Order $primaryOrder, Collection $additionalOrders): OrderBatch
    {
        return DB::transaction(function () use ($primaryOrder, $additionalOrders) {
            $allOrders = collect([$primaryOrder])->merge($additionalOrders);
            
            // Calculer le prix total et le bonus de batch
            $totalFee = $allOrders->sum('delivery_fee');
            $batchBonus = $additionalOrders->count() * 150; // +150 FCFA par commande supplémentaire
            
            $batch = OrderBatch::create([
                'status' => 'pending',
                'total_orders' => $allOrders->count(),
                'total_fee' => $totalFee + $batchBonus,
                'batch_bonus' => $batchBonus,
                'optimized_route' => $this->calculateOptimizedRoute($allOrders),
            ]);
            
            // Associer les commandes au batch
            foreach ($allOrders as $index => $order) {
                $batch->orders()->attach($order->id, [
                    'sequence' => $index,
                    'estimated_arrival' => $this->estimateArrival($batch, $order, $index),
                ]);
            }
            
            return $batch;
        });
    }
}
```

### 2.2 Migration Order Batches

```php
<?php
// database/migrations/xxxx_create_order_batches_table.php

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_batches', function (Blueprint $table) {
            $table->id();
            $table->foreignId('courier_id')->nullable()->constrained();
            $table->foreignId('delivery_offer_id')->nullable()->constrained();
            $table->enum('status', ['pending', 'assigned', 'in_progress', 'completed', 'cancelled']);
            $table->unsignedTinyInteger('total_orders');
            $table->integer('total_fee');
            $table->integer('batch_bonus')->default(0);
            $table->json('optimized_route')->nullable();
            $table->timestamps();
        });

        Schema::create('order_batch_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_batch_id')->constrained()->onDelete('cascade');
            $table->foreignId('order_id')->constrained()->onDelete('cascade');
            $table->unsignedTinyInteger('sequence');
            $table->timestamp('estimated_arrival')->nullable();
            $table->timestamp('actual_arrival')->nullable();
            $table->timestamps();
            
            $table->unique(['order_batch_id', 'order_id']);
        });
    }
};
```

---

## 🎯 PHASE 3 : Surge Pricing Dynamique

### 3.1 Service de Pricing Dynamique

```php
<?php
// app/Services/DynamicPricingService.php

namespace App\Services;

use App\Models\DeliveryZone;
use Illuminate\Support\Facades\Cache;

class DynamicPricingService
{
    /**
     * Multipliers de surge
     */
    const SURGE_LEVELS = [
        'none' => 1.0,
        'low' => 1.2,      // +20%
        'medium' => 1.5,   // +50%
        'high' => 1.8,     // +80%
        'extreme' => 2.5,  // +150%
    ];

    /**
     * Calculer le multiplier de surge pour une zone
     */
    public function getSurgeMultiplier(float $latitude, float $longitude): array
    {
        $zoneKey = $this->getZoneKey($latitude, $longitude);
        
        $metrics = Cache::remember("zone_metrics:{$zoneKey}", 60, function () use ($latitude, $longitude) {
            return $this->calculateZoneMetrics($latitude, $longitude);
        });
        
        $surgeLevel = $this->determineSurgeLevel($metrics);
        
        return [
            'multiplier' => self::SURGE_LEVELS[$surgeLevel],
            'level' => $surgeLevel,
            'demand' => $metrics['demand_ratio'],
            'supply' => $metrics['supply_ratio'],
        ];
    }

    /**
     * Calculer les métriques de demande/offre pour une zone
     */
    protected function calculateZoneMetrics(float $lat, float $lng): array
    {
        $radius = 5; // 5km de rayon pour la zone
        
        // Commandes en attente de livreur dans la zone
        $pendingOrders = Order::where('status', 'ready')
            ->whereNull('delivery_id')
            ->whereHas('pharmacy', function ($q) use ($lat, $lng, $radius) {
                $q->nearLocation($lat, $lng, $radius);
            })
            ->count();
        
        // Livreurs disponibles dans la zone
        $availableCouriers = Courier::available()
            ->nearLocation($lat, $lng, $radius)
            ->count();
        
        // Historique de la dernière heure
        $avgPendingLastHour = Cache::get("zone:{$this->getZoneKey($lat, $lng)}:avg_pending", 5);
        $avgCouriersLastHour = Cache::get("zone:{$this->getZoneKey($lat, $lng)}:avg_couriers", 10);
        
        return [
            'pending_orders' => $pendingOrders,
            'available_couriers' => $availableCouriers,
            'demand_ratio' => $avgCouriersLastHour > 0 ? $pendingOrders / $avgCouriersLastHour : 0,
            'supply_ratio' => $avgPendingLastHour > 0 ? $availableCouriers / $avgPendingLastHour : 1,
        ];
    }

    /**
     * Déterminer le niveau de surge basé sur les métriques
     */
    protected function determineSurgeLevel(array $metrics): string
    {
        $demandRatio = $metrics['demand_ratio'];
        $supplyRatio = $metrics['supply_ratio'];
        
        // Ratio commandes/livreurs
        $ratio = $metrics['pending_orders'] / max($metrics['available_couriers'], 1);
        
        if ($ratio >= 5 || $supplyRatio < 0.2) return 'extreme';
        if ($ratio >= 3 || $supplyRatio < 0.4) return 'high';
        if ($ratio >= 2 || $supplyRatio < 0.6) return 'medium';
        if ($ratio >= 1.5 || $supplyRatio < 0.8) return 'low';
        
        return 'none';
    }

    /**
     * Calculer le prix final avec surge
     */
    public function calculateFinalPrice(
        float $basePrice,
        float $pickupLat,
        float $pickupLng
    ): array {
        $surge = $this->getSurgeMultiplier($pickupLat, $pickupLng);
        
        return [
            'base_price' => $basePrice,
            'surge_multiplier' => $surge['multiplier'],
            'surge_level' => $surge['level'],
            'final_price' => round($basePrice * $surge['multiplier']),
            'surge_amount' => round($basePrice * ($surge['multiplier'] - 1)),
        ];
    }

    /**
     * Générer une clé de zone (grille H3 ou simple)
     */
    protected function getZoneKey(float $lat, float $lng): string
    {
        // Grille simple: arrondir à 0.05 degrés (~5km)
        $gridLat = round($lat / 0.05) * 0.05;
        $gridLng = round($lng / 0.05) * 0.05;
        
        return "{$gridLat}_{$gridLng}";
    }
}
```

---

## 🎯 PHASE 4 : ETA Temps Réel & Tracking Avancé

### 4.1 Service ETA Intelligent

```php
<?php
// app/Services/EtaService.php

namespace App\Services;

use App\Models\Delivery;
use App\Models\Courier;
use Illuminate\Support\Facades\Http;

class EtaService
{
    /**
     * Calculer l'ETA en temps réel
     */
    public function calculateRealTimeEta(Delivery $delivery): array
    {
        $courier = $delivery->courier;
        
        // Position actuelle du livreur
        $courierLat = $courier->latitude;
        $courierLng = $courier->longitude;
        
        // Destination selon le statut
        if ($delivery->status === 'accepted' || $delivery->status === 'assigned') {
            // En route vers la pharmacie
            $destLat = $delivery->pickup_latitude;
            $destLng = $delivery->pickup_longitude;
            $phase = 'pickup';
        } else {
            // En route vers le client
            $destLat = $delivery->delivery_latitude;
            $destLng = $delivery->delivery_longitude;
            $phase = 'delivery';
        }
        
        // Appeler Google Maps pour le trajet temps réel
        $route = $this->getGoogleMapsRoute($courierLat, $courierLng, $destLat, $destLng);
        
        // Ajuster avec les facteurs historiques
        $adjustedEta = $this->adjustEtaWithHistory($route['duration'], $delivery);
        
        return [
            'phase' => $phase,
            'eta_seconds' => $adjustedEta,
            'eta_formatted' => $this->formatEta($adjustedEta),
            'distance_meters' => $route['distance'],
            'traffic_delay' => $route['traffic_delay'] ?? 0,
            'confidence' => $this->calculateConfidence($delivery, $route),
            'updated_at' => now()->toIso8601String(),
        ];
    }

    /**
     * Ajuster l'ETA avec l'historique
     */
    protected function adjustEtaWithHistory(int $googleEta, Delivery $delivery): int
    {
        $hour = now()->hour;
        $dayOfWeek = now()->dayOfWeek;
        
        // Facteur historique pour cette heure/jour
        $historicalFactor = Cache::remember(
            "eta_factor:{$hour}:{$dayOfWeek}",
            3600,
            function () use ($hour, $dayOfWeek) {
                return $this->calculateHistoricalFactor($hour, $dayOfWeek);
            }
        );
        
        // Facteur livreur (certains sont plus rapides)
        $courierFactor = $delivery->courier->avg_delivery_speed_factor ?? 1.0;
        
        // Facteur zone (certaines zones sont plus lentes)
        $zoneFactor = $this->getZoneFactor($delivery->delivery_latitude, $delivery->delivery_longitude);
        
        return (int) ($googleEta * $historicalFactor * $courierFactor * $zoneFactor);
    }

    /**
     * Mettre à jour l'ETA et broadcaster aux clients
     */
    public function broadcastEtaUpdate(Delivery $delivery): void
    {
        $eta = $this->calculateRealTimeEta($delivery);
        
        // Sauvegarder
        $delivery->update([
            'estimated_duration' => ceil($eta['eta_seconds'] / 60),
            'metadata' => array_merge($delivery->metadata ?? [], ['last_eta' => $eta]),
        ]);
        
        // Broadcaster via WebSocket/Pusher
        broadcast(new DeliveryEtaUpdated($delivery, $eta))->toOthers();
        
        // Notification si retard significatif
        if ($eta['eta_seconds'] > ($delivery->original_eta_seconds ?? 0) * 1.5) {
            $this->notifyDelay($delivery, $eta);
        }
    }
}
```

### 4.2 Migration pour le Tracking Avancé

```php
<?php
// database/migrations/xxxx_add_advanced_tracking_to_deliveries.php

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('deliveries', function (Blueprint $table) {
            $table->integer('original_eta_seconds')->nullable()->after('estimated_duration');
            $table->integer('current_eta_seconds')->nullable();
            $table->timestamp('last_eta_update')->nullable();
            $table->json('route_polyline')->nullable();
            $table->integer('total_stops')->default(1);
            $table->integer('current_stop')->default(0);
        });

        // Table pour l'historique détaillé des positions
        Schema::create('delivery_tracking_points', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delivery_id')->constrained()->onDelete('cascade');
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->integer('speed')->nullable(); // km/h
            $table->integer('heading')->nullable(); // degrés
            $table->integer('accuracy')->nullable(); // mètres
            $table->timestamp('recorded_at');
            
            $table->index(['delivery_id', 'recorded_at']);
        });
    }
};
```

---

## 🎯 PHASE 5 : Machine Learning & Prédictions

### 5.1 Modèle de Prédiction de Demande

```php
<?php
// app/Services/DemandPredictionService.php

namespace App\Services;

use App\Models\Order;
use Illuminate\Support\Facades\Http;

class DemandPredictionService
{
    /**
     * Prédire la demande pour les prochaines heures
     */
    public function predictDemand(string $zoneId, int $hoursAhead = 6): array
    {
        // Features pour le modèle ML
        $features = $this->buildPredictionFeatures($zoneId);
        
        // Appeler le service ML (Python/FastAPI)
        $response = Http::post(config('services.ml.url') . '/predict/demand', [
            'zone_id' => $zoneId,
            'features' => $features,
            'hours_ahead' => $hoursAhead,
        ]);
        
        if ($response->successful()) {
            return $response->json();
        }
        
        // Fallback: prédiction simple basée sur l'historique
        return $this->fallbackPrediction($zoneId, $hoursAhead);
    }

    /**
     * Construire les features pour la prédiction
     */
    protected function buildPredictionFeatures(string $zoneId): array
    {
        $now = now();
        
        return [
            'hour' => $now->hour,
            'day_of_week' => $now->dayOfWeek,
            'is_weekend' => $now->isWeekend(),
            'is_holiday' => $this->isHoliday($now),
            'weather_code' => $this->getWeatherCode($zoneId),
            'temperature' => $this->getTemperature($zoneId),
            'rain_probability' => $this->getRainProbability($zoneId),
            'last_hour_orders' => $this->getOrderCount($zoneId, 1),
            'last_3h_orders' => $this->getOrderCount($zoneId, 3),
            'same_time_last_week' => $this->getHistoricalOrderCount($zoneId, 7, $now->hour),
            'active_promotions' => $this->getActivePromotions($zoneId),
            'nearby_events' => $this->getNearbyEvents($zoneId),
        ];
    }

    /**
     * Recommander le nombre optimal de livreurs
     */
    public function recommendCourierCount(string $zoneId): array
    {
        $prediction = $this->predictDemand($zoneId, 2);
        
        $hourlyPredictions = collect($prediction['hourly'])
            ->map(function ($hour) {
                // 1 livreur pour ~3-4 commandes/heure
                $optimalCouriers = ceil($hour['predicted_orders'] / 3.5);
                
                return [
                    'hour' => $hour['hour'],
                    'predicted_orders' => $hour['predicted_orders'],
                    'optimal_couriers' => $optimalCouriers,
                    'min_couriers' => max(2, $optimalCouriers - 2),
                    'max_couriers' => $optimalCouriers + 3,
                ];
            });
        
        return [
            'zone_id' => $zoneId,
            'recommendations' => $hourlyPredictions,
            'generated_at' => now()->toIso8601String(),
        ];
    }
}
```

### 5.2 Score de Fiabilité Livreur (ML-based)

```php
<?php
// app/Services/CourierReliabilityService.php

namespace App\Services;

class CourierReliabilityService
{
    /**
     * Calculer le score de fiabilité d'un livreur
     */
    public function calculateReliabilityScore(Courier $courier): array
    {
        $metrics = $this->getCourierMetrics($courier);
        
        // Pondérations
        $weights = [
            'acceptance_rate' => 0.25,
            'completion_rate' => 0.25,
            'on_time_rate' => 0.20,
            'customer_rating' => 0.15,
            'response_time' => 0.10,
            'availability_consistency' => 0.05,
        ];
        
        $score = 0;
        foreach ($weights as $metric => $weight) {
            $normalizedValue = $this->normalizeMetric($metric, $metrics[$metric]);
            $score += $normalizedValue * $weight;
        }
        
        return [
            'score' => round($score * 100, 1),
            'tier' => $this->getTier($score),
            'metrics' => $metrics,
            'improvements' => $this->getSuggestions($metrics),
        ];
    }

    /**
     * Obtenir les métriques du livreur
     */
    protected function getCourierMetrics(Courier $courier): array
    {
        $thirtyDaysAgo = now()->subDays(30);
        
        $deliveries = $courier->deliveries()
            ->where('created_at', '>=', $thirtyDaysAgo)
            ->get();
        
        $offers = DeliveryOffer::whereHas('targetedCouriers', fn($q) => $q->where('courier_id', $courier->id))
            ->where('created_at', '>=', $thirtyDaysAgo)
            ->get();
        
        $totalOffers = $offers->count();
        $acceptedOffers = $offers->where('accepted_by_courier_id', $courier->id)->count();
        
        $completedDeliveries = $deliveries->where('status', 'delivered')->count();
        $totalDeliveries = $deliveries->count();
        
        $onTimeDeliveries = $deliveries
            ->where('status', 'delivered')
            ->filter(fn($d) => $d->delivered_at <= $d->estimated_delivery_at)
            ->count();
        
        return [
            'acceptance_rate' => $totalOffers > 0 ? $acceptedOffers / $totalOffers : 0,
            'completion_rate' => $totalDeliveries > 0 ? $completedDeliveries / $totalDeliveries : 0,
            'on_time_rate' => $completedDeliveries > 0 ? $onTimeDeliveries / $completedDeliveries : 0,
            'customer_rating' => $courier->rating ?? 5.0,
            'response_time' => $courier->avg_response_time_seconds ?? 30,
            'availability_consistency' => $this->calculateAvailabilityConsistency($courier),
        ];
    }

    /**
     * Déterminer le tier du livreur
     */
    protected function getTier(float $score): string
    {
        if ($score >= 0.95) return 'champion';
        if ($score >= 0.85) return 'gold';
        if ($score >= 0.70) return 'silver';
        if ($score >= 0.50) return 'bronze';
        return 'newcomer';
    }
}
```

---

## 🎯 PHASE 6 : Système de Shifts & Planning

### 6.1 Service de Gestion des Shifts

```php
<?php
// app/Services/ShiftManagementService.php

namespace App\Services;

use App\Models\CourierShift;
use App\Models\Courier;

class ShiftManagementService
{
    /**
     * Types de shifts disponibles
     */
    const SHIFT_TYPES = [
        'morning' => ['start' => '06:00', 'end' => '12:00', 'bonus' => 0],
        'lunch' => ['start' => '11:00', 'end' => '15:00', 'bonus' => 100], // Peak
        'afternoon' => ['start' => '14:00', 'end' => '19:00', 'bonus' => 0],
        'dinner' => ['start' => '18:00', 'end' => '23:00', 'bonus' => 150], // Peak
        'night' => ['start' => '22:00', 'end' => '02:00', 'bonus' => 200], // Late bonus
    ];

    /**
     * Ouvrir des slots de shift pour une zone
     */
    public function openShiftSlots(string $zoneId, Carbon $date, array $shiftTypes): Collection
    {
        // Prédire la demande pour déterminer les capacités
        $demand = app(DemandPredictionService::class)->predictDemand($zoneId, 24);
        
        $slots = collect();
        
        foreach ($shiftTypes as $type) {
            $config = self::SHIFT_TYPES[$type];
            
            // Capacité basée sur la prédiction
            $capacity = $this->calculateShiftCapacity($demand, $config);
            
            $slot = CourierShiftSlot::create([
                'zone_id' => $zoneId,
                'date' => $date,
                'shift_type' => $type,
                'start_time' => $config['start'],
                'end_time' => $config['end'],
                'capacity' => $capacity,
                'booked_count' => 0,
                'bonus_amount' => $config['bonus'],
                'status' => 'open',
            ]);
            
            $slots->push($slot);
        }
        
        // Notifier les livreurs éligibles
        $this->notifyEligibleCouriers($zoneId, $slots);
        
        return $slots;
    }

    /**
     * Réserver un shift
     */
    public function bookShift(Courier $courier, CourierShiftSlot $slot): ?CourierShift
    {
        return DB::transaction(function () use ($courier, $slot) {
            // Vérifier la capacité
            if ($slot->booked_count >= $slot->capacity) {
                return null;
            }
            
            // Vérifier que le livreur n'a pas déjà un shift chevauchant
            if ($this->hasOverlappingShift($courier, $slot)) {
                return null;
            }
            
            // Vérifier le score de fiabilité minimum
            $reliability = app(CourierReliabilityService::class)
                ->calculateReliabilityScore($courier);
            
            if ($reliability['score'] < 50 && $slot->bonus_amount > 100) {
                return null; // Bonus shifts réservés aux livreurs fiables
            }
            
            // Créer le shift
            $shift = CourierShift::create([
                'courier_id' => $courier->id,
                'slot_id' => $slot->id,
                'zone_id' => $slot->zone_id,
                'date' => $slot->date,
                'start_time' => $slot->start_time,
                'end_time' => $slot->end_time,
                'guaranteed_bonus' => $slot->bonus_amount,
                'status' => 'confirmed',
            ]);
            
            // Incrémenter le compteur
            $slot->increment('booked_count');
            
            return $shift;
        });
    }

    /**
     * Vérifier le respect des shifts
     */
    public function checkShiftCompliance(): void
    {
        $activeShifts = CourierShift::where('status', 'in_progress')
            ->where('start_time', '<=', now())
            ->get();
        
        foreach ($activeShifts as $shift) {
            $courier = $shift->courier;
            
            // Vérifier si le livreur est bien actif
            if ($courier->status !== 'available' && $courier->status !== 'busy') {
                $this->flagShiftViolation($shift, 'not_active');
            }
            
            // Vérifier si le GPS est à jour
            if ($courier->last_location_update?->diffInMinutes(now()) > 10) {
                $this->flagShiftViolation($shift, 'gps_stale');
            }
            
            // Vérifier la zone
            if (!$this->isCourierInZone($courier, $shift->zone_id)) {
                $this->flagShiftViolation($shift, 'out_of_zone');
            }
        }
    }
}
```

### 6.2 Migrations pour les Shifts

```php
<?php
// database/migrations/xxxx_create_courier_shifts_tables.php

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('courier_shift_slots', function (Blueprint $table) {
            $table->id();
            $table->string('zone_id');
            $table->date('date');
            $table->string('shift_type');
            $table->time('start_time');
            $table->time('end_time');
            $table->unsignedInteger('capacity');
            $table->unsignedInteger('booked_count')->default(0);
            $table->integer('bonus_amount')->default(0);
            $table->enum('status', ['open', 'full', 'closed']);
            $table->timestamps();
            
            $table->index(['zone_id', 'date', 'status']);
        });

        Schema::create('courier_shifts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('courier_id')->constrained();
            $table->foreignId('slot_id')->constrained('courier_shift_slots');
            $table->string('zone_id');
            $table->date('date');
            $table->time('start_time');
            $table->time('end_time');
            $table->time('actual_start_time')->nullable();
            $table->time('actual_end_time')->nullable();
            $table->integer('guaranteed_bonus')->default(0);
            $table->integer('earned_bonus')->default(0);
            $table->enum('status', ['confirmed', 'in_progress', 'completed', 'cancelled', 'no_show']);
            $table->integer('deliveries_completed')->default(0);
            $table->integer('violations_count')->default(0);
            $table->json('violations')->nullable();
            $table->timestamps();
            
            $table->index(['courier_id', 'date']);
            $table->index(['zone_id', 'date', 'status']);
        });
    }
};
```

---

## 🎯 PHASE 7 : Analytics & Heatmaps

### 7.1 Service de Heatmap

```php
<?php
// app/Services/HeatmapService.php

namespace App\Services;

class HeatmapService
{
    /**
     * Générer les données de heatmap pour le dashboard
     */
    public function generateDemandHeatmap(): array
    {
        $cells = [];
        
        // Grille H3 ou simple lat/lng
        $zones = $this->getActiveZones();
        
        foreach ($zones as $zone) {
            $metrics = $this->getZoneMetrics($zone);
            
            $cells[] = [
                'zone_id' => $zone->id,
                'center' => ['lat' => $zone->center_lat, 'lng' => $zone->center_lng],
                'boundary' => $zone->boundary,
                'heat_value' => $this->calculateHeatValue($metrics),
                'color' => $this->getHeatColor($metrics),
                'metrics' => [
                    'pending_orders' => $metrics['pending_orders'],
                    'available_couriers' => $metrics['available_couriers'],
                    'surge_level' => $metrics['surge_level'],
                    'avg_wait_time' => $metrics['avg_wait_time'],
                ],
            ];
        }
        
        return [
            'cells' => $cells,
            'generated_at' => now()->toIso8601String(),
            'legend' => $this->getHeatmapLegend(),
        ];
    }

    /**
     * Obtenir les opportunités de gains pour les livreurs
     */
    public function getCourierOpportunities(Courier $courier): array
    {
        $currentLat = $courier->latitude;
        $currentLng = $courier->longitude;
        
        $opportunities = collect($this->generateDemandHeatmap()['cells'])
            ->map(function ($cell) use ($currentLat, $currentLng) {
                $distance = $this->calculateDistance(
                    $currentLat, $currentLng,
                    $cell['center']['lat'], $cell['center']['lng']
                );
                
                $potentialEarnings = $this->estimatePotentialEarnings($cell);
                
                return [
                    'zone_id' => $cell['zone_id'],
                    'distance_km' => round($distance, 1),
                    'potential_earnings' => $potentialEarnings,
                    'surge_level' => $cell['metrics']['surge_level'],
                    'recommendation' => $this->generateRecommendation($distance, $potentialEarnings),
                ];
            })
            ->filter(fn($o) => $o['distance_km'] <= 15) // Max 15km
            ->sortByDesc('potential_earnings')
            ->take(5)
            ->values();
        
        return [
            'opportunities' => $opportunities,
            'best_action' => $opportunities->first()['recommendation'] ?? 'stay_put',
        ];
    }
}
```

---

## 🎯 PHASE 8 : Gamification Avancée

### 8.1 Système de Quêtes & Challenges

```php
<?php
// app/Services/GamificationService.php

namespace App\Services;

class GamificationService
{
    /**
     * Types de challenges
     */
    const CHALLENGE_TYPES = [
        'daily_streak' => [
            'description' => 'Faire X livraisons aujourd\'hui',
            'tiers' => [
                ['target' => 5, 'reward' => 250],
                ['target' => 10, 'reward' => 600],
                ['target' => 15, 'reward' => 1200],
                ['target' => 20, 'reward' => 2000],
            ],
        ],
        'peak_hour_hero' => [
            'description' => 'Livrer pendant les heures de pointe',
            'tiers' => [
                ['target' => 3, 'reward' => 300],
                ['target' => 7, 'reward' => 800],
            ],
        ],
        'perfect_rating' => [
            'description' => 'Maintenir 5 étoiles sur X livraisons',
            'tiers' => [
                ['target' => 10, 'reward' => 500],
                ['target' => 25, 'reward' => 1500],
            ],
        ],
        'speed_demon' => [
            'description' => 'Livrer X commandes avant l\'ETA',
            'tiers' => [
                ['target' => 5, 'reward' => 400],
                ['target' => 15, 'reward' => 1000],
            ],
        ],
        'zone_explorer' => [
            'description' => 'Livrer dans X zones différentes cette semaine',
            'tiers' => [
                ['target' => 3, 'reward' => 300],
                ['target' => 5, 'reward' => 700],
            ],
        ],
    ];

    /**
     * Mettre à jour les progressions des challenges
     */
    public function updateChallengeProgress(Delivery $delivery): void
    {
        $courier = $delivery->courier;
        
        // Daily streak
        $this->incrementChallenge($courier, 'daily_streak');
        
        // Peak hour
        if ($this->isPeakHour()) {
            $this->incrementChallenge($courier, 'peak_hour_hero');
        }
        
        // Perfect rating
        if ($delivery->customer_rating >= 5) {
            $this->incrementChallenge($courier, 'perfect_rating');
        }
        
        // Speed demon
        if ($delivery->delivered_at < $delivery->estimated_delivered_at) {
            $this->incrementChallenge($courier, 'speed_demon');
        }
        
        // Zone explorer
        $this->trackZoneVisit($courier, $delivery);
    }

    /**
     * Obtenir le tableau de bord gamification
     */
    public function getGamificationDashboard(Courier $courier): array
    {
        return [
            'level' => $this->calculateLevel($courier),
            'xp' => [
                'current' => $courier->total_xp,
                'next_level' => $this->xpForNextLevel($courier),
                'progress_percent' => $this->levelProgress($courier),
            ],
            'tier' => $this->getTierInfo($courier),
            'active_challenges' => $this->getActiveChallenges($courier),
            'completed_today' => $this->getCompletedToday($courier),
            'weekly_rank' => $this->getWeeklyRank($courier),
            'streak_days' => $courier->current_streak_days,
            'badges' => $this->getUnlockedBadges($courier),
            'available_rewards' => $this->getClaimableRewards($courier),
        ];
    }

    /**
     * Système de niveaux
     */
    protected function calculateLevel(Courier $courier): int
    {
        $xp = $courier->total_xp;
        
        // Progression logarithmique
        // Niveau 1: 0 XP
        // Niveau 2: 100 XP
        // Niveau 3: 300 XP
        // Niveau 10: 10,000 XP
        // etc.
        
        return (int) floor(sqrt($xp / 50)) + 1;
    }
}
```

### 8.2 Migration Gamification

```php
<?php
// database/migrations/xxxx_add_gamification_to_couriers.php

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('couriers', function (Blueprint $table) {
            $table->unsignedInteger('total_xp')->default(0);
            $table->unsignedInteger('current_streak_days')->default(0);
            $table->date('last_active_date')->nullable();
            $table->json('badges')->nullable();
            $table->string('tier')->default('bronze');
        });

        Schema::create('courier_challenge_progress', function (Blueprint $table) {
            $table->id();
            $table->foreignId('courier_id')->constrained();
            $table->string('challenge_type');
            $table->date('period_date'); // Pour daily/weekly
            $table->unsignedInteger('current_progress')->default(0);
            $table->unsignedTinyInteger('tier_reached')->default(0);
            $table->integer('rewards_earned')->default(0);
            $table->timestamps();
            
            $table->unique(['courier_id', 'challenge_type', 'period_date']);
        });
    }
};
```

---

## 📋 Roadmap d'Implémentation

### Sprint 1 (2 semaines) - Fondations
- [ ] Migration des tables: `delivery_offers`, `delivery_offer_courier`
- [ ] `BroadcastDispatchService` avec 4 niveaux
- [ ] Job `ExpireDeliveryOffer` pour l'escalade
- [ ] Tests unitaires et d'intégration
- [ ] Interface admin pour suivi des broadcasts

### Sprint 2 (2 semaines) - Batching
- [ ] Migration `order_batches`, `order_batch_items`
- [ ] `OrderBatchingService` avec détection auto
- [ ] Intégration Google Maps pour routes optimisées
- [ ] UI mobile pour multi-commandes

### Sprint 3 (2 semaines) - Pricing Dynamique
- [ ] `DynamicPricingService` avec surge
- [ ] Cache Redis pour métriques temps réel
- [ ] Dashboard admin pour monitoring surge
- [ ] Règles métier configurables

### Sprint 4 (2 semaines) - ETA & Tracking
- [ ] `EtaService` avec Google Maps Directions
- [ ] WebSockets pour mise à jour temps réel
- [ ] Tracking avancé avec points détaillés
- [ ] Notifications proactives de retard

### Sprint 5 (2 semaines) - ML & Prédiction
- [ ] Service Python/FastAPI pour ML
- [ ] `DemandPredictionService` avec features
- [ ] `CourierReliabilityService` avec scoring
- [ ] Recommandations auto de capacité

### Sprint 6 (2 semaines) - Shifts & Planning
- [ ] Migrations shifts
- [ ] `ShiftManagementService`
- [ ] UI de réservation dans l'app livreur
- [ ] Dashboard admin pour gestion shifts

### Sprint 7 (2 semaines) - Analytics & Gamification
- [ ] `HeatmapService` pour visualisation
- [ ] `GamificationService` complet
- [ ] Leaderboards et badges
- [ ] Dashboard analytics avancé

---

## 📊 KPIs à Suivre

| Métrique | Actuel | Objectif Glovo |
|----------|--------|----------------|
| Temps moyen d'assignation | ? min | < 2 min |
| Taux d'acceptation | ? % | > 85% |
| Taux de livraison à temps | ? % | > 90% |
| NPS Livreurs | ? | > 40 |
| Taux de batch | 0% | > 20% |
| Précision ETA | ? | ±3 min |

---

## 💰 Estimation des Coûts

### Infrastructure
- **Redis Cache** : ~$15/mois (pour métriques temps réel)
- **Google Maps API** : ~$50-200/mois (selon volume)
- **WebSockets (Pusher/Ably)** : ~$30/mois
- **ML Service (si hébergé)** : ~$50/mois

### Développement
- **8 sprints × 2 semaines** = ~4 mois
- **1-2 développeurs backend** 
- **1 développeur mobile**

---

## 🔗 Ressources

- [Uber Engineering Blog - Dispatch](https://eng.uber.com/)
- [Glovo Tech Blog](https://medium.com/glovo-engineering)
- [Google OR-Tools](https://developers.google.com/optimization) (pour optimisation de routes)
- [H3 Geo-indexing](https://eng.uber.com/h3/) (pour les zones/heatmaps)

---

*Document généré par le Senior Fullstack Skill - DR-PHARMA Project*
