<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class PayoutCompletedNotification extends Notification implements ShouldQueue
{
    use Queueable;

    private float $amount;
    private string $reference;

    public function __construct(float $amount, string $reference)
    {
        $this->amount = $amount;
        $this->reference = $reference;
    }

    public function via(object $notifiable): array
    {
        $channels = ['database'];

        if ($notifiable->fcm_token) {
            $channels[] = \App\Channels\FcmChannel::class;
        }

        return $channels;
    }

    public function toArray(object $notifiable): array
    {
        return [
            'type' => 'payout_completed',
            'title' => 'Décaissement effectué',
            'body' => sprintf(
                'Votre décaissement de %s F CFA (Réf: %s) a été traité avec succès.',
                number_format($this->amount, 0, ',', ' '),
                $this->reference,
            ),
            'amount' => $this->amount,
            'reference' => $this->reference,
        ];
    }

    public function toFcm(object $notifiable): array
    {
        $fcmConfig = \App\Services\NotificationSettingsService::getFcmConfig('payout_completed');

        return [
            'title' => 'Décaissement effectué ✅',
            'body' => sprintf(
                '%s F CFA transférés sur votre compte (Réf: %s)',
                number_format($this->amount, 0, ',', ' '),
                $this->reference,
            ),
            'data' => array_merge($fcmConfig['data'], [
                'type' => 'payout_completed',
                'reference' => $this->reference,
            ]),
            'android' => $fcmConfig['android'],
            'apns' => $fcmConfig['apns'],
        ];
    }
}
