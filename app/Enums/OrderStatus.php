<?php

namespace App\Enums;

enum OrderStatus: string
{
    case Pending = 'pending';
    case Confirmed = 'confirmed';
    case Preparing = 'preparing';
    case Ready = 'ready';
    case Paid = 'paid';
    case Assigned = 'assigned';
    case InTransit = 'in_transit';
    case InDelivery = 'in_delivery';
    case Delivered = 'delivered';
    case Cancelled = 'cancelled';

    /**
     * Label traduit en français
     */
    public function label(): string
    {
        return match ($this) {
            self::Pending => 'En attente',
            self::Confirmed => 'Confirmée',
            self::Preparing => 'En préparation',
            self::Ready => 'Prête',
            self::Paid => 'Payée',
            self::Assigned => 'Assignée',
            self::InTransit => 'En transit',
            self::InDelivery => 'En livraison',
            self::Delivered => 'Livrée',
            self::Cancelled => 'Annulée',
        };
    }

    /**
     * Couleur pour l'affichage UI
     */
    public function color(): string
    {
        return match ($this) {
            self::Pending => 'warning',
            self::Confirmed => 'info',
            self::Preparing => 'info',
            self::Ready => 'success',
            self::Paid => 'success',
            self::Assigned => 'primary',
            self::InTransit => 'primary',
            self::InDelivery => 'primary',
            self::Delivered => 'success',
            self::Cancelled => 'danger',
        };
    }

    /**
     * Statuts annulables
     */
    public function isCancellable(): bool
    {
        return in_array($this, [self::Pending, self::Confirmed, self::Preparing]);
    }

    /**
     * Statuts actifs (en cours de traitement)
     */
    public function isActive(): bool
    {
        return in_array($this, [self::Confirmed, self::Preparing, self::Ready, self::Paid, self::Assigned, self::InTransit, self::InDelivery]);
    }
}
