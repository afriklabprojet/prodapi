<?php

namespace App\Notifications;

use App\Models\Order;
use App\Services\NotificationSettingsService;
use App\Channels\FcmChannel;
use App\Channels\SmsChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Envoyée au client quand la pharmacie rejette une ordonnance.
 */
class PrescriptionRejectedNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public Order $order,
        public string $rejectionReason = ''
    ) {
        $this->queue = 'notifications';
    }

    public function via(object $notifiable): array
    {
        $channels = ['database'];

        if ($notifiable->fcm_token) {
            $channels[] = FcmChannel::class;
        }
        if ($notifiable->email) {
            $channels[] = 'mail';
        }
        if ($notifiable->phone) {
            $channels[] = SmsChannel::class;
        }

        return $channels;
    }

    public function toFcm(object $notifiable): array
    {
        $pharmacy = $this->order->pharmacy;
        $fcmConfig = NotificationSettingsService::getFcmConfig('prescription_rejected');

        return [
            'title' => '📋 Ordonnance refusée',
            'body' => "Votre ordonnance pour {$pharmacy->name} a été refusée. {$this->rejectionReason}",
            'data' => array_merge([
                'type' => 'prescription_rejected',
                'order_id' => (string) $this->order->id,
                'order_reference' => $this->order->reference,
                'pharmacy_name' => $pharmacy->name,
                'reason' => $this->rejectionReason,
                'click_action' => 'ORDER_DETAIL',
            ], $fcmConfig['data']),
            'android' => $fcmConfig['android'],
            'apns' => $fcmConfig['apns'],
        ];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $pharmacy = $this->order->pharmacy;

        return (new MailMessage)
            ->subject("Ordonnance refusée - {$pharmacy->name}")
            ->greeting("Bonjour {$notifiable->name},")
            ->line("Votre ordonnance soumise à **{$pharmacy->name}** a été refusée.")
            ->when($this->rejectionReason, fn ($mail) => $mail->line("**Raison:** {$this->rejectionReason}"))
            ->line('Vous pouvez soumettre une nouvelle ordonnance ou contacter la pharmacie pour plus de détails.')
            ->action('Nouvelle ordonnance', url('/prescriptions/new'))
            ->line('Si vous pensez qu\'il s\'agit d\'une erreur, contactez notre support.');
    }

    public function toSms(object $notifiable): string
    {
        return "DR-PHARMA: Votre ordonnance ({$this->order->reference}) a été refusée par la pharmacie. Raison: {$this->rejectionReason}. Soumettez-en une nouvelle via l'app.";
    }

    public function toArray(object $notifiable): array
    {
        return [
            'order_id' => $this->order->id,
            'order_reference' => $this->order->reference,
            'type' => 'prescription_rejected',
            'pharmacy_name' => $this->order->pharmacy->name,
            'message' => "Ordonnance refusée par {$this->order->pharmacy->name}",
            'reason' => $this->rejectionReason,
        ];
    }
}
