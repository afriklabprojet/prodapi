<?php

namespace App\Enums;

enum DeliveryStatus: string
{
    case Pending = 'pending';
    case Accepted = 'accepted';
    case Assigned = 'assigned';
    case PickedUp = 'picked_up';
    case InTransit = 'in_transit';
    case Delivered = 'delivered';
    case Cancelled = 'cancelled';
    case Failed = 'failed';

    /**
     * Label traduit en français
     */
    public function label(): string
    {
        return match ($this) {
            self::Pending => 'En attente',
            self::Accepted => 'Acceptée',
            self::Assigned => 'Assignée',
            self::PickedUp => 'Récupérée',
            self::InTransit => 'En transit',
            self::Delivered => 'Livrée',
            self::Cancelled => 'Annulée',
            self::Failed => 'Échouée',
        };
    }

    /**
     * Couleur pour l'affichage UI
     */
    public function color(): string
    {
        return match ($this) {
            self::Pending => 'warning',
            self::Accepted => 'info',
            self::Assigned => 'primary',
            self::PickedUp => 'primary',
            self::InTransit => 'primary',
            self::Delivered => 'success',
            self::Cancelled => 'danger',
            self::Failed => 'danger',
        };
    }

    /**
     * Statuts actifs (livraison en cours)
     */
    public function isActive(): bool
    {
        return in_array($this, [self::Accepted, self::Assigned, self::PickedUp, self::InTransit]);
    }

    /**
     * Statuts terminaux
     */
    public function isTerminal(): bool
    {
        return in_array($this, [self::Delivered, self::Cancelled, self::Failed]);
    }
}
