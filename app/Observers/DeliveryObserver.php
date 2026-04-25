<?php

namespace App\Observers;

use App\Models\Delivery;
use App\Notifications\DeliveryAssignedNotification;
use App\Services\AutoAssignmentService;
use App\Services\WalletService;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Log;

/**
 * Observer pour l'assignation automatique des livraisons
 * 
 * Dès qu'une livraison est créée, le système assigne automatiquement
 * le meilleur livreur disponible sans aucune intervention humaine.
 */
class DeliveryObserver
{
    /**
     * Quand une livraison est créée → Assigner automatiquement
     */
    public function created(Delivery $delivery): void
    {
        // Seulement si la livraison est en attente et pas encore assignée
        if ($delivery->status === 'pending' && $delivery->courier_id === null) {
            $this->tryAutoAssign($delivery);
        }
    }

    /**
     * Quand une livraison est mise à jour
     */
    public function updated(Delivery $delivery): void
    {
        // Si un livreur a refusé ou annulé, réassigner automatiquement
        if ($delivery->wasChanged('status')) {
            $newStatus = $delivery->status;
            
            // Si la livraison revient en "pending" (livreur a refusé)
            if ($newStatus === 'pending' && $delivery->courier_id === null) {
                Log::info("DeliveryObserver: Livraison #{$delivery->id} revenue en attente, tentative de réassignation");
                $this->tryAutoAssign($delivery);
            }

            // Si la livraison est annulée et qu'un coursier était assigné, rembourser la commission
            if ($newStatus === 'cancelled' && $delivery->courier_id !== null) {
                $this->refundCommissionIfAny($delivery);
            }
        }
    }

    /**
     * Rembourser la commission prélevée à l'assignation si la livraison est annulée.
     */
    protected function refundCommissionIfAny(Delivery $delivery): void
    {
        try {
            $courier = $delivery->courier;
            if (!$courier) {
                return;
            }

            $refund = app(WalletService::class)->refundCommission($courier, $delivery);

            if ($refund) {
                Log::info("DeliveryObserver: Commission remboursée pour livraison #{$delivery->id}", [
                    'courier_id' => $courier->id,
                    'amount' => $refund->amount,
                    'transaction_id' => $refund->id,
                ]);
            }
        } catch (\Exception $e) {
            Log::error("DeliveryObserver: Erreur lors du remboursement commission livraison #{$delivery->id}", [
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Tenter d'assigner automatiquement un livreur
     */
    protected function tryAutoAssign(Delivery $delivery): void
    {
        try {
            // Désactiver temporairement la protection lazy loading
            $wasPreventingLazyLoading = Model::preventsLazyLoading();
            Model::preventLazyLoading(false);
            
            $service = app(AutoAssignmentService::class);
            $courier = $service->assignDelivery($delivery);
            
            // Réactiver si nécessaire
            Model::preventLazyLoading($wasPreventingLazyLoading);
            
            if ($courier) {
                Log::info("DeliveryObserver: Livraison #{$delivery->id} auto-assignée à {$courier->name}");
                
                // Envoyer une notification push au livreur
                try {
                    $courier->user?->notify(new DeliveryAssignedNotification($delivery));
                } catch (\Exception $e) {
                    Log::warning("DeliveryObserver: Notification non envoyée au livreur", [
                        'delivery_id' => $delivery->id,
                        'error' => $e->getMessage(),
                    ]);
                }
            } else {
                Log::warning("DeliveryObserver: Aucun livreur disponible pour la livraison #{$delivery->id}");
            }
        } catch (\Exception $e) {
            Log::error("DeliveryObserver: Erreur lors de l'auto-assignation de la livraison #{$delivery->id}", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
        }
    }
}
