<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\DeliveryPricingService;
use App\Services\WalletService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Controller pour l'estimation des frais de livraison.
 *
 * Toute la logique de calcul (Google Maps / Haversine / geocoding fallback)
 * est déléguée à DeliveryPricingService — source UNIQUE partagée avec
 * OrderController::store et PricingController::calculate.
 */
class DeliveryPricingController extends Controller
{
    public function __construct(private DeliveryPricingService $pricingService)
    {
    }

    /**
     * GET /api/delivery/pricing
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
     * POST /api/delivery/estimate
     *
     * Accepte soit `distance_km` (compat), soit `pharmacy_id` + coords/adresse
     * (chemin principal, passe par DeliveryPricingService).
     */
    public function estimate(Request $request): JsonResponse
    {
        $request->validate([
            'distance_km'      => 'nullable|numeric|min:0|max:100',
            'pharmacy_id'      => 'nullable|exists:pharmacies,id',
            'pharmacy_lat'     => 'nullable|numeric|between:-90,90',
            'pharmacy_lng'     => 'nullable|numeric|between:-180,180',
            'delivery_lat'     => 'nullable|numeric|between:-90,90',
            'delivery_lng'     => 'nullable|numeric|between:-180,180',
            'delivery_address' => 'nullable|string|max:500',
        ]);

        $pricing = WalletService::getDeliveryPricing();

        if ($request->filled('distance_km')) {
            return response()->json($this->buildResponse(
                (float) $request->input('distance_km'),
                null,
                'provided',
                $pricing,
                null,
            ));
        }

        if (!$request->filled('pharmacy_id')) {
            return response()->json([
                'error' => 'Veuillez fournir soit distance_km, soit pharmacy_id avec coordonnées GPS ou delivery_address',
            ], 422);
        }

        $deliveryLat = $request->input('delivery_lat');
        $deliveryLng = $request->input('delivery_lng');

        $resolved = $this->pricingService->resolve(
            (int) $request->input('pharmacy_id'),
            $deliveryLat !== null ? (float) $deliveryLat : null,
            $deliveryLng !== null ? (float) $deliveryLng : null,
            $request->input('delivery_address')
        );

        return response()->json($this->buildResponse(
            $resolved['distance_km'],
            $resolved['duration_minutes'],
            $resolved['source'],
            $pricing,
            $resolved['fee'],
        ));
    }

    /**
     * @param array{base_fee:int,fee_per_km:int,min_fee:int,max_fee:int} $pricing
     */
    private function buildResponse(
        float $distanceKm,
        ?int $durationMinutes,
        string $source,
        array $pricing,
        ?int $feeOverride
    ): array {
        $deliveryFee = $feeOverride ?? WalletService::calculateDeliveryFee($distanceKm);
        $distanceFee = (int) ceil($distanceKm * $pricing['fee_per_km']);
        $rawTotal = $pricing['base_fee'] + $distanceFee;

        return [
            'distance_km' => round($distanceKm, 2),
            'delivery_fee' => $deliveryFee,
            'estimated_duration_minutes' => $durationMinutes,
            'distance_source' => $source,
            'currency' => 'XOF',
            'breakdown' => [
                'base_fee' => $pricing['base_fee'],
                'distance_fee' => $distanceFee,
                'raw_total' => $rawTotal,
                'min_applied' => $rawTotal < $pricing['min_fee'],
                'max_applied' => $rawTotal > $pricing['max_fee'],
            ],
            'pricing' => $pricing,
        ];
    }
}
