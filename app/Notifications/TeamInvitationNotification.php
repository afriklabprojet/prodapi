<?php

namespace App\Notifications;

use App\Models\TeamInvitation;
use App\Channels\FcmChannel;
use App\Channels\SmsChannel;
use App\Channels\WhatsAppChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Notification envoyée quand un utilisateur est invité à rejoindre une pharmacie
 */
class TeamInvitationNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public TeamInvitation $invitation
    ) {}

    public function via($notifiable): array
    {
        $channels = ['database', 'mail'];

        // FCM pour les notifications push
        if ($notifiable->fcm_token) {
            $channels[] = FcmChannel::class;
        }

        // SMS si le téléphone est disponible
        if ($notifiable->phone || $this->invitation->phone) {
            $channels[] = SmsChannel::class;
        }

        return $channels;
    }

    public function toDatabase($notifiable): array
    {
        $pharmacyName = $this->invitation->pharmacy?->name ?? 'Une pharmacie';
        $inviterName = $this->invitation->invitedBy?->name ?? 'Un administrateur';
        $roleName = $this->getRoleName();

        return [
            'type' => 'team_invitation',
            'title' => "🏥 Invitation - {$pharmacyName}",
            'body' => "{$inviterName} vous invite à rejoindre {$pharmacyName} en tant que {$roleName}",
            'invitation_id' => $this->invitation->id,
            'invitation_token' => $this->invitation->token,
            'pharmacy_id' => $this->invitation->pharmacy_id,
            'pharmacy_name' => $pharmacyName,
            'inviter_name' => $inviterName,
            'role' => $this->invitation->role?->value,
            'expires_at' => $this->invitation->expires_at?->toISOString(),
            'message' => "{$inviterName} vous invite à rejoindre {$pharmacyName} en tant que {$roleName}",
        ];
    }

    public function toMail($notifiable): MailMessage
    {
        $pharmacyName = $this->invitation->pharmacy?->name ?? 'Une pharmacie';
        $inviterName = $this->invitation->invitedBy?->name ?? 'Un administrateur';
        $roleName = $this->getRoleName();
        $expiresIn = $this->invitation->expires_at?->diffForHumans() ?? '7 jours';

        $acceptUrl = config('app.frontend_url', config('app.url')) . 
                     '/invitation/accept?token=' . $this->invitation->token;

        return (new MailMessage)
            ->subject("Invitation à rejoindre {$pharmacyName} - DR PHARMA")
            ->greeting("Bonjour {$notifiable->name},")
            ->line("{$inviterName} vous invite à rejoindre l'équipe de **{$pharmacyName}** sur DR PHARMA.")
            ->line("Rôle proposé : **{$roleName}**")
            ->action('Accepter l\'invitation', $acceptUrl)
            ->line("Cette invitation expire {$expiresIn}.")
            ->line("Si vous n'avez pas demandé cette invitation, vous pouvez ignorer cet email.")
            ->salutation('L\'équipe DR PHARMA');
    }

    public function toFcm($notifiable): array
    {
        $pharmacyName = $this->invitation->pharmacy?->name ?? 'Une pharmacie';
        $inviterName = $this->invitation->invitedBy?->name ?? 'Un administrateur';
        $roleName = $this->getRoleName();

        return [
            'title' => "🏥 Invitation à rejoindre {$pharmacyName}",
            'body' => "{$inviterName} vous invite en tant que {$roleName}",
            'data' => [
                'type' => 'team_invitation',
                'invitation_id' => (string) $this->invitation->id,
                'invitation_token' => $this->invitation->token,
                'pharmacy_id' => (string) $this->invitation->pharmacy_id,
                'pharmacy_name' => $pharmacyName,
                'role' => $this->invitation->role?->value ?? '',
                'click_action' => 'TEAM_INVITATION',
            ],
            'android' => [
                'priority' => 'high',
                'notification' => [
                    'channel_id' => 'team_notifications',
                    'sound' => 'default',
                ],
            ],
            'apns' => [
                'payload' => [
                    'aps' => [
                        'sound' => 'default',
                        'badge' => 1,
                    ],
                ],
            ],
        ];
    }

    public function toSms($notifiable): string
    {
        $pharmacyName = $this->invitation->pharmacy?->name ?? 'Une pharmacie';
        $roleName = $this->getRoleName();

        return "DR PHARMA: Vous êtes invité(e) à rejoindre {$pharmacyName} en tant que {$roleName}. " .
               "Ouvrez l'app DR PHARMA pour accepter.";
    }

    /**
     * Obtient le nom lisible du rôle
     */
    private function getRoleName(): string
    {
        return match($this->invitation->role?->value) {
            'owner' => 'Propriétaire',
            'manager' => 'Manager',
            'pharmacist' => 'Pharmacien',
            'assistant' => 'Assistant',
            'viewer' => 'Lecteur',
            default => $this->invitation->role?->value ?? 'Membre',
        };
    }
}
