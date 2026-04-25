<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

/**
 * Service Google Maps pour le calcul de distances et routes
 * 
 * Utilise la Distance Matrix API pour calculer les distances réelles
 * (pas en ligne droite) entre pharmacie et adresse de livraison.
 */
class GoogleMapsService
{
    protected string $apiKey;
    protected string $baseUrl;

    public function __construct()
    {
        $this->apiKey = config('services.google_maps.key', '');
        $this->baseUrl = config('services.google_maps.base_url', 'https://maps.googleapis.com/maps/api');
    }

    /**
     * Calculer la distance et la durée entre deux points via Distance Matrix API
     * 
     * @param float $originLat Latitude d'origine
     * @param float $originLng Longitude d'origine
     * @param float $destLat Latitude de destination
     * @param float $destLng Longitude de destination
     * @return array{distance_km: float, duration_minutes: float, distance_text: string, duration_text: string}|null
     */
    public function getDistanceMatrix(
        float $originLat, 
        float $originLng, 
        float $destLat, 
        float $destLng
    ): ?array {
        $cacheKey = "distance_matrix:{$originLat},{$originLng}:{$destLat},{$destLng}";
        
        // Cache pour 1h (les routes ne changent pas souvent)
        return Cache::remember($cacheKey, 3600, function () use ($originLat, $originLng, $destLat, $destLng) {
            try {
                $response = Http::get("{$this->baseUrl}/distancematrix/json", [
                    'origins' => "{$originLat},{$originLng}",
                    'destinations' => "{$destLat},{$destLng}",
                    'mode' => 'driving',
                    'language' => 'fr',
                    'key' => $this->apiKey,
                ]);

                if ($response->failed()) {
                    Log::error('[GoogleMaps] Distance Matrix request failed', [
                        'status' => $response->status(),
                    ]);
                    return null;
                }

                $data = $response->json();

                if ($data['status'] !== 'OK') {
                    Log::warning('[GoogleMaps] Distance Matrix API error', [
                        'status' => $data['status'],
                        'error' => $data['error_message'] ?? '',
                    ]);
                    return null;
                }

                $element = $data['rows'][0]['elements'][0] ?? null;

                if (!$element || $element['status'] !== 'OK') {
                    Log::warning('[GoogleMaps] No route found');
                    return null;
                }

                return [
                    'distance_km' => round($element['distance']['value'] / 1000, 2),
                    'duration_minutes' => round($element['duration']['value'] / 60, 1),
                    'distance_text' => $element['distance']['text'],
                    'duration_text' => $element['duration']['text'],
                ];
            } catch (\Exception $e) {
                Log::error('[GoogleMaps] Distance Matrix exception', ['error' => $e->getMessage()]);
                return null;
            }
        });
    }

    /**
     * Calculer la distance Matrix pour plusieurs destinations (batch)
     * Ex: 1 pharmacie → plusieurs clients
     * 
     * @param float $originLat
     * @param float $originLng
     * @param array $destinations [[lat, lng], [lat, lng], ...]
     * @return array Liste de résultats distance/durée pour chaque destination
     */
    public function getBatchDistances(
        float $originLat,
        float $originLng,
        array $destinations
    ): array {
        if (empty($destinations)) return [];

        // Construire la chaîne de destinations (max 25 par requête)
        $chunks = array_chunk($destinations, 25);
        $results = [];

        foreach ($chunks as $chunk) {
            $destString = implode('|', array_map(fn($d) => "{$d[0]},{$d[1]}", $chunk));

            try {
                $response = Http::get("{$this->baseUrl}/distancematrix/json", [
                    'origins' => "{$originLat},{$originLng}",
                    'destinations' => $destString,
                    'mode' => 'driving',
                    'language' => 'fr',
                    'key' => $this->apiKey,
                ]);

                if ($response->ok() && $response->json('status') === 'OK') {
                    $elements = $response->json('rows.0.elements') ?? [];
                    foreach ($elements as $i => $element) {
                        if ($element['status'] === 'OK') {
                            $results[] = [
                                'destination' => $chunk[$i],
                                'distance_km' => round($element['distance']['value'] / 1000, 2),
                                'duration_minutes' => round($element['duration']['value'] / 60, 1),
                                'distance_text' => $element['distance']['text'],
                                'duration_text' => $element['duration']['text'],
                            ];
                        } else {
                            $results[] = [
                                'destination' => $chunk[$i],
                                'distance_km' => null,
                                'duration_minutes' => null,
                                'error' => $element['status'],
                            ];
                        }
                    }
                }
            } catch (\Exception $e) {
                Log::error('[GoogleMaps] Batch distance error', ['error' => $e->getMessage()]);
            }
        }

        return $results;
    }

    /**
     * Obtenir l'itinéraire entre deux points via Directions API
     * 
     * @param float $originLat
     * @param float $originLng
     * @param float $destLat
     * @param float $destLng
     * @param array $waypoints Points intermédiaires [[lat, lng], ...]
     * @param bool $optimize Optimiser l'ordre des waypoints
     * @return array|null
     */
    public function getDirections(
        float $originLat,
        float $originLng,
        float $destLat,
        float $destLng,
        array $waypoints = [],
        bool $optimize = false
    ): ?array {
        try {
            $params = [
                'origin' => "{$originLat},{$originLng}",
                'destination' => "{$destLat},{$destLng}",
                'mode' => 'driving',
                'language' => 'fr',
                'key' => $this->apiKey,
            ];

            if (!empty($waypoints)) {
                $prefix = $optimize ? 'optimize:true|' : '';
                $waypointStr = $prefix . implode('|', array_map(fn($w) => "{$w[0]},{$w[1]}", $waypoints));
                $params['waypoints'] = $waypointStr;
            }

            $response = Http::get("{$this->baseUrl}/directions/json", $params);

            if ($response->failed() || $response->json('status') !== 'OK') {
                Log::warning('[GoogleMaps] Directions API error', [
                    'status' => $response->json('status'),
                ]);
                return null;
            }

            $route = $response->json('routes.0');
            $legs = $route['legs'] ?? [];

            $totalDistanceM = 0;
            $totalDurationS = 0;
            $legsInfo = [];

            foreach ($legs as $leg) {
                $totalDistanceM += $leg['distance']['value'];
                $totalDurationS += $leg['duration']['value'];
                $legsInfo[] = [
                    'start_address' => $leg['start_address'],
                    'end_address' => $leg['end_address'],
                    'distance_km' => round($leg['distance']['value'] / 1000, 2),
                    'duration_minutes' => round($leg['duration']['value'] / 60, 1),
                    'distance_text' => $leg['distance']['text'],
                    'duration_text' => $leg['duration']['text'],
                ];
            }

            return [
                'total_distance_km' => round($totalDistanceM / 1000, 2),
                'total_duration_minutes' => round($totalDurationS / 60, 1),
                'polyline' => $route['overview_polyline']['points'] ?? '',
                'waypoint_order' => $route['waypoint_order'] ?? [],
                'legs' => $legsInfo,
            ];
        } catch (\Exception $e) {
            Log::error('[GoogleMaps] Directions exception', ['error' => $e->getMessage()]);
            return null;
        }
    }

    /**
     * Geocoding: adresse → coordonnées
     */
    public function geocode(string $address): ?array
    {
        $cacheKey = 'geocode:' . md5($address);

        return Cache::remember($cacheKey, 86400, function () use ($address) {
            try {
                $response = Http::get("{$this->baseUrl}/geocode/json", [
                    'address' => $address,
                    'key' => $this->apiKey,
                    'language' => 'fr',
                    'region' => 'ci',
                ]);

                if ($response->ok() && $response->json('status') === 'OK') {
                    $result = $response->json('results.0');
                    $location = $result['geometry']['location'];
                    return [
                        'latitude' => $location['lat'],
                        'longitude' => $location['lng'],
                        'formatted_address' => $result['formatted_address'],
                    ];
                }
                return null;
            } catch (\Exception $e) {
                Log::error('[GoogleMaps] Geocode error', ['error' => $e->getMessage()]);
                return null;
            }
        });
    }

    /**
     * Reverse geocoding: coordonnées → adresse
     */
    public function reverseGeocode(float $lat, float $lng): ?string
    {
        $cacheKey = "reverse_geocode:{$lat},{$lng}";

        return Cache::remember($cacheKey, 86400, function () use ($lat, $lng) {
            try {
                $response = Http::get("{$this->baseUrl}/geocode/json", [
                    'latlng' => "{$lat},{$lng}",
                    'key' => $this->apiKey,
                    'language' => 'fr',
                ]);

                if ($response->ok() && $response->json('status') === 'OK') {
                    return $response->json('results.0.formatted_address');
                }
                return null;
            } catch (\Exception $e) {
                return null;
            }
        });
    }
}
