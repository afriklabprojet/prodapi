<?php

namespace App\Http\Controllers\Api\Pharmacy;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class PharmacyDashboardController extends Controller
{
    /**
     * Statistiques hebdomadaires pour le bandeau d'intelligence du tableau de bord.
     * Retourne les tendances de commandes, le pic d'activité et le stock critique.
     */
    public function weekStats(): JsonResponse
    {
        /** @var User|null $user */
        $user = Auth::user();

        if (! $user instanceof User) {
            abort(401, 'Unauthenticated.');
        }

        $pharmacy = $user->pharmacies()->firstOrFail();
        $pharmacyId = $pharmacy->id;

        $now = Carbon::now();

        // Semaine en cours : lundi 00:00 → maintenant
        $startOfThisWeek = $now->copy()->startOfWeek(Carbon::MONDAY);
        // Semaine dernière : lundi 00:00 → dimanche 23:59:59
        $startOfLastWeek = $startOfThisWeek->copy()->subWeek();
        $endOfLastWeek   = $startOfThisWeek->copy()->subSecond();

        // Comptes de commandes — on exclut les commandes non terminées (pending/cancelled)
        // pour ne pas fausser les statistiques avec des paniers abandonnés
        $thisWeekOrders = Order::forStats()
            ->where('pharmacy_id', $pharmacyId)
            ->where('created_at', '>=', $startOfThisWeek)
            ->count();

        $lastWeekOrders = Order::forStats()
            ->where('pharmacy_id', $pharmacyId)
            ->whereBetween('created_at', [$startOfLastWeek, $endOfLastWeek])
            ->count();

        // Tendance en pourcentage
        $trendPercent = null;
        if ($lastWeekOrders > 0) {
            $trendPercent = (int) round(
                ($thisWeekOrders - $lastWeekOrders) / $lastWeekOrders * 100
            );
        }

        // Pic d'activité : jour de la semaine (dernières 4 semaines) le plus chargé
        $peakDayLabel = null;
        $fourWeeksAgo = $now->copy()->subWeeks(4)->startOfWeek(Carbon::MONDAY);
        $driver = DB::getDriverName();
        if ($driver === 'sqlite') {
            // strftime('%w'): 0=dimanche, 1=lundi, …, 6=samedi
            $ordersByDay = Order::forStats()
                ->where('pharmacy_id', $pharmacyId)
                ->where('created_at', '>=', $fourWeeksAgo)
                ->selectRaw("CAST(strftime('%w', created_at) AS INTEGER) as dow, COUNT(*) as cnt")
                ->groupBy('dow')
                ->orderByDesc('cnt')
                ->first();

            if ($ordersByDay) {
                $days = [0 => 'Dim', 1 => 'Lun', 2 => 'Mar', 3 => 'Mer', 4 => 'Jeu', 5 => 'Ven', 6 => 'Sam'];
                $peakDayLabel = $days[$ordersByDay->dow] ?? null;
            }
        } else {
            $ordersByDay = Order::forStats()
                ->where('pharmacy_id', $pharmacyId)
                ->where('created_at', '>=', $fourWeeksAgo)
                ->selectRaw('DAYOFWEEK(created_at) as dow, COUNT(*) as cnt')
                ->groupBy('dow')
                ->orderByDesc('cnt')
                ->first();

            if ($ordersByDay) {
                // DAYOFWEEK: 1=dimanche, 2=lundi, …, 7=samedi (MySQL)
                $days = [1 => 'Dim', 2 => 'Lun', 3 => 'Mar', 4 => 'Mer', 5 => 'Jeu', 6 => 'Ven', 7 => 'Sam'];
                $peakDayLabel = $days[$ordersByDay->dow] ?? null;
            }
        }

        // Stock critique : produits en rupture ou seuil bas
        $criticalProductsCount = Product::where('pharmacy_id', $pharmacyId)
            ->where(function ($q) {
                $q->where('stock_quantity', '<=', 0)
                  ->orWhereRaw('stock_quantity > 0 AND stock_quantity <= low_stock_threshold');
            })
            ->count();

        // Produits expirant dans les 30 prochains jours
        $expiringProductsCount = Product::where('pharmacy_id', $pharmacyId)
            ->where('stock_quantity', '>', 0)
            ->whereNotNull('expiry_date')
            ->where('expiry_date', '>', $now)
            ->where('expiry_date', '<=', $now->copy()->addDays(30))
            ->count();

        // Produits déjà expirés
        $expiredProductsCount = Product::where('pharmacy_id', $pharmacyId)
            ->where('stock_quantity', '>', 0)
            ->whereNotNull('expiry_date')
            ->where('expiry_date', '<', $now)
            ->count();

        // ====== Breakdown revenu journalier (Lun→Dim) pour le widget RevenueChart ======
        // Revenu = SUM(total_amount) sur orders payées ou livrées (status delivered/completed
        // OU payment_status=paid), dans la semaine courante.
        $revenueStatuses = ['delivered', 'completed', 'paid'];
        $dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

        $dailyData = [];
        $thisWeekTotal = 0.0;
        for ($i = 0; $i < 7; $i++) {
            $dayStart = $startOfThisWeek->copy()->addDays($i)->startOfDay();
            $dayEnd   = $dayStart->copy()->endOfDay();
            $amount = (float) Order::where('pharmacy_id', $pharmacyId)
                ->whereBetween('created_at', [$dayStart, $dayEnd])
                ->where(function ($q) use ($revenueStatuses) {
                    $q->whereIn('status', $revenueStatuses)
                      ->orWhere('payment_status', 'paid');
                })
                ->sum('total_amount');
            $thisWeekTotal += $amount;
            $dailyData[] = [
                'day_label' => $dayLabels[$i],
                'amount'    => $amount,
                'date'      => $dayStart->toDateString(),
            ];
        }

        $lastWeekTotal = (float) Order::where('pharmacy_id', $pharmacyId)
            ->whereBetween('created_at', [$startOfLastWeek, $endOfLastWeek])
            ->where(function ($q) use ($revenueStatuses) {
                $q->whereIn('status', $revenueStatuses)
                  ->orWhere('payment_status', 'paid');
            })
            ->sum('total_amount');

        $percentChange = 0.0;
        if ($lastWeekTotal > 0) {
            $percentChange = round((($thisWeekTotal - $lastWeekTotal) / $lastWeekTotal) * 100, 1);
        } elseif ($thisWeekTotal > 0) {
            $percentChange = 100.0;
        }

        return response()->json([
            // Champs intelligence (compatibilité existante)
            'this_week_orders'        => $thisWeekOrders,
            'last_week_orders'        => $lastWeekOrders,
            'trend_percent'           => $trendPercent,
            'peak_day_label'          => $peakDayLabel,
            'critical_products_count' => $criticalProductsCount,
            'expiring_products_count' => $expiringProductsCount,
            'expired_products_count'  => $expiredProductsCount,
            // Champs revenu pour RevenueChartWidget
            'daily_data'              => $dailyData,
            'this_week_total'         => $thisWeekTotal,
            'last_week_total'         => $lastWeekTotal,
            'percent_change'          => $percentChange,
        ]);
    }

    /**
     * Statistiques quotidiennes pour le widget de performance quotidienne.
     * Retourne commandes/revenus aujourd'hui vs hier.
     */
    public function dailyStats(): JsonResponse
    {
        /** @var User|null $user */
        $user = Auth::user();

        if (! $user instanceof User) {
            abort(401, 'Unauthenticated.');
        }

        $pharmacy = $user->pharmacies()->firstOrFail();
        $pharmacyId = $pharmacy->id;

        $now = Carbon::now();
        $startOfToday = $now->copy()->startOfDay();
        $startOfYesterday = $startOfToday->copy()->subDay();
        $endOfYesterday = $startOfToday->copy()->subSecond();

        // Commandes aujourd'hui — exclut pending/cancelled (non terminées)
        $ordersToday = Order::forStats()
            ->where('pharmacy_id', $pharmacyId)
            ->where('created_at', '>=', $startOfToday)
            ->count();

        // Revenus aujourd'hui
        $revenueToday = Order::forStats()
            ->where('pharmacy_id', $pharmacyId)
            ->where('created_at', '>=', $startOfToday)
            ->whereIn('status', ['completed', 'delivered'])
            ->sum('subtotal');

        // Commandes hier — exclut pending/cancelled
        $ordersYesterday = Order::forStats()
            ->where('pharmacy_id', $pharmacyId)
            ->whereBetween('created_at', [$startOfYesterday, $endOfYesterday])
            ->count();

        // Revenus hier
        $revenueYesterday = Order::forStats()
            ->where('pharmacy_id', $pharmacyId)
            ->whereBetween('created_at', [$startOfYesterday, $endOfYesterday])
            ->whereIn('status', ['completed', 'delivered'])
            ->sum('subtotal');

        // Prescriptions aujourd'hui (si modèle existe)
        $prescriptionsToday = 0;
        $prescriptionsYesterday = 0;
        
        if (class_exists(\App\Models\Prescription::class)) {
            $prescriptionsToday = \App\Models\Prescription::where('pharmacy_id', $pharmacyId)
                ->where('created_at', '>=', $startOfToday)
                ->count();
            
            $prescriptionsYesterday = \App\Models\Prescription::where('pharmacy_id', $pharmacyId)
                ->whereBetween('created_at', [$startOfYesterday, $endOfYesterday])
                ->count();
        }

        return response()->json([
            'orders_today'           => $ordersToday,
            'orders_yesterday'       => $ordersYesterday,
            'revenue_today'          => (float) $revenueToday,
            'revenue_yesterday'      => (float) $revenueYesterday,
            'prescriptions_today'    => $prescriptionsToday,
            'prescriptions_yesterday'=> $prescriptionsYesterday,
            'daily_goal'             => 20, // TODO: Configurable par pharmacie
        ]);
    }
}
