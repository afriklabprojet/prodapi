<?php

namespace App\Services;

use App\Models\Pharmacy;
use Illuminate\Support\Facades\Log;

/**
 * Source UNIQUE pour le calcul des frais de livraison.
 *
 * Utilisé par :
 *  - OrderController::store               (création de commande → montant en DB)
 *  - PricingController::calculate         (affichage checkout)
 *  - DeliveryPricingController::estimate  (endpoint /delivery/estimate)
 *
 * Garantit : montant affiché = montant en DB = montant envoyé à JEKO.
 */
class DeliveryPricingService
{
    public function __construct(private GoogleMapsService $mapsService)
    {
    }

    /**
     * Résout distance + durée + frais depuis pharmacy + coords/adresse client.
     *
     * @return array{distance_km: float, duration_minutes: int|null, fee: int, source: string}
     */
    public function resolve(
        int $pharmacyId,
        ?float $deliveryLat,
        ?float $deliveryLng,
        ?string $deliveryAddress = null
    ): array {
        $source = 'fallback_min';
        $durationMinutes = null;

        // 1) Géocoder l'adresse texte si coords GPS absentes
        if (($deliveryLat === null || $deliveryLng === null) && $deliveryAddress) {
            try {
                $geocoded = $this->mapsService->geocode($deliveryAddress);
                if ($geocoded) {
                    $deliveryLat = $geocoded['latitude'];
                    $deliveryLng = $geocoded['longitude'];
                    $source = 'geocoded_address';
                }
            } catch (\Throwable $e) {
                Log::warning('DeliveryPricingService: geocoding échoué', [
                    'address' => $deliveryAddress,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        if ($deliveryLat === null || $deliveryLng === null) {
            return [
                'distance_km' => 0.0,
                'duration_minutes' => null,
                'fee' => WalletService::getDeliveryFeeMin(),
                'source' => 'fallback_min_no_coords',
            ];
        }

        $pharmacy = Pharmacy::find($pharmacyId);
        if (!$pharmacy || !$pharmacy->latitude || !$pharmacy->longitude) {
            return [
                'distance_km' => 0.0,
                'duration_minutes' => null,
                'fee' => WalletService::getDeliveryFeeMin(),
                'source' => 'fallback_min_no_pharmacy',
            ];
        }

        // 2) Google Maps Distance Matrix
        $distanceKm = null;
        try {
            $matrixResult = $this->mapsService->getDistanceMatrix(
                (float) $pharmacy->latitude,
                (float) $pharmacy->longitude,
                $deliveryLat,
                $deliveryLng
            );
            if ($matrixResult) {
                $distanceKm = $matrixResult['distance_km'];
                $durationMinutes = $matrixResult['duration_minutes'] ?? null;
                $source = $source === 'geocoded_address'
                    ? 'geocoded_distance_matrix'
                    : 'google_distance_matrix';
            }
        } catch (\Throwable $e) {
            Log::warning('DeliveryPricingService: GoogleMaps indisponible, fallback Haversine', [
                'pharmacy_id' => $pharmacyId,
                'error' => $e->getMessage(),
            ]);
        }

        // 3) Fallback Haversine
        if ($distanceKm === null) {
            $distanceKm = $this->haversine(
                (float) $pharmacy->latitude, (float) $pharmacy->longitude,
                $deliveryLat, $deliveryLng
            );
            $source = $source === 'geocoded_address' ? 'geocoded_haversine' : 'haversine';
        }

        // 4) Fallback geocoding texte si distance GPS aberrante (< 0.5 km)
        if ($distanceKm < 0.5 && $deliveryAddress
            && $source !== 'geocoded_address'
            && $source !== 'geocoded_distance_matrix'
            && $source !== 'geocoded_haversine') {
            try {
                $geocoded = $this->mapsService->geocode($deliveryAddress);
                if ($geocoded) {
                    $matrixGeo = $this->mapsService->getDistanceMatrix(
                        (float) $pharmacy->latitude, (float) $pharmacy->longitude,
                        (float) $geocoded['latitude'], (float) $geocoded['longitude']
                    );
                    if ($matrixGeo && $matrixGeo['distance_km'] > $distanceKm) {
                        $distanceKm = $matrixGeo['distance_km'];
                        $durationMinutes = $matrixGeo['duration_minutes'] ?? $durationMinutes;
                        $source = 'geocoded_address_fallback';
                    }
                }
            } catch (\Throwable $e) {
                Log::warning('DeliveryPricingService: fallback geocoding texte échoué', [
                    'address' => $deliveryAddress,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        return [
            'distance_km' => (float) $distanceKm,
            'duration_minutes' => $durationMinutes,
            'fee' => WalletService::calculateDeliveryFee($distanceKm),
            'source' => $source,
        ];
    }

    /**
     * Raccourci : retourne uniquement le montant des frais de livraison (XOF, entier).
     */
    public function calculate(
        int $pharmacyId,
        ?float $deliveryLat,
        ?float $deliveryLng,
        ?string $deliveryAddress = null
    ): int {
        return $this->resolve($pharmacyId, $deliveryLat, $deliveryLng, $deliveryAddress)['fee'];
    }

    private function haversine(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $earthRadius = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;
        return $earthRadius * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }
}
