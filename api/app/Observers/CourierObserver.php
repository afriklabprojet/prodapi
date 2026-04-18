<?php

namespace App\Observers;

use App\Models\Courier;
use App\Notifications\KycStatusNotification;

class CourierObserver
{
    /**
     * Handle the Courier "updating" event.
     * Synchronise automatiquement le statut général quand le KYC est approuvé.
     */
    public function updating(Courier $courier): void
    {
        // Vérifier si kyc_status vient de changer vers 'approved'
        if ($courier->isDirty('kyc_status')) {
            $newKycStatus = $courier->kyc_status;
            $oldKycStatus = $courier->getOriginal('kyc_status');

            // Si le KYC passe à 'approved' et que le status était 'pending_approval'
            if ($newKycStatus === 'approved' && $courier->status === 'pending_approval') {
                $courier->status = 'available';
                $courier->kyc_verified_at = $courier->kyc_verified_at ?? now();
            }

            // Si le KYC passe à 'rejected', mettre le status à 'rejected'
            if ($newKycStatus === 'rejected' && $courier->status === 'pending_approval') {
                $courier->status = 'rejected';
            }

            // Si le KYC passe à 'incomplete' (resoumission demandée), réinitialiser
            if ($newKycStatus === 'incomplete') {
                // Garder le status actuel, le livreur doit resoumettre
                $courier->kyc_verified_at = null;
            }
        }
    }

    /**
     * Handle the Courier "updated" event.
     * Envoie les notifications après la mise à jour.
     */
    public function updated(Courier $courier): void
    {
        // Envoyer une notification si le kyc_status a changé
        if ($courier->wasChanged('kyc_status')) {
            $kycStatus = $courier->kyc_status;
            $user = $courier->user;

            if ($user && in_array($kycStatus, ['approved', 'rejected', 'incomplete'])) {
                $reason = $kycStatus === 'approved' ? null : $courier->kyc_rejection_reason;
                
                // Ne pas doublonner si la notification a déjà été envoyée (par ex. via action Filament)
                // On vérifie si la notification récente existe
                $recentNotification = $user->notifications()
                    ->where('type', KycStatusNotification::class)
                    ->where('created_at', '>=', now()->subMinutes(1))
                    ->exists();

                if (!$recentNotification) {
                    $user->notify(new KycStatusNotification($kycStatus, $reason));
                }
            }
        }
    }
}
