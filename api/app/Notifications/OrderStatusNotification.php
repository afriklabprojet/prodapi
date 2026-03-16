<?php

namespace App\Notifications;

use App\Models\Order;
use App\Channels\WhatsAppChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class OrderStatusNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public Order $order;
    public string $status;
    public ?string $additionalMessage;

    /**
     * Create a new notification instance.
     */
    public function __construct(Order $order, string $status, ?string $additionalMessage = null)
    {
        $this->order = $order;
        $this->status = $status;
        $this->additionalMessage = $additionalMessage;
    }

    /**
     * Get the notification's delivery channels.
     *
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        $channels = ['database'];

        // Email for customers and pharmacy
        if ($notifiable->email) {
            $channels[] = 'mail';
        }

        // SMS for important status updates
        if (in_array($this->status, ['confirmed', 'assigned', 'delivered']) && $notifiable->phone) {
            $channels[] = \App\Channels\SmsChannel::class;
        }

        // FCM channel
        if ($notifiable->fcm_token) {
            $channels[] = \App\Channels\FcmChannel::class;
        }

        // WhatsApp for important status updates
        if (in_array($this->status, ['confirmed', 'assigned', 'on_the_way', 'delivered', 'cancelled'])) {
            if ($notifiable->phone && config('whatsapp.notifications.order_status', true)) {
                $channels[] = WhatsAppChannel::class;
            }
        }

        return $channels;
    }

    /**
     * Get the FCM representation of the notification.
     */
    public function toFcm(object $notifiable): array
    {
        $titles = [
            'confirmed' => 'Commande confirmée ✅',
            'preparing' => 'Préparation en cours 💊',
            'ready_for_pickup' => 'Commande prête 🛍️',
            'assigned' => 'Livreur assigné 🛵',
            'on_the_way' => 'En route 🚚',
            'delivered' => 'Livrée 🎉',
            'cancelled' => 'Commande annulée ❌',
        ];

        $bodies = [
            'confirmed' => 'Votre commande a été acceptée par la pharmacie.',
            'preparing' => 'La pharmacie prépare votre commande.',
            'ready_for_pickup' => 'Votre commande est prête à être récupérée.',
            'assigned' => 'Un livreur a été assigné à votre commande.',
            'on_the_way' => 'Votre commande est en route vers vous.',
            'delivered' => 'Votre commande a été livrée avec succès.',
            'cancelled' => 'Votre commande a été annulée.',
        ];

        return [
            'title' => $titles[$this->status] ?? 'Mise à jour commande',
            'body' => $this->additionalMessage ?? ($bodies[$this->status] ?? "Le statut de votre commande est maintenant : {$this->status}"),
            'data' => [
                'type' => 'order_status',
                'order_id' => (string) $this->order->id,
                'status' => $this->status,
            ],
        ];
    }

    /**
     * Get the SMS representation of the notification.
     */
    public function toSms(object $notifiable): string
    {
        $message = "DR-PHARMA: ";
        
        switch ($this->status) {
            case 'confirmed':
                $message .= "Votre commande {$this->order->reference} a été confirmée par la pharmacie.";
                break;
            case 'assigned':
                $courier = $this->order->delivery?->courier;
                $courierInfo = $courier ? " Livreur: {$courier->name} ({$courier->phone})" : "";
                $message .= "Un livreur a été assigné à votre commande {$this->order->reference}.{$courierInfo}";
                break;
            case 'delivered':
                $message .= "Votre commande {$this->order->reference} a été livrée! Merci d'avoir utilisé DR-PHARMA.";
                break;
            default:
                $message .= "Votre commande {$this->order->reference} a été mise à jour.";
        }

        return $message;
    }

    /**
     * Get the WhatsApp representation of the notification.
     */
    public function toWhatsApp(object $notifiable): ?array
    {
        $customerName = $notifiable->name ?? 'Client';
        $reference = $this->order->reference;
        $pharmacyName = $this->order->pharmacy?->name ?? 'la pharmacie';

        return match ($this->status) {
            'confirmed' => [
                'type' => 'template',
                'template_name' => 'order_confirmed',
                'placeholders' => [$customerName, $reference, $pharmacyName],
            ],
            'ready', 'ready_for_pickup' => [
                'type' => 'template',
                'template_name' => 'order_ready',
                'placeholders' => [$customerName, $reference],
            ],
            'assigned' => [
                'type' => 'template',
                'template_name' => 'delivery_assigned',
                'placeholders' => [
                    $customerName,
                    $reference,
                    $this->order->delivery?->courier?->name ?? 'Votre livreur',
                    $this->order->delivery?->courier?->phone ?? '',
                ],
            ],
            'delivered' => [
                'type' => 'template',
                'template_name' => 'order_delivered',
                'placeholders' => [
                    $customerName,
                    $reference,
                    ($this->order->total_amount ?? 0) . ' FCFA',
                ],
            ],
            'cancelled' => [
                'type' => 'template',
                'template_name' => 'order_cancelled',
                'placeholders' => [
                    $customerName,
                    $reference,
                    $this->order->cancellation_reason ?? 'Non spécifiée',
                ],
            ],
            default => null,
        };
    }

    /**
     * Get the mail representation of the notification.
     */
    public function toMail(object $notifiable): MailMessage
    {
        $message = (new MailMessage)
            ->subject($this->getEmailSubject())
            ->greeting($this->getGreeting($notifiable))
            ->line($this->getStatusMessage());

        // Add order details
        $message->line("**Référence commande:** {$this->order->reference}")
            ->line("**Montant total:** {$this->order->total_amount} {$this->order->currency}");

        // Status-specific content
        switch ($this->status) {
            case 'confirmed':
                $message->line('Votre commande a été confirmée par la pharmacie.')
                    ->line('Vous serez notifié lorsqu\'elle sera prête pour livraison.');
                break;

            case 'ready':
                $message->line('Votre commande est prête et sera livrée bientôt.')
                    ->line('Un livreur vous contactera sous peu.');
                break;

            case 'assigned':
                if ($this->order->delivery && $this->order->delivery->courier) {
                    $courier = $this->order->delivery->courier;
                    $message->line("**Livreur:** {$courier->name}")
                        ->line("**Contact:** {$courier->phone}");
                }
                break;

            case 'picked_up':
                $message->line('Votre commande est en route vers vous!')
                    ->line("**Adresse de livraison:** {$this->order->delivery_address}");
                break;

            case 'delivered':
                $message->line('Votre commande a été livrée avec succès!')
                    ->line('Merci d\'avoir utilisé DR-PHARMA.');
                break;

            case 'cancelled':
                $message->line('Votre commande a été annulée.')
                    ->line("**Raison:** {$this->order->cancellation_reason}");
                break;
        }

        if ($this->additionalMessage) {
            $message->line($this->additionalMessage);
        }

        $message->action('Voir ma commande', url("/orders/{$this->order->id}"))
            ->line('Merci d\'utiliser DR-PHARMA!');

        return $message;
    }

    /**
     * Get the array representation of the notification.
     *
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        return [
            'order_id' => $this->order->id,
            'order_reference' => $this->order->reference,
            'type' => 'order_status',
            'status' => $this->status,
            'title' => $this->getNotificationTitle(),
            'body' => $this->additionalMessage ?? $this->getStatusMessage(),
            'message' => $this->getStatusMessage(),
            'additional_message' => $this->additionalMessage,
            'order_data' => [
                'total_amount' => $this->order->total_amount,
                'currency' => $this->order->currency,
                'delivery_address' => $this->order->delivery_address,
            ],
        ];
    }

    /**
     * Get email subject based on status
     */
    protected function getEmailSubject(): string
    {
        return match ($this->status) {
            'confirmed' => 'Commande confirmée - ' . $this->order->reference,
            'ready' => 'Commande prête - ' . $this->order->reference,
            'assigned' => 'Livreur assigné - ' . $this->order->reference,
            'picked_up' => 'Commande en livraison - ' . $this->order->reference,
            'delivered' => 'Commande livrée - ' . $this->order->reference,
            'cancelled' => 'Commande annulée - ' . $this->order->reference,
            default => 'Mise à jour de votre commande - ' . $this->order->reference,
        };
    }

    /**
     * Get notification title
     */
    protected function getNotificationTitle(): string
    {
        return match ($this->status) {
            'confirmed' => '✅ Commande confirmée',
            'ready' => '📦 Commande prête',
            'assigned' => '🚴 Livreur en route',
            'picked_up' => '🚀 En livraison',
            'delivered' => '🎉 Livré!',
            'cancelled' => '❌ Commande annulée',
            default => '📱 Mise à jour',
        };
    }

    /**
     * Get status message
     */
    protected function getStatusMessage(): string
    {
        return match ($this->status) {
            'confirmed' => 'Votre commande a été confirmée par la pharmacie.',
            'ready' => 'Votre commande est prête pour la livraison.',
            'assigned' => 'Un livreur a été assigné à votre commande.',
            'picked_up' => 'Votre commande est en cours de livraison.',
            'delivered' => 'Votre commande a été livrée avec succès!',
            'cancelled' => 'Votre commande a été annulée.',
            default => 'Votre commande a été mise à jour.',
        };
    }

    /**
     * Get greeting based on user type
     */
    protected function getGreeting(object $notifiable): string
    {
        return "Bonjour {$notifiable->name},";
    }
}
