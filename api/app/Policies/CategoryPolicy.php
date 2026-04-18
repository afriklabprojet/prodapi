<?php

namespace App\Policies;

use App\Models\Category;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

/**
 * Policy pour la gestion des catégories de produits.
 * 
 * Règles:
 * - Admins: accès complet (CRUD)
 * - Pharmacies: création et lecture uniquement
 * - Autres: lecture seule
 */
class CategoryPolicy
{
    use HandlesAuthorization;

    /**
     * Determine if the user can view any categories.
     */
    public function viewAny(User $user): bool
    {
        // Everyone can browse categories
        return true;
    }

    /**
     * Determine if the user can view the category.
     */
    public function view(User $user, Category $category): bool
    {
        // Everyone can view categories
        return true;
    }

    /**
     * Determine if the user can create categories.
     */
    public function create(User $user): bool
    {
        // Admins and pharmacies can create categories
        return $user->isAdmin() || $user->role === 'pharmacy';
    }

    /**
     * Determine if the user can update the category.
     */
    public function update(User $user, Category $category): bool
    {
        // Only admins can update categories
        // This prevents inconsistencies if multiple pharmacies use the same category
        return $user->isAdmin();
    }

    /**
     * Determine if the user can delete the category.
     */
    public function delete(User $user, Category $category): bool
    {
        // Only admins can delete categories
        // Should also check if category is empty before allowing delete
        return $user->isAdmin();
    }

    /**
     * Determine if the user can reorder categories.
     */
    public function reorder(User $user): bool
    {
        // Only admins can reorder categories
        return $user->isAdmin();
    }
}
