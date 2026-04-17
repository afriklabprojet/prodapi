<?php

namespace App\Policies;

use App\Models\Product;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

/**
 * Policy pour la gestion des produits (médicaments).
 * 
 * Règles:
 * - Admins: accès complet
 * - Pharmacies: CRUD sur leurs propres produits uniquement
 * - Customers/Couriers: lecture seule des produits disponibles
 */
class ProductPolicy
{
    use HandlesAuthorization;

    /**
     * Determine if the user can view any products.
     */
    public function viewAny(User $user): bool
    {
        // Everyone can browse products
        return true;
    }

    /**
     * Determine if the user can view the product.
     */
    public function view(User $user, Product $product): bool
    {
        // Admins can view all
        if ($user->isAdmin()) {
            return true;
        }

        // Pharmacy can view their own products (including hidden)
        if ($user->role === 'pharmacy') {
            $pharmacyIds = $user->pharmacies()->pluck('pharmacies.id')->toArray();
            if (in_array($product->pharmacy_id, $pharmacyIds)) {
                return true;
            }
        }

        // Others can only view available products
        return $product->is_available;
    }

    /**
     * Determine if the user can create products.
     */
    public function create(User $user): bool
    {
        // Only admins and pharmacy users can create products
        return $user->isAdmin() || $user->role === 'pharmacy';
    }

    /**
     * Determine if the user can update the product.
     */
    public function update(User $user, Product $product): bool
    {
        // Admins can update any product
        if ($user->isAdmin()) {
            return true;
        }

        // Pharmacy can only update their own products
        if ($user->role === 'pharmacy') {
            $pharmacyIds = $user->pharmacies()->pluck('pharmacies.id')->toArray();
            return in_array($product->pharmacy_id, $pharmacyIds);
        }

        return false;
    }

    /**
     * Determine if the user can delete the product.
     */
    public function delete(User $user, Product $product): bool
    {
        // Admins can delete any product
        if ($user->isAdmin()) {
            return true;
        }

        // Pharmacy can only delete their own products
        if ($user->role === 'pharmacy') {
            $pharmacyIds = $user->pharmacies()->pluck('pharmacies.id')->toArray();
            return in_array($product->pharmacy_id, $pharmacyIds);
        }

        return false;
    }

    /**
     * Determine if the user can update stock quantity.
     */
    public function updateStock(User $user, Product $product): bool
    {
        return $this->update($user, $product);
    }

    /**
     * Determine if the user can update price.
     */
    public function updatePrice(User $user, Product $product): bool
    {
        return $this->update($user, $product);
    }

    /**
     * Determine if the user can toggle product availability.
     */
    public function toggleStatus(User $user, Product $product): bool
    {
        return $this->update($user, $product);
    }
}
