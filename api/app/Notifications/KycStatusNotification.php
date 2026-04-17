<?php

namespace App\Notifications;

use App\Models\Courier;
use App\Channels\FcmChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class KycStatusNotification extends Notification implements ShouldQueue
{
    use Queueable;

    private string $status;
    private ?string $reason;

    /**
     * @param string $status approved|incomplete|rejected
     * @param string|null $reason Motif (pour incomplete/rejected)
     */
    public function __construct(string $status, ?string $reason = null)
    {
        $this->status = $status;
        $this->reason = $reason;
    }

    public function via(object $notifiable): array
    {
        $channels = ['database'];

        if ($notifiable->fcm_token) {
            $channels[] = FcmChannel::class;
        }

        return $channels;
    }

    public function toFcm(object $notifiable): array
    {
        $config = $this->getMessageConfig();
        $fcmConfig = \App\Services\NotificationSettingsService::getFcmConfig('kyc_status_update');

        return [
            'title' => $config['title'],
            'body' => $config['body'],
            'data' => array_merge($fcmConfig['data'], [
                'type' => 'kyc_status_update',
                'kyc_status' => $this->status,
                'click_action' => 'KYC_STATUS',
            ]),
            'android' => $fcmConfig['android'],
            'apns' => $fcmConfig['apns'],
        ];
    }

    public function toArray(object $notifiable): array
    {
        $config = $this->getMessageConfig();

        return [
            'type' => 'kyc_status_update',
            'kyc_status' => $this->status,
            'title' => $config['title'],
            'body' => $config['body'],
            'reason' => $this->reason,
        ];
    }

    private function getMessageConfig(): array
    {
        return match ($this->status) {
            'approved' => [
                'title' => '✅ Vérification KYC approuvée !',
                'body' => 'Félicitations ! Votre identité a été vérifiée. Vous pouvez maintenant accepter des livraisons.',
            ],
            'incomplete' => [
                'title' => '📤 Documents à resoumettre',
                'body' => $this->reason
                    ? "Certains documents doivent être renvoyés :\n{$this->reason}"
                    : 'Veuillez vérifier et resoumettre vos documents KYC.',
            ],
            'rejected' => [
                'title' => '❌ Vérification KYC rejetée',
                'body' => $this->reason
                    ? "Votre vérification a été rejetée :\n{$this->reason}"
                    : 'Votre vérification KYC a été rejetée. Contactez le support pour plus d\'informations.',
            ],
            default => [
                'title' => 'Mise à jour KYC',
                'body' => 'Le statut de votre vérification KYC a été mis à jour.',
            ],
        };
    }
}
