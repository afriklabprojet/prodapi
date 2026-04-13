<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PricingController extends Controller
{
    public function index(): JsonResponse
    {
        $pricing = [
            'delivery_base_fee' => (int) Setting::get('delivery_base_fee', 500),
            'delivery_per_km' => (int) Setting::get('delivery_per_km', 200),
            'service_fee_percent' => (float) Setting::get('service_fee_percent', 5),
            'minimum_order' => (int) Setting::get('minimum_order', 1000),
            'free_delivery_threshold' => (int) Setting::get('free_delivery_threshold', 0),
            'currency' => 'XOF',
            'payment_modes' => [
                'platform' => (bool) Setting::get('payment_mode_platform_enabled', true),
                'cash' => (bool) Setting::get('payment_mode_cash_enabled', false),
                'wallet' => (bool) Setting::get('payment_mode_wallet_enabled', true),
            ],
        ];

        return response()->json([
            'success' => true,
            'data' => $pricing,
        ]);
    }

    public function calculate(Request $request): JsonResponse
    {
        $request->validate([
            'subtotal' => 'required|numeric|min:0',
            'distance_km' => 'nullable|numeric|min:0',
        ]);

        $subtotal = $request->subtotal;
        $distanceKm = $request->input('distance_km', 0);

        $deliveryBaseFee = (int) Setting::get('delivery_base_fee', 500);
        $deliveryPerKm = (int) Setting::get('delivery_per_km', 200);
        $serviceFeePercent = (float) Setting::get('service_fee_percent', 5);

        $deliveryFee = $deliveryBaseFee + ($deliveryPerKm * $distanceKm);
        $serviceFee = round($subtotal * $serviceFeePercent / 100);
        $total = $subtotal + $deliveryFee + $serviceFee;

        return response()->json([
            'success' => true,
            'data' => [
                'subtotal' => $subtotal,
                'delivery_fee' => round($deliveryFee),
                'service_fee' => $serviceFee,
                'total' => round($total),
                'currency' => 'XOF',
            ],
        ]);
    }

    public function estimateDelivery(Request $request): JsonResponse
    {
        $request->validate([
            'origin_lat' => 'required|numeric',
            'origin_lng' => 'required|numeric',
            'destination_lat' => 'required|numeric',
            'destination_lng' => 'required|numeric',
        ]);

        $distance = $this->haversine(
            $request->origin_lat, $request->origin_lng,
            $request->destination_lat, $request->destination_lng,
        );

        $deliveryBaseFee = (int) Setting::get('delivery_base_fee', 500);
        $deliveryPerKm = (int) Setting::get('delivery_per_km', 200);
        $baseFee = $deliveryBaseFee + ($deliveryPerKm * $distance);

        // Surge pricing
        $surge = app(\App\Services\DynamicPricingService::class)
            ->getSurgeMultiplier($request->origin_lat, $request->origin_lng);
        
        $finalFee = round($baseFee * $surge['multiplier']);
        $surgeAmount = $finalFee - round($baseFee);

        return response()->json([
            'success' => true,
            'data' => [
                'distance_km' => round($distance, 2),
                'base_fee' => round($baseFee),
                'estimated_fee' => $finalFee,
                'surge' => [
                    'active' => $surge['multiplier'] > 1.0,
                    'multiplier' => $surge['multiplier'],
                    'level' => $surge['level'],
                    'amount' => $surgeAmount,
                ],
                'estimated_minutes' => max(10, round($distance * 4)),
                'currency' => 'XOF',
            ],
        ]);
    }

    private function haversine(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $r = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return $r * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }
}
