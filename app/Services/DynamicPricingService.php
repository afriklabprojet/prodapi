<?php

namespace App\Services;

use App\Models\Order;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class DynamicPricingService
{
    /**
     * Configuration du surge pricing
     */
    const BASE_SURGE_MULTIPLIER = 1.0;
    const MAX_SURGE_MULTIPLIER = 2.5;

    // Seuils de demande (ordres en attente / livreurs disponibles)
    const SURGE_THRESHOLDS = [
        ['threshold' => 1.5, 'multiplier' => 1.2],  // 1.5x demande → 1.2x prix
        ['threshold' => 2.0, 'multiplier' => 1.4],  // 2.0x demande → 1.4x prix
        ['threshold' => 2.5, 'multiplier' => 1.6],  // 2.5x demande → 1.6x prix
        ['threshold' => 3.0, 'multiplier' => 1.8],  // 3.0x demande → 1.8x prix
        ['threshold' => 4.0, 'multiplier' => 2.0],  // 4.0x demande → 2.0x prix
        ['threshold' => 5.0, 'multiplier' => 2.5],  // 5.0x demande → 2.5x prix
    ];

    // Heures de pointe
    const PEAK_HOURS = [
        'lunch' => ['start' => 11, 'end' => 14],
        'dinner' => ['start' => 18, 'end' => 22],
    ];

    const PEAK_HOUR_BONUS_PERCENT = 15;

    // Conditions météo (bonus pour intempéries)
    const WEATHER_MULTIPLIERS = [
        'clear' => 1.0,
        'cloudy' => 1.0,
        'rain' => 1.3,
        'heavy_rain' => 1.5,
        'storm' => 1.8,
    ];

    /**
     * Calculer le multiplicateur de surge actuel pour une zone
     */
    public function getSurgeMultiplier(?string $zoneId = null): float
    {
        $cacheKey = "surge_multiplier_" . ($zoneId ?? 'global');
        
        return Cache::remember($cacheKey, 60, function () use ($zoneId) {
            return $this->calculateSurgeMultiplier($zoneId);
        });
    }

    /**
     * Calculer le multiplicateur de surge
     */
    protected function calculateSurgeMultiplier(?string $zoneId = null): float
    {
        $demandRatio = $this->getDemandSupplyRatio($zoneId);
        $peakMultiplier = $this->getPeakHourMultiplier();
        $weatherMultiplier = $this->getWeatherMultiplier($zoneId);

        // Trouver le seuil applicable
        $surgeFromDemand = self::BASE_SURGE_MULTIPLIER;
        foreach (self::SURGE_THRESHOLDS as $config) {
            if ($demandRatio >= $config['threshold']) {
                $surgeFromDemand = $config['multiplier'];
            }
        }

        // Combiner les multiplicateurs (moyenne pondérée)
        $combined = ($surgeFromDemand * 0.5) + 
                    ($peakMultiplier * 0.3) + 
                    ($weatherMultiplier * 0.2);

        return min($combined, self::MAX_SURGE_MULTIPLIER);
    }

    /**
     * Obtenir le ratio demande/offre
     */
    protected function getDemandSupplyRatio(?string $zoneId = null): float
    {
        // Compter les ordres en attente
        $pendingOrders = Order::where('status', 'confirmed')
            ->whereNull('courier_id')
            ->when($zoneId, function ($q) use ($zoneId) {
                // Filtrer par zone si spécifié
                // TODO: Implémenter le filtrage par zone
            })
            ->count();

        // Compter les livreurs disponibles
        $availableCouriers = \App\Models\Courier::available()
            ->whereNotNull('last_location_update')
            ->where('last_location_update', '>=', now()->subMinutes(10))
            ->count();

        if ($availableCouriers === 0) {
            return 10.0; // Maximum si aucun livreur
        }

        return $pendingOrders / $availableCouriers;
    }

    /**
     * Obtenir le multiplicateur heure de pointe
     */
    protected function getPeakHourMultiplier(): float
    {
        $currentHour = (int) now()->format('H');

        foreach (self::PEAK_HOURS as $period => $hours) {
            if ($currentHour >= $hours['start'] && $currentHour < $hours['end']) {
                return 1 + (self::PEAK_HOUR_BONUS_PERCENT / 100);
            }
        }

        return 1.0;
    }

    /**
     * Obtenir le multiplicateur météo
     */
    protected function getWeatherMultiplier(?string $zoneId = null): float
    {
        // TODO: Intégrer une API météo (OpenWeather, etc.)
        // Pour l'instant, retourner la valeur par défaut
        $weather = Cache::get("weather_{$zoneId}", 'clear');
        
        return self::WEATHER_MULTIPLIERS[$weather] ?? 1.0;
    }

    /**
     * Mettre à jour les conditions météo pour une zone
     */
    public function updateWeather(string $zoneId, string $condition): void
    {
        if (!isset(self::WEATHER_MULTIPLIERS[$condition])) {
            $condition = 'clear';
        }

        Cache::put("weather_{$zoneId}", $condition, 3600);
        
        // Invalider le cache du surge
        Cache::forget("surge_multiplier_{$zoneId}");
    }

    /**
     * Calculer les frais de surge pour une commande
     */
    public function calculateSurgeFee(Order $order): int
    {
        $zoneId = $this->getZoneIdForOrder($order);
        $surgeMultiplier = $this->getSurgeMultiplier($zoneId);

        if ($surgeMultiplier <= 1.0) {
            return 0;
        }

        // Calculer le supplément
        $baseFee = $order->delivery_fee;
        $surgeAmount = (int) round($baseFee * ($surgeMultiplier - 1));

        return $surgeAmount;
    }

    /**
     * Calculer le prix total avec surge
     */
    public function calculateTotalDeliveryFee(Order $order): array
    {
        $baseFee = $order->delivery_fee;
        $surgeFee = $this->calculateSurgeFee($order);
        $zoneId = $this->getZoneIdForOrder($order);
        $multiplier = $this->getSurgeMultiplier($zoneId);

        return [
            'base_fee' => $baseFee,
            'surge_fee' => $surgeFee,
            'total_fee' => $baseFee + $surgeFee,
            'surge_multiplier' => $multiplier,
            'surge_active' => $multiplier > 1.0,
        ];
    }

    /**
     * Obtenir l'ID de zone pour une commande
     */
    protected function getZoneIdForOrder(Order $order): ?string
    {
        // TODO: Implémenter le système de zones géographiques
        // Pour l'instant, utiliser la ville de la pharmacie
        return $order->pharmacy?->city ?? 'default';
    }

    /**
     * Vérifier si c'est une heure de pointe
     */
    public function isPeakHour(): bool
    {
        return $this->getPeakHourMultiplier() > 1.0;
    }

    /**
     * Obtenir le statut actuel du surge
     */
    public function getSurgeStatus(?string $zoneId = null): array
    {
        $multiplier = $this->getSurgeMultiplier($zoneId);
        $ratio = $this->getDemandSupplyRatio($zoneId);

        return [
            'multiplier' => $multiplier,
            'is_active' => $multiplier > 1.0,
            'level' => $this->getSurgeLevel($multiplier),
            'demand_ratio' => round($ratio, 2),
            'is_peak_hour' => $this->isPeakHour(),
        ];
    }

    /**
     * Obtenir le niveau de surge (low, medium, high, extreme)
     */
    protected function getSurgeLevel(float $multiplier): string
    {
        if ($multiplier <= 1.0) return 'none';
        if ($multiplier <= 1.3) return 'low';
        if ($multiplier <= 1.6) return 'medium';
        if ($multiplier <= 2.0) return 'high';
        return 'extreme';
    }

    /**
     * Informer le client du surge pricing avant commande
     */
    public function getSurgePricingInfo(float $latitude, float $longitude): array
    {
        // TODO: Convertir coordonnées en zone
        $zoneId = 'default';
        
        $status = $this->getSurgeStatus($zoneId);

        $messages = [
            'none' => 'Les frais de livraison sont au tarif normal',
            'low' => 'Léger supplément surge (+' . (($status['multiplier'] - 1) * 100) . '%)',
            'medium' => 'Demande élevée - supplément de ' . (($status['multiplier'] - 1) * 100) . '%',
            'high' => 'Très forte demande - supplément de ' . (($status['multiplier'] - 1) * 100) . '%',
            'extreme' => 'Demande exceptionnelle - frais majorés de ' . (($status['multiplier'] - 1) * 100) . '%',
        ];

        return [
            ...$status,
            'message' => $messages[$status['level']],
            'estimated_wait_minutes' => $this->estimateWaitTime($zoneId),
        ];
    }

    /**
     * Estimer le temps d'attente pour un livreur
     */
    protected function estimateWaitTime(?string $zoneId): int
    {
        $ratio = $this->getDemandSupplyRatio($zoneId);
        
        // Base: 5 minutes, +3 minutes par point de ratio
        return (int) min(45, 5 + ($ratio * 3));
    }
}
