<?php

namespace App\Http\Controllers\Api\Courier;

use App\Http\Controllers\Controller;
use App\Models\Courier;
use App\Models\Delivery;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class StatisticsController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $courier = $request->user()->courier;
        
        if (!$courier) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Profil coursier non trouvé',
                'error_code' => 'COURIER_PROFILE_NOT_FOUND',
            ], 403);
        }
        
        $period = $request->input('period', 'week');
        
        // Déterminer les dates selon la période
        [$startDate, $endDate] = $this->getPeriodDates($period);
        
        // Récupérer les livraisons pour la période
        $deliveries = Delivery::where('courier_id', $courier->id)
            ->whereBetween('created_at', [$startDate, $endDate])
            ->get();
        
        // Livraisons de la période précédente pour calculer les tendances
        $previousPeriodDays = $startDate->diffInDays($endDate) + 1;
        $previousStartDate = $startDate->copy()->subDays($previousPeriodDays);
        $previousEndDate = $startDate->copy()->subDay();
        
        $previousDeliveries = Delivery::where('courier_id', $courier->id)
            ->whereBetween('created_at', [$previousStartDate, $previousEndDate])
            ->get();
        
        // Calculer les statistiques
        $deliveredDeliveries = $deliveries->where('status', 'delivered');
        $previousDelivered = $previousDeliveries->where('status', 'delivered');
        
        $totalDeliveries = $deliveredDeliveries->count();
        $previousTotalDeliveries = $previousDelivered->count();
        
        $totalEarnings = $deliveredDeliveries->sum('delivery_fee') ?? 0;
        $previousEarnings = $previousDelivered->sum('delivery_fee') ?? 0;
        
        // Calculer les tendances
        $deliveryTrend = $previousTotalDeliveries > 0 
            ? (($totalDeliveries - $previousTotalDeliveries) / $previousTotalDeliveries) * 100 
            : ($totalDeliveries > 0 ? 100 : 0);
        $earningsTrend = $previousEarnings > 0 
            ? (($totalEarnings - $previousEarnings) / $previousEarnings) * 100 
            : ($totalEarnings > 0 ? 100 : 0);
        
        // Breakdown quotidien
        $dailyBreakdown = $this->getDailyBreakdown($courier->id, $startDate, $endDate);
        
        // Heures de pointe
        $peakHours = $this->getPeakHours($courier->id, $startDate, $endDate);
        
        // Performance
        $totalAssigned = $deliveries->count();
        $totalAccepted = $deliveries->whereNotIn('status', ['pending', 'cancelled'])->count();
        $totalDelivered = $deliveredDeliveries->count();
        $totalCancelled = $deliveries->where('status', 'cancelled')->count();
        
        $stats = [
            'period' => $period,
            'start_date' => $startDate->toDateString(),
            'end_date' => $endDate->toDateString(),
            'overview' => [
                'total_deliveries' => $totalDeliveries,
                'total_earnings' => round($totalEarnings, 2),
                'total_distance_km' => round($deliveredDeliveries->sum('distance_km') ?? 0, 2),
                'total_duration_minutes' => (int) $deliveredDeliveries->sum('duration_minutes') ?? 0,
                'average_rating' => round($courier->rating ?? 0, 2),
                'delivery_trend' => round($deliveryTrend, 1),
                'earnings_trend' => round($earningsTrend, 1),
                'currency' => 'FCFA',
            ],
            'performance' => [
                'total_assigned' => $totalAssigned,
                'total_accepted' => $totalAccepted,
                'total_delivered' => $totalDelivered,
                'total_cancelled' => $totalCancelled,
                'acceptance_rate' => $totalAssigned > 0 ? round(($totalAccepted / $totalAssigned) * 100, 1) : 0,
                'completion_rate' => $totalAccepted > 0 ? round(($totalDelivered / $totalAccepted) * 100, 1) : 0,
                'cancellation_rate' => $totalAssigned > 0 ? round(($totalCancelled / $totalAssigned) * 100, 1) : 0,
                'on_time_rate' => $this->calculateOnTimeRate($deliveredDeliveries),
                'satisfaction_rate' => round($courier->rating ? ($courier->rating / 5) * 100 : 0, 1),
            ],
            'daily_breakdown' => $dailyBreakdown,
            'peak_hours' => $peakHours,
            'revenue_breakdown' => [
                'delivery_commissions' => [
                    'amount' => round($totalEarnings, 2),
                    'percentage' => 100.0,
                ],
                'challenge_bonuses' => [
                    'amount' => 0.0,
                    'percentage' => 0.0,
                ],
                'rush_bonuses' => [
                    'amount' => 0.0,
                    'percentage' => 0.0,
                ],
                'total' => round($totalEarnings, 2),
            ],
            'goals' => [
                'weekly_target' => 20,
                'current_progress' => $totalDeliveries,
                'progress_percentage' => min(round(($totalDeliveries / 20) * 100, 1), 100),
                'remaining' => max(20 - $totalDeliveries, 0),
            ],
        ];

        return response()->json([
            'success' => true,
            'data' => $stats,
        ]);
    }
    
    /**
     * Obtenir les dates de début et fin selon la période
     */
    private function getPeriodDates(string $period): array
    {
        $now = now();
        
        return match($period) {
            'today' => [$now->copy()->startOfDay(), $now->copy()->endOfDay()],
            'week' => [$now->copy()->startOfWeek(), $now->copy()->endOfWeek()],
            'month' => [$now->copy()->startOfMonth(), $now->copy()->endOfMonth()],
            'year' => [$now->copy()->startOfYear(), $now->copy()->endOfYear()],
            default => [$now->copy()->startOfWeek(), $now->copy()->endOfWeek()],
        };
    }
    
    /**
     * Obtenir le breakdown quotidien
     */
    private function getDailyBreakdown(int $courierId, Carbon $startDate, Carbon $endDate): array
    {
        $days = [];
        $frenchDays = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
        
        $deliveries = Delivery::where('courier_id', $courierId)
            ->where('status', 'delivered')
            ->whereBetween('created_at', [$startDate, $endDate])
            ->get()
            ->groupBy(fn($d) => $d->created_at->toDateString());
        
        $current = $startDate->copy();
        while ($current <= $endDate) {
            $dateKey = $current->toDateString();
            $dayDeliveries = $deliveries->get($dateKey, collect());
            
            $days[] = [
                'date' => $dateKey,
                'day_name' => $frenchDays[$current->dayOfWeek],
                'deliveries' => $dayDeliveries->count(),
                'earnings' => round($dayDeliveries->sum('delivery_fee') ?? 0, 2),
            ];
            
            $current->addDay();
        }
        
        return $days;
    }
    
    /**
     * Obtenir les heures de pointe
     */
    private function getPeakHours(int $courierId, Carbon $startDate, Carbon $endDate): array
    {
        $hourLabels = [
            '08' => '8h-9h', '09' => '9h-10h', '10' => '10h-11h', '11' => '11h-12h',
            '12' => '12h-13h', '13' => '13h-14h', '14' => '14h-15h', '15' => '15h-16h',
            '16' => '16h-17h', '17' => '17h-18h', '18' => '18h-19h', '19' => '19h-20h',
            '20' => '20h-21h', '21' => '21h-22h',
        ];
        
        $hourly = Delivery::where('courier_id', $courierId)
            ->where('status', 'delivered')
            ->whereBetween('created_at', [$startDate, $endDate])
            ->selectRaw('HOUR(created_at) as hour, COUNT(*) as count')
            ->groupBy('hour')
            ->orderByDesc('count')
            ->limit(5)
            ->pluck('count', 'hour')
            ->toArray();
        
        $total = array_sum($hourly);
        $peakHours = [];
        
        foreach ($hourly as $hour => $count) {
            $hourStr = str_pad($hour, 2, '0', STR_PAD_LEFT);
            $peakHours[] = [
                'hour' => $hourStr,
                'label' => $hourLabels[$hourStr] ?? "{$hour}h",
                'count' => $count,
                'percentage' => $total > 0 ? round(($count / $total) * 100, 1) : 0,
            ];
        }
        
        // Si aucune donnée, retourner des heures vides par défaut
        if (empty($peakHours)) {
            $peakHours = [
                ['hour' => '12', 'label' => '12h-13h', 'count' => 0, 'percentage' => 0],
                ['hour' => '18', 'label' => '18h-19h', 'count' => 0, 'percentage' => 0],
            ];
        }
        
        return $peakHours;
    }

    /**
     * Calculer le taux de livraisons à l'heure
     * 
     * Une livraison est considérée "à l'heure" si le temps réel de livraison
     * (delivered_at - picked_up_at) ne dépasse pas le temps estimé + 15 minutes de marge
     */
    private function calculateOnTimeRate($deliveredDeliveries): float
    {
        // Filtrer les livraisons avec toutes les données nécessaires
        $deliveriesWithTimeData = $deliveredDeliveries->filter(function ($delivery) {
            return $delivery->picked_up_at 
                && $delivery->delivered_at 
                && $delivery->estimated_duration > 0;
        });

        if ($deliveriesWithTimeData->isEmpty()) {
            return 0.0; // Pas de données pour calculer
        }

        $onTimeCount = 0;
        $marginMinutes = 15; // Marge de tolérance en minutes

        foreach ($deliveriesWithTimeData as $delivery) {
            // Temps réel en minutes
            $actualMinutes = $delivery->picked_up_at->diffInMinutes($delivery->delivered_at);
            
            // Temps estimé + marge
            $allowedMinutes = $delivery->estimated_duration + $marginMinutes;

            if ($actualMinutes <= $allowedMinutes) {
                $onTimeCount++;
            }
        }

        return round(($onTimeCount / $deliveriesWithTimeData->count()) * 100, 1);
    }

    public function leaderboard(Request $request): JsonResponse
    {
        $couriers = Courier::select('id', 'name', 'completed_deliveries', 'rating')
            ->where('status', 'available')
            ->orderByDesc('completed_deliveries')
            ->limit(20)
            ->get()
            ->map(fn ($c, $i) => [
                'rank' => $i + 1,
                'name' => $c->name,
                'deliveries' => $c->completed_deliveries,
                'rating' => round($c->rating ?? 0, 2),
            ]);

        return response()->json([
            'success' => true,
            'data' => $couriers,
        ]);
    }

    /**
     * GET /courier/statistics/today
     * Quick snapshot of today's stats.
     */
    public function today(Request $request): JsonResponse
    {
        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json(['success' => false, 'message' => 'Profil coursier non trouvé'], 403);
        }

        $startOfDay = Carbon::today();
        $endOfDay   = Carbon::tomorrow();

        $deliveries = Delivery::where('courier_id', $courier->id)
            ->whereBetween('created_at', [$startOfDay, $endOfDay])
            ->get();

        $delivered  = $deliveries->where('status', 'delivered');
        $earnings   = (float) $delivered->sum('courier_fee');

        return response()->json([
            'success' => true,
            'data'    => [
                'date'                => $startOfDay->toDateString(),
                'deliveries_total'    => $deliveries->count(),
                'deliveries_completed'=> $delivered->count(),
                'deliveries_pending'  => $deliveries->whereIn('status', ['accepted', 'picked_up'])->count(),
                'earnings_today'      => $earnings,
                'currency'            => 'XOF',
                'on_time_rate'        => $this->calculateOnTimeRate($delivered),
            ],
        ]);
    }

    /**
     * GET /courier/me/next-mission-preview
     * Preview of the next available delivery offer in the courier's zone.
     */
    public function nextMissionPreview(Request $request): JsonResponse
    {
        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json(['success' => false, 'message' => 'Profil coursier non trouvé'], 403);
        }

        $nextOffer = \App\Models\DeliveryOffer::where('status', 'pending')
            ->whereDoesntHave('couriers', fn ($q) => $q->where('courier_id', $courier->id))
            ->latest()
            ->first();

        if (!$nextOffer) {
            return response()->json([
                'success' => true,
                'data'    => null,
                'message' => 'Aucune livraison disponible pour le moment',
            ]);
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'offer_id'           => $nextOffer->id,
                'estimated_distance' => $nextOffer->estimated_distance ?? 0,
                'estimated_fee'      => $nextOffer->courier_fee ?? 0,
                'pickup_address'     => $nextOffer->pickup_address ?? null,
                'delivery_address'   => $nextOffer->delivery_address ?? null,
                'expires_at'         => $nextOffer->expires_at?->toIso8601String(),
            ],
        ]);
    }
}
