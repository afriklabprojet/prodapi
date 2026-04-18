<?php

namespace App\Notifications;

use App\Models\Order;
use App\Services\NotificationSettingsService;
use App\Channels\FcmChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Envoyée au client quand un paiement échoue.
 */
class PaymentFailedNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public Order $order,
        public string $reason = ''
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

        return $channels;
    }

    public function toFcm(object $notifiable): array
    {
        $fcmConfig = NotificationSettingsService::getFcmConfig('payment_failed');

        return [
            'title' => '❌ Paiement échoué',
            'body' => "Le paiement pour la commande {$this->order->reference} a échoué. Veuillez réessayer.",
            'data' => array_merge([
                'type' => 'payment_failed',
                'order_id' => (string) $this->order->id,
                'order_reference' => $this->order->reference,
                'amount' => (string) $this->order->total_amount,
                'reason' => $this->reason,
                'click_action' => 'ORDER_DETAIL',
            ], $fcmConfig['data']),
            'android' => $fcmConfig['android'],
            'apns' => $fcmConfig['apns'],
        ];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject("Paiement échoué - Commande {$this->order->reference}")
            ->greeting("Bonjour {$notifiable->name},")
            ->line("Le paiement pour votre commande **{$this->order->reference}** a échoué.")
            ->line("**Montant:** {$this->order->total_amount} FCFA")
            ->when($this->reason, fn ($mail) => $mail->line("**Raison:** {$this->reason}"))
            ->line('Veuillez réessayer le paiement ou utiliser un autre moyen de paiement.')
            ->action('Réessayer le paiement', url("/orders/{$this->order->id}/pay"))
            ->line('Si le problème persiste, contactez notre support.');
    }

    public function toArray(object $notifiable): array
    {
        return [
            'order_id' => $this->order->id,
            'order_reference' => $this->order->reference,
            'type' => 'payment_failed',
            'message' => "Paiement échoué pour la commande {$this->order->reference}",
            'amount' => $this->order->total_amount,
            'reason' => $this->reason,
        ];
    }
}
