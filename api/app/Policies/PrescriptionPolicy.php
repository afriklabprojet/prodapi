<?php

namespace App\Policies;

use App\Models\Prescription;
use App\Models\User;

class PrescriptionPolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function view(User $user, Prescription $prescription): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        if ($user->isCustomer()) {
            return $user->id === $prescription->customer_id;
        }

        if ($user->isPharmacy()) {
            return $prescription->status === 'pending' || $prescription->pharmacy_id !== null;
        }

        return false;
    }

    public function create(User $user): bool
    {
        return $user->isCustomer();
    }

    public function updateStatus(User $user, Prescription $prescription): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        if ($user->isPharmacy()) {
            return $prescription->status === 'pending';
        }

        return false;
    }

    public function delete(User $user, Prescription $prescription): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        if ($user->isCustomer()) {
            return $user->id === $prescription->customer_id && $prescription->status === 'pending';
        }

        return false;
    }
}
