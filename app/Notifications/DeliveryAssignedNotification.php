<?php

namespace App\Notifications;

use App\Models\Delivery;
use App\Services\NotificationSettingsService;
use App\Services\WalletService;
use App\Channels\SmsChannel;
use App\Channels\WhatsAppChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class DeliveryAssignedNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public Delivery $delivery;

    public function __construct(Delivery $delivery)
    {
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

        // SMS pour les notifications de livraison
        if ($notifiable->phone) {
            $channels[] = SmsChannel::class;
        }

        // WhatsApp pour les notifications de livraison
        if ($notifiable->phone && config('whatsapp.notifications.delivery', true)) {
            $channels[] = WhatsAppChannel::class;
        }

        return $channels;
    }

    public function toFcm(object $notifiable): array
    {
        $order = $this->delivery->order;
        $pharmacy = $order->pharmacy;
        
        $fcmConfig = NotificationSettingsService::getFcmConfig('delivery_assigned');
        
        $deliveryFee = (float) ($this->delivery->delivery_fee ?? 0);
        $commissionAmount = WalletService::getCommissionAmount();
        $estimatedEarnings = max(0, $deliveryFee - $commissionAmount);
        
        $body = "🏪 {$pharmacy->name}\n📍 {$this->delivery->pickup_address}\n📏 Distance: {$this->delivery->estimated_distance} km\n💰 Gain estimé: {$estimatedEarnings} FCFA";

        return [
            'title' => '🚨 NOUVELLE LIVRAISON ! 📦',
            'body' => $body,
            'data' => array_merge([
                'type' => 'delivery_assigned',
                'delivery_id' => (string) $this->delivery->id,
                'order_id' => (string) $order->id,
                'order_reference' => $order->reference,
                'pharmacy_name' => $pharmacy->name,
                'pharmacy_address' => $this->delivery->pickup_address,
                'delivery_address' => $this->delivery->delivery_address,
                'estimated_distance' => (string) $this->delivery->estimated_distance,
                'delivery_fee' => (string) $deliveryFee,
                'amount' => (string) $deliveryFee,
                'estimated_earnings' => (string) $estimatedEarnings,
                'customer_phone' => $order->customer_phone ?? '',
                'click_action' => 'DELIVERY_DETAIL',
            ], $fcmConfig['data']),
            'android' => $fcmConfig['android'],
            'apns' => $fcmConfig['apns'],
        ];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $order = $this->delivery->order;
        $pharmacy = $order->pharmacy;

        return (new MailMessage)
            ->subject("Nouvelle livraison assignée - #{$this->delivery->id}")
            ->greeting("Bonjour {$notifiable->name},")
            ->line('Une nouvelle livraison vous a été assignée!')
            ->line("**Commande:** {$order->reference}")
            ->line("**Pharmacie:** {$pharmacy->name}")
            ->line("**Adresse pickup:** {$this->delivery->pickup_address}")
            ->line("**Adresse livraison:** {$this->delivery->delivery_address}")
            ->line("**Frais de livraison:** {$this->delivery->delivery_fee} XOF")
            ->action('Voir la livraison', url("/courier/deliveries/{$this->delivery->id}"))
            ->line('Merci pour votre service!');
    }

    public function toArray(object $notifiable): array
    {
        $order = $this->delivery->order;
        $deliveryFee = (float) ($this->delivery->delivery_fee ?? 0);
        $commissionAmount = WalletService::getCommissionAmount();
        $estimatedEarnings = max(0, $deliveryFee - $commissionAmount);

        return [
            'delivery_id' => $this->delivery->id,
            'order_id' => $order->id,
            'order_reference' => $order->reference,
            'type' => 'delivery_assigned',
            'action' => 'accept_delivery',
            'message' => "Nouvelle livraison assignée: {$order->reference}",
            'delivery_data' => [
                'pickup_address' => $this->delivery->pickup_address,
                'delivery_address' => $this->delivery->delivery_address,
                'delivery_fee' => $deliveryFee,
                'amount' => $deliveryFee,
                'estimated_earnings' => $estimatedEarnings,
                'pharmacy_name' => $order->pharmacy->name,
                'customer_phone' => $order->customer_phone,
            ],
        ];
    }

    /**
     * Get the SMS representation of the notification.
     */
    public function toSms(object $notifiable): string
    {
        $order = $this->delivery->order;
        $pharmacy = $order->pharmacy;
        $deliveryFee = (float) ($this->delivery->delivery_fee ?? 0);
        $estimatedEarnings = max(0, $deliveryFee - WalletService::getCommissionAmount());
        return "DR-PHARMA: Nouvelle livraison assignée! Commande #{$order->reference} - Pharmacie: {$pharmacy->name} - Adresse: {$this->delivery->pickup_address} - Gain estimé: {$estimatedEarnings} FCFA";
    }

    /**
     * Get the WhatsApp representation of the notification.
     */
    public function toWhatsApp(object $notifiable): array
    {
        $order = $this->delivery->order;

        return [
            'type' => 'template',
            'template_name' => 'delivery_assigned',
            'placeholders' => [
                $notifiable->name ?? 'Client',
                $order->reference,
                $this->delivery->courier?->name ?? 'Votre livreur',
                $this->delivery->courier?->phone ?? '',
            ],
        ];
    }
}
