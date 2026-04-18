<?php

namespace App\Http\Controllers\Api\Courier;

use App\Http\Controllers\Controller;
use App\Models\Delivery;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class CourierHeatmapController extends Controller
{
    /**
     * GET /courier/heatmap/opportunities
     * Zones where deliveries are most concentrated for the courier.
     * Helps couriers position themselves for faster assignment.
     */
    public function opportunities(Request $request): JsonResponse
    {
        $courier  = $request->user()->courier;
        $cacheKey = 'courier_heatmap_v1_' . now()->format('YmdH');

        $data = Cache::remember($cacheKey, 900, function () {
            return DB::table('deliveries')
                ->join('orders', 'deliveries.order_id', '=', 'orders.id')
                ->join('pharmacies', 'orders.pharmacy_id', '=', 'pharmacies.id')
                ->where('deliveries.created_at', '>=', now()->subHours(24))
                ->whereIn('deliveries.status', ['pending', 'assigned', 'picked_up'])
                ->select(
                    DB::raw('ROUND(pharmacies.latitude, 2) as lat'),
                    DB::raw('ROUND(pharmacies.longitude, 2) as lng'),
                    DB::raw('COUNT(*) as order_count'),
                    DB::raw('AVG(orders.delivery_fee) as avg_fee'),
                )
                ->groupBy('lat', 'lng')
                ->orderByDesc('order_count')
                ->limit(30)
                ->get()
                ->map(fn ($r) => [
                    'latitude'    => (float) $r->lat,
                    'longitude'   => (float) $r->lng,
                    'weight'      => (int) $r->order_count,
                    'avg_fee'     => (float) ($r->avg_fee ?? 0),
                ])
                ->values();
        });

        return response()->json([
            'success'    => true,
            'data'       => $data,
            'generated_at' => now()->toIso8601String(),
        ]);
    }
}
