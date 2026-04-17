<?php

namespace App\Http\Controllers\Api\Pharmacy;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReportsController extends Controller
{
    public function overview(Request $request): JsonResponse
    {
        $pharmacy = $request->user()->pharmacies()->first();
        
        if (!$pharmacy) {
            return response()->json([
                'success' => true,
                'data' => [
                    'period' => $request->get('period', 'month'),
                    'sales' => ['today' => 0, 'yesterday' => 0, 'period_total' => 0, 'growth' => 0],
                    'orders' => ['total' => 0, 'pending' => 0, 'completed' => 0, 'cancelled' => 0],
                    'inventory' => ['total_products' => 0, 'low_stock' => 0, 'out_of_stock' => 0, 'expiring_soon' => 0],
                ],
            ]);
        }
        
        $period = $request->get('period', 'month');
        $start = $this->periodStart($period);

        // Commandes de la période
        $ordersQuery = Order::where('pharmacy_id', $pharmacy->id)
            ->where('created_at', '>=', $start);

        $totalOrders = (clone $ordersQuery)->count();
        $completedOrders = (clone $ordersQuery)->where('status', 'delivered')->count();
        $cancelledOrders = (clone $ordersQuery)->where('status', 'cancelled')->count();
        $pendingOrders = (clone $ordersQuery)->where('status', 'pending')->count();
        $totalRevenue = (clone $ordersQuery)->where('status', 'delivered')->sum('total_amount');

        // Ventes aujourd'hui et hier
        $salesToday = Order::where('pharmacy_id', $pharmacy->id)
            ->where('status', 'delivered')
            ->whereDate('created_at', today())
            ->sum('total_amount');

        $salesYesterday = Order::where('pharmacy_id', $pharmacy->id)
            ->where('status', 'delivered')
            ->whereDate('created_at', today()->subDay())
            ->sum('total_amount');

        $growth = $salesYesterday > 0
            ? round(($salesToday - $salesYesterday) / $salesYesterday * 100, 1)
            : 0;

        // Inventaire
        $totalProducts = Product::where('pharmacy_id', $pharmacy->id)->count();
        $lowStock = Product::where('pharmacy_id', $pharmacy->id)
            ->where('stock_quantity', '>', 0)
            ->whereColumn('stock_quantity', '<=', 'low_stock_threshold')
            ->count();
        $outOfStock = Product::where('pharmacy_id', $pharmacy->id)
            ->where('stock_quantity', '<=', 0)
            ->count();
        $expiringSoon = Product::where('pharmacy_id', $pharmacy->id)
            ->where('is_available', true)
            ->where('stock_quantity', '>', 0)
            ->whereNotNull('expiry_date')
            ->where('expiry_date', '>', now())
            ->where('expiry_date', '<=', now()->addDays(30))
            ->count();

        return response()->json([
            'success' => true,
            'data' => [
                'period' => $period,
                'sales' => [
                    'today' => (float) $salesToday,
                    'yesterday' => (float) $salesYesterday,
                    'period_total' => (float) $totalRevenue,
                    'growth' => (float) $growth,
                ],
                'orders' => [
                    'total' => $totalOrders,
                    'pending' => $pendingOrders,
                    'completed' => $completedOrders,
                    'cancelled' => $cancelledOrders,
                ],
                'inventory' => [
                    'total_products' => $totalProducts,
                    'low_stock' => $lowStock,
                    'out_of_stock' => $outOfStock,
                    'expiring_soon' => $expiringSoon,
                ],
            ],
        ]);
    }

    public function sales(Request $request): JsonResponse
    {
        $pharmacy = $request->user()->pharmacies()->first();
        
        if (!$pharmacy) {
            return response()->json([
                'success' => true,
                'data' => ['total_revenue' => 0, 'average_order_value' => 0, 'total_orders' => 0, 'daily_breakdown' => [], 'top_products' => []],
            ]);
        }
        
        $period = $request->get('period', 'month');
        $start = $this->periodStart($period);

        $deliveredOrders = Order::where('pharmacy_id', $pharmacy->id)
            ->where('status', 'delivered')
            ->where('created_at', '>=', $start);

        $totalRevenue = (clone $deliveredOrders)->sum('total_amount');
        $totalOrders = (clone $deliveredOrders)->count();
        $averageOrderValue = $totalOrders > 0 ? $totalRevenue / $totalOrders : 0;

        // Ventilation journalière
        $dailyBreakdown = (clone $deliveredOrders)
            ->selectRaw('DATE(created_at) as date, COUNT(*) as order_count, SUM(total_amount) as amount')
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        // Top produits vendus
        $topProducts = \DB::table('order_items')
            ->join('orders', 'orders.id', '=', 'order_items.order_id')
            ->join('products', 'products.id', '=', 'order_items.product_id')
            ->where('orders.pharmacy_id', $pharmacy->id)
            ->where('orders.status', 'delivered')
            ->where('orders.created_at', '>=', $start)
            ->selectRaw('products.id as product_id, products.name, SUM(order_items.quantity) as quantity_sold, SUM(order_items.quantity * order_items.unit_price) as revenue')
            ->groupBy('products.id', 'products.name')
            ->orderByDesc('quantity_sold')
            ->limit(10)
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'total_revenue' => (float) $totalRevenue,
                'average_order_value' => round((float) $averageOrderValue, 0),
                'total_orders' => $totalOrders,
                'daily_breakdown' => $dailyBreakdown,
                'top_products' => $topProducts,
            ],
        ]);
    }

    public function orders(Request $request): JsonResponse
    {
        $pharmacy = $request->user()->pharmacies()->first();
        
        if (!$pharmacy) {
            return response()->json(['success' => true, 'data' => []]);
        }
        
        $period = $request->get('period', 'month');
        $start = $this->periodStart($period);

        $orders = Order::where('pharmacy_id', $pharmacy->id)
            ->where('created_at', '>=', $start)
            ->selectRaw("status, COUNT(*) as count")
            ->groupBy('status')
            ->get()
            ->pluck('count', 'status');

        return response()->json([
            'success' => true,
            'data' => $orders,
        ]);
    }

    public function inventory(Request $request): JsonResponse
    {
        $pharmacy = $request->user()->pharmacies()->first();
        
        if (!$pharmacy) {
            return response()->json([
                'success' => true,
                'data' => ['total_products' => 0, 'active_products' => 0, 'out_of_stock' => 0, 'low_stock' => 0, 'expiring_soon' => 0],
            ]);
        }

        $stats = [
            'total_products' => Product::where('pharmacy_id', $pharmacy->id)->count(),
            'active_products' => Product::where('pharmacy_id', $pharmacy->id)->where('is_available', true)->count(),
            'out_of_stock' => Product::where('pharmacy_id', $pharmacy->id)->where('stock_quantity', '<=', 0)->count(),
            'low_stock' => Product::where('pharmacy_id', $pharmacy->id)
                ->where('stock_quantity', '>', 0)
                ->whereColumn('stock_quantity', '<=', 'low_stock_threshold')
                ->count(),
            'expiring_soon' => Product::where('pharmacy_id', $pharmacy->id)
                ->where('is_available', true)
                ->where('stock_quantity', '>', 0)
                ->whereNotNull('expiry_date')
                ->where('expiry_date', '>', now())
                ->where('expiry_date', '<=', now()->addDays(30))
                ->count(),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats,
        ]);
    }

    public function stockAlerts(Request $request): JsonResponse
    {
        $pharmacy = $request->user()->pharmacies()->first();
        
        if (!$pharmacy) {
            return response()->json(['success' => true, 'data' => ['alerts' => []]]);
        }
        
        $alerts = collect();

        // Produits en rupture de stock
        Product::where('pharmacy_id', $pharmacy->id)
            ->where('is_available', true)
            ->outOfStock()
            ->get(['id', 'name', 'stock_quantity', 'low_stock_threshold', 'price', 'expiry_date'])
            ->each(function ($p) use ($alerts) {
                $alerts->push([
                    'product_id' => $p->id,
                    'product_name' => $p->name,
                    'type' => 'out_of_stock',
                    'current_quantity' => $p->stock_quantity,
                    'threshold' => $p->low_stock_threshold ?? 5,
                    'expiry_date' => $p->expiry_date?->toDateString(),
                    'price' => $p->price,
                ]);
            });

        // Produits en stock bas (> 0 mais <= seuil)
        Product::where('pharmacy_id', $pharmacy->id)
            ->where('is_available', true)
            ->lowStock()
            ->get(['id', 'name', 'stock_quantity', 'low_stock_threshold', 'price', 'expiry_date'])
            ->each(function ($p) use ($alerts) {
                $alerts->push([
                    'product_id' => $p->id,
                    'product_name' => $p->name,
                    'type' => 'low_stock',
                    'current_quantity' => $p->stock_quantity,
                    'threshold' => $p->low_stock_threshold ?? 5,
                    'expiry_date' => $p->expiry_date?->toDateString(),
                    'price' => $p->price,
                ]);
            });

        // Produits expirant dans les 30 prochains jours
        Product::where('pharmacy_id', $pharmacy->id)
            ->where('is_available', true)
            ->where('stock_quantity', '>', 0)
            ->whereNotNull('expiry_date')
            ->where('expiry_date', '>', now())
            ->where('expiry_date', '<=', now()->addDays(30))
            ->get(['id', 'name', 'stock_quantity', 'low_stock_threshold', 'price', 'expiry_date'])
            ->each(function ($p) use ($alerts) {
                $alerts->push([
                    'product_id' => $p->id,
                    'product_name' => $p->name,
                    'type' => 'expiring_soon',
                    'current_quantity' => $p->stock_quantity,
                    'threshold' => $p->low_stock_threshold ?? 5,
                    'expiry_date' => $p->expiry_date?->toDateString(),
                    'price' => $p->price,
                ]);
            });

        // Produits déjà expirés (à retirer du stock !)
        Product::where('pharmacy_id', $pharmacy->id)
            ->where('is_available', true)
            ->where('stock_quantity', '>', 0)
            ->whereNotNull('expiry_date')
            ->where('expiry_date', '<', now())
            ->get(['id', 'name', 'stock_quantity', 'low_stock_threshold', 'price', 'expiry_date'])
            ->each(function ($p) use ($alerts) {
                $alerts->push([
                    'product_id' => $p->id,
                    'product_name' => $p->name,
                    'type' => 'expired',
                    'current_quantity' => $p->stock_quantity,
                    'threshold' => $p->low_stock_threshold ?? 5,
                    'expiry_date' => $p->expiry_date?->toDateString(),
                    'price' => $p->price,
                ]);
            });

        return response()->json([
            'success' => true,
            'data' => [
                'alerts' => $alerts->values()->all(),
            ],
        ]);
    }

    public function export(Request $request): JsonResponse
    {
        $pharmacy = $request->user()->pharmacies()->first();
        
        if (!$pharmacy) {
            return response()->json(['success' => true, 'data' => []]);
        }
        
        $period = $request->get('period', 'month');
        $start = $this->periodStart($period);

        $orders = Order::where('pharmacy_id', $pharmacy->id)
            ->where('status', 'delivered')
            ->where('created_at', '>=', $start)
            ->with('payments')
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $orders,
        ]);
    }

    private function periodStart(string $period): \Carbon\Carbon
    {
        return match ($period) {
            'week' => now()->startOfWeek(),
            'month' => now()->startOfMonth(),
            'quarter' => now()->startOfQuarter(),
            'year' => now()->startOfYear(),
            default => now()->startOfMonth(),
        };
    }
}
