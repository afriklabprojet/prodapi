<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Contract\Firestore;
use Google\Cloud\Firestore\FirestoreClient;

/**
 * Service pour écrire dans Firestore depuis le backend Laravel.
 * 
 * Utilisé pour synchroniser les changements de statut de livraison
 * en temps réel vers les apps mobiles via Firestore.
 */
class FirestoreService
{
    protected ?FirestoreClient $firestore = null;

    public function __construct()
    {
        try {
            /** @var Firestore $firestoreFactory */
            $firestoreFactory = app(Firestore::class);
            $this->firestore = $firestoreFactory->database();
        } catch (\Exception $e) {
            Log::warning('Firestore not available: ' . $e->getMessage());
        }
    }

    /**
     * Mettre à jour le statut d'une livraison dans Firestore.
     * 
     * Collection: deliveries/{deliveryId}
     * 
     * @param int $orderId L'ID de la commande (utilisé comme clé Firestore, car le client ne connaît que l'orderId)
     * @param string $status (pending, assigned, accepted, picked_up, in_transit, arriving, delivered, cancelled)
     * @param int|null $courierId
     * @param int|null $deliveryId L'ID de la livraison (stocké dans le document pour référence)
     * @param array $extraData Données supplémentaires (latitude, longitude, etc.)
     */
    public function updateDeliveryStatus(int $orderId, string $status, ?int $courierId = null, ?int $deliveryId = null, array $extraData = []): void
    {
        if (!$this->firestore) return;

        try {
            $data = array_merge([
                'status' => $status,
                'updatedAt' => new \Google\Cloud\Core\Timestamp(new \DateTime()),
            ], $extraData);

            if ($courierId !== null) {
                $data['courierId'] = $courierId;
            }

            if ($deliveryId !== null) {
                $data['deliveryId'] = $deliveryId;
            }

            // Utiliser orderId comme clé du document Firestore
            // Le client ne connaît que l'orderId, pas le deliveryId
            $this->firestore
                ->collection('deliveries')
                ->document((string) $orderId)
                ->set($data, ['merge' => true]);

            Log::debug("Firestore: order #{$orderId} delivery → {$status}");
        } catch (\Exception $e) {
            Log::error("Firestore updateDeliveryStatus failed: {$e->getMessage()}", [
                'delivery_id' => $deliveryId,
                'status' => $status,
            ]);
        }
    }

    /**
     * Mettre à jour le statut en ligne d'un livreur.
     * 
     * Collection: couriers/{courierId}
     * 
     * @param int $courierId
     * @param bool $isOnline
     */
    public function updateCourierOnlineStatus(int $courierId, bool $isOnline): void
    {
        if (!$this->firestore) return;

        try {
            $this->firestore
                ->collection('couriers')
                ->document((string) $courierId)
                ->set([
                    'isOnline' => $isOnline,
                    'updatedAt' => new \Google\Cloud\Core\Timestamp(new \DateTime()),
                ], ['merge' => true]);

            Log::debug("Firestore: courier #{$courierId} online={$isOnline}");
        } catch (\Exception $e) {
            Log::error("Firestore updateCourierOnlineStatus failed: {$e->getMessage()}");
        }
    }

    /**
     * Supprimer le document de tracking d'une livraison (après livraison).
     * 
     * @param int $deliveryId
     */
    public function clearDeliveryTracking(int $orderId): void
    {
        if (!$this->firestore) return;

        try {
            $this->firestore
                ->collection('deliveries')
                ->document((string) $orderId)
                ->delete();

            Log::debug("Firestore: order #{$orderId} tracking cleared");
        } catch (\Exception $e) {
            Log::error("Firestore clearDeliveryTracking failed: {$e->getMessage()}");
        }
    }
}
