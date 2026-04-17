<?php

namespace App\Policies;

use App\Models\Courier;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

/**
 * Policy pour la gestion des profils coursiers.
 * 
 * Règles:
 * - Admins: accès complet (CRUD + approbation/suspension)
 * - Coursiers: lecture/modification de leur propre profil
 * - Pharmacies: lecture seule des coursiers approuvés
 * - Customers: aucun accès direct
 */
class CourierPolicy
{
    use HandlesAuthorization;

    /**
     * Determine if the user can view any couriers.
     */
    public function viewAny(User $user): bool
    {
        // Admins can view all couriers
        // Pharmacies might need to see available couriers
        return $user->isAdmin() || $user->role === 'pharmacy';
    }

    /**
     * Determine if the user can view the courier.
     */
    public function view(User $user, Courier $courier): bool
    {
        // Admins can view any courier
        if ($user->isAdmin()) {
            return true;
        }

        // Courier can view their own profile
        if ($user->role === 'courier' && $user->courier?->id === $courier->id) {
            return true;
        }

        // Pharmacies can view approved couriers
        if ($user->role === 'pharmacy') {
            return $courier->status === 'available' || $courier->status === 'busy';
        }

        return false;
    }

    /**
     * Determine if the user can update the courier.
     */
    public function update(User $user, Courier $courier): bool
    {
        // Admins can update any courier
        if ($user->isAdmin()) {
            return true;
        }

        // Courier can only update their own profile
        return $user->role === 'courier' && $user->courier?->id === $courier->id;
    }

    /**
     * Determine if the user can delete the courier.
     */
    public function delete(User $user, Courier $courier): bool
    {
        // Only admins can delete courier profiles
        return $user->isAdmin();
    }

    /**
     * Determine if the user can approve the courier.
     */
    public function approve(User $user, Courier $courier): bool
    {
        // Only admins can approve couriers
        return $user->isAdmin() && $courier->status === 'pending_approval';
    }

    /**
     * Determine if the user can suspend the courier.
     */
    public function suspend(User $user, Courier $courier): bool
    {
        // Only admins can suspend couriers
        return $user->isAdmin() && !in_array($courier->status, ['suspended', 'rejected']);
    }

    /**
     * Determine if the user can reject the courier.
     */
    public function reject(User $user, Courier $courier): bool
    {
        // Only admins can reject courier applications
        return $user->isAdmin() && $courier->status === 'pending_approval';
    }

    /**
     * Determine if the user can view courier documents (KYC).
     */
    public function viewDocuments(User $user, Courier $courier): bool
    {
        // Admins can view any courier's documents
        if ($user->isAdmin()) {
            return true;
        }

        // Courier can view their own documents
        return $user->role === 'courier' && $user->courier?->id === $courier->id;
    }

    /**
     * Determine if the user can update courier location.
     */
    public function updateLocation(User $user, Courier $courier): bool
    {
        // Only the courier themselves can update their location
        return $user->role === 'courier' && $user->courier?->id === $courier->id;
    }

    /**
     * Determine if the user can toggle courier availability.
     */
    public function toggleAvailability(User $user, Courier $courier): bool
    {
        // Only the courier themselves can toggle availability
        return $user->role === 'courier' && $user->courier?->id === $courier->id;
    }
}
