<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;

/**
 * Service de gestion des paramètres de notification FCM et sons.
 *
 * Fournit la configuration FCM (android/apns/data) par type de notification,
 * ainsi que les sons disponibles pour les notifications push.
 */
class NotificationSettingsService
{
    /**
     * Get FCM configuration for a specific notification type.
     * Called statically from Notification classes (toFcm).
     *
     * @return array{data: array, android: array, apns: array}
     */
    public static function getFcmConfig(string $notificationType): array
    {
        $settings = Cache::remember(
            "fcm_config_{$notificationType}",
            now()->addHours(1),
            fn () => self::loadFcmConfig($notificationType)
        );

        return $settings;
    }

    /**
     * Get the configuration for a notification type (instance method).
     * Called from NotificationController::getSoundSettings().
     */
    public function getConfig(string $notificationType): array
    {
        $config = static::getFcmConfig($notificationType);

        return [
            'sound' => $config['android']['notification']['sound'] ?? 'default',
            'vibration' => true,
            'priority' => $config['android']['priority'] ?? 'high',
            'notification_type' => $notificationType,
        ];
    }

    /**
     * Get list of available notification sounds.
     */
    public function getAvailableSounds(): array
    {
        return [
            ['id' => 'default', 'label' => 'Son par défaut', 'file' => 'default'],
            ['id' => 'order_received', 'label' => 'Nouvelle commande', 'file' => 'order_received.mp3'],
            ['id' => 'urgent', 'label' => 'Urgent', 'file' => 'urgent.mp3'],
            ['id' => 'soft', 'label' => 'Doux', 'file' => 'soft.mp3'],
            ['id' => 'chime', 'label' => 'Carillon', 'file' => 'chime.mp3'],
            ['id' => 'alert', 'label' => 'Alerte', 'file' => 'alert.mp3'],
            ['id' => 'none', 'label' => 'Silencieux', 'file' => null],
        ];
    }

    /**
     * Load FCM config from database/config for a notification type.
     */
    protected static function loadFcmConfig(string $notificationType): array
    {
        $sound = self::getSoundForType($notificationType);
        $channelId = self::getChannelForType($notificationType);

        return [
            'data' => [
                'notification_type' => $notificationType,
                'sound' => $sound,
            ],
            'android' => [
                'priority' => 'high',
                'notification' => [
                    'sound' => $sound,
                    'channel_id' => $channelId,
                    'default_vibrate_timings' => true,
                ],
            ],
            'apns' => [
                'payload' => [
                    'aps' => [
                        'sound' => $sound === 'default' ? 'default' : "{$sound}.caf",
                        'badge' => 1,
                        'content-available' => 1,
                    ],
                ],
            ],
        ];
    }

    /**
     * Get the Android channel ID for a notification type.
     * Maps to Flutter app channel IDs:
     * - Pharmacy app: orders_channel, stock_channel, payments_channel, system_channel
     * - Delivery app: new_delivery, delivery_updates, earnings, system
     */
    protected static function getChannelForType(string $notificationType): string
    {
        return match ($notificationType) {
            // Pharmacy app channels
            'new_order', 'new_order_received', 'new_prescription' => 'orders_channel',
            'order_status', 'order_delivered', 'courier_arrived_at_client' => 'orders_channel',
            'low_stock', 'out_of_stock' => 'stock_channel',
            // Delivery app channels
            'delivery_assigned' => 'new_delivery',
            'courier_arrived', 'delivery_timeout' => 'delivery_updates',
            'kyc_status_update' => 'system',
            // Shared channels
            'payout_completed' => 'payments_channel',
            'chat_message', 'new_message' => 'messages_channel',
            'prescription_status' => 'orders_channel',
            // New notification types
            'payment_failed' => 'payments_channel',
            'courier_cancelled' => 'orders_channel',
            'prescription_rejected' => 'orders_channel',
            'low_stock' => 'stock_channel',
            'refund_status' => 'payments_channel',
            'promo_applied' => 'system_channel',
            default => 'system_channel',
        };
    }

    /**
     * Get sound file for notification type.
     */
    protected static function getSoundForType(string $notificationType): string
    {
        return match ($notificationType) {
            'new_order', 'new_order_received' => 'order_received',
            'new_prescription' => 'order_received',
            'delivery_assigned' => 'notification_new_order',
            'courier_arrived', 'courier_arrived_at_client' => 'chime',
            'delivery_timeout' => 'notification_urgent',
            'order_status', 'order_delivered' => 'chime',
            'chat_message' => 'notification_chat',
            'payout_completed' => 'notification_cash',
            'prescription_status' => 'alert',
            'kyc_status_update' => 'alert',
            // New notification types
            'payment_failed' => 'alert',
            'courier_cancelled' => 'chime',
            'prescription_rejected' => 'alert',
            'low_stock' => 'notification_urgent',
            'refund_status' => 'notification_cash',
            'promo_applied' => 'chime',
            default => 'default',
        };
    }

    /**
     * Clear cached FCM config (e.g. after admin changes settings).
     */
    public static function clearCache(?string $notificationType = null): void
    {
        if ($notificationType) {
            Cache::forget("fcm_config_{$notificationType}");
        } else {
            $types = ['new_order', 'new_order_received', 'new_prescription', 'delivery_assigned', 'courier_arrived', 'courier_arrived_at_client', 'delivery_timeout', 'order_confirmed', 'delivery_completed', 'order_status', 'order_delivered', 'chat_message', 'payout_completed', 'prescription_status', 'kyc_status_update', 'payment_failed', 'courier_cancelled', 'prescription_rejected', 'low_stock', 'refund_status', 'promo_applied'];
            foreach ($types as $type) {
                Cache::forget("fcm_config_{$type}");
            }
        }
    }
}
