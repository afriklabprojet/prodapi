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
        $servicePricing = \App\Services\WalletService::getServicePricing();
        $deliveryPricing = \App\Services\WalletService::getDeliveryPricing();

        $pricing = [
            // Format nested attendu par l'app mobile (PricingConfigModel.fromJson)
            'delivery' => [
                'base_fee'   => $deliveryPricing['base_fee'],
                'fee_per_km' => $deliveryPricing['fee_per_km'],
                'min_fee'    => $deliveryPricing['min_fee'],
                'max_fee'    => $deliveryPricing['max_fee'],
            ],
            'service' => [
                'service_fee' => [
                    'enabled'    => $servicePricing['service_fee']['enabled'],
                    'percentage' => $servicePricing['service_fee']['percentage'],
                    'min'        => $servicePricing['service_fee']['min'],
                    'max'        => $servicePricing['service_fee']['max'],
                    'fixed_fee'  => (int) Setting::get('service_fee_fixed', 0),
                ],
                'payment_fee' => [
                    'enabled'    => $servicePricing['payment_fee']['enabled'],
                    'fixed_fee'  => $servicePricing['payment_fee']['fixed_fee'],
                    'percentage' => $servicePricing['payment_fee']['percentage'],
                ],
            ],
            'payment_modes' => [
                'platform' => (bool) Setting::get('payment_mode_platform_enabled', true),
                'cash'     => (bool) Setting::get('payment_mode_cash_enabled', false),
                'wallet'   => (bool) Setting::get('payment_mode_wallet_enabled', true),
            ],
            // Champs legacy conservés pour compatibilité
            'minimum_order'            => (int) Setting::get('minimum_order', 1000),
            'free_delivery_threshold'  => (int) Setting::get('free_delivery_threshold', 0),
            'currency'                 => 'XOF',
        ];

        return response()->json([
            'success' => true,
            'data' => $pricing,
        ]);
    }

    public function calculate(Request $request): JsonResponse
    {
        $request->validate([
            'subtotal'            => 'nullable|numeric|min:0',
            'distance_km'         => 'nullable|numeric|min:0',
            'payment_mode'        => 'nullable|string|in:cash,wave,orange_money,free_money,wallet,platform,mobile_money,on_delivery,card',
            'items'               => 'nullable|array',
            'items.*.id'          => 'nullable|integer|min:1',
            'items.*.quantity'    => 'required_with:items|integer|min:1',
            'items.*.price'       => 'nullable|numeric|min:0',
            // Optionnels : si fournis, on recalcule les frais comme à la création de commande
            'pharmacy_id'         => 'nullable|integer|min:1',
            'delivery_latitude'   => 'nullable|numeric',
            'delivery_longitude'  => 'nullable|numeric',
            'delivery_address'    => 'nullable|string',
        ]);

        $paymentMode = $request->input('payment_mode', 'wave');
        // Normaliser les modes — identique à OrderController::store (source de vérité)
        if ($paymentMode === 'platform') {
            $paymentMode = 'mobile_money';
        } elseif ($paymentMode === 'on_delivery') {
            $paymentMode = 'cash';
        }

        // ── Pipeline complet via calculateFullPricing ────────────────────────
        // SOURCE UNIQUE partagée avec OrderController::store.
        // Garantit : total checkout Flutter == total DB == total JEKO.
        $items = $request->input('items', []);

        $pricing = app(\App\Services\PricingService::class)->calculateFullPricing(
            $request->input('pharmacy_id') !== null ? (int) $request->input('pharmacy_id') : null,
            $items,
            $request->input('delivery_latitude')  !== null ? (float) $request->input('delivery_latitude')  : null,
            $request->input('delivery_longitude') !== null ? (float) $request->input('delivery_longitude') : null,
            $paymentMode,
            $request->input('delivery_address'),
            (float) $request->input('distance_km', 0),
            empty($items) ? (int) $request->input('subtotal', 0) : null
        );

        return response()->json([
            'success' => true,
            'data' => [
                'subtotal'     => $pricing['subtotal'],
                'delivery_fee' => $pricing['delivery_fee'],
                'service_fee'  => $pricing['service_fee'],
                'payment_fee'  => $pricing['payment_fee'],
                'total_amount' => $pricing['total_amount'],
                'distance_km'  => $pricing['distance_km'],
                'currency'     => 'XOF',
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
        $fee = $deliveryBaseFee + ($deliveryPerKm * $distance);

        return response()->json([
            'success' => true,
            'data' => [
                'distance_km' => round($distance, 2),
                'estimated_fee' => round($fee),
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
