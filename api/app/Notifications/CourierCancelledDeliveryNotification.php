<?php

namespace App\Notifications;

use App\Models\Delivery;
use App\Services\NotificationSettingsService;
use App\Channels\FcmChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Envoyée au client quand un livreur annule une livraison avant pickup.
 * La commande sera réassignée automatiquement.
 */
class CourierCancelledDeliveryNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public Delivery $delivery,
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

        return $channels;
    }

    public function toFcm(object $notifiable): array
    {
        $order = $this->delivery->order;
        $fcmConfig = NotificationSettingsService::getFcmConfig('courier_cancelled');

        return [
            'title' => '🔄 Livreur indisponible',
            'body' => "Votre commande {$order->reference} est en cours de réassignation à un autre livreur.",
            'data' => array_merge([
                'type' => 'courier_cancelled',
                'order_id' => (string) $order->id,
                'order_reference' => $order->reference,
                'delivery_id' => (string) $this->delivery->id,
                'click_action' => 'ORDER_DETAIL',
            ], $fcmConfig['data']),
            'android' => $fcmConfig['android'],
            'apns' => $fcmConfig['apns'],
        ];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $order = $this->delivery->order;

        return (new MailMessage)
            ->subject("Réassignation en cours - Commande {$order->reference}")
            ->greeting("Bonjour {$notifiable->name},")
            ->line("Le livreur assigné à votre commande **{$order->reference}** n'est plus disponible.")
            ->line('Nous recherchons un nouveau livreur pour vous. Vous serez notifié dès qu\'un livreur accepte.')
            ->action('Suivre ma commande', url("/orders/{$order->id}"));
    }

    public function toArray(object $notifiable): array
    {
        $order = $this->delivery->order;

        return [
            'order_id' => $order->id,
            'order_reference' => $order->reference,
            'delivery_id' => $this->delivery->id,
            'type' => 'courier_cancelled',
            'message' => "Livreur indisponible pour la commande {$order->reference}. Réassignation en cours.",
            'reason' => $this->reason,
        ];
    }
}
