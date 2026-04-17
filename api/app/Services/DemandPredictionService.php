<?php

namespace App\Services;

use App\Models\Courier;
use App\Models\Order;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class DemandPredictionService
{
    /**
     * Heures de pointe connues pour la livraison pharma
     */
    const PEAK_HOURS = [
        'morning' => [8, 9, 10, 11],
        'lunch' => [12, 13, 14],
        'evening' => [17, 18, 19, 20],
    ];

    /**
     * Prédire la demande pour les prochaines heures
     * Utilise un fallback statistique basé sur l'historique local.
     */
    public function predictDemand(string $zoneId, int $hoursAhead = 6): array
    {
        $cacheKey = "demand_prediction:{$zoneId}:{$hoursAhead}";

        return Cache::remember($cacheKey, 300, function () use ($zoneId, $hoursAhead) {
            $features = $this->buildPredictionFeatures($zoneId);
            $hourly = $this->generateHourlyPredictions($features, $hoursAhead);

            return [
                'zone_id' => $zoneId,
                'features' => $features,
                'hourly' => $hourly,
                'total_predicted' => collect($hourly)->sum('predicted_orders'),
                'confidence' => $this->calculateConfidence($features),
                'generated_at' => now()->toIso8601String(),
            ];
        });
    }

    /**
     * Construire les features pour la prédiction
     */
    protected function buildPredictionFeatures(string $zoneId): array
    {
        $now = now();

        return [
            'hour' => $now->hour,
            'day_of_week' => $now->dayOfWeek,
            'is_weekend' => $now->isWeekend(),
            'is_peak_hour' => $this->isPeakHour($now->hour),
            'peak_type' => $this->getPeakType($now->hour),
            'last_hour_orders' => $this->getOrderCount($zoneId, 1),
            'last_3h_orders' => $this->getOrderCount($zoneId, 3),
            'same_hour_last_week' => $this->getHistoricalOrderCount($zoneId, 7, $now->hour),
            'same_hour_2_weeks_ago' => $this->getHistoricalOrderCount($zoneId, 14, $now->hour),
            'avg_daily_orders_30d' => $this->getAverageDailyOrders($zoneId, 30),
            'active_couriers' => $this->getActiveCourierCount($zoneId),
        ];
    }

    /**
     * Générer des prédictions heure par heure
     */
    protected function generateHourlyPredictions(array $features, int $hoursAhead): array
    {
        $predictions = [];
        $now = now();

        for ($i = 0; $i < $hoursAhead; $i++) {
            $targetHour = ($features['hour'] + $i) % 24;
            $targetTime = $now->copy()->addHours($i);

            $basePrediction = $this->predictForHour($features, $targetHour, $targetTime);

            $predictions[] = [
                'hour' => $targetHour,
                'time' => $targetTime->format('H:i'),
                'predicted_orders' => max(0, round($basePrediction)),
                'is_peak' => $this->isPeakHour($targetHour),
                'confidence' => $this->hourConfidence($features, $i),
            ];
        }

        return $predictions;
    }

    /**
     * Prédiction pour une heure spécifique (moyenne pondérée historique)
     */
    protected function predictForHour(array $features, int $hour, Carbon $targetTime): float
    {
        // Moyenne pondérée : semaine dernière × 0.5, il y a 2 semaines × 0.2, tendance récente × 0.3
        $lastWeek = $this->getHistoricalOrderCount($features['zone_id'] ?? 'all', 7, $hour);
        $twoWeeksAgo = $this->getHistoricalOrderCount($features['zone_id'] ?? 'all', 14, $hour);
        $recentTrend = $features['last_hour_orders'] ?? 0;

        $prediction = ($lastWeek * 0.5) + ($twoWeeksAgo * 0.2) + ($recentTrend * 0.3);

        // Ajustements
        if ($this->isPeakHour($hour)) {
            $prediction *= 1.2;
        }

        if ($targetTime->isWeekend()) {
            $prediction *= 0.7; // Weekends généralement plus calmes pour la pharma
        }

        return $prediction;
    }

    /**
     * Recommander le nombre optimal de livreurs
     */
    public function recommendCourierCount(string $zoneId): array
    {
        $prediction = $this->predictDemand($zoneId, 4);

        $recommendations = collect($prediction['hourly'])
            ->map(function ($hour) {
                // 1 livreur pour ~3-4 commandes/heure
                $optimal = (int) ceil($hour['predicted_orders'] / 3.5);

                return [
                    'hour' => $hour['hour'],
                    'time' => $hour['time'],
                    'predicted_orders' => $hour['predicted_orders'],
                    'optimal_couriers' => max(1, $optimal),
                    'min_couriers' => max(1, $optimal - 1),
                    'max_couriers' => $optimal + 2,
                ];
            })
            ->toArray();

        return [
            'zone_id' => $zoneId,
            'recommendations' => $recommendations,
            'generated_at' => now()->toIso8601String(),
        ];
    }

    /**
     * Compter les commandes dans une fenêtre horaire
     */
    protected function getOrderCount(string $zoneId, int $hours): int
    {
        $query = Order::where('created_at', '>=', now()->subHours($hours));

        if ($zoneId !== 'all') {
            $query->whereHas('pharmacy', fn ($q) => $q->where('zone_id', $zoneId));
        }

        return $query->count();
    }

    /**
     * Commandes historiques pour un jour/heure donné
     */
    protected function getHistoricalOrderCount(string $zoneId, int $daysAgo, int $hour): int
    {
        $date = now()->subDays($daysAgo)->startOfDay()->addHours($hour);

        $query = Order::whereBetween('created_at', [
            $date,
            $date->copy()->addHour(),
        ]);

        if ($zoneId !== 'all') {
            $query->whereHas('pharmacy', fn ($q) => $q->where('zone_id', $zoneId));
        }

        return $query->count();
    }

    /**
     * Moyenne journalière sur N jours
     */
    protected function getAverageDailyOrders(string $zoneId, int $days): float
    {
        $total = Order::where('created_at', '>=', now()->subDays($days));

        if ($zoneId !== 'all') {
            $total->whereHas('pharmacy', fn ($q) => $q->where('zone_id', $zoneId));
        }

        $count = $total->count();

        return $days > 0 ? round($count / $days, 1) : 0;
    }

    /**
     * Livreurs actifs dans une zone
     */
    protected function getActiveCourierCount(string $zoneId): int
    {
        return Courier::where('status', 'available')
            ->whereNotNull('latitude')
            ->where('last_location_update', '>=', now()->subMinutes(10))
            ->count();
    }

    protected function isPeakHour(int $hour): bool
    {
        foreach (self::PEAK_HOURS as $hours) {
            if (in_array($hour, $hours)) {
                return true;
            }
        }
        return false;
    }

    protected function getPeakType(int $hour): ?string
    {
        foreach (self::PEAK_HOURS as $type => $hours) {
            if (in_array($hour, $hours)) {
                return $type;
            }
        }
        return null;
    }

    protected function calculateConfidence(array $features): float
    {
        $score = 0.5; // Base

        // Plus de données historiques = plus confiant
        if (($features['same_hour_last_week'] ?? 0) > 0) {
            $score += 0.2;
        }
        if (($features['avg_daily_orders_30d'] ?? 0) > 5) {
            $score += 0.2;
        }
        if (($features['last_hour_orders'] ?? 0) > 0) {
            $score += 0.1;
        }

        return min(1.0, round($score, 2));
    }

    protected function hourConfidence(array $features, int $hoursFromNow): float
    {
        // La confiance diminue avec le temps
        $base = $this->calculateConfidence($features);
        return round(max(0.2, $base - ($hoursFromNow * 0.05)), 2);
    }
}
