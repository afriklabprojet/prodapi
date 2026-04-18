<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class AdminAlertMail extends Mailable
{
    use Queueable, SerializesModels;

    public string $alertType;
    public array $data;

    /**
     * Create a new message instance.
     */
    public function __construct(string $alertType, array $data = [])
    {
        $this->alertType = $alertType;
        $this->data = $data;
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        $subjects = [
            'no_courier_available' => '⚠️ Aucun livreur disponible',
            'kyc_pending' => '📋 Nouvelle demande KYC en attente',
            'withdrawal_request' => '💰 Demande de retrait',
            'payment_failed' => '❌ Échec de paiement',
            'high_value_order' => '🔔 Commande de valeur élevée',
            'wallet_reconciliation' => '🔍 Écarts de solde wallets détectés',
            'daily_digest' => '📊 Rapport quotidien DR-PHARMA',
            'ticket_escalation' => '🎫 Tickets support escaladés',
            'failed_jobs' => '🚨 Jobs en échec détectés',
            'withdrawal_timeout' => '⏰ Retraits bloqués auto-échoués',
        ];

        return new Envelope(
            subject: $subjects[$this->alertType] ?? "Alerte Admin: {$this->alertType}",
        );
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            markdown: 'emails.admin-alert',
            with: [
                'alertType' => $this->alertType,
                'data' => $this->data,
                'alertTitle' => $this->getAlertTitle(),
                'alertMessage' => $this->getAlertMessage(),
            ],
        );
    }

    protected function getAlertTitle(): string
    {
        return match ($this->alertType) {
            'no_courier_available' => 'Aucun livreur disponible',
            'kyc_pending' => 'Demande KYC en attente',
            'withdrawal_request' => 'Demande de retrait',
            'payment_failed' => 'Échec de paiement',
            'high_value_order' => 'Commande de valeur élevée',
            'wallet_reconciliation' => 'Écarts de solde wallets',
            'daily_digest' => 'Rapport quotidien',
            'ticket_escalation' => 'Tickets support escaladés',
            'failed_jobs' => 'Jobs en échec détectés',
            'withdrawal_timeout' => 'Retraits bloqués auto-échoués',
            default => ucfirst(str_replace('_', ' ', $this->alertType)),
        };
    }

    protected function getAlertMessage(): string
    {
        return match ($this->alertType) {
            'no_courier_available' => sprintf(
                'La commande %s de la pharmacie %s n\'a pas pu être assignée à un livreur.',
                $this->data['order_reference'] ?? 'N/A',
                $this->data['pharmacy_name'] ?? 'N/A'
            ),
            'kyc_pending' => 'Une nouvelle demande de vérification KYC nécessite votre attention.',
            'withdrawal_request' => sprintf('Demande de retrait de %s FCFA.', $this->data['amount'] ?? '0'),
            'payment_failed' => sprintf(
                'Le paiement pour la commande %s a échoué.',
                $this->data['order_reference'] ?? 'N/A'
            ),
            'high_value_order' => sprintf(
                'Commande de %s FCFA reçue.',
                $this->data['total_amount'] ?? '0'
            ),
            'wallet_reconciliation' => sprintf(
                '%d écart(s) de solde détecté(s) sur %d wallets vérifiés.',
                $this->data['discrepancy_count'] ?? 0,
                $this->data['total_checked'] ?? 0
            ),
            'daily_digest' => sprintf(
                'Résumé de la période %s.',
                $this->data['period'] ?? 'N/A'
            ),
            'ticket_escalation' => sprintf(
                '%d ticket(s) escaladé(s) en haute priorité.',
                $this->data['count'] ?? 0
            ),
            'failed_jobs' => sprintf(
                '%d job(s) en échec dans les 2 dernières heures (%d total en attente). Période: %s',
                $this->data['recent_count'] ?? 0,
                $this->data['total_count'] ?? 0,
                $this->data['period'] ?? 'N/A'
            ),
            'withdrawal_timeout' => sprintf(
                '%d demande(s) de retrait bloquée(s) >48h auto-échouée(s). IDs: %s',
                $this->data['count'] ?? 0,
                implode(', ', $this->data['ids'] ?? [])
            ),
            default => 'Une alerte nécessite votre attention.',
        };
    }
}
