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

class CourierArrivedNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public Delivery $delivery,
        public int $timeoutMinutes,
        public int $freeMinutes,
        public int $feePerMinute,
        public string $recipientType = 'customer' // 'customer', 'courier', 'pharmacy'
    ) {}

    /**
     * Get the notification's delivery channels.
     */
    public function via(object $notifiable): array
    {
        $channels = ['database', FcmChannel::class];

        // SMS pour les arrivées de livreur (client seulement)
        if ($this->recipientType === 'customer' && $notifiable->phone) {
            $channels[] = SmsChannel::class;
        }

        // WhatsApp pour les arrivées de livreur
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
        $data = $this->getMessageForRecipient();
        
        return [
            'title' => $data['title'],
            'message' => $data['message'],
            'type' => 'courier_arrived',
            'order_id' => $this->delivery->order_id,
            'delivery_id' => $this->delivery->id,
            'timeout_minutes' => $this->timeoutMinutes,
            'free_minutes' => $this->freeMinutes,
            'fee_per_minute' => $this->feePerMinute,
            'waiting_started_at' => $this->delivery->waiting_started_at?->toIso8601String(),
            'recipient_type' => $this->recipientType,
        ];
    }

    /**
     * Get the FCM notification representation.
     */
    public function toFcm(object $notifiable): array
    {
        $data = $this->getMessageForRecipient();
        
        // Récupérer les paramètres de notification depuis la config admin
        $fcmConfig = NotificationSettingsService::getFcmConfig('courier_arrived');
        
        return [
            'title' => $data['title'],
            'body' => $data['message'],
            'data' => array_merge([
                'type' => 'courier_arrived',
                'order_id' => (string) $this->delivery->order_id,
                'delivery_id' => (string) $this->delivery->id,
                'timeout_minutes' => (string) $this->timeoutMinutes,
                'free_minutes' => (string) $this->freeMinutes,
                'fee_per_minute' => (string) $this->feePerMinute,
                'waiting_started_at' => $this->delivery->waiting_started_at?->toIso8601String() ?? '',
                'recipient_type' => $this->recipientType,
                'show_countdown' => 'true',
                'countdown_seconds' => (string) ($this->timeoutMinutes * 60),
            ], $fcmConfig['data']),
            'android' => $fcmConfig['android'],
            'apns' => $fcmConfig['apns'],
        ];
    }

    /**
     * Get message content based on recipient type
     */
    private function getMessageForRecipient(): array
    {
        $orderRef = $this->delivery->order->reference ?? "#{$this->delivery->order_id}";
        $totalFeeAfterTimeout = ($this->timeoutMinutes - $this->freeMinutes) * $this->feePerMinute;
        
        return match($this->recipientType) {
            'customer' => [
                'title' => '🚴 Livreur arrivé !',
                'message' => "Votre livreur est arrivé pour la commande {$orderRef}.\n\n" .
                    "⏱️ Vous avez {$this->timeoutMinutes} minutes pour réceptionner.\n\n" .
                    "⚠️ ATTENTION: Après {$this->freeMinutes} minutes gratuites, des frais d'attente de {$this->feePerMinute} FCFA/min seront facturés.\n\n" .
                    "❌ Si vous n'êtes pas disponible après {$this->timeoutMinutes} min, la livraison sera annulée avec {$totalFeeAfterTimeout} FCFA de frais.",
            ],
            'courier' => [
                'title' => '⏱️ Minuterie d\'attente démarrée',
                'message' => "Attente client pour commande {$orderRef}.\n\n" .
                    "⏱️ Temps max: {$this->timeoutMinutes} minutes\n" .
                    "💰 Après {$this->freeMinutes} min: +{$this->feePerMinute} FCFA/min pour le client\n\n" .
                    "La livraison s'annulera automatiquement après le délai.",
            ],
            'pharmacy' => [
                'title' => '📍 Livreur arrivé chez le client',
                'message' => "Le livreur est arrivé pour la commande {$orderRef}.\n\n" .
                    "⏱️ Attente max: {$this->timeoutMinutes} minutes\n" .
                    "En cas de non-réponse du client, la commande sera annulée automatiquement.",
            ],
            default => [
                'title' => 'Livreur arrivé',
                'message' => "Le livreur est arrivé pour la commande {$orderRef}.",
            ],
        };
    }

    /**
     * Get the SMS representation of the notification.
     */
    public function toSms(object $notifiable): ?string
    {
        if ($this->recipientType !== 'customer') {
            return null;
        }

        $orderRef = $this->delivery->order->reference ?? "#{$this->delivery->order_id}";
        return "DR-PHARMA: Votre livreur est arrivé pour la commande {$orderRef}! Vous avez {$this->timeoutMinutes} min pour réceptionner. Après {$this->freeMinutes} min: frais d'attente de {$this->feePerMinute} FCFA/min.";
    }

    /**
     * Get the WhatsApp representation of the notification.
     */
    public function toWhatsApp(object $notifiable): ?array
    {
        // Only send WhatsApp to customers
        if ($this->recipientType !== 'customer') {
            return null;
        }

        $courierName = $this->delivery->courier?->name ?? 'Votre livreur';

        return [
            'type' => 'template',
            'template_name' => 'courier_arrived',
            'placeholders' => [
                $notifiable->name ?? 'Client',
                $courierName,
            ],
        ];
    }
}
