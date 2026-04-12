<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

/**
 * Service de tracking d'événements business.
 * 
 * Enregistre les événements clés pour l'analyse :
 * - signup, login, booking_created, payment_success, etc.
 * 
 * Stocke en base + log structuré pour analyse.
 * Fournit des métriques de revenus en temps réel.
 */
class BusinessEventService
{
    // ──────────────────────────────────────────
    // ÉVÉNEMENTS CLÉS
    // ──────────────────────────────────────────

    public static function signup(int $userId, string $role, array $meta = []): void
    {
        self::track('signup', $userId, array_merge([
            'role' => $role,
        ], $meta));
    }

    public static function login(int $userId, string $role, array $meta = []): void
    {
        self::track('login', $userId, array_merge([
            'role' => $role,
        ], $meta));
    }

    public static function phoneVerified(int $userId, string $method = 'firebase'): void
    {
        self::track('phone_verified', $userId, [
            'method' => $method,
        ]);
    }

    public static function orderCreated(int $userId, int $orderId, float $amount, string $paymentMode): void
    {
        self::track('booking_created', $userId, [
            'order_id' => $orderId,
            'amount' => $amount,
            'payment_mode' => $paymentMode,
            'currency' => 'XOF',
        ]);
    }

    public static function paymentInitiated(int $userId, string $reference, float $amount, string $method): void
    {
        self::track('payment_initiated', $userId, [
            'reference' => $reference,
            'amount' => $amount,
            'method' => $method,
            'currency' => 'XOF',
        ]);
    }

    public static function paymentSuccess(int $userId, string $reference, float $amount, string $type = 'order'): void
    {
        self::track('payment_success', $userId, [
            'reference' => $reference,
            'amount' => $amount,
            'type' => $type,
            'currency' => 'XOF',
        ]);

        // Invalider les caches de revenus
        Cache::forget('revenue:today');
        Cache::forget('revenue:month');
        Cache::forget('revenue:stats');
    }

    public static function paymentFailed(int $userId, string $reference, ?string $reason = null): void
    {
        self::track('payment_failed', $userId, [
            'reference' => $reference,
            'reason' => $reason,
        ]);
    }

    public static function orderDelivered(int $userId, int $orderId, float $amount): void
    {
        self::track('order_delivered', $userId, [
            'order_id' => $orderId,
            'amount' => $amount,
        ]);
    }

    public static function orderCancelled(int $userId, int $orderId, ?string $reason = null, string $cancelledBy = 'customer'): void
    {
        self::track('order_cancelled', $userId, [
            'order_id' => $orderId,
            'reason' => $reason,
            'cancelled_by' => $cancelledBy,
        ]);
    }

    public static function walletTopup(int $userId, float $amount, string $method): void
    {
        self::track('wallet_topup', $userId, [
            'amount' => $amount,
            'method' => $method,
        ]);
    }

    public static function walletWithdrawal(int $userId, float $amount): void
    {
        self::track('wallet_withdrawal', $userId, [
            'amount' => $amount,
        ]);
    }

    public static function courierKycSubmitted(int $userId): void
    {
        self::track('kyc_submitted', $userId);
    }

    public static function pharmacyRegistered(int $userId, int $pharmacyId): void
    {
        self::track('pharmacy_registered', $userId, [
            'pharmacy_id' => $pharmacyId,
        ]);
    }

    // ──────────────────────────────────────────
    // UX FRICTION
    // ──────────────────────────────────────────

    public static function uxFriction(int $userId, string $screen, string $issue, array $meta = []): void
    {
        self::track('ux_friction', $userId, array_merge([
            'screen' => $screen,
            'issue' => $issue,
        ], $meta));
    }

    public static function apiError(int $userId, string $endpoint, int $statusCode, ?string $errorCode = null): void
    {
        self::track('api_error', $userId, [
            'endpoint' => $endpoint,
            'status_code' => $statusCode,
            'error_code' => $errorCode,
        ]);
    }

    // ──────────────────────────────────────────
    // MÉTRIQUES DE REVENUS
    // ──────────────────────────────────────────

    /**
     * Revenus du jour (cachés 5 min)
     */
    public static function todayRevenue(): array
    {
        return Cache::remember('revenue:today', 300, function () {
            $orders = DB::table('orders')
                ->whereDate('created_at', today())
                ->selectRaw("
                    COUNT(*) as total_orders,
                    COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered_orders,
                    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_orders,
                    COALESCE(SUM(CASE WHEN status = 'delivered' THEN total_amount ELSE 0 END), 0) as delivered_revenue,
                    COALESCE(SUM(total_amount), 0) as total_order_value
                ")
                ->first();

            $payments = DB::table('jeko_payments')
                ->whereDate('created_at', today())
                ->selectRaw("
                    COUNT(CASE WHEN status = 'completed' THEN 1 END) as successful_payments,
                    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_payments,
                    COALESCE(SUM(CASE WHEN status = 'completed' THEN amount_cents ELSE 0 END), 0) as total_collected
                ")
                ->first();

            $signups = DB::table('users')
                ->whereDate('created_at', today())
                ->selectRaw("
                    COUNT(*) as total,
                    COUNT(CASE WHEN role = 'customer' THEN 1 END) as customers,
                    COUNT(CASE WHEN role = 'courier' THEN 1 END) as couriers,
                    COUNT(CASE WHEN role = 'pharmacy' THEN 1 END) as pharmacies
                ")
                ->first();

            return [
                'date' => today()->toDateString(),
                'orders' => [
                    'total' => (int) $orders->total_orders,
                    'delivered' => (int) $orders->delivered_orders,
                    'cancelled' => (int) $orders->cancelled_orders,
                    'revenue' => (float) $orders->delivered_revenue,
                    'total_value' => (float) $orders->total_order_value,
                ],
                'payments' => [
                    'successful' => (int) $payments->successful_payments,
                    'failed' => (int) $payments->failed_payments,
                    'collected' => (float) $payments->total_collected,
                ],
                'signups' => [
                    'total' => (int) $signups->total,
                    'customers' => (int) $signups->customers,
                    'couriers' => (int) $signups->couriers,
                    'pharmacies' => (int) $signups->pharmacies,
                ],
                'currency' => 'XOF',
            ];
        });
    }

    /**
     * Stats globales revenus (cachées 10min)
     */
    public static function revenueStats(): array
    {
        return Cache::remember('revenue:stats', 600, function () {
            $today = today();
            $monthStart = $today->copy()->startOfMonth();
            $weekStart = $today->copy()->startOfWeek();
            $yesterday = $today->copy()->subDay();

            // Revenus par période
            $revenue = DB::table('orders')
                ->where('status', 'delivered')
                ->selectRaw("
                    COALESCE(SUM(CASE WHEN DATE(created_at) = ? THEN total_amount ELSE 0 END), 0) as today,
                    COALESCE(SUM(CASE WHEN DATE(created_at) = ? THEN total_amount ELSE 0 END), 0) as yesterday,
                    COALESCE(SUM(CASE WHEN created_at >= ? THEN total_amount ELSE 0 END), 0) as this_week,
                    COALESCE(SUM(CASE WHEN created_at >= ? THEN total_amount ELSE 0 END), 0) as this_month,
                    COALESCE(SUM(total_amount), 0) as all_time,
                    COUNT(*) as total_delivered
                ", [$today, $yesterday, $weekStart, $monthStart])
                ->first();

            // Commissions plateforme (service_fee)
            $commissions = DB::table('orders')
                ->where('status', 'delivered')
                ->selectRaw("
                    COALESCE(SUM(CASE WHEN DATE(created_at) = ? THEN service_fee ELSE 0 END), 0) as today,
                    COALESCE(SUM(CASE WHEN created_at >= ? THEN service_fee ELSE 0 END), 0) as this_month,
                    COALESCE(SUM(service_fee), 0) as all_time
                ", [$today, $monthStart])
                ->first();

            // Taux de conversion paiement
            $paymentConversion = DB::table('jeko_payments')
                ->where('created_at', '>=', $monthStart)
                ->selectRaw("
                    COUNT(*) as total,
                    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
                    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed
                ")
                ->first();

            $conversionRate = $paymentConversion->total > 0
                ? round(($paymentConversion->completed / $paymentConversion->total) * 100, 1)
                : 0;

            // Daily revenue trend (7 derniers jours)
            $dailyTrend = DB::table('orders')
                ->where('status', 'delivered')
                ->where('created_at', '>=', $today->copy()->subDays(7))
                ->selectRaw("DATE(created_at) as date, COALESCE(SUM(total_amount), 0) as revenue, COUNT(*) as orders")
                ->groupByRaw('DATE(created_at)')
                ->orderBy('date')
                ->get();

            return [
                'revenue' => [
                    'today' => (float) $revenue->today,
                    'yesterday' => (float) $revenue->yesterday,
                    'this_week' => (float) $revenue->this_week,
                    'this_month' => (float) $revenue->this_month,
                    'all_time' => (float) $revenue->all_time,
                    'total_delivered_orders' => (int) $revenue->total_delivered,
                ],
                'platform_commissions' => [
                    'today' => (float) $commissions->today,
                    'this_month' => (float) $commissions->this_month,
                    'all_time' => (float) $commissions->all_time,
                ],
                'payment_conversion' => [
                    'rate' => $conversionRate,
                    'total' => (int) $paymentConversion->total,
                    'completed' => (int) $paymentConversion->completed,
                    'failed' => (int) $paymentConversion->failed,
                ],
                'daily_trend' => $dailyTrend->map(fn($d) => [
                    'date' => $d->date,
                    'revenue' => (float) $d->revenue,
                    'orders' => (int) $d->orders,
                ])->values(),
                'currency' => 'XOF',
            ];
        });
    }

    // ──────────────────────────────────────────
    // CORE TRACKING
    // ──────────────────────────────────────────

    /**
     * Enregistre un événement business
     */
    public static function track(string $event, ?int $userId = null, array $properties = []): void
    {
        try {
            DB::table('business_events')->insert([
                'event' => $event,
                'user_id' => $userId,
                'properties' => json_encode($properties),
                'ip_address' => request()?->ip(),
                'user_agent' => request()?->userAgent(),
                'created_at' => now(),
            ]);

            // Log structuré pour analyse
            Log::channel('business')->info($event, array_merge([
                'user_id' => $userId,
            ], $properties));

        } catch (\Throwable $e) {
            // Ne jamais bloquer le flux business pour un tracking raté
            Log::warning('BusinessEvent tracking failed', [
                'event' => $event,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Lire les événements récents (admin)
     */
    public static function recentEvents(?string $event = null, int $limit = 50): array
    {
        $query = DB::table('business_events')
            ->orderByDesc('created_at')
            ->limit($limit);

        if ($event) {
            $query->where('event', $event);
        }

        return $query->get()->map(fn($row) => [
            'id' => $row->id,
            'event' => $row->event,
            'user_id' => $row->user_id,
            'properties' => json_decode($row->properties, true),
            'created_at' => $row->created_at,
        ])->toArray();
    }
}
