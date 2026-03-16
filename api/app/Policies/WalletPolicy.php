<?php

namespace App\Policies;

use App\Models\User;
use App\Models\Wallet;
use Illuminate\Auth\Access\HandlesAuthorization;

/**
 * Policy pour la gestion des portefeuilles.
 * 
 * Règles:
 * - Admins: accès complet
 * - Propriétaires (Pharmacy/Courier): accès à leur propre wallet uniquement
 * - Autres: aucun accès
 */
class WalletPolicy
{
    use HandlesAuthorization;

    /**
     * Determine if the user can view any wallets.
     */
    public function viewAny(User $user): bool
    {
        // Only admins can view all wallets
        return $user->isAdmin();
    }

    /**
     * Determine if the user can view the wallet.
     */
    public function view(User $user, Wallet $wallet): bool
    {
        // Admins can view any wallet
        if ($user->isAdmin()) {
            return true;
        }

        return $this->isWalletOwner($user, $wallet);
    }

    /**
     * Determine if the user can view wallet transactions.
     */
    public function viewTransactions(User $user, Wallet $wallet): bool
    {
        return $this->view($user, $wallet);
    }

    /**
     * Determine if the user can top up the wallet.
     */
    public function topUp(User $user, Wallet $wallet): bool
    {
        // Only wallet owner can top up (mainly for couriers)
        return $this->isWalletOwner($user, $wallet);
    }

    /**
     * Determine if the user can withdraw from the wallet.
     */
    public function withdraw(User $user, Wallet $wallet): bool
    {
        // Only wallet owner can withdraw
        return $this->isWalletOwner($user, $wallet);
    }

    /**
     * Determine if the user can update wallet settings.
     */
    public function updateSettings(User $user, Wallet $wallet): bool
    {
        // Admins or wallet owner
        if ($user->isAdmin()) {
            return true;
        }

        return $this->isWalletOwner($user, $wallet);
    }

    /**
     * Determine if the user can export wallet transactions.
     */
    public function export(User $user, Wallet $wallet): bool
    {
        return $this->view($user, $wallet);
    }

    /**
     * Check if the user owns the wallet.
     * 
     * Wallets are polymorphic (walletable_type: Courier or Pharmacy)
     */
    private function isWalletOwner(User $user, Wallet $wallet): bool
    {
        // Check if it's a Courier wallet
        if ($wallet->walletable_type === \App\Models\Courier::class) {
            $courier = $user->courier;
            return $courier && $courier->id === $wallet->walletable_id;
        }

        // Check if it's a Pharmacy wallet
        if ($wallet->walletable_type === \App\Models\Pharmacy::class) {
            if ($user->role !== 'pharmacy') {
                return false;
            }
            $pharmacyIds = $user->pharmacies()->pluck('pharmacies.id')->toArray();
            return in_array($wallet->walletable_id, $pharmacyIds);
        }

        return false;
    }
}
