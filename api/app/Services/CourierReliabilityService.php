<?php

namespace App\Services;

use App\Models\Courier;
use App\Models\Delivery;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CourierReliabilityService
{
    /**
     * Métriques et leur poids dans le score global
     */
    const METRIC_WEIGHTS = [
        'acceptance_rate' => 0.20,      // Taux d'acceptation des offres
        'completion_rate' => 0.40,      // Taux de livraisons complétées
        'on_time_rate' => 0.30,         // Taux de ponctualité
        'rating_score' => 0.10,         // Note moyenne client
    ];

    /**
     * Seuils de performance
     */
    const PERFORMANCE_THRESHOLDS = [
        'excellent' => 90,
        'good' => 75,
        'average' => 60,
        'poor' => 40,
    ];

    /**
     * Période d'analyse par défaut (en jours)
     */
    const DEFAULT_ANALYSIS_PERIOD = 30;

    /**
     * Recalculer toutes les métriques de fiabilité d'un livreur
     */
    public function recalculateMetrics(Courier $courier, int $periodDays = self::DEFAULT_ANALYSIS_PERIOD): array
    {
        $startDate = now()->subDays($periodDays);

        $metrics = [
            'acceptance_rate' => $this->calculateAcceptanceRate($courier, $startDate),
            'completion_rate' => $this->calculateCompletionRate($courier, $startDate),
            'on_time_rate' => $this->calculateOnTimeRate($courier, $startDate),
            'rating_score' => $this->normalizeRating($courier->rating ?? 0),
        ];

        // Calculer le score global
        $reliabilityScore = $this->calculateWeightedScore($metrics);

        // Mettre à jour le livreur
        $courier->update([
            'acceptance_rate' => $metrics['acceptance_rate'],
            'completion_rate' => $metrics['completion_rate'],
            'on_time_rate' => $metrics['on_time_rate'],
            'reliability_score' => $reliabilityScore,
        ]);

        Log::info("CourierReliability: Updated metrics for courier {$courier->id}", [
            'metrics' => $metrics,
            'reliability_score' => $reliabilityScore,
        ]);

        return [
            'metrics' => $metrics,
            'reliability_score' => $reliabilityScore,
            'performance_level' => $this->getPerformanceLevel($reliabilityScore),
        ];
    }

    /**
     * Calculer le taux d'acceptation des offres
     */
    protected function calculateAcceptanceRate(Courier $courier, $startDate): float
    {
        // Offres reçues
        $totalOffers = $courier->deliveryOffers()
            ->where('created_at', '>=', $startDate)
            ->count();

        if ($totalOffers === 0) {
            return 100.0; // Pas d'offres = pas de refus
        }

        // Offres acceptées
        $acceptedOffers = $courier->acceptedOffers()
            ->where('created_at', '>=', $startDate)
            ->count();

        return round(($acceptedOffers / $totalOffers) * 100, 2);
    }

    /**
     * Calculer le taux de complétion des livraisons
     */
    protected function calculateCompletionRate(Courier $courier, $startDate): float
    {
        $totalAssigned = Delivery::where('courier_id', $courier->id)
            ->where('created_at', '>=', $startDate)
            ->count();

        if ($totalAssigned === 0) {
            return 100.0;
        }

        $completed = Delivery::where('courier_id', $courier->id)
            ->where('created_at', '>=', $startDate)
            ->whereIn('status', ['delivered', 'completed'])
            ->count();

        return round(($completed / $totalAssigned) * 100, 2);
    }

    /**
     * Calculer le taux de ponctualité
     */
    protected function calculateOnTimeRate(Courier $courier, $startDate): float
    {
        $deliveries = Delivery::where('courier_id', $courier->id)
            ->where('created_at', '>=', $startDate)
            ->whereIn('status', ['delivered', 'completed'])
            ->whereNotNull('original_eta_seconds')
            ->whereNotNull('completed_at')
            ->get();

        if ($deliveries->isEmpty()) {
            return 100.0;
        }

        $onTime = $deliveries->filter(function ($delivery) {
            if (!$delivery->assigned_at || !$delivery->completed_at) {
                return true;
            }

            $actualSeconds = $delivery->assigned_at->diffInSeconds($delivery->completed_at);
            // Tolérance de 5 minutes
            return $actualSeconds <= ($delivery->original_eta_seconds + 300);
        })->count();

        return round(($onTime / $deliveries->count()) * 100, 2);
    }

    /**
     * Normaliser la note (0-5 → 0-100)
     */
    protected function normalizeRating(float $rating): float
    {
        return ($rating / 5) * 100;
    }

    /**
     * Calculer le score pondéré
     */
    protected function calculateWeightedScore(array $metrics): float
    {
        $score = 0;

        foreach (self::METRIC_WEIGHTS as $metric => $weight) {
            $score += ($metrics[$metric] ?? 0) * $weight;
        }

        return round($score, 2);
    }

    /**
     * Obtenir le niveau de performance
     */
    public function getPerformanceLevel(float $score): string
    {
        if ($score >= self::PERFORMANCE_THRESHOLDS['excellent']) {
            return 'excellent';
        }
        if ($score >= self::PERFORMANCE_THRESHOLDS['good']) {
            return 'good';
        }
        if ($score >= self::PERFORMANCE_THRESHOLDS['average']) {
            return 'average';
        }
        if ($score >= self::PERFORMANCE_THRESHOLDS['poor']) {
            return 'poor';
        }
        return 'critical';
    }

    /**
     * Mettre à jour après une livraison complétée
     */
    public function onDeliveryCompleted(Delivery $delivery): void
    {
        $courier = $delivery->courier;
        
        if (!$courier) {
            return;
        }

        // Recalculer les métriques
        $this->recalculateMetrics($courier);

        // Vérifier la ponctualité de cette livraison
        if ($delivery->original_eta_seconds && $delivery->assigned_at && $delivery->completed_at) {
            $actualSeconds = $delivery->assigned_at->diffInSeconds($delivery->completed_at);
            $wasOnTime = $actualSeconds <= ($delivery->original_eta_seconds + 300);

            // Mettre à jour le speed factor
            app(EtaService::class)->updateCourierSpeedFactor($courier, $delivery);

            Log::info("CourierReliability: Delivery {$delivery->id} completed", [
                'courier_id' => $courier->id,
                'expected_seconds' => $delivery->original_eta_seconds,
                'actual_seconds' => $actualSeconds,
                'on_time' => $wasOnTime,
            ]);
        }
    }

    /**
     * Mettre à jour après une livraison annulée
     */
    public function onDeliveryCancelled(Delivery $delivery): void
    {
        $courier = $delivery->courier;
        
        if (!$courier) {
            return;
        }

        // Recalculer (la complétion aura baissé)
        $this->recalculateMetrics($courier);

        Log::warning("CourierReliability: Delivery {$delivery->id} cancelled", [
            'courier_id' => $courier->id,
        ]);
    }

    /**
     * Identifier les livreurs à risque
     */
    public function getAtRiskCouriers(): array
    {
        return Courier::where('kyc_status', 'verified')
            ->where('reliability_score', '<', self::PERFORMANCE_THRESHOLDS['poor'])
            ->get()
            ->map(function ($courier) {
                return [
                    'courier_id' => $courier->id,
                    'name' => $courier->name,
                    'reliability_score' => $courier->reliability_score,
                    'acceptance_rate' => $courier->acceptance_rate,
                    'completion_rate' => $courier->completion_rate,
                    'on_time_rate' => $courier->on_time_rate,
                    'performance_level' => $this->getPerformanceLevel($courier->reliability_score),
                ];
            })
            ->toArray();
    }

    /**
     * Obtenir les top performers
     */
    public function getTopPerformers(int $limit = 10): array
    {
        return Courier::where('kyc_status', 'verified')
            ->where('reliability_score', '>=', self::PERFORMANCE_THRESHOLDS['excellent'])
            ->orderByDesc('reliability_score')
            ->limit($limit)
            ->get()
            ->map(function ($courier) {
                return [
                    'courier_id' => $courier->id,
                    'name' => $courier->name,
                    'reliability_score' => $courier->reliability_score,
                    'completed_deliveries' => $courier->completed_deliveries,
                    'tier' => $courier->tier,
                ];
            })
            ->toArray();
    }

    /**
     * Générer un rapport de fiabilité pour un livreur
     */
    public function generateReport(Courier $courier): array
    {
        $metrics = $this->recalculateMetrics($courier);

        // Statistiques détaillées
        $last30Days = now()->subDays(30);
        
        $deliveryStats = Delivery::where('courier_id', $courier->id)
            ->where('created_at', '>=', $last30Days)
            ->selectRaw('
                COUNT(*) as total,
                SUM(CASE WHEN status IN ("delivered", "completed") THEN 1 ELSE 0 END) as completed,
                SUM(CASE WHEN status = "cancelled" THEN 1 ELSE 0 END) as cancelled,
                AVG(' . db_timestampdiff('SECOND', 'assigned_at', 'completed_at') . ') as avg_duration
            ')
            ->first();

        return [
            'courier' => [
                'id' => $courier->id,
                'name' => $courier->name,
                'tier' => $courier->tier,
                'total_xp' => $courier->total_xp,
            ],
            'reliability' => $metrics,
            'last_30_days' => [
                'total_deliveries' => $deliveryStats->total ?? 0,
                'completed' => $deliveryStats->completed ?? 0,
                'cancelled' => $deliveryStats->cancelled ?? 0,
                'avg_duration_minutes' => round(($deliveryStats->avg_duration ?? 0) / 60, 1),
            ],
            'recommendations' => $this->generateRecommendations($courier, $metrics),
        ];
    }

    /**
     * Générer des recommandations d'amélioration
     */
    protected function generateRecommendations(Courier $courier, array $metrics): array
    {
        $recommendations = [];

        if ($metrics['metrics']['acceptance_rate'] < 70) {
            $recommendations[] = [
                'type' => 'acceptance',
                'priority' => 'high',
                'message' => 'Votre taux d\'acceptation est bas. Acceptez plus d\'offres pour améliorer votre score.',
            ];
        }

        if ($metrics['metrics']['on_time_rate'] < 80) {
            $recommendations[] = [
                'type' => 'punctuality',
                'priority' => 'medium',
                'message' => 'Essayez de respecter les délais de livraison pour améliorer votre ponctualité.',
            ];
        }

        if ($metrics['metrics']['completion_rate'] < 95) {
            $recommendations[] = [
                'type' => 'completion',
                'priority' => 'high',
                'message' => 'Évitez d\'annuler des livraisons pour maintenir un bon taux de complétion.',
            ];
        }

        return $recommendations;
    }
}
