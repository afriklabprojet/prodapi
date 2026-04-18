<?php

namespace App\Services;

use App\Models\Courier;
use App\Models\Delivery;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Service d'assignation automatique des livraisons aux livreurs
 *
 * Utilisé par DeliveryObserver pour réassigner automatiquement
 * une livraison quand un livreur refuse ou annule.
 */
class AutoAssignmentService
{
    /**
     * Assigner automatiquement un livreur à une livraison existante.
     *
     * @return Courier|null Le livreur assigné ou null si aucun disponible
     */
    public function assignDelivery(Delivery $delivery): ?Courier
    {
        try {
            return DB::transaction(function () use ($delivery) {
                $order = $delivery->order;

                if (!$order) {
                    Log::warning("AutoAssignment: Livraison #{$delivery->id} sans commande associée");
                    return null;
                }

                $pharmacy = $order->pharmacy;

                if (!$pharmacy || !$pharmacy->latitude || !$pharmacy->longitude) {
                    Log::warning("AutoAssignment: Pas de coordonnées GPS pour la pharmacie", [
                        'delivery_id' => $delivery->id,
                        'pharmacy_id' => $pharmacy?->id,
                    ]);
                    return null;
                }

                // Exclure les livreurs qui ont déjà refusé cette livraison
                $excludedCourierIds = $delivery->rejected_courier_ids ?? [];

                $courier = $this->findBestCourier(
                    $pharmacy->latitude,
                    $pharmacy->longitude,
                    $excludedCourierIds
                );

                if (!$courier) {
                    Log::info("AutoAssignment: Aucun livreur disponible pour livraison #{$delivery->id}");
                    return null;
                }

                $delivery->update([
                    'courier_id' => $courier->id,
                    'status' => 'pending',
                ]);

                Log::info("AutoAssignment: Livraison #{$delivery->id} assignée au livreur {$courier->name}", [
                    'courier_id' => $courier->id,
                ]);

                return $courier;
            });
        } catch (\Exception $e) {
            Log::error("AutoAssignment: Erreur pour livraison #{$delivery->id}", [
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Trouver le meilleur livreur disponible à proximité.
     */
    protected function findBestCourier(float $lat, float $lng, array $excludeIds = []): ?Courier
    {
        // Filtre status='available' via scopeAvailable() — aligné avec
        // CourierAssignmentService (pas de colonnes is_available/is_active).
        $query = Courier::available()
            ->whereNotNull('latitude')
            ->whereNotNull('longitude');

        if (!empty($excludeIds)) {
            $query->whereNotIn('id', $excludeIds);
        }

        // Haversine formula for distance sorting (in km)
        $query->select('couriers.*')
            ->selectRaw(
                '(6371 * acos(cos(radians(?)) * cos(radians(latitude)) * cos(radians(longitude) - radians(?)) + sin(radians(?)) * sin(radians(latitude)))) AS distance',
                [$lat, $lng, $lat]
            )
            ->having('distance', '<=', 20)
            ->orderBy('distance', 'asc');

        return $query->first();
    }
}
