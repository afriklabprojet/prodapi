<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;

/**
 * Pricing Quote signé (HMAC-SHA256) — figé entre /pricing/calculate et /orders.
 *
 * Pattern « Price Quote » à la Uber/Glovo :
 *   1. /pricing/calculate retourne un quote_token (TTL 5 min) avec les montants signés.
 *   2. /customer/orders accepte ce token : s'il est valide et que le panier n'a pas
 *      changé (items_hash identique), on utilise EXACTEMENT les montants du token.
 *      → Le client paie ce qu'il a vu, point.
 *   3. Si le token est absent / expiré / altéré, on recalcule + log explicite.
 *
 * Sécurité :
 *   - Signature HMAC-SHA256 avec APP_KEY (jamais exposée).
 *   - items_hash empêche d'utiliser un token avec un panier modifié.
 *   - expires_at empêche les vieux tokens (5 min par défaut).
 *   - Aucun montant n'est lu côté client : tout est validé serveur.
 */
class PricingQuoteService
{
    /** Durée de validité d'un quote (secondes). Aligné sur typical checkout time. */
    public const TTL_SECONDS = 300; // 5 min

    /**
     * Génère un quote_token signé à partir du résultat de PricingService::calculateFullPricing.
     *
     * @param array $pricing  Résultat brut de calculateFullPricing()
     * @param array $items    Items normalisés (id, quantity)
     * @param int   $pharmacyId
     * @param string $paymentMode
     */
    public function issue(
        array $pricing,
        array $items,
        int $pharmacyId,
        string $paymentMode
    ): string {
        $payload = [
            'v'             => 1,
            'pharmacy_id'   => $pharmacyId,
            'payment_mode'  => $paymentMode,
            'items_hash'    => $this->hashItems($items),
            'subtotal'      => (int) $pricing['subtotal'],
            'delivery_fee'  => (int) $pricing['delivery_fee'],
            'service_fee'   => (int) $pricing['service_fee'],
            'payment_fee'   => (int) $pricing['payment_fee'],
            'total_amount'  => (int) $pricing['total_amount'],
            'currency'      => $pricing['currency'] ?? 'XOF',
            'distance_km'   => (float) ($pricing['distance_km'] ?? 0),
            'issued_at'     => time(),
            'expires_at'    => time() + self::TTL_SECONDS,
        ];

        $body = $this->b64url(json_encode($payload, JSON_UNESCAPED_SLASHES));
        $sig  = $this->b64url(hash_hmac('sha256', $body, $this->secret(), true));

        return $body . '.' . $sig;
    }

    /**
     * Vérifie un quote_token et retourne le payload si valide.
     *
     * @return array{valid: bool, reason: ?string, payload: ?array}
     */
    public function verify(
        ?string $token,
        int $pharmacyId,
        string $paymentMode,
        array $items
    ): array {
        if (!$token) {
            return ['valid' => false, 'reason' => 'missing', 'payload' => null];
        }

        $parts = explode('.', $token, 2);
        if (count($parts) !== 2) {
            return ['valid' => false, 'reason' => 'malformed', 'payload' => null];
        }

        [$body, $sig] = $parts;
        $expected = $this->b64url(hash_hmac('sha256', $body, $this->secret(), true));

        if (!hash_equals($expected, $sig)) {
            Log::warning('[PricingQuoteService] signature invalide', [
                'pharmacy_id' => $pharmacyId,
            ]);
            return ['valid' => false, 'reason' => 'bad_signature', 'payload' => null];
        }

        $json = base64_decode(strtr($body, '-_', '+/'));
        $payload = $json ? json_decode($json, true) : null;
        if (!is_array($payload)) {
            return ['valid' => false, 'reason' => 'bad_payload', 'payload' => null];
        }

        if (($payload['expires_at'] ?? 0) < time()) {
            return ['valid' => false, 'reason' => 'expired', 'payload' => $payload];
        }

        if ((int) ($payload['pharmacy_id'] ?? 0) !== $pharmacyId) {
            return ['valid' => false, 'reason' => 'pharmacy_mismatch', 'payload' => $payload];
        }

        if (($payload['payment_mode'] ?? null) !== $paymentMode) {
            return ['valid' => false, 'reason' => 'payment_mode_mismatch', 'payload' => $payload];
        }

        if (($payload['items_hash'] ?? null) !== $this->hashItems($items)) {
            return ['valid' => false, 'reason' => 'items_changed', 'payload' => $payload];
        }

        return ['valid' => true, 'reason' => null, 'payload' => $payload];
    }

    /**
     * Hash déterministe des items (insensible à l'ordre).
     */
    public function hashItems(array $items): string
    {
        $normalized = collect($items)
            ->map(fn ($i) => [
                'id'       => (int) ($i['id'] ?? 0),
                'quantity' => (int) ($i['quantity'] ?? 0),
            ])
            ->sortBy(fn ($i) => $i['id'] . ':' . $i['quantity'])
            ->values()
            ->all();

        return hash('sha256', json_encode($normalized));
    }

    private function secret(): string
    {
        $key = config('app.key');
        // Laravel APP_KEY format: base64:xxxxx — strip prefix if present.
        if (is_string($key) && str_starts_with($key, 'base64:')) {
            return base64_decode(substr($key, 7));
        }
        return (string) $key;
    }

    private function b64url(string $bin): string
    {
        return rtrim(strtr(base64_encode($bin), '+/', '-_'), '=');
    }
}
