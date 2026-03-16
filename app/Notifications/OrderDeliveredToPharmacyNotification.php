<?php

namespace App\Notifications;

use App\Models\Order;
use App\Models\Delivery;
use App\Channels\SmsChannel;
use App\Channels\WhatsAppChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Notification envoyée à la pharmacie quand le coursier livre au client
 */
class OrderDeliveredToPharmacyNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public Order $order;
    public Delivery $delivery;

    public function __construct(Order $order, Delivery $delivery)
    {
        $this->order = $order;
        $this->delivery = $delivery;
    }

    public function via(object $notifiable): array
    {
        $channels = ['database'];

        if ($notifiable->email) {
            $channels[] = 'mail';
        }

        if ($notifiable->fcm_token) {
            $channels[] = \App\Channels\FcmChannel::class;
        }

        // SMS pour la notification de livraison
        if ($notifiable->phone) {
            $channels[] = SmsChannel::class;
        }

        // WhatsApp pour la notification de livraison
        if ($notifiable->phone && config('whatsapp.notifications.delivery', true)) {
            $channels[] = WhatsAppChannel::class;
        }

        return $channels;
    }

    /**
     * FCM Push Notification pour l'app pharmacie
     */
    public function toFcm(object $notifiable): array
    {
        $customer = $this->order->customer;
        $courier = $this->delivery->courier;
        
        return [
            'title' => '✅ Livraison Confirmée !',
            'body' => "Commande #{$this->order->reference} livrée à {$customer->name} par {$courier->user->name}",
            'data' => [
                'type' => 'order_delivered',
                'order_id' => (string) $this->order->id,
                'order_reference' => $this->order->reference,
                'delivery_id' => (string) $this->delivery->id,
                'customer_name' => $customer->name,
                'courier_name' => $courier->user->name,
                'delivered_at' => now()->toIso8601String(),
                'click_action' => 'ORDER_DETAIL',
            ],
        ];
    }

    /**
     * Email notification
     */
    public function toMail(object $notifiable): MailMessage
    {
        $customer = $this->order->customer;
        $courier = $this->delivery->courier;

        return (new MailMessage)
            ->subject("✅ Commande livrée - {$this->order->reference}")
            ->greeting("Bonjour,")
            ->line('Bonne nouvelle ! Une commande a été livrée avec succès.')
            ->line('')
            ->line("**Référence:** {$this->order->reference}")
            ->line("**Client:** {$customer->name}")
            ->line("**Livreur:** {$courier->user->name}")
            ->line("**Montant:** {$this->order->total_amount} FCFA")
            ->line("**Livrée le:** " . now()->format('d/m/Y à H:i'))
            ->line('')
            ->line('Le montant sera crédité sur votre compte.')
            ->action('Voir la commande', url("/pharmacy/orders/{$this->order->id}"))
            ->line('Merci de votre confiance !');
    }

    /**
     * Database notification
     */
    public function toArray(object $notifiable): array
    {
        $customer = $this->order->customer;
        $courier = $this->delivery->courier;

        return [
            'type' => 'order_delivered',
            'order_id' => $this->order->id,
            'order_reference' => $this->order->reference,
            'delivery_id' => $this->delivery->id,
            'customer_name' => $customer->name,
            'courier_name' => $courier->user->name,
            'total_amount' => $this->order->total_amount,
            'delivered_at' => now()->toIso8601String(),
            'message' => "Commande #{$this->order->reference} livrée à {$customer->name}",
        ];
    }

    /**
     * Get the SMS representation of the notification.
     */
    public function toSms(object $notifiable): string
    {
        $customer = $this->order->customer;
        $courier = $this->delivery->courier;
        return "DR-PHARMA: ✅ Commande #{$this->order->reference} livrée à {$customer->name} par {$courier->user->name}. Montant: {$this->order->total_amount} FCFA.";
    }

    /**
     * Get the WhatsApp representation of the notification.
     */
    public function toWhatsApp(object $notifiable): array
    {
        $customer = $this->order->customer;
        $courier = $this->delivery->courier;

        return [
            'type' => 'template',
            'template_name' => 'order_delivered_pharmacy',
            'placeholders' => [
                $notifiable->name ?? 'Pharmacie',
                $this->order->reference,
                $customer->name ?? 'Client',
                $courier->user->name ?? 'Livreur',
                ($this->order->total_amount ?? 0) . ' FCFA',
            ],
        ];
    }
}
