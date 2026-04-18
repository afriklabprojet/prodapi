<?php

namespace App\Services;

use App\Models\Courier;
use App\Models\Order;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class HeatmapService
{
    /**
     * Taille de la grille en degrés (~1km à Abidjan/Lomé)
     */
    const GRID_SIZE = 0.01;

    /**
     * Couleurs par intensité de demande
     */
    const HEAT_COLORS = [
        'cold' => '#3b82f6',     // Bleu — faible demande
        'warm' => '#f59e0b',     // Orange — demande modérée
        'hot' => '#ef4444',      // Rouge — forte demande
        'extreme' => '#7c3aed',  // Violet — surge
    ];

    /**
     * Générer les données de heatmap pour le dashboard admin
     */
    public function generateDemandHeatmap(int $hoursBack = 2): array
    {
        $cacheKey = "heatmap:demand:{$hoursBack}";

        return Cache::remember($cacheKey, 60, function () use ($hoursBack) {
            $cells = $this->aggregateOrdersByGrid($hoursBack);
            $courierPositions = $this->getCourierPositions();

            return [
                'cells' => $cells->toArray(),
                'couriers' => $courierPositions->toArray(),
                'generated_at' => now()->toIso8601String(),
                'legend' => $this->getHeatmapLegend(),
                'stats' => [
                    'total_pending_orders' => Order::where('status', 'ready')->whereNull('delivery_id')->count(),
                    'total_available_couriers' => Courier::where('status', 'available')->count(),
                    'hot_zones' => $cells->where('heat_level', 'hot')->count() + $cells->where('heat_level', 'extreme')->count(),
                ],
            ];
        });
    }

    /**
     * Agréger les commandes par grille géographique
     */
    protected function aggregateOrdersByGrid(int $hoursBack)
    {
        $since = now()->subHours($hoursBack);

        $orders = DB::table('orders')
            ->join('pharmacies', 'orders.pharmacy_id', '=', 'pharmacies.id')
            ->where('orders.created_at', '>=', $since)
            ->whereNotNull('pharmacies.latitude')
            ->whereNotNull('pharmacies.longitude')
            ->select(
                DB::raw('ROUND(pharmacies.latitude / ' . self::GRID_SIZE . ') * ' . self::GRID_SIZE . ' as grid_lat'),
                DB::raw('ROUND(pharmacies.longitude / ' . self::GRID_SIZE . ') * ' . self::GRID_SIZE . ' as grid_lng'),
                DB::raw('COUNT(*) as order_count'),
                DB::raw("SUM(CASE WHEN orders.status = 'ready' AND orders.delivery_id IS NULL THEN 1 ELSE 0 END) as pending_count"),
            )
            ->groupBy('grid_lat', 'grid_lng')
            ->get();

        return $orders->map(function ($cell) {
            $heatLevel = $this->determineHeatLevel($cell->order_count, $cell->pending_count);

            return [
                'center' => [
                    'lat' => (float) $cell->grid_lat,
                    'lng' => (float) $cell->grid_lng,
                ],
                'order_count' => (int) $cell->order_count,
                'pending_count' => (int) $cell->pending_count,
                'heat_level' => $heatLevel,
                'color' => self::HEAT_COLORS[$heatLevel],
                'intensity' => $this->calculateIntensity($cell->order_count),
            ];
        });
    }

    /**
     * Positions des livreurs actifs pour overlay sur la carte
     */
    protected function getCourierPositions()
    {
        return Courier::where('status', 'available')
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->where('last_location_update', '>=', now()->subMinutes(10))
            ->select('id', 'name', 'latitude', 'longitude', 'vehicle_type', 'last_location_update')
            ->get()
            ->map(fn ($c) => [
                'id' => $c->id,
                'name' => $c->name,
                'lat' => (float) $c->latitude,
                'lng' => (float) $c->longitude,
                'vehicle' => $c->vehicle_type,
                'gps_age_min' => $c->last_location_update?->diffInMinutes(now()),
            ]);
    }

    /**
     * Opportunités de gains pour un livreur
     */
    public function getCourierOpportunities(Courier $courier, float $maxDistanceKm = 15): array
    {
        $heatmap = $this->generateDemandHeatmap();

        $opportunities = collect($heatmap['cells'])
            ->filter(fn ($cell) => $cell['pending_count'] > 0)
            ->map(function ($cell) use ($courier) {
                $distance = $this->haversineDistance(
                    (float) $courier->latitude,
                    (float) $courier->longitude,
                    $cell['center']['lat'],
                    $cell['center']['lng']
                );

                return [
                    'center' => $cell['center'],
                    'distance_km' => round($distance, 1),
                    'pending_orders' => $cell['pending_count'],
                    'heat_level' => $cell['heat_level'],
                    'potential_earnings' => $cell['pending_count'] * 500, // estimation FCFA
                ];
            })
            ->filter(fn ($o) => $o['distance_km'] <= $maxDistanceKm)
            ->sortByDesc('pending_orders')
            ->take(5)
            ->values()
            ->toArray();

        return [
            'courier_id' => $courier->id,
            'opportunities' => $opportunities,
            'best_action' => !empty($opportunities)
                ? "Se déplacer vers {$opportunities[0]['center']['lat']},{$opportunities[0]['center']['lng']}"
                : 'Rester en position',
            'generated_at' => now()->toIso8601String(),
        ];
    }

    protected function determineHeatLevel(int $totalOrders, int $pendingOrders): string
    {
        if ($pendingOrders >= 5) return 'extreme';
        if ($pendingOrders >= 3 || $totalOrders >= 10) return 'hot';
        if ($pendingOrders >= 1 || $totalOrders >= 5) return 'warm';
        return 'cold';
    }

    protected function calculateIntensity(int $orderCount): float
    {
        // 0.0 à 1.0, saturé à 15 commandes
        return min(1.0, round($orderCount / 15, 2));
    }

    protected function getHeatmapLegend(): array
    {
        return [
            ['level' => 'cold', 'color' => self::HEAT_COLORS['cold'], 'label' => 'Faible demande'],
            ['level' => 'warm', 'color' => self::HEAT_COLORS['warm'], 'label' => 'Demande modérée'],
            ['level' => 'hot', 'color' => self::HEAT_COLORS['hot'], 'label' => 'Forte demande'],
            ['level' => 'extreme', 'color' => self::HEAT_COLORS['extreme'], 'label' => 'Zone surge'],
        ];
    }

    /**
     * Distance Haversine en km
     */
    protected function haversineDistance(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $earthRadius = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $a = sin($dLat / 2) * sin($dLat / 2)
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2))
            * sin($dLng / 2) * sin($dLng / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }
}
