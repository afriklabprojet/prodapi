<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Services\BusinessEventService;
use App\Traits\ApiResponder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

/**
 * API Admin : Stats & Revenus en temps réel
 * 
 * Endpoints pour le dashboard mobile admin et monitoring business.
 */
class StatsController extends Controller
{
    use ApiResponder;

    /**
     * GET /api/admin/stats/dashboard
     * 
     * Vue d'ensemble en temps réel
     */
    public function dashboard()
    {
        $today = BusinessEventService::todayRevenue();
        $revenue = BusinessEventService::revenueStats();

        return $this->success([
            'today' => $today,
            'revenue' => $revenue,
            'health' => $this->systemHealth(),
        ], 'Dashboard stats');
    }

    /**
     * GET /api/admin/stats/revenue
     * 
     * Détail des revenus avec période configurable
     */
    public function revenue(Request $request)
    {
        return $this->success(
            BusinessEventService::revenueStats(),
            'Revenue stats'
        );
    }

    /**
     * GET /api/admin/stats/today
     * 
     * Snapshot du jour (léger, pour polling mobile)
     */
    public function today()
    {
        return $this->success(
            BusinessEventService::todayRevenue(),
            'Stats du jour'
        );
    }

    /**
     * GET /api/admin/stats/events
     * 
     * Événements business récents
     */
    public function events(Request $request)
    {
        $event = $request->query('event');
        $limit = min((int) $request->query('limit', 50), 200);

        return $this->success(
            BusinessEventService::recentEvents($event, $limit),
            'Business events'
        );
    }

    /**
     * GET /api/admin/stats/funnel
     * 
     * Funnel conversion : signup → phone_verified → order → payment → delivered
     */
    public function funnel(Request $request)
    {
        $days = min((int) $request->query('days', 30), 90);
        $since = now()->subDays($days);

        $funnel = Cache::remember("funnel:{$days}", 600, function () use ($since) {
            return [
                'signups' => (int) DB::table('users')
                    ->where('created_at', '>=', $since)
                    ->where('role', 'customer')
                    ->count(),

                'phone_verified' => (int) DB::table('users')
                    ->where('created_at', '>=', $since)
                    ->where('role', 'customer')
                    ->whereNotNull('phone_verified_at')
                    ->count(),

                'first_order' => (int) DB::table('orders')
                    ->where('created_at', '>=', $since)
                    ->distinct('customer_id')
                    ->count('customer_id'),

                'payment_initiated' => (int) DB::table('jeko_payments')
                    ->where('created_at', '>=', $since)
                    ->distinct('user_id')
                    ->count('user_id'),

                'payment_completed' => (int) DB::table('jeko_payments')
                    ->where('created_at', '>=', $since)
                    ->where('status', 'completed')
                    ->distinct('user_id')
                    ->count('user_id'),

                'order_delivered' => (int) DB::table('orders')
                    ->where('created_at', '>=', $since)
                    ->where('status', 'delivered')
                    ->distinct('customer_id')
                    ->count('customer_id'),
            ];
        });

        return $this->success([
            'funnel' => $funnel,
            'period_days' => $days,
        ], 'Conversion funnel');
    }

    /**
     * GET /api/admin/stats/alerts
     * 
     * Alertes critiques en temps réel
     */
    public function alerts()
    {
        $alerts = [];

        // Paiements bloqués (pending > 30min)
        $stuckPayments = DB::table('jeko_payments')
            ->whereIn('status', ['pending', 'processing'])
            ->where('created_at', '<', now()->subMinutes(30))
            ->count();
        if ($stuckPayments > 0) {
            $alerts[] = [
                'level' => 'critical',
                'type' => 'stuck_payments',
                'message' => "{$stuckPayments} paiement(s) bloqué(s) depuis +30min",
                'count' => $stuckPayments,
            ];
        }

        // Commandes en attente trop longtemps (pending > 1h)
        $staleOrders = DB::table('orders')
            ->where('status', 'pending')
            ->where('created_at', '<', now()->subHour())
            ->count();
        if ($staleOrders > 0) {
            $alerts[] = [
                'level' => 'warning',
                'type' => 'stale_orders',
                'message' => "{$staleOrders} commande(s) en attente depuis +1h",
                'count' => $staleOrders,
            ];
        }

        // Jobs échoués
        $failedJobs = DB::table('failed_jobs')->count();
        if ($failedJobs > 0) {
            $alerts[] = [
                'level' => 'warning',
                'type' => 'failed_jobs',
                'message' => "{$failedJobs} job(s) en échec",
                'count' => $failedJobs,
            ];
        }

        // Taux d'échec paiement élevé (>30% sur les 2 dernières heures)
        $recentPayments = DB::table('jeko_payments')
            ->where('created_at', '>=', now()->subHours(2))
            ->selectRaw("
                COUNT(*) as total,
                COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed
            ")
            ->first();
        if ($recentPayments->total >= 5) {
            $failRate = round(($recentPayments->failed / $recentPayments->total) * 100, 1);
            if ($failRate > 30) {
                $alerts[] = [
                    'level' => 'critical',
                    'type' => 'high_payment_failure_rate',
                    'message' => "Taux d'échec paiement: {$failRate}% sur 2h ({$recentPayments->failed}/{$recentPayments->total})",
                    'rate' => $failRate,
                ];
            }
        }

        // Erreurs API fréquentes (>10 sur la dernière heure)
        if (DB::getSchemaBuilder()->hasTable('business_events')) {
            $apiErrors = DB::table('business_events')
                ->where('event', 'api_error')
                ->where('created_at', '>=', now()->subHour())
                ->count();
            if ($apiErrors > 10) {
                $alerts[] = [
                    'level' => 'warning',
                    'type' => 'frequent_api_errors',
                    'message' => "{$apiErrors} erreurs API sur la dernière heure",
                    'count' => $apiErrors,
                ];
            }
        }

        return $this->success([
            'alerts' => $alerts,
            'alert_count' => count($alerts),
            'checked_at' => now()->toIso8601String(),
        ], count($alerts) > 0 ? 'Alertes détectées' : 'Aucune alerte');
    }

    /**
     * Données de santé système
     */
    private function systemHealth(): array
    {
        return [
            'queue_size' => (int) DB::table('jobs')->count(),
            'failed_jobs' => (int) DB::table('failed_jobs')->count(),
            'pending_orders' => (int) DB::table('orders')->where('status', 'pending')->count(),
            'pending_payments' => (int) DB::table('jeko_payments')
                ->whereIn('status', ['pending', 'processing'])
                ->count(),
            'active_couriers' => (int) DB::table('couriers')
                ->where('status', 'available')
                ->count(),
        ];
    }
}
