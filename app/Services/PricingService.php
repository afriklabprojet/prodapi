<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;

/**
 * Source UNIQUE pour le calcul de TOUS les frais d'une commande.
 *
 * Garantit que /pricing/calculate et OrderController::store utilisent
 * EXACTEMENT le même pipeline de calcul :
 *   1. resolveDelivery()  → frais livraison via DeliveryPricingService (Google Maps / Haversine)
 *   2. computeAllFees()   → service_fee + payment_fee + total via WalletService
 *
 * Utilisé par :
 *  - PricingController::calculate   (estimation checkout)
 *  - OrderController::store         (création commande → montant en DB)
 */
class PricingService
{
    public function __construct(private DeliveryPricingService $deliveryService)
    {
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1. Résolution des frais de livraison
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Retourne les frais de livraison + distance + source.
     *
     * Priorité : pharmacy_id + (lat/lng ou adresse) → Google Maps / Haversine
     * Fallback  : distance_km fourni par le client (legacy, log warning)
     *
     * @return array{fee: int, distance_km: float, duration_minutes: int|null, source: string}
     */
    public function resolveDelivery(
        ?int $pharmacyId,
        ?float $lat,
        ?float $lng,
        ?string $address,
        ?float $distanceKmFallback = null
    ): array {
        if ($pharmacyId && ($lat !== null || $address)) {
            return $this->deliveryService->resolve($pharmacyId, $lat, $lng, $address);
        }

        // Fallback legacy : utiliser distance_km envoyé par le client
        $dk = (float) ($distanceKmFallback ?? 0);
        Log::warning('[PricingService] Fallback distance_km — pharmacy_id ou coords/adresse manquants', [
            'pharmacy_id'   => $pharmacyId,
            'lat'           => $lat,
            'lng'           => $lng,
            'address'       => $address,
            'distance_km'   => $dk,
        ]);

        return [
            'fee'              => WalletService::calculateDeliveryFee($dk),
            'distance_km'      => $dk,
            'duration_minutes' => null,
            'source'           => 'fallback_distance_km',
        ];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. Calcul de tous les frais (service + paiement + total)
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Calcule service_fee, payment_fee et total_amount depuis subtotal + delivery_fee connus.
     *
     * Délègue à WalletService::calculateAllFees — source de vérité pour les taux.
     *
     * @param string $caller  Identifiant du controller appelant (pour les logs)
     * @return array{subtotal: int, delivery_fee: int, service_fee: int, payment_fee: int, total_amount: int, pharmacy_amount: int}
     */
    public function computeAllFees(
        int $subtotal,
        int $deliveryFee,
        string $paymentMode,
        string $caller = 'unknown'
    ): array {
        $allFees = WalletService::calculateAllFees($subtotal, $deliveryFee, $paymentMode);

        Log::info('[PricingService] computeAllFees', [
            'caller'       => $caller,
            'subtotal'     => $subtotal,
            'delivery_fee' => $deliveryFee,
            'service_fee'  => $allFees['service_fee'],
            'payment_fee'  => $allFees['payment_fee'],
            'total_amount' => $allFees['total_amount'],
            'payment_mode' => $paymentMode,
        ]);

        return $allFees;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. Pipeline complet — SOURCE UNIQUE utilisée par tous les endpoints
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Calcul COMPLET en un seul appel :
     *   1. Subtotal recalculé depuis les prix DB (jamais depuis le client)
     *   2. Frais de livraison via DeliveryPricingService (Google Maps / Haversine)
     *   3. service_fee + payment_fee + total via WalletService
     *
     * Utilisé par :
     *  - PricingController::calculate  (estimation checkout Flutter)
     *  - OrderController::store        (création commande → montant DB + JEKO)
     *
     * @param array  $items            Liste [{id, quantity, price}, ...]
     * @param int|null $subtotalFallback  Utilisé uniquement si $items est vide (legacy)
     *
     * @return array{
     *     subtotal: int,
     *     delivery_fee: int,
     *     service_fee: int,
     *     payment_fee: int,
     *     total_amount: int,
     *     pharmacy_amount: int,
     *     distance_km: float,
     *     duration_minutes: int|null,
     *     delivery_source: string,
     *     currency: string,
     * }
     */
    public function calculateFullPricing(
        ?int $pharmacyId,
        array $items,
        ?float $lat,
        ?float $lng,
        string $paymentMode,
        ?string $address = null,
        ?float $distanceKmFallback = null,
        ?int $subtotalFallback = null
    ): array {
        // 1. Subtotal depuis DB (prix réels, jamais prix client)
        if (!empty($items)) {
            $productIds = collect($items)->pluck('id')->filter()->unique()->values()->toArray();
            $products   = !empty($productIds)
                ? \App\Models\Product::whereIn('id', $productIds)->get()->keyBy('id')
                : collect();

            $subtotal = 0;
            foreach ($items as $item) {
                $price = isset($item['unit_price']) ? $item['unit_price'] : ($item['price'] ?? 0);
                if (isset($item['id']) && $products->has($item['id'])) {
                    $price = $products->get($item['id'])->price;
                }
                $subtotal += (int) (($item['quantity'] ?? 0) * $price);
            }
        } else {
            $subtotal = (int) ($subtotalFallback ?? 0);
        }

        // 2. Frais de livraison (Google Maps / Haversine / fallback distance_km)
        $resolved = $this->resolveDelivery(
            $pharmacyId,
            $lat,
            $lng,
            $address,
            $distanceKmFallback
        );

        // 3. service_fee + payment_fee + total
        $allFees = WalletService::calculateAllFees($subtotal, $resolved['fee'], $paymentMode);

        Log::info('[PricingService] calculateFullPricing', [
            'pharmacy_id'     => $pharmacyId,
            'subtotal'        => $subtotal,
            'delivery_fee'    => $resolved['fee'],
            'service_fee'     => $allFees['service_fee'],
            'payment_fee'     => $allFees['payment_fee'],
            'total_amount'    => $allFees['total_amount'],
            'distance_km'     => $resolved['distance_km'],
            'delivery_source' => $resolved['source'],
            'payment_mode'    => $paymentMode,
        ]);

        return [
            'subtotal'         => $allFees['subtotal'],
            'delivery_fee'     => $allFees['delivery_fee'],
            'service_fee'      => $allFees['service_fee'],
            'payment_fee'      => $allFees['payment_fee'],
            'total_amount'     => $allFees['total_amount'],
            'pharmacy_amount'  => $allFees['pharmacy_amount'],
            'distance_km'      => $resolved['distance_km'],
            'duration_minutes' => $resolved['duration_minutes'],
            'delivery_source'  => $resolved['source'],
            'currency'         => 'XOF',
        ];
    }
}
