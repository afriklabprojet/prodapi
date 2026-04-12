<?php

namespace App\Notifications;

use App\Services\NotificationSettingsService;
use App\Channels\FcmChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Envoyée à la pharmacie quand un produit atteint le seuil de stock bas.
 */
class LowStockAlertNotification extends Notification implements ShouldQueue
{
    use Queueable;

    /**
     * @param array $products Liste des produits en stock bas [{name, quantity, threshold}]
     */
    public function __construct(
        public array $products
    ) {
        $this->queue = 'notifications';
    }

    public function via(object $notifiable): array
    {
        $channels = ['database'];

        // La pharmacie a un user propriétaire avec fcm_token
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
        $count = count($this->products);
        $firstProduct = $this->products[0]['name'] ?? 'Produit';
        $fcmConfig = NotificationSettingsService::getFcmConfig('low_stock');

        $body = $count === 1
            ? "⚠️ {$firstProduct} n'a plus que {$this->products[0]['quantity']} unité(s) en stock."
            : "⚠️ {$count} produits sont en stock critique.";

        return [
            'title' => '📦 Alerte stock bas',
            'body' => $body,
            'data' => array_merge([
                'type' => 'low_stock',
                'product_count' => (string) $count,
                'click_action' => 'INVENTORY',
            ], $fcmConfig['data']),
            'android' => $fcmConfig['android'],
            'apns' => $fcmConfig['apns'],
        ];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $count = count($this->products);
        $mail = (new MailMessage)
            ->subject("⚠️ {$count} produit(s) en stock bas")
            ->greeting("Bonjour,")
            ->line("Les produits suivants sont en stock critique :");

        foreach ($this->products as $product) {
            $mail->line("• **{$product['name']}** : {$product['quantity']} restant(s) (seuil: {$product['threshold']})");
        }

        return $mail
            ->action('Gérer l\'inventaire', url('/pharmacy/inventory'))
            ->line('Pensez à réapprovisionner ces produits.');
    }

    public function toArray(object $notifiable): array
    {
        return [
            'type' => 'low_stock',
            'message' => count($this->products) . ' produit(s) en stock critique',
            'products' => $this->products,
        ];
    }
}
