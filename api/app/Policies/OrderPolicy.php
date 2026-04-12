<?php

namespace App\Policies;

use App\Models\Order;
use App\Models\User;

class OrderPolicy
{
    /**
     * Determine whether the user can view any orders.
     */
    public function viewAny(User $user): bool
    {
        return true;
    }

    /**
     * Determine whether the user can view the order.
     */
    public function view(User $user, Order $order): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        if ($user->id === $order->customer_id) {
            return true;
        }

        if ($user->isPharmacy()) {
            $pharmacyIds = $user->pharmacies->pluck('id')->toArray();
            return in_array($order->pharmacy_id, $pharmacyIds);
        }

        if ($user->isCourier()) {
            $courier = $user->courier;
            return $courier && $order->delivery && $order->delivery->courier_id === $courier->id;
        }

        return false;
    }

    /**
     * Determine whether the user can cancel the order.
     */
    public function cancel(User $user, Order $order): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        if ($user->id === $order->customer_id) {
            return in_array($order->status, ['pending', 'confirmed']);
        }

        return false;
    }

    /**
     * Determine whether the user can update the order.
     */
    public function update(User $user, Order $order): bool
    {
        return $user->id === $order->customer_id;
    }

    /**
     * Determine whether the user can create orders.
     */
    public function create(User $user): bool
    {
        return $user->isCustomer();
    }

    /**
     * Determine whether the pharmacy can accept the order.
     */
    public function accept(User $user, Order $order): bool
    {
        if (!$user->isPharmacy()) {
            return false;
        }

        $pharmacyIds = $user->pharmacies->pluck('id')->toArray();

        return in_array($order->pharmacy_id, $pharmacyIds) && $order->status === 'pending';
    }

    /**
     * Determine whether the user can assign a courier to the order.
     */
    public function assignCourier(User $user, Order $order): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        if ($user->isPharmacy()) {
            $pharmacyIds = $user->pharmacies->pluck('id')->toArray();
            return in_array($order->pharmacy_id, $pharmacyIds) && $order->status === 'ready';
        }

        return false;
    }
}
