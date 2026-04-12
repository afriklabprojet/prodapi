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

        // Comptes de commandes
        $thisWeekOrders = Order::where('pharmacy_id', $pharmacyId)
            ->where('created_at', '>=', $startOfThisWeek)
            ->count();

        $lastWeekOrders = Order::where('pharmacy_id', $pharmacyId)
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
            $ordersByDay = Order::where('pharmacy_id', $pharmacyId)
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
            $ordersByDay = Order::where('pharmacy_id', $pharmacyId)
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

        return response()->json([
            'this_week_orders'        => $thisWeekOrders,
            'last_week_orders'        => $lastWeekOrders,
            'trend_percent'           => $trendPercent,
            'peak_day_label'          => $peakDayLabel,
            'critical_products_count' => $criticalProductsCount,
            'expiring_products_count' => $expiringProductsCount,
            'expired_products_count'  => $expiredProductsCount,
        ]);
    }
}
