<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

/**
 * API Heatmap des commandes
 * 
 * Retourne la densité des commandes par zone géographique
 * pour visualiser les zones les plus actives (admin dashboard).
 */
class OrderHeatmapController extends Controller
{
    /**
     * Obtenir les données de heatmap des commandes
     * 
     * Regroupe les commandes par grille géographique (arrondi GPS)
     * et retourne le nombre de commandes par cellule.
     * 
     * @param Request $request
     *   - period: 'day'|'week'|'month'|'all' (default: 'month')
     *   - precision: int 2-4 (décimales GPS, default: 3 → ~111m grille)  
     *   - min_lat, max_lat, min_lng, max_lng: bounding box (optional)
     */
    public function index(Request $request)
    {
        $period = $request->query('period', 'month');
        $precision = min(4, max(2, (int) $request->query('precision', 3)));

        // Filtre temporel
        $dateFilter = match ($period) {
            'day' => now()->subDay(),
            'week' => now()->subWeek(),
            'month' => now()->subMonth(),
            'quarter' => now()->subMonths(3),
            'year' => now()->subYear(),
            default => null,
        };

        // Cache key basée sur les paramètres
        $cacheKey = "heatmap:{$period}:{$precision}";
        $cacheTtl = match ($period) {
            'day' => 300,    // 5 min
            'week' => 1800,  // 30 min
            default => 3600, // 1h
        };

        $data = Cache::remember($cacheKey, $cacheTtl, function () use ($dateFilter, $precision, $request) {
            $factor = pow(10, $precision);

            $query = DB::table('orders')
                ->select(
                    DB::raw("ROUND(delivery_latitude * {$factor}) / {$factor} as lat"),
                    DB::raw("ROUND(delivery_longitude * {$factor}) / {$factor} as lng"),
                    DB::raw('COUNT(*) as count'),
                    DB::raw('SUM(total_amount) as total_revenue'),
                    DB::raw('AVG(total_amount) as avg_amount'),
                )
                ->whereNotNull('delivery_latitude')
                ->whereNotNull('delivery_longitude')
                ->where('delivery_latitude', '!=', 0)
                ->where('delivery_longitude', '!=', 0);

            if ($dateFilter) {
                $query->where('created_at', '>=', $dateFilter);
            }

            // Bounding box filter
            if ($request->filled('min_lat')) {
                $query->where('delivery_latitude', '>=', (float) $request->query('min_lat'));
            }
            if ($request->filled('max_lat')) {
                $query->where('delivery_latitude', '<=', (float) $request->query('max_lat'));
            }
            if ($request->filled('min_lng')) {
                $query->where('delivery_longitude', '>=', (float) $request->query('min_lng'));
            }
            if ($request->filled('max_lng')) {
                $query->where('delivery_longitude', '<=', (float) $request->query('max_lng'));
            }

            $points = $query
                ->groupBy('lat', 'lng')
                ->having('count', '>', 0)
                ->orderByDesc('count')
                ->limit(500)
                ->get();

            // Statistiques globales
            $statsQuery = DB::table('orders')
                ->whereNotNull('delivery_latitude')
                ->whereNotNull('delivery_longitude')
                ->where('delivery_latitude', '!=', 0)
                ->where('delivery_longitude', '!=', 0);

            if ($dateFilter) {
                $statsQuery->where('created_at', '>=', $dateFilter);
            }

            $stats = $statsQuery
                ->select(
                    DB::raw('COUNT(*) as total_orders'),
                    DB::raw('SUM(total_amount) as total_revenue'),
                    DB::raw('AVG(delivery_latitude) as center_lat'),
                    DB::raw('AVG(delivery_longitude) as center_lng'),
                )
                ->first();

            // Top zones (communes/quartiers) via reverse geocoding simplifié
            $topZones = $points->take(10)->map(fn($p) => [
                'lat' => (float) $p->lat,
                'lng' => (float) $p->lng,
                'count' => (int) $p->count,
                'total_revenue' => round((float) $p->total_revenue, 0),
                'avg_amount' => round((float) $p->avg_amount, 0),
            ])->values();

            return [
                'points' => $points->map(fn($p) => [
                    'lat' => (float) $p->lat,
                    'lng' => (float) $p->lng,
                    'weight' => (int) $p->count,
                ])->values(),
                'stats' => [
                    'total_orders' => (int) ($stats->total_orders ?? 0),
                    'total_revenue' => round((float) ($stats->total_revenue ?? 0), 0),
                    'center_lat' => (float) ($stats->center_lat ?? 5.36),
                    'center_lng' => (float) ($stats->center_lng ?? -4.008),
                    'zones_count' => $points->count(),
                ],
                'top_zones' => $topZones,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    /**
     * Heatmap des pharmacies les plus sollicitées
     */
    public function pharmacyHeatmap(Request $request)
    {
        $period = $request->query('period', 'month');

        $dateFilter = match ($period) {
            'day' => now()->subDay(),
            'week' => now()->subWeek(),
            'month' => now()->subMonth(),
            default => null,
        };

        $cacheKey = "pharmacy_heatmap:{$period}";

        $data = Cache::remember($cacheKey, 1800, function () use ($dateFilter) {
            $query = DB::table('orders')
                ->join('pharmacies', 'orders.pharmacy_id', '=', 'pharmacies.id')
                ->select(
                    'pharmacies.id',
                    'pharmacies.name',
                    'pharmacies.latitude as lat',
                    'pharmacies.longitude as lng',
                    DB::raw('COUNT(orders.id) as order_count'),
                    DB::raw('SUM(orders.total_amount) as total_revenue'),
                )
                ->whereNotNull('pharmacies.latitude')
                ->whereNotNull('pharmacies.longitude');

            if ($dateFilter) {
                $query->where('orders.created_at', '>=', $dateFilter);
            }

            return $query
                ->groupBy('pharmacies.id', 'pharmacies.name', 'pharmacies.latitude', 'pharmacies.longitude')
                ->orderByDesc('order_count')
                ->limit(50)
                ->get()
                ->map(fn($p) => [
                    'id' => $p->id,
                    'name' => $p->name,
                    'lat' => (float) $p->lat,
                    'lng' => (float) $p->lng,
                    'order_count' => (int) $p->order_count,
                    'total_revenue' => round((float) $p->total_revenue, 0),
                ])
                ->values();
        });

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }
}
