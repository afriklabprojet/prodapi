<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Service de gestion des zones géographiques
 * 
 * Gère les zones de livraison, la détection de zone par coordonnées,
 * et les requêtes vers les API externes (météo, trafic, routing).
 */
class GeoZoneService
{
    /**
     * Zones prédéfinies pour Abidjan et environs
     * Format: [nom => [center_lat, center_lng, radius_km]]
     */
    const ZONES = [
        'cocody' => [
            'name' => 'Cocody',
            'center_lat' => 5.3500,
            'center_lng' => -3.9833,
            'radius_km' => 5.0,
            'city' => 'Abidjan',
        ],
        'plateau' => [
            'name' => 'Plateau',
            'center_lat' => 5.3167,
            'center_lng' => -4.0167,
            'radius_km' => 3.0,
            'city' => 'Abidjan',
        ],
        'marcory' => [
            'name' => 'Marcory',
            'center_lat' => 5.3000,
            'center_lng' => -3.9833,
            'radius_km' => 4.0,
            'city' => 'Abidjan',
        ],
        'yopougon' => [
            'name' => 'Yopougon',
            'center_lat' => 5.3333,
            'center_lng' => -4.0667,
            'radius_km' => 8.0,
            'city' => 'Abidjan',
        ],
        'abobo' => [
            'name' => 'Abobo',
            'center_lat' => 5.4167,
            'center_lng' => -4.0167,
            'radius_km' => 6.0,
            'city' => 'Abidjan',
        ],
        'treichville' => [
            'name' => 'Treichville',
            'center_lat' => 5.2833,
            'center_lng' => -4.0000,
            'radius_km' => 3.0,
            'city' => 'Abidjan',
        ],
        'koumassi' => [
            'name' => 'Koumassi',
            'center_lat' => 5.2833,
            'center_lng' => -3.9500,
            'radius_km' => 4.0,
            'city' => 'Abidjan',
        ],
        'adjame' => [
            'name' => 'Adjamé',
            'center_lat' => 5.3500,
            'center_lng' => -4.0333,
            'radius_km' => 4.0,
            'city' => 'Abidjan',
        ],
        'port_bouet' => [
            'name' => 'Port-Bouët',
            'center_lat' => 5.2500,
            'center_lng' => -3.9167,
            'radius_km' => 5.0,
            'city' => 'Abidjan',
        ],
        'bingerville' => [
            'name' => 'Bingerville',
            'center_lat' => 5.3500,
            'center_lng' => -3.8833,
            'radius_km' => 4.0,
            'city' => 'Abidjan',
        ],
    ];

    /**
     * Conditions météo standards
     */
    const WEATHER_CONDITIONS = [
        'clear' => 'Dégagé',
        'cloudy' => 'Nuageux',
        'rain' => 'Pluie',
        'heavy_rain' => 'Forte pluie',
        'storm' => 'Orage',
    ];

    // =========================================================================
    // ZONES GÉOGRAPHIQUES
    // =========================================================================

    /**
     * Obtenir l'ID de zone à partir de coordonnées GPS
     */
    public function getZoneIdFromCoordinates(float $latitude, float $longitude): string
    {
        $cacheKey = "zone_" . round($latitude, 3) . "_" . round($longitude, 3);

        return Cache::remember($cacheKey, 3600, function () use ($latitude, $longitude) {
            return $this->calculateZoneId($latitude, $longitude);
        });
    }

    /**
     * Calculer la zone la plus proche
     */
    protected function calculateZoneId(float $latitude, float $longitude): string
    {
        $closestZone = 'default';
        $minDistance = PHP_FLOAT_MAX;

        foreach (self::ZONES as $zoneId => $zone) {
            $distance = $this->calculateHaversineDistance(
                $latitude, $longitude,
                $zone['center_lat'], $zone['center_lng']
            );

            // Si dans le rayon de la zone
            if ($distance <= $zone['radius_km'] && $distance < $minDistance) {
                $minDistance = $distance;
                $closestZone = $zoneId;
            }
        }

        return $closestZone;
    }

    /**
     * Vérifier si des coordonnées sont dans une zone spécifique
     */
    public function isInZone(float $latitude, float $longitude, string $zoneId): bool
    {
        if (!isset(self::ZONES[$zoneId])) {
            return false;
        }

        $zone = self::ZONES[$zoneId];
        $distance = $this->calculateHaversineDistance(
            $latitude, $longitude,
            $zone['center_lat'], $zone['center_lng']
        );

        return $distance <= $zone['radius_km'];
    }

    /**
     * Obtenir les informations d'une zone
     */
    public function getZoneInfo(string $zoneId): ?array
    {
        return self::ZONES[$zoneId] ?? null;
    }

    /**
     * Obtenir toutes les zones
     */
    public function getAllZones(): array
    {
        return self::ZONES;
    }

    /**
     * Vérifier si un livreur est dans sa zone assignée
     */
    public function isCourierInAssignedZone(\App\Models\Courier $courier, ?string $requiredZoneId = null): bool
    {
        if (!$courier->latitude || !$courier->longitude) {
            return false;
        }

        // Si une zone spécifique est requise
        if ($requiredZoneId) {
            return $this->isInZone($courier->latitude, $courier->longitude, $requiredZoneId);
        }

        // Sinon, vérifier si le livreur est dans n'importe quelle zone active
        $currentZone = $this->getZoneIdFromCoordinates($courier->latitude, $courier->longitude);
        return $currentZone !== 'default';
    }

    // =========================================================================
    // API MÉTÉO
    // =========================================================================

    /**
     * Obtenir les conditions météo pour une zone
     */
    public function getWeatherCondition(string $zoneId): string
    {
        $cacheKey = "weather_condition_{$zoneId}";

        return Cache::remember($cacheKey, 900, function () use ($zoneId) {
            return $this->fetchWeatherCondition($zoneId);
        });
    }

    /**
     * Récupérer les conditions météo depuis l'API ou heuristiques
     */
    protected function fetchWeatherCondition(string $zoneId): string
    {
        $zone = self::ZONES[$zoneId] ?? null;

        if (!$zone) {
            return 'clear';
        }

        // Essayer l'API OpenWeatherMap si configurée
        $apiKey = config('services.openweather.key');

        if ($apiKey) {
            try {
                $response = Http::timeout(5)->get('https://api.openweathermap.org/data/2.5/weather', [
                    'lat' => $zone['center_lat'],
                    'lon' => $zone['center_lng'],
                    'appid' => $apiKey,
                    'units' => 'metric',
                ]);

                if ($response->successful()) {
                    $data = $response->json();
                    return $this->mapOpenWeatherCondition($data);
                }
            } catch (\Exception $e) {
                Log::warning("GeoZone: OpenWeather API failed", ['error' => $e->getMessage()]);
            }
        }

        // Fallback: heuristiques basées sur la saison
        return $this->getSeasonalWeatherHeuristic();
    }

    /**
     * Mapper les conditions OpenWeatherMap vers nos conditions
     */
    protected function mapOpenWeatherCondition(array $data): string
    {
        $weatherId = $data['weather'][0]['id'] ?? 800;

        // Codes OpenWeather: https://openweathermap.org/weather-conditions
        return match (true) {
            $weatherId >= 200 && $weatherId < 300 => 'storm',      // Thunderstorm
            $weatherId >= 500 && $weatherId < 505 => 'rain',       // Light to moderate rain
            $weatherId >= 505 && $weatherId < 600 => 'heavy_rain', // Heavy rain
            $weatherId >= 300 && $weatherId < 400 => 'rain',       // Drizzle
            $weatherId >= 600 && $weatherId < 700 => 'rain',       // Snow (rare en CI)
            $weatherId >= 700 && $weatherId < 800 => 'cloudy',     // Atmosphere
            $weatherId >= 801 => 'cloudy',                         // Clouds
            default => 'clear',
        };
    }

    /**
     * Heuristiques météo basées sur la saison en Côte d'Ivoire
     */
    protected function getSeasonalWeatherHeuristic(): string
    {
        $month = (int) now()->format('n');
        $hour = (int) now()->format('H');

        // Saison des pluies: Avril-Juillet, Septembre-Novembre
        $rainySeasons = [4, 5, 6, 7, 9, 10, 11];
        $isRainySeason = in_array($month, $rainySeasons);

        if ($isRainySeason) {
            // Plus de chance de pluie l'après-midi
            if ($hour >= 14 && $hour <= 18) {
                return random_int(1, 100) <= 40 ? 'rain' : 'cloudy';
            }
            return random_int(1, 100) <= 20 ? 'rain' : 'cloudy';
        }

        // Saison sèche
        return random_int(1, 100) <= 90 ? 'clear' : 'cloudy';
    }

    /**
     * Forcer la mise à jour météo pour une zone
     */
    public function refreshWeather(string $zoneId): string
    {
        Cache::forget("weather_condition_{$zoneId}");
        return $this->getWeatherCondition($zoneId);
    }

    // =========================================================================
    // API TRAFIC
    // =========================================================================

    /**
     * Obtenir les conditions de trafic
     */
    public function getTrafficCondition(float $latitude, float $longitude): string
    {
        $zoneId = $this->getZoneIdFromCoordinates($latitude, $longitude);
        $cacheKey = "traffic_{$zoneId}";

        return Cache::remember($cacheKey, 300, function () use ($latitude, $longitude, $zoneId) {
            return $this->calculateTrafficCondition($latitude, $longitude, $zoneId);
        });
    }

    /**
     * Calculer les conditions de trafic (heuristiques + API si disponible)
     */
    protected function calculateTrafficCondition(float $latitude, float $longitude, string $zoneId): string
    {
        // Essayer TomTom API si configuré
        $tomtomKey = config('services.tomtom.key');

        if ($tomtomKey) {
            try {
                $response = Http::timeout(5)->get("https://api.tomtom.com/traffic/services/4/flowSegmentData/absolute/10/json", [
                    'point' => "{$latitude},{$longitude}",
                    'key' => $tomtomKey,
                ]);

                if ($response->successful()) {
                    $data = $response->json();
                    return $this->mapTomTomTraffic($data);
                }
            } catch (\Exception $e) {
                Log::warning("GeoZone: TomTom API failed", ['error' => $e->getMessage()]);
            }
        }

        // Fallback: heuristiques intelligentes
        return $this->getTrafficHeuristic($zoneId);
    }

    /**
     * Mapper les données TomTom vers nos conditions
     */
    protected function mapTomTomTraffic(array $data): string
    {
        $flowData = $data['flowSegmentData'] ?? [];
        $freeFlowSpeed = $flowData['freeFlowSpeed'] ?? 50;
        $currentSpeed = $flowData['currentSpeed'] ?? 50;

        $ratio = $currentSpeed / max(1, $freeFlowSpeed);

        return match (true) {
            $ratio >= 0.8 => 'normal',
            $ratio >= 0.5 => 'traffic',
            default => 'heavy_traffic',
        };
    }

    /**
     * Heuristiques de trafic basées sur l'heure et la zone
     */
    protected function getTrafficHeuristic(string $zoneId): string
    {
        $hour = (int) now()->format('H');
        $dayOfWeek = (int) now()->format('N'); // 1=Lundi ... 7=Dimanche

        // Week-end: trafic généralement léger
        if ($dayOfWeek >= 6) {
            return ($hour >= 10 && $hour <= 18) ? 'traffic' : 'normal';
        }

        // Zones à fort trafic
        $highTrafficZones = ['plateau', 'adjame', 'treichville'];
        $isHighTrafficZone = in_array($zoneId, $highTrafficZones);

        // Heures de pointe matin (7h-9h)
        if ($hour >= 7 && $hour <= 9) {
            return $isHighTrafficZone ? 'heavy_traffic' : 'traffic';
        }

        // Heures de pointe soir (17h-19h)
        if ($hour >= 17 && $hour <= 19) {
            return $isHighTrafficZone ? 'heavy_traffic' : 'traffic';
        }

        // Pause déjeuner (12h-14h)
        if ($hour >= 12 && $hour <= 14) {
            return $isHighTrafficZone ? 'traffic' : 'normal';
        }

        return 'normal';
    }

    /**
     * Obtenir le multiplicateur de temps basé sur le trafic
     */
    public function getTrafficTimeMultiplier(string $condition): float
    {
        return match ($condition) {
            'normal' => 1.0,
            'traffic' => 1.3,
            'heavy_traffic' => 1.6,
            default => 1.0,
        };
    }

    // =========================================================================
    // API ROUTING (OSRM)
    // =========================================================================

    /**
     * Obtenir le polyline de route via OSRM
     */
    public function getRoutePolyline(
        float $startLat, float $startLng,
        float $endLat, float $endLng
    ): ?array {
        $osrmUrl = config('services.osrm.url', 'https://router.project-osrm.org');

        try {
            $response = Http::timeout(10)->get("{$osrmUrl}/route/v1/driving/{$startLng},{$startLat};{$endLng},{$endLat}", [
                'overview' => 'full',
                'geometries' => 'polyline',
                'steps' => 'false',
            ]);

            if ($response->successful()) {
                $data = $response->json();

                if (($data['code'] ?? '') === 'Ok' && !empty($data['routes'])) {
                    $route = $data['routes'][0];

                    return [
                        'polyline' => $route['geometry'],
                        'distance_km' => round($route['distance'] / 1000, 2),
                        'duration_seconds' => (int) $route['duration'],
                        'duration_minutes' => round($route['duration'] / 60, 1),
                    ];
                }
            }
        } catch (\Exception $e) {
            Log::warning("GeoZone: OSRM routing failed", [
                'error' => $e->getMessage(),
                'from' => [$startLat, $startLng],
                'to' => [$endLat, $endLng],
            ]);
        }

        return null;
    }

    /**
     * Calculer la distance routière via OSRM
     */
    public function getRoutingDistance(
        float $startLat, float $startLng,
        float $endLat, float $endLng
    ): ?float {
        $route = $this->getRoutePolyline($startLat, $startLng, $endLat, $endLng);
        return $route['distance_km'] ?? null;
    }

    /**
     * Calculer le temps de trajet via OSRM (avec ajustement trafic)
     */
    public function getRoutingDuration(
        float $startLat, float $startLng,
        float $endLat, float $endLng,
        bool $includeTraffic = true
    ): ?int {
        $route = $this->getRoutePolyline($startLat, $startLng, $endLat, $endLng);

        if (!$route) {
            return null;
        }

        $baseSeconds = $route['duration_seconds'];

        if ($includeTraffic) {
            $trafficCondition = $this->getTrafficCondition($startLat, $startLng);
            $multiplier = $this->getTrafficTimeMultiplier($trafficCondition);
            return (int) round($baseSeconds * $multiplier);
        }

        return $baseSeconds;
    }

    // =========================================================================
    // UTILITAIRES
    // =========================================================================

    /**
     * Calcul de distance Haversine (en km)
     */
    public function calculateHaversineDistance(
        float $lat1, float $lon1,
        float $lat2, float $lon2
    ): float {
        $earthRadius = 6371.0; // km

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }

    /**
     * Obtenir les livreurs dans une zone
     */
    public function getCouriersInZone(string $zoneId): \Illuminate\Support\Collection
    {
        $zone = self::ZONES[$zoneId] ?? null;

        if (!$zone) {
            return collect();
        }

        return \App\Models\Courier::available()
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->get()
            ->filter(function ($courier) use ($zoneId) {
                return $this->isInZone($courier->latitude, $courier->longitude, $zoneId);
            });
    }

    /**
     * Filtrer les commandes par zone
     */
    public function filterOrdersByZone($query, string $zoneId)
    {
        $zone = self::ZONES[$zoneId] ?? null;

        if (!$zone) {
            return $query;
        }

        // Filtrer par la ville de la pharmacie associée
        return $query->whereHas('pharmacy', function ($q) use ($zone) {
            $q->where('city', 'LIKE', "%{$zone['name']}%")
              ->orWhere('city', 'LIKE', "%{$zone['city']}%");
        });
    }
}
