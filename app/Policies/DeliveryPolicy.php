<?php

namespace App\Policies;

use App\Models\Delivery;
use App\Models\User;

class DeliveryPolicy
{
    /**
     * Admin et livreurs peuvent lister les livraisons.
     */
    public function viewAny(User $user): bool
    {
        return $user->isAdmin() || $user->isCourier();
    }

    /**
     * Le livreur peut voir ses propres livraisons.
     */
    public function view(User $user, Delivery $delivery): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        // Customer can view deliveries for their orders
        if ($user->isCustomer()) {
            return $delivery->order && $delivery->order->customer_id === $user->id;
        }

        $courier = $user->courier;

        if (!$courier) {
            return false;
        }

        // Le livreur assigné peut voir la livraison
        if ($delivery->courier_id === $courier->id) {
            return true;
        }

        // Les livraisons en attente (marketplace) sont visibles par tous les livreurs
        return $delivery->status === 'pending' && $delivery->courier_id === null;
    }

    /**
     * Le livreur assigné peut accepter la livraison.
     */
    public function accept(User $user, Delivery $delivery): bool
    {
        $courier = $user->courier;

        if (!$courier) {
            return false;
        }

        // Marketplace: tout livreur actif peut accepter une livraison pending sans courier
        if ($delivery->status === 'pending' && $delivery->courier_id === null) {
            return $courier->status === 'active' && $courier->is_available;
        }

        // Direct assignment: seulement le livreur assigné
        return $delivery->courier_id === $courier->id && $delivery->status === 'assigned';
    }

    /**
     * Le livreur assigné peut mettre à jour la livraison (statut, position).
     */
    public function update(User $user, Delivery $delivery): bool
    {
        $courier = $user->courier;

        return $courier && $delivery->courier_id === $courier->id;
    }

    /**
     * Le livreur peut annuler seulement avant le pickup.
     */
    public function cancel(User $user, Delivery $delivery): bool
    {
        $courier = $user->courier;

        if (!$courier || $delivery->courier_id !== $courier->id) {
            return false;
        }

        // Annulation possible seulement avant pickup
        return in_array($delivery->status, ['assigned', 'accepted']);
    }

    /**
     * Admin ou livreur assigné peut mettre à jour le statut.
     */
    public function updateStatus(User $user, Delivery $delivery): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        $courier = $user->courier;

        return $courier && $delivery->courier_id === $courier->id;
    }

    /**
     * Le livreur assigné peut marquer comme arrivé si en transit.
     */
    public function markArrived(User $user, Delivery $delivery): bool
    {
        $courier = $user->courier;

        return $courier
            && $delivery->courier_id === $courier->id
            && $delivery->status === 'in_transit';
    }

    /**
     * Le livreur peut marquer comme livré seulement s'il est en transit.
     */
    public function complete(User $user, Delivery $delivery): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        $courier = $user->courier;

        return $courier
            && $delivery->courier_id === $courier->id
            && $delivery->status === 'in_transit';
    }
}
