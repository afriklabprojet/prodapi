<?php

namespace App\Http\Controllers\Api\Courier;

use App\Http\Controllers\Controller;
use App\Models\Courier;
use App\Models\Delivery;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DriverDashboardController extends Controller
{
    /**
     * GET /courier/orders/nearby?lat=&lng=&radius_km=3
     *
     * Returns individual unassigned orders within radius with lat/lng for map markers.
     */
    public function nearbyOrders(Request $request): JsonResponse
    {
        $courier = $request->user()->courier;
        if (!$courier) {
            return response()->json(['success' => false, 'message' => 'Profil coursier non trouvé'], 403);
        }

        $lat = (float) ($request->query('lat') ?: $courier->latitude);
        $lng = (float) ($request->query('lng') ?: $courier->longitude);
        $radiusKm = (float) $request->query('radius_km', 3);

        if (!$lat || !$lng) {
            return response()->json([
                'success' => true,
                'data' => ['orders' => [], 'total' => 0, 'radius_km' => $radiusKm],
            ]);
        }

        $orders = DB::table('orders')
            ->join('pharmacies', 'orders.pharmacy_id', '=', 'pharmacies.id')
            ->leftJoin('duty_zones', 'pharmacies.duty_zone_id', '=', 'duty_zones.id')
            ->where('orders.status', 'ready')
            ->whereNull('orders.delivery_id')
            ->whereNotNull('pharmacies.latitude')
            ->whereNotNull('pharmacies.longitude')
            ->select(
                'orders.id',
                'orders.reference',
                'orders.delivery_fee',
                'orders.total_amount',
                'orders.created_at',
                'pharmacies.name as pharmacy_name',
                'pharmacies.latitude as pickup_lat',
                'pharmacies.longitude as pickup_lng',
                'pharmacies.city',
                'orders.delivery_latitude as dropoff_lat',
                'orders.delivery_longitude as dropoff_lng',
                'orders.delivery_address',
                'orders.delivery_city',
                'duty_zones.name as zone_name',
            )
            ->get()
            ->map(function ($o) use ($lat, $lng) {
                $o->distance_km = round($this->haversine($lat, $lng, (float) $o->pickup_lat, (float) $o->pickup_lng), 2);
                $o->estimated_minutes = (int) ceil($o->distance_km * 2.5);
                return $o;
            })
            ->filter(fn ($o) => $o->distance_km <= $radiusKm)
            ->sortBy('distance_km')
            ->take(20)
            ->values()
            ->map(fn ($o) => [
                'id' => $o->id,
                'reference' => $o->reference,
                'delivery_fee' => (int) ($o->delivery_fee ?? 0),
                'total_amount' => (int) ($o->total_amount ?? 0),
                'pharmacy_name' => $o->pharmacy_name,
                'pickup_lat' => round((float) $o->pickup_lat, 6),
                'pickup_lng' => round((float) $o->pickup_lng, 6),
                'dropoff_lat' => $o->dropoff_lat ? round((float) $o->dropoff_lat, 6) : null,
                'dropoff_lng' => $o->dropoff_lng ? round((float) $o->dropoff_lng, 6) : null,
                'delivery_address' => $o->delivery_address,
                'zone_name' => $o->zone_name ?: $o->city ?: 'À proximité',
                'distance_km' => $o->distance_km,
                'estimated_minutes' => $o->estimated_minutes,
                'created_at' => $o->created_at,
            ]);

        return response()->json([
            'success' => true,
            'data' => [
                'orders' => $orders->toArray(),
                'total' => $orders->count(),
                'radius_km' => $radiusKm,
                'courier_lat' => $lat,
                'courier_lng' => $lng,
            ],
        ]);
    }

    /**
     * GET /courier/smart-guidance
     *
     * Returns intelligent recommendation for the driver:
     * zone, distance, estimated_time, earnings_range, bonus, reasoning.
     */
    public function smartGuidance(Request $request): JsonResponse
    {
        $courier = $request->user()->courier;
        if (!$courier) {
            return response()->json(['success' => false, 'message' => 'Profil coursier non trouvé'], 403);
        }

        $lat = (float) ($request->query('lat') ?: $courier->latitude);
        $lng = (float) ($request->query('lng') ?: $courier->longitude);

        if (!$lat || !$lng) {
            return response()->json([
                'success' => true,
                'data' => ['recommendation' => null, 'reason' => 'no_location'],
            ]);
        }

        // Fetch unassigned ready orders
        $orders = DB::table('orders')
            ->join('pharmacies', 'orders.pharmacy_id', '=', 'pharmacies.id')
            ->leftJoin('duty_zones', 'pharmacies.duty_zone_id', '=', 'duty_zones.id')
            ->where('orders.status', 'ready')
            ->whereNull('orders.delivery_id')
            ->whereNotNull('pharmacies.latitude')
            ->whereNotNull('pharmacies.longitude')
            ->select(
                'orders.delivery_fee',
                'pharmacies.latitude',
                'pharmacies.longitude',
                'pharmacies.city',
                'duty_zones.name as zone_name',
            )
            ->get()
            ->map(function ($o) use ($lat, $lng) {
                $o->distance_km = $this->haversine($lat, $lng, (float) $o->latitude, (float) $o->longitude);
                return $o;
            })
            ->filter(fn ($o) => $o->distance_km <= 15)
            ->sortBy('distance_km');

        if ($orders->isEmpty()) {
            return response()->json([
                'success' => true,
                'data' => [
                    'recommendation' => null,
                    'reason' => 'no_orders',
                    'message' => 'Aucune commande disponible pour le moment',
                ],
            ]);
        }

        // Group by zone
        $zones = $orders->groupBy(fn ($o) => $o->zone_name ?: $o->city ?: 'À proximité');
        
        // Score each zone: density * proximity * avg_fee
        $scoredZones = $zones->map(function ($zoneOrders, $zoneName) {
            $count = $zoneOrders->count();
            $avgDist = $zoneOrders->avg('distance_km');
            $fees = $zoneOrders->pluck('delivery_fee')->filter()->map(fn ($f) => (int) $f);
            $avgFee = $fees->isNotEmpty() ? (int) $fees->avg() : 1000;
            $minFee = $fees->isNotEmpty() ? (int) $fees->min() : 800;
            $maxFee = $fees->isNotEmpty() ? (int) $fees->max() : 2000;
            
            // Score: more orders closer = better, higher fees = better
            $proximityScore = max(1, 10 - $avgDist); // 0-10, closer is higher
            $densityScore = min($count * 2, 20);      // cap at 20
            $feeScore = $avgFee / 500;                 // normalize
            $score = $proximityScore * $densityScore * $feeScore;
            
            $avgLat = $zoneOrders->avg('latitude');
            $avgLng = $zoneOrders->avg('longitude');
            $minDist = round($zoneOrders->min('distance_km'), 1);
            
            return [
                'zone' => $zoneName,
                'lat' => round($avgLat, 5),
                'lng' => round($avgLng, 5),
                'distance' => $minDist,
                'estimated_time' => (int) ceil($minDist * 2.5),
                'orders_count' => $count,
                'earnings_range' => [$minFee, $maxFee],
                'avg_fee' => $avgFee,
                'score' => round($score, 1),
            ];
        })->sortByDesc('score')->values();

        $best = $scoredZones->first();

        // Calculate bonus based on demand
        $bonus = 0;
        $reason = '';
        if ($best['orders_count'] >= 5) {
            $bonus = 500;
            $reason = 'rush_zone';
        } elseif ($best['orders_count'] >= 3) {
            $bonus = 200;
            $reason = 'high_demand';
        } elseif ($best['distance'] <= 1.5) {
            $bonus = 100;
            $reason = 'proximity';
        }

        // Courier's streak & tier bonus
        $tierBonus = 0;
        $tier = $courier->tier ?? 'bronze';
        $tierBonusPercent = match ($tier) {
            'silver' => 5,
            'gold' => 10,
            'platinum' => 15,
            default => 0,
        };
        if ($tierBonusPercent > 0) {
            $tierBonus = (int) round($best['avg_fee'] * $tierBonusPercent / 100);
        }

        // Build recommendation message
        $message = $this->buildGuidanceMessage($best, $bonus, $reason, $courier);

        return response()->json([
            'success' => true,
            'data' => [
                'recommendation' => [
                    'zone' => $best['zone'],
                    'lat' => $best['lat'],
                    'lng' => $best['lng'],
                    'distance' => $best['distance'],
                    'estimated_time' => $best['estimated_time'],
                    'orders_count' => $best['orders_count'],
                    'earnings_range' => $best['earnings_range'],
                    'avg_fee' => $best['avg_fee'],
                    'bonus' => $bonus + $tierBonus,
                    'tier_bonus' => $tierBonus,
                    'reason' => $reason,
                    'message' => $message,
                ],
                'alternatives' => $scoredZones->slice(1, 2)->values()->toArray(),
                'total_available' => $orders->count(),
            ],
        ]);
    }

    /**
     * GET /courier/dashboard/pressure
     *
     * Returns realtime pressure data:
     * - nearby available orders count
     * - nearby active drivers count
     * - demand/supply ratio
     */
    public function pressure(Request $request): JsonResponse
    {
        $courier = $request->user()->courier;
        if (!$courier) {
            return response()->json(['success' => false, 'message' => 'Profil coursier non trouvé'], 403);
        }

        $lat = (float) ($request->query('lat') ?: $courier->latitude);
        $lng = (float) ($request->query('lng') ?: $courier->longitude);
        $radiusKm = (float) $request->query('radius_km', 5);

        if (!$lat || !$lng) {
            return response()->json([
                'success' => true,
                'data' => [
                    'nearby_orders' => 0,
                    'nearby_drivers' => 0,
                    'demand_ratio' => 0,
                    'pressure_level' => 'unknown',
                ],
            ]);
        }

        // Count unassigned orders nearby
        $nearbyOrders = DB::table('orders')
            ->join('pharmacies', 'orders.pharmacy_id', '=', 'pharmacies.id')
            ->where('orders.status', 'ready')
            ->whereNull('orders.delivery_id')
            ->whereNotNull('pharmacies.latitude')
            ->whereNotNull('pharmacies.longitude')
            ->get()
            ->filter(function ($o) use ($lat, $lng, $radiusKm) {
                return $this->haversine($lat, $lng, (float) $o->latitude, (float) $o->longitude) <= $radiusKm;
            })
            ->count();

        // Count active couriers nearby (online, not on delivery)
        $nearbyDrivers = DB::table('couriers')
            ->where('status', 'available')
            ->where('id', '!=', $courier->id)
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->get()
            ->filter(function ($c) use ($lat, $lng, $radiusKm) {
                return $this->haversine($lat, $lng, (float) $c->latitude, (float) $c->longitude) <= $radiusKm;
            })
            ->count();

        // Demand ratio: orders per driver
        $demandRatio = $nearbyDrivers > 0
            ? round($nearbyOrders / $nearbyDrivers, 1)
            : ($nearbyOrders > 0 ? 99.0 : 0);

        // Pressure level
        $pressureLevel = 'low';
        if ($demandRatio >= 3 || ($nearbyOrders >= 5 && $nearbyDrivers <= 1)) {
            $pressureLevel = 'critical';
        } elseif ($demandRatio >= 1.5 || $nearbyOrders >= 3) {
            $pressureLevel = 'high';
        } elseif ($demandRatio >= 0.5) {
            $pressureLevel = 'medium';
        }

        // Urgency message
        $urgencyMessage = match ($pressureLevel) {
            'critical' => "🚨 {$nearbyOrders} commandes, seulement {$nearbyDrivers} livreurs — opportunité rare !",
            'high' => "⚡ Forte demande : {$nearbyOrders} commandes à moins de {$radiusKm} km",
            'medium' => "📦 {$nearbyOrders} commandes disponibles autour de vous",
            default => $nearbyOrders > 0
                ? "📦 {$nearbyOrders} commande(s) disponible(s)"
                : "🔍 Aucune commande à proximité pour le moment",
        };

        return response()->json([
            'success' => true,
            'data' => [
                'nearby_orders' => $nearbyOrders,
                'nearby_drivers' => $nearbyDrivers,
                'demand_ratio' => $demandRatio,
                'pressure_level' => $pressureLevel,
                'urgency_message' => $urgencyMessage,
                'radius_km' => $radiusKm,
            ],
        ]);
    }

    /**
     * GET /courier/dashboard/gamification-summary
     *
     * Quick gamification snapshot for the HUD:
     * daily goal progress, streak, next reward.
     */
    public function gamificationSummary(Request $request): JsonResponse
    {
        $courier = $request->user()->courier;
        if (!$courier) {
            return response()->json(['success' => false, 'message' => 'Profil coursier non trouvé'], 403);
        }

        $today = Carbon::today();

        // Today's deliveries
        $todayDeliveries = Delivery::where('courier_id', $courier->id)
            ->where('status', 'delivered')
            ->whereDate('created_at', $today)
            ->count();

        // Daily goals (tiered)
        $dailyGoals = [
            ['target' => 5, 'reward' => 500, 'label' => 'Starter', 'emoji' => '🎯'],
            ['target' => 10, 'reward' => 1500, 'label' => 'Performer', 'emoji' => '🔥'],
            ['target' => 15, 'reward' => 3000, 'label' => 'Champion', 'emoji' => '🏆'],
            ['target' => 25, 'reward' => 5000, 'label' => 'Légende', 'emoji' => '💎'],
        ];

        $currentGoal = null;
        $completedGoals = [];
        foreach ($dailyGoals as $goal) {
            if ($todayDeliveries >= $goal['target']) {
                $completedGoals[] = array_merge($goal, ['completed' => true]);
            } else {
                if ($currentGoal === null) {
                    $currentGoal = array_merge($goal, [
                        'progress' => $todayDeliveries,
                        'remaining' => $goal['target'] - $todayDeliveries,
                        'progress_percent' => round(($todayDeliveries / $goal['target']) * 100, 1),
                    ]);
                }
            }
        }

        // Streak
        $streakDays = $courier->current_streak_days ?? 0;
        $streakRewards = [
            ['days' => 3, 'bonus' => 500, 'label' => '3 jours 🔥'],
            ['days' => 7, 'bonus' => 2000, 'label' => '1 semaine 🔥'],
            ['days' => 14, 'bonus' => 5000, 'label' => '2 semaines 💪'],
            ['days' => 30, 'bonus' => 15000, 'label' => '1 mois 🏆'],
        ];

        $nextStreakReward = null;
        foreach ($streakRewards as $sr) {
            if ($streakDays < $sr['days']) {
                $nextStreakReward = array_merge($sr, [
                    'remaining_days' => $sr['days'] - $streakDays,
                ]);
                break;
            }
        }

        // Level (quick calc)
        $completedTotal = $courier->deliveries()->where('status', 'delivered')->count();
        $totalXP = $completedTotal * 10;
        $level = 1;
        $levels = [1 => 0, 5 => 500, 10 => 1500, 15 => 3000, 20 => 5000, 30 => 10000, 40 => 20000, 50 => 50000];
        foreach (array_reverse($levels, true) as $l => $xp) {
            if ($totalXP >= $xp) { $level = $l; break; }
        }

        return response()->json([
            'success' => true,
            'data' => [
                'daily_goal' => $currentGoal,
                'completed_goals' => $completedGoals,
                'all_goals' => $dailyGoals,
                'deliveries_today' => $todayDeliveries,
                'streak' => [
                    'days' => $streakDays,
                    'next_reward' => $nextStreakReward,
                    'is_active' => $streakDays > 0,
                ],
                'level' => $level,
                'total_xp' => $totalXP,
                'tier' => $courier->tier ?? 'bronze',
            ],
        ]);
    }

    // ── Helpers ──

    private function buildGuidanceMessage(array $zone, int $bonus, string $reason, $courier): string
    {
        $parts = [];
        
        if ($reason === 'rush_zone') {
            $parts[] = "⚡ Rush zone {$zone['zone']} — {$zone['orders_count']} commandes !";
        } elseif ($reason === 'high_demand') {
            $parts[] = "🔥 Forte demande à {$zone['zone']}";
        } elseif ($zone['distance'] <= 1.0) {
            $parts[] = "📍 Commandes juste à côté — {$zone['zone']}";
        } else {
            $parts[] = "🎯 Meilleure zone : {$zone['zone']}";
        }

        if ($bonus > 0) {
            $parts[] = "+{$bonus} F bonus";
        }

        $parts[] = "~{$zone['estimated_time']} min";

        return implode(' · ', $parts);
    }

    private function haversine(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $r = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;
        return $r * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }
}
