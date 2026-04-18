<?php

namespace App\Notifications;

use App\Models\Delivery;
use App\Models\Order;
use App\Services\NotificationSettingsService;
use App\Channels\FcmChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

/**
 * Notification envoyée à la pharmacie quand un livreur est assigné
 */
class CourierAssignedToPharmacyNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public Delivery $delivery,
        public Order $order
    ) {}

    /**
     * Get the notification's delivery channels.
     */
    public function via(object $notifiable): array
    {
        return ['database', FcmChannel::class];
    }

    /**
     * Get the notification data for database.
     */
    public function toArray(object $notifiable): array
    {
        $courier = $this->delivery->courier;
        
        return [
            'title' => '🛵 Livreur assigné',
            'message' => "Un livreur ({$courier->user->name}) a été assigné à la commande {$this->order->reference}",
            'type' => 'courier_assigned',
            'order_id' => $this->order->id,
            'delivery_id' => $this->delivery->id,
            'courier_id' => $courier->id,
            'courier_name' => $courier->user->name,
            'courier_phone' => $courier->user->phone,
            'courier_vehicle_type' => $courier->vehicle_type,
        ];
    }

    /**
     * Get the FCM notification representation.
     */
    public function toFcm(object $notifiable): array
    {
        $courier = $this->delivery->courier;
        $fcmConfig = NotificationSettingsService::getFcmConfig('courier_assigned');
        
        return [
            'title' => '🛵 Livreur assigné',
            'body' => "Le livreur {$courier->user->name} a été assigné à la commande {$this->order->reference}. Préparez la commande pour le retrait.",
            'sound' => $fcmConfig['sound'] ?? 'notification.wav',
            'channel_id' => $fcmConfig['channel_id'] ?? 'order_updates',
            'priority' => 'high',
            'data' => [
                'type' => 'courier_assigned',
                'order_id' => (string) $this->order->id,
                'order_reference' => $this->order->reference,
                'delivery_id' => (string) $this->delivery->id,
                'courier_id' => (string) $courier->id,
                'courier_name' => $courier->user->name,
                'courier_phone' => $courier->user->phone ?? '',
                'courier_vehicle_type' => $courier->vehicle_type ?? 'moto',
                'click_action' => 'OPEN_ORDER_DETAILS',
            ],
        ];
    }
}
