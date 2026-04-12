<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\WalletService;
use App\Services\GoogleMapsService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Controller pour l'estimation des frais de livraison
 * 
 * Permet aux clients de connaître les frais de livraison
 * avant de passer une commande.
 */
class DeliveryPricingController extends Controller
{
    /**
     * Récupérer les paramètres de tarification de la livraison
     * 
     * @return JsonResponse
     * 
     * GET /api/delivery/pricing
     * 
     * Response:
     * {
     *   "base_fee": 200,          // Frais de départ en FCFA
     *   "fee_per_km": 100,        // Frais par kilomètre en FCFA
     *   "min_fee": 300,           // Frais minimum en FCFA
     *   "max_fee": 5000,          // Frais maximum en FCFA
     *   "currency": "XOF",
     *   "formula": "frais = base_fee + (distance_km × fee_per_km)"
     * }
     */
    public function getPricing(): JsonResponse
    {
        $pricing = WalletService::getDeliveryPricing();
        
        return response()->json([
            'base_fee' => $pricing['base_fee'],
            'fee_per_km' => $pricing['fee_per_km'],
            'min_fee' => $pricing['min_fee'],
            'max_fee' => $pricing['max_fee'],
            'currency' => 'XOF',
            'formula' => 'frais = base_fee + (distance_km × fee_per_km)',
            'example' => [
                'distance_km' => 5,
                'calculated_fee' => WalletService::calculateDeliveryFee(5),
            ],
        ]);
    }

    /**
     * Estimer les frais de livraison pour une distance donnée
     * 
     * @param Request $request
     * @return JsonResponse
     * 
     * POST /api/delivery/estimate
     * 
     * Body:
     * {
     *   "distance_km": 5.5
     * }
     * 
     * OU avec coordonnées (calcul automatique de la distance):
     * {
     *   "pharmacy_lat": 5.3600,
     *   "pharmacy_lng": -4.0083,
     *   "delivery_lat": 5.3200,
     *   "delivery_lng": -3.9900
     * }
     * 
     * Response:
     * {
     *   "distance_km": 5.5,
     *   "delivery_fee": 750,
     *   "currency": "XOF",
     *   "breakdown": {
     *     "base_fee": 200,
     *     "distance_fee": 550,
     *     "total": 750
     *   }
     * }
     */
    public function estimate(Request $request): JsonResponse
    {
        // Validation
        $request->validate([
            'distance_km' => 'nullable|numeric|min:0|max:100',
            'pharmacy_lat' => 'nullable|numeric|between:-90,90',
            'pharmacy_lng' => 'nullable|numeric|between:-180,180',
            'delivery_lat' => 'nullable|numeric|between:-90,90',
            'delivery_lng' => 'nullable|numeric|between:-180,180',
        ]);

        $distanceKm = $request->input('distance_km');
        $durationMinutes = null;
        $distanceSource = 'provided';

        // Si pas de distance fournie, calculer depuis les coordonnées
        if ($distanceKm === null) {
            $pharmacyLat = $request->input('pharmacy_lat');
            $pharmacyLng = $request->input('pharmacy_lng');
            $deliveryLat = $request->input('delivery_lat');
            $deliveryLng = $request->input('delivery_lng');

            if ($pharmacyLat && $pharmacyLng && $deliveryLat && $deliveryLng) {
                // Essayer d'abord Distance Matrix API (distance route réelle)
                $mapsService = app(GoogleMapsService::class);
                $matrixResult = $mapsService->getDistanceMatrix(
                    (float) $pharmacyLat,
                    (float) $pharmacyLng,
                    (float) $deliveryLat,
                    (float) $deliveryLng
                );

                if ($matrixResult) {
                    $distanceKm = $matrixResult['distance_km'];
                    $durationMinutes = $matrixResult['duration_minutes'];
                    $distanceSource = 'google_distance_matrix';
                } else {
                    // Fallback: distance Haversine (ligne droite)
                    $distanceKm = $this->calculateDistance(
                        $pharmacyLat,
                        $pharmacyLng,
                        $deliveryLat,
                        $deliveryLng
                    );
                    $distanceSource = 'haversine';
                }
            } else {
                return response()->json([
                    'error' => 'Veuillez fournir soit distance_km, soit les coordonnées (pharmacy_lat, pharmacy_lng, delivery_lat, delivery_lng)',
                ], 422);
            }
        }

        // Récupérer les paramètres de tarification
        $pricing = WalletService::getDeliveryPricing();
        
        // Calculer les frais
        $deliveryFee = WalletService::calculateDeliveryFee($distanceKm);
        
        // Détail du calcul
        $baseFee = $pricing['base_fee'];
        $distanceFee = (int) ceil($distanceKm * $pricing['fee_per_km']);
        $rawTotal = $baseFee + $distanceFee;

        return response()->json([
            'distance_km' => round($distanceKm, 2),
            'delivery_fee' => $deliveryFee,
            'estimated_duration_minutes' => $durationMinutes ?? null,
            'distance_source' => $distanceSource ?? 'provided',
            'currency' => 'XOF',
            'breakdown' => [
                'base_fee' => $baseFee,
                'distance_fee' => $distanceFee,
                'raw_total' => $rawTotal,
                'min_applied' => $rawTotal < $pricing['min_fee'],
                'max_applied' => $rawTotal > $pricing['max_fee'],
            ],
            'pricing' => $pricing,
        ]);
    }

    /**
     * Calculer la distance entre deux points GPS (formule Haversine)
     * 
     * @param float $lat1 Latitude point 1
     * @param float $lng1 Longitude point 1
     * @param float $lat2 Latitude point 2
     * @param float $lng2 Longitude point 2
     * @return float Distance en kilomètres
     */
    private function calculateDistance(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $earthRadius = 6371; // Rayon de la Terre en km

        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLng / 2) * sin($dLng / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }
}
