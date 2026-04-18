<?php

namespace App\Policies;

use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

/**
 * Policy pour la gestion des pharmacies.
 * 
 * Règles:
 * - Admins: accès complet (CRUD + approbation)
 * - Propriétaires pharmacie: lecture/modification de leur propre pharmacie
 * - Customers/Couriers: lecture seule des pharmacies approuvées
 */
class PharmacyPolicy
{
    use HandlesAuthorization;

    /**
     * Determine if the user can view any pharmacies.
     */
    public function viewAny(User $user): bool
    {
        // Everyone can browse pharmacies
        return true;
    }

    /**
     * Determine if the user can view the pharmacy.
     */
    public function view(User $user, Pharmacy $pharmacy): bool
    {
        // Admins can view all
        if ($user->isAdmin()) {
            return true;
        }

        // Pharmacy owner can view their pharmacy
        if ($user->role === 'pharmacy') {
            $pharmacyIds = $user->pharmacies()->pluck('pharmacies.id')->toArray();
            if (in_array($pharmacy->id, $pharmacyIds)) {
                return true;
            }
        }

        // Others can only view approved/active pharmacies
        return $pharmacy->status === 'approved' && $pharmacy->is_active;
    }

    /**
     * Determine if the user can create pharmacies.
     */
    public function create(User $user): bool
    {
        // Admins can create pharmacies
        // New pharmacy registration is handled via auth/register/pharmacy
        return $user->isAdmin();
    }

    /**
     * Determine if the user can update the pharmacy.
     */
    public function update(User $user, Pharmacy $pharmacy): bool
    {
        // Admins can update any pharmacy
        if ($user->isAdmin()) {
            return true;
        }

        // Pharmacy owner can update their own pharmacy
        if ($user->role === 'pharmacy') {
            $pharmacyIds = $user->pharmacies()->pluck('pharmacies.id')->toArray();
            return in_array($pharmacy->id, $pharmacyIds);
        }

        return false;
    }

    /**
     * Determine if the user can delete the pharmacy.
     */
    public function delete(User $user, Pharmacy $pharmacy): bool
    {
        // Only admins can delete pharmacies
        return $user->isAdmin();
    }

    /**
     * Determine if the user can approve the pharmacy.
     */
    public function approve(User $user, Pharmacy $pharmacy): bool
    {
        // Only admins can approve pharmacies
        return $user->isAdmin() && $pharmacy->status === 'pending';
    }

    /**
     * Determine if the user can suspend the pharmacy.
     */
    public function suspend(User $user, Pharmacy $pharmacy): bool
    {
        // Only admins can suspend pharmacies
        return $user->isAdmin() && $pharmacy->status !== 'suspended';
    }

    /**
     * Determine if the user can manage pharmacy on-call schedules.
     */
    public function manageOnCalls(User $user, Pharmacy $pharmacy): bool
    {
        return $this->update($user, $pharmacy);
    }

    /**
     * Determine if the user can view pharmacy inventory.
     */
    public function viewInventory(User $user, Pharmacy $pharmacy): bool
    {
        // Admins can view any inventory
        if ($user->isAdmin()) {
            return true;
        }

        // Pharmacy owner can view their inventory
        if ($user->role === 'pharmacy') {
            $pharmacyIds = $user->pharmacies()->pluck('pharmacies.id')->toArray();
            return in_array($pharmacy->id, $pharmacyIds);
        }

        return false;
    }

    /**
     * Determine if the user can manage pharmacy inventory.
     */
    public function manageInventory(User $user, Pharmacy $pharmacy): bool
    {
        return $this->update($user, $pharmacy);
    }

    /**
     * Determine if the user can view pharmacy reports.
     */
    public function viewReports(User $user, Pharmacy $pharmacy): bool
    {
        return $this->viewInventory($user, $pharmacy);
    }

    /**
     * Determine if the user can manage pharmacy wallet.
     */
    public function manageWallet(User $user, Pharmacy $pharmacy): bool
    {
        return $this->update($user, $pharmacy);
    }
}
