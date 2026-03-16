<?php

namespace App\Notifications;

use App\Models\Delivery;
use App\Services\NotificationSettingsService;
use App\Channels\SmsChannel;
use App\Channels\WhatsAppChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use App\Channels\FcmChannel;

class DeliveryTimeoutCancelledNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public Delivery $delivery,
        public int $waitingMinutes,
        public int $waitingFee,
        public string $recipientType // 'customer', 'courier', 'pharmacy'
    ) {}

    /**
     * Get the notification's delivery channels.
     */
    public function via(object $notifiable): array
    {
        $channels = ['database', FcmChannel::class];

        // SMS pour les annulations timeout
        if ($notifiable->phone) {
            $channels[] = SmsChannel::class;
        }

        // WhatsApp pour les annulations timeout
        if ($notifiable->phone && config('whatsapp.notifications.delivery', true)) {
            $channels[] = WhatsAppChannel::class;
        }

        return $channels;
    }

    /**
     * Get the notification data for database.
     */
    public function toArray(object $notifiable): array
    {
        $title = match($this->recipientType) {
            'customer' => 'Livraison annulée',
            'courier' => 'Livraison annulée - Timeout',
            'pharmacy' => 'Commande annulée - Client indisponible',
            default => 'Livraison annulée',
        };

        $message = match($this->recipientType) {
            'customer' => "Votre commande a été annulée car vous n'étiez pas disponible après {$this->waitingMinutes} minutes d'attente. Frais d'attente: {$this->waitingFee} FCFA",
            'courier' => "La livraison a été annulée automatiquement. Le client n'était pas disponible. Vous pouvez accepter de nouvelles livraisons.",
            'pharmacy' => "La commande a été annulée automatiquement. Le client n'était pas disponible après {$this->waitingMinutes} minutes d'attente.",
            default => 'Livraison annulée pour timeout',
        };

        return [
            'title' => $title,
            'message' => $message,
            'type' => 'delivery_timeout_cancelled',
            'order_id' => $this->delivery->order_id,
            'delivery_id' => $this->delivery->id,
            'waiting_minutes' => $this->waitingMinutes,
            'waiting_fee' => $this->waitingFee,
        ];
    }

    /**
     * Get the FCM notification representation.
     */
    public function toFcm(object $notifiable): array
    {
        $data = $this->toArray($notifiable);
        
        // Récupérer les paramètres de notification depuis la config admin
        $fcmConfig = NotificationSettingsService::getFcmConfig('delivery_timeout');
        
        return [
            'title' => $data['title'],
            'body' => $data['message'],
            'data' => array_merge([
                'type' => 'delivery_timeout_cancelled',
                'order_id' => (string) $this->delivery->order_id,
                'delivery_id' => (string) $this->delivery->id,
                'waiting_minutes' => (string) $this->waitingMinutes,
                'waiting_fee' => (string) $this->waitingFee,
            ], $fcmConfig['data']),
            'android' => $fcmConfig['android'],
            'apns' => $fcmConfig['apns'],
        ];
    }

    /**
     * Get the SMS representation of the notification.
     */
    public function toSms(object $notifiable): string
    {
        $orderRef = $this->delivery->order?->reference ?? 'N/A';

        return match($this->recipientType) {
            'customer' => "DR-PHARMA: Votre commande {$orderRef} a été annulée (non disponible après {$this->waitingMinutes} min). Frais d'attente: {$this->waitingFee} FCFA.",
            'courier' => "DR-PHARMA: Livraison {$orderRef} annulée (timeout client). Vous pouvez accepter de nouvelles livraisons.",
            'pharmacy' => "DR-PHARMA: Commande {$orderRef} annulée. Client indisponible après {$this->waitingMinutes} min d'attente.",
            default => "DR-PHARMA: Livraison annulée pour timeout - Commande {$orderRef}.",
        };
    }

    /**
     * Get the WhatsApp representation of the notification.
     */
    public function toWhatsApp(object $notifiable): array
    {
        $orderRef = $this->delivery->order?->reference ?? 'N/A';

        return match($this->recipientType) {
            'customer' => [
                'type' => 'template',
                'template_name' => 'delivery_timeout_customer',
                'placeholders' => [
                    $notifiable->name ?? 'Client',
                    (string) $this->waitingMinutes,
                    (string) $this->waitingFee . ' FCFA',
                ],
            ],
            'courier' => [
                'type' => 'template',
                'template_name' => 'delivery_timeout_courier',
                'placeholders' => [
                    $notifiable->name ?? 'Livreur',
                    $orderRef,
                ],
            ],
            'pharmacy' => [
                'type' => 'template',
                'template_name' => 'delivery_timeout_pharmacy',
                'placeholders' => [
                    $notifiable->name ?? 'Pharmacie',
                    $orderRef,
                    (string) $this->waitingMinutes,
                ],
            ],
            default => [
                'type' => 'text',
                'text' => "Livraison annulée pour timeout - Commande {$orderRef}",
            ],
        };
    }
}
