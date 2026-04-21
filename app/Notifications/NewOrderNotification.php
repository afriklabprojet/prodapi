<?php

namespace App\Notifications;

use App\Models\Order;
use App\Channels\SmsChannel;
use App\Channels\WhatsAppChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class NewOrderNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public Order $order;

    /**
     * Create a new notification instance.
     */
    public function __construct(Order $order)
    {
        $this->order = $order;
    }

    /**
     * Get the notification's delivery channels.
     */
    public function via(object $notifiable): array
    {
        $channels = ['database'];

        if ($notifiable->email) {
            $channels[] = 'mail';
        }

        if ($notifiable->fcm_token) {
            $channels[] = \App\Channels\FcmChannel::class;
        }

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

    /**
     * Get the FCM representation of the notification.
     */
    public function toFcm(object $notifiable): array
    {
        $fcmConfig = \App\Services\NotificationSettingsService::getFcmConfig('new_order');

        return [
            'title' => 'Nouvelle commande 🛒',
            'body' => "Ref: {$this->order->reference} - Médicaments: {$this->order->subtotal} FCFA",
            'data' => array_merge($fcmConfig['data'], [
                'type' => 'new_order',
                'order_id' => (string) $this->order->id,
            ]),
            'android' => $fcmConfig['android'],
            'apns' => $fcmConfig['apns'],
        ];
    }

    /**
     * Get the mail representation of the notification.
     */
    public function toMail(object $notifiable): MailMessage
    {
        $customer = $this->order->customer;

        $message = (new MailMessage)
            ->subject("Nouvelle commande - {$this->order->reference}")
            ->greeting("Bonjour,")
            ->line('Vous avez reçu une nouvelle commande!')
            ->line('')
            ->line("**Référence:** {$this->order->reference}")
            ->line("**Client:** {$customer->name}")
            ->line("**Téléphone:** {$this->order->customer_phone}")
            ->line("**Montant:** {$this->order->total_amount} {$this->order->currency}")
            ->line("**Adresse de livraison:** {$this->order->delivery_address}")
            ->line('');

        // Add items
        if ($this->order->items->isNotEmpty()) {
            $message->line('**Articles commandés:**');
            foreach ($this->order->items as $item) {
                $message->line("• {$item->name} x{$item->quantity} - {$item->total_price} XOF");
            }
            $message->line('');
        }

        if ($this->order->customer_notes) {
            $message->line("**Notes du client:** {$this->order->customer_notes}");
        }

        $message->line('')
            ->line('⚠️ Veuillez confirmer cette commande dans les plus brefs délais.')
            ->action('Voir la commande', url("/pharmacy/orders/{$this->order->id}"))
            ->line('Merci!');

        return $message;
    }

    /**
     * Get the array representation of the notification.
     */
    public function toArray(object $notifiable): array
    {
        $itemsCount = $this->order->items->count();

        return [
            'order_id' => $this->order->id,
            'order_reference' => $this->order->reference,
            'type' => 'new_order',
            'action' => 'confirm_order',
            'title' => $this->order->customer?->name
                ? "🛒 Commande de {$this->order->customer->name}"
                : "🛒 Nouvelle commande · {$itemsCount} article(s)",
            'body' => "Client: {$this->order->customer?->name} · {$itemsCount} article(s) · {$this->order->subtotal} {$this->order->currency}",
            'message' => "Client: {$this->order->customer?->name} · {$itemsCount} article(s) · {$this->order->subtotal} {$this->order->currency}",
            'customer_name' => $this->order->customer?->name,
            'items_count' => $itemsCount,
            'total_amount' => $this->order->total_amount,
            'currency' => $this->order->currency,
            'order_data' => [
                'customer_name' => $this->order->customer->name,
                'customer_phone' => $this->order->customer_phone,
                'total_amount' => $this->order->total_amount,
                'currency' => $this->order->currency,
                'items_count' => $itemsCount,
                'delivery_address' => $this->order->delivery_address,
            ],
        ];
    }

    /**
     * Get the SMS representation of the notification.
     */
    public function toSms(object $notifiable): string
    {
        $itemsCount = $this->order->items->count();
        return "DR-PHARMA: Nouvelle commande #{$this->order->reference} - {$itemsCount} article(s) - {$this->order->subtotal} FCFA. Veuillez confirmer rapidement.";
    }

    /**
     * Get the WhatsApp representation of the notification.
     */
    public function toWhatsApp(object $notifiable): array
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
