<?php

namespace App\Jobs;

use App\Mail\AdminAlertMail;
use App\Models\Courier;
use App\Models\Delivery;
use App\Models\JekoPayment;
use App\Models\Order;
use App\Models\SupportTicket;
use App\Models\User;
use App\Models\WalletTransaction;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

/**
 * Rapport quotidien d'activité envoyé à l'admin.
 *
 * Agrège les KPIs des dernières 24h :
 * - Commandes (total, livrées, annulées)
 * - Revenus et commissions
 * - Livraisons (temps moyen, taux de succès)
 * - Paiements (succès/échecs)
 * - Livreurs actifs
 * - Tickets support ouverts
 *
 * Exécuté tous les jours à 6h du matin.
 */
class DailyAdminDigestJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public int $timeout = 120;

    public function middleware(): array
    {
        return [new WithoutOverlapping('daily-admin-digest')];
    }

    public function handle(): void
    {
        $yesterday = now()->subDay();
        $today = now();

        $digest = [
            'period' => $yesterday->format('d/m/Y') . ' → ' . $today->format('d/m/Y'),
            'orders' => $this->getOrderStats($yesterday, $today),
            'revenue' => $this->getRevenueStats($yesterday, $today),
            'deliveries' => $this->getDeliveryStats($yesterday, $today),
            'payments' => $this->getPaymentStats($yesterday, $today),
            'couriers' => $this->getCourierStats(),
            'support' => $this->getSupportStats(),
            'users' => $this->getUserStats($yesterday, $today),
        ];

        Log::info('DailyAdminDigest: generated', $digest);

        try {
            Mail::to(config('mail.admin_address', 'admin@drlpharma.com'))
                ->send(new AdminAlertMail('daily_digest', $digest));
        } catch (\Throwable $e) {
            Log::warning('DailyAdminDigest: email failed', [
                'error' => $e->getMessage(),
            ]);
        }
    }

    private function getOrderStats($from, $to): array
    {
        $orders = Order::whereBetween('created_at', [$from, $to]);

        return [
            'total' => (clone $orders)->count(),
            'delivered' => (clone $orders)->where('status', 'delivered')->count(),
            'cancelled' => (clone $orders)->where('status', 'cancelled')->count(),
            'pending' => Order::where('status', 'pending')->count(),
            'avg_amount' => round((float) (clone $orders)->where('status', 'delivered')->avg('total_amount'), 0),
        ];
    }

    private function getRevenueStats($from, $to): array
    {
        $transactions = WalletTransaction::whereBetween('created_at', [$from, $to])
            ->where('status', 'completed');

        return [
            'total_credits' => round((float) (clone $transactions)->where('type', 'CREDIT')->sum('amount'), 0),
            'total_debits' => round((float) (clone $transactions)->where('type', 'DEBIT')->sum('amount'), 0),
            'total_delivery_fees' => round((float) Order::whereBetween('delivered_at', [$from, $to])
                ->where('status', 'delivered')
                ->sum('delivery_fee'), 0),
            'total_service_fees' => round((float) Order::whereBetween('delivered_at', [$from, $to])
                ->where('status', 'delivered')
                ->sum('service_fee'), 0),
        ];
    }

    private function getDeliveryStats($from, $to): array
    {
        $deliveries = Delivery::whereBetween('created_at', [$from, $to]);
        $completed = Delivery::whereBetween('delivered_at', [$from, $to])->where('status', 'delivered');

        $avgDuration = $completed->get()->avg(function ($d) {
            if ($d->accepted_at && $d->delivered_at) {
                return $d->accepted_at->diffInMinutes($d->delivered_at);
            }
            return null;
        });

        $total = (clone $deliveries)->count();
        $deliveredCount = (clone $deliveries)->where('status', 'delivered')->count();

        return [
            'total' => $total,
            'delivered' => $deliveredCount,
            'cancelled' => (clone $deliveries)->where('status', 'cancelled')->count(),
            'failed' => (clone $deliveries)->where('status', 'failed')->count(),
            'success_rate' => $total > 0 ? round(($deliveredCount / $total) * 100, 1) : 0,
            'avg_duration_minutes' => $avgDuration ? round($avgDuration) : null,
        ];
    }

    private function getPaymentStats($from, $to): array
    {
        $payments = JekoPayment::whereBetween('created_at', [$from, $to]);

        $total = (clone $payments)->count();
        $success = (clone $payments)->where('status', 'success')->count();

        return [
            'total' => $total,
            'success' => $success,
            'failed' => (clone $payments)->where('status', 'failed')->count(),
            'expired' => (clone $payments)->where('status', 'expired')->count(),
            'success_rate' => $total > 0 ? round(($success / $total) * 100, 1) : 0,
            'total_amount' => round((float) (clone $payments)->where('status', 'success')->sum('amount_cents') / 100, 0),
        ];
    }

    private function getCourierStats(): array
    {
        return [
            'total' => Courier::count(),
            'available' => Courier::where('status', 'available')->count(),
            'busy' => Courier::where('status', 'busy')->count(),
            'offline' => Courier::where('status', 'offline')->count(),
            'pending_kyc' => Courier::where('kyc_status', 'pending')->count(),
        ];
    }

    private function getSupportStats(): array
    {
        return [
            'open_tickets' => SupportTicket::where('status', 'open')->count(),
            'oldest_open_days' => SupportTicket::where('status', 'open')
                ->orderBy('created_at')
                ->first()?->created_at?->diffInDays(now()),
        ];
    }

    private function getUserStats($from, $to): array
    {
        return [
            'new_customers' => User::where('role', 'customer')
                ->whereBetween('created_at', [$from, $to])
                ->count(),
            'total_customers' => User::where('role', 'customer')->count(),
        ];
    }

    public function failed(\Throwable $exception): void
    {
        Log::error('DailyAdminDigestJob failed', [
            'error' => $exception->getMessage(),
        ]);
    }
}
