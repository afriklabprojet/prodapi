<?php

namespace App\Enums;

/**
 * Rôles au sein d'une pharmacie (distinct du rôle utilisateur global).
 * Utilisé dans le pivot pharmacy_user.
 */
enum PharmacyRole: string
{
    case TITULAIRE = 'titulaire';      // Pharmacien titulaire - tous les droits
    case ADJOINT = 'adjoint';          // Pharmacien adjoint - presque tous les droits
    case PREPARATEUR = 'preparateur';  // Préparateur - gestion stock + commandes
    case STAGIAIRE = 'stagiaire';      // Stagiaire - lecture seule
    
    public function label(): string
    {
        return match($this) {
            self::TITULAIRE => 'Pharmacien Titulaire',
            self::ADJOINT => 'Pharmacien Adjoint',
            self::PREPARATEUR => 'Préparateur',
            self::STAGIAIRE => 'Stagiaire',
        };
    }
    
    /**
     * Permissions accordées par rôle
     */
    public function permissions(): array
    {
        return match($this) {
            self::TITULAIRE => [
                'team.manage',
                'team.invite',
                'pharmacy.edit',
                'orders.manage',
                'inventory.manage',
                'reports.view',
                'finances.view',
                'prescriptions.manage',
            ],
            self::ADJOINT => [
                'team.invite',
                'orders.manage',
                'inventory.manage',
                'reports.view',
                'finances.view',
                'prescriptions.manage',
            ],
            self::PREPARATEUR => [
                'orders.manage',
                'inventory.manage',
                'prescriptions.view',
            ],
            self::STAGIAIRE => [
                'orders.view',
                'inventory.view',
                'prescriptions.view',
            ],
        };
    }
    
    public function canManageTeam(): bool
    {
        return in_array('team.manage', $this->permissions());
    }
    
    public function canInvite(): bool
    {
        return in_array('team.invite', $this->permissions());
    }
    
    public function canEditPharmacy(): bool
    {
        return in_array('pharmacy.edit', $this->permissions());
    }
}
