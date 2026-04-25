<?php

namespace App\Jobs;

use App\Mail\AdminAlertMail;
use App\Models\Courier;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

/**
 * Rapport hebdomadaire consolidé pour l'administration.
 *
 * Contenu :
 * - CA livré (commandes status=delivered + total_amount)
 * - Taux d'annulation
 * - Nombre de commandes (total, livrées, annulées)
 * - Livreurs actifs sur la semaine (≥1 livraison)
 * - Délai moyen de livraison
 * - Top 5 produits vendus (par quantité)
 * - Nouveaux clients inscrits
 * - Taux de fidélisation (clients avec ≥2 commandes)
 *
 * Fréquence recommandée : chaque lundi à 07h00
 */
class WeeklyBusinessReportJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public array $backoff = [120, 300];
    public int $timeout = 300;

    public function middleware(): array
    {
        return [new WithoutOverlapping('weekly-business-report')];
    }

    public function handle(): void
    {
        $from = now()->subWeek()->startOfWeek();
        $to   = now()->subWeek()->endOfWeek();

        $report = [
            'period'    => $from->format('d/m/Y').' – '.$to->format('d/m/Y'),
            'orders'    => $this->buildOrderStats($from, $to),
            'revenue'   => $this->buildRevenueStats($from, $to),
            'deliveries'=> $this->buildDeliveryStats($from, $to),
            'couriers'  => $this->buildCourierStats($from, $to),
            'products'  => $this->buildTopProducts($from, $to),
            'customers' => $this->buildCustomerStats($from, $to),
        ];

        Log::info('WeeklyBusinessReportJob: rapport généré', [
            'period' => $report['period'],
            'orders_total' => $report['orders']['total'],
            'revenue_ca' => $report['revenue']['ca_delivered'],
        ]);

        try {
            Mail::to(config('mail.admin_address', 'admin@drlpharma.com'))
                ->send(new AdminAlertMail('weekly_report', $report));
        } catch (\Throwable $e) {
            Log::warning('WeeklyBusinessReportJob: email failed', ['error' => $e->getMessage()]);
        }
    }

    // ── Statistiques commandes ──────────────────────────────────────────────

    private function buildOrderStats(\Carbon\Carbon $from, \Carbon\Carbon $to): array
    {
        $base = Order::whereBetween('created_at', [$from, $to]);

        $total     = (clone $base)->count();
        $delivered = (clone $base)->where('status', 'delivered')->count();
        $cancelled = (clone $base)->where('status', 'cancelled')->count();

        return [
            'total'            => $total,
            'delivered'        => $delivered,
            'cancelled'        => $cancelled,
            'cancellation_rate'=> $total > 0 ? round($cancelled / $total * 100, 1) : 0,
            'avg_amount'       => round((float) (clone $base)->where('status', 'delivered')->avg('total_amount') ?? 0, 0),
        ];
    }

    // ── Chiffre d'affaires ──────────────────────────────────────────────────

    private function buildRevenueStats(\Carbon\Carbon $from, \Carbon\Carbon $to): array
    {
        $ca = Order::whereBetween('delivered_at', [$from, $to])
            ->where('status', 'delivered')
            ->sum('total_amount');

        $deliveryFees = Order::whereBetween('delivered_at', [$from, $to])
            ->where('status', 'delivered')
            ->sum('delivery_fee');

        return [
            'ca_delivered'  => round((float) $ca, 0),
            'delivery_fees' => round((float) $deliveryFees, 0),
        ];
    }

    // ── Livraisons ──────────────────────────────────────────────────────────

    private function buildDeliveryStats(\Carbon\Carbon $from, \Carbon\Carbon $to): array
    {
        $base = Delivery::whereBetween('created_at', [$from, $to]);

        $delivered = (clone $base)->where('status', 'delivered');

        // Délai moyen pickup → delivery en minutes
        $avgMins = $delivered->clone()
            ->whereNotNull('picked_up_at')
            ->whereNotNull('delivered_at')
            ->selectRaw('AVG(TIMESTAMPDIFF(MINUTE, picked_up_at, delivered_at)) as avg_min')
            ->value('avg_min');

        return [
            'total'          => (clone $base)->count(),
            'delivered'      => $delivered->count(),
            'failed'         => (clone $base)->where('status', 'failed')->count(),
            'avg_time_min'   => $avgMins ? (int) round($avgMins) : null,
        ];
    }

    // ── Livreurs actifs ─────────────────────────────────────────────────────

    private function buildCourierStats(\Carbon\Carbon $from, \Carbon\Carbon $to): array
    {
        $activeCount = Delivery::whereBetween('delivered_at', [$from, $to])
            ->where('status', 'delivered')
            ->distinct('courier_id')
            ->count('courier_id');

        $totalApproved = Courier::where('kyc_status', 'approved')->count();

        return [
            'active_this_week' => $activeCount,
            'total_approved'   => $totalApproved,
            'activity_rate'    => $totalApproved > 0 ? round($activeCount / $totalApproved * 100, 1) : 0,
        ];
    }

    // ── Top 5 produits ──────────────────────────────────────────────────────

    private function buildTopProducts(\Carbon\Carbon $from, \Carbon\Carbon $to): array
    {
        return OrderItem::join('orders', 'order_items.order_id', '=', 'orders.id')
            ->join('products', 'order_items.product_id', '=', 'products.id')
            ->whereBetween('orders.created_at', [$from, $to])
            ->where('orders.status', 'delivered')
            ->selectRaw('products.name, SUM(order_items.quantity) as qty_sold, SUM(order_items.total_price) as revenue')
            ->groupBy('products.id', 'products.name')
            ->orderByDesc('qty_sold')
            ->limit(5)
            ->get()
            ->map(fn ($r) => [
                'name'    => $r->name,
                'qty'     => (int) $r->qty_sold,
                'revenue' => round((float) $r->revenue, 0),
            ])
            ->all();
    }

    // ── Clients ─────────────────────────────────────────────────────────────

    private function buildCustomerStats(\Carbon\Carbon $from, \Carbon\Carbon $to): array
    {
        $newClients = User::whereBetween('created_at', [$from, $to])
            ->where('role', 'customer')
            ->count();

        // Clients avec ≥ 2 commandes livrées sur la période (fidélisation)
        $loyalCount = Order::whereBetween('created_at', [$from, $to])
            ->where('status', 'delivered')
            ->select('customer_id')
            ->groupBy('customer_id')
            ->havingRaw('COUNT(*) >= 2')
            ->get()
            ->count();

        $totalActiveClients = Order::whereBetween('created_at', [$from, $to])
            ->distinct('customer_id')
            ->count('customer_id');

        return [
            'new_this_week'     => $newClients,
            'active_this_week'  => $totalActiveClients,
            'loyal_repeat'      => $loyalCount,
            'retention_rate'    => $totalActiveClients > 0 ? round($loyalCount / $totalActiveClients * 100, 1) : 0,
        ];
    }
}
