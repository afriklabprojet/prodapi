<?php

namespace App\Notifications;

use App\Models\Order;
use App\Channels\FcmChannel;
use App\Channels\SmsChannel;
use App\Channels\WhatsAppChannel;
use App\Services\NotificationSettingsService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

/**
 * Notification envoyée à la pharmacie quand une nouvelle commande est reçue
 */
class NewOrderReceivedNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public Order $order
    ) {}

    public function via($notifiable): array
    {
        $channels = ['database', FcmChannel::class];

        // SMS pour les nouvelles commandes (pharmacie)
        if ($notifiable->phone) {
            $channels[] = SmsChannel::class;
        }

        // WhatsApp pour les nouvelles commandes (pharmacie)
        if ($notifiable->phone && config('whatsapp.notifications.order_status', true)) {
            $channels[] = WhatsAppChannel::class;
        }

        return $channels;
    }

    public function toDatabase($notifiable): array
    {
        $itemsCount = $this->order->items->count();
        $subtotal = $this->order->subtotal; // Prix médicaments (montant reçu par la pharmacie)
        
        return [
            'type' => 'new_order_received',
            'title' => $this->order->customer?->name
                ? "🛒 Commande de {$this->order->customer->name}"
                : "🛒 Nouvelle commande · {$itemsCount} article(s)",
            'body' => "Client: {$this->order->customer?->name} · {$itemsCount} article(s) · {$subtotal} FCFA",
            'order_id' => $this->order->id,
            'order_reference' => $this->order->reference,
            'customer_name' => $this->order->customer?->name,
            'customer_phone' => $this->order->customer_phone,
            'items_count' => $itemsCount,
            'total_amount' => $this->order->total_amount,
            'subtotal' => $subtotal,
            'payment_mode' => $this->order->payment_mode,
            'delivery_address' => $this->order->delivery_address,
            'has_prescription' => !empty($this->order->prescription_image),
            'customer_notes' => $this->order->customer_notes,
            'message' => "Client: {$this->order->customer?->name} · {$itemsCount} article(s) · {$subtotal} FCFA",
        ];
    }

    public function toFcm($notifiable): array
    {
        $itemsCount = $this->order->items->count();
        $paymentLabel = match($this->order->payment_mode) {
            'cash' => 'Espèces',
            'mobile_money' => 'Mobile Money',
            'card' => 'Carte bancaire',
            default => $this->order->payment_mode,
        };

        // Récupérer les paramètres de notification depuis la config admin
        $fcmConfig = NotificationSettingsService::getFcmConfig('new_order');

        $subtotal = $this->order->subtotal; // Prix médicaments (montant reçu par la pharmacie)
        $body = "Client: {$this->order->customer?->name}\n" .
                "{$itemsCount} article(s) - {$subtotal} FCFA\n" .
                "Paiement: {$paymentLabel}";

        if ($this->order->customer_notes) {
            $body .= "\n📝 Note: " . substr($this->order->customer_notes, 0, 50);
        }

        if (!empty($this->order->prescription_image)) {
            $body .= "\n📋 Ordonnance jointe";
        }

        return [
            'title' => "🛒 Nouvelle commande #{$this->order->reference}",
            'body' => $body,
            'data' => array_merge([
                'type' => 'new_order_received',
                'order_id' => (string) $this->order->id,
                'order_reference' => $this->order->reference,
                'customer_name' => $this->order->customer?->name ?? '',
                'customer_phone' => $this->order->customer_phone ?? '',
                'items_count' => (string) $itemsCount,
                'total_amount' => (string) $this->order->total_amount,
                'subtotal' => (string) $this->order->subtotal,
                'payment_mode' => $this->order->payment_mode,
                'has_prescription' => !empty($this->order->prescription_image) ? 'true' : 'false',
                'click_action' => 'ORDER_DETAIL',
            ], $fcmConfig['data']),
            'android' => $fcmConfig['android'],
            'apns' => $fcmConfig['apns'],
        ];
    }

    /**
     * Get the array representation of the notification.
     */
    public function toArray($notifiable): array
    {
        return $this->toDatabase($notifiable);
    }

    /**
     * Get the SMS representation of the notification.
     */
    public function toSms($notifiable): string
    {
        $itemsCount = $this->order->items->count();
        return "DR-PHARMA: 🛒 Nouvelle commande #{$this->order->reference} - {$itemsCount} article(s) - {$this->order->subtotal} FCFA. Confirmez rapidement!";
    }

    /**
     * Get the WhatsApp representation of the notification.
     */
    public function toWhatsApp($notifiable): array
    {
        $itemsCount = $this->order->items->count();

        return [
            'type' => 'template',
            'template_name' => 'new_order_pharmacy',
            'placeholders' => [
                $notifiable->name ?? 'Pharmacie',
                $this->order->reference,
                (string) $itemsCount,
                ($this->order->subtotal ?? 0) . ' FCFA',
            ],
        ];
    }
}
