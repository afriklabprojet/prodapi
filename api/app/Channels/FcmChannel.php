<?php

namespace App\Channels;

use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification as FcmNotification;

/**
 * Canal de notification FCM (Firebase Cloud Messaging)
 *
 * Les notifications utilisant ce canal doivent implémenter une méthode toFcm()
 * qui retourne un tableau avec 'title', 'body', et optionnellement 'data', 'android', 'apns'.
 */
class FcmChannel
{
    public function __construct(
        protected Messaging $messaging
    ) {}

    /**
     * Send the given notification via FCM.
     * 
     * Sends a DATA-ONLY message so the Flutter app controls 
     * the notification display with the correct channel & sound.
     * A notification-type message would be handled by the OS directly 
     * and ignore custom channels/sounds.
     */
    public function send(object $notifiable, Notification $notification): void
    {
        if (!method_exists($notification, 'toFcm')) {
            return;
        }

        $fcmToken = $notifiable->fcm_token ?? null;

        if (!$fcmToken) {
            Log::debug('No FCM token for notifiable', [
                'notifiable_type' => get_class($notifiable),
                'notifiable_id' => $notifiable->id ?? null,
                'notification' => get_class($notification),
            ]);
            return;
        }

        $payload = $notification->toFcm($notifiable);

        if (!$payload || empty($payload['title'])) {
            return;
        }

        try {
            // Build data payload — include title/body so Flutter can show local notification
            $data = array_merge($payload['data'] ?? [], [
                'title' => $payload['title'],
                'body' => $payload['body'] ?? '',
            ]);

            // Add Android channel_id and sound into data for Flutter to use
            if (!empty($payload['android']['notification']['channel_id'])) {
                $data['channel_id'] = $payload['android']['notification']['channel_id'];
            }
            if (!empty($payload['android']['notification']['sound'])) {
                $data['sound'] = $payload['android']['notification']['sound'];
            }

            // Ensure all data values are strings (FCM requirement)
            $data = array_map('strval', $data);

            // Build the message — DATA-ONLY (no notification block)
            $messageArray = [
                'token' => $fcmToken,
                'data' => $data,
                'android' => $payload['android'] ?? [
                    'priority' => 'high',
                ],
                'apns' => $payload['apns'] ?? [
                    'payload' => [
                        'aps' => [
                            'content-available' => 1,
                            'sound' => $data['sound'] ?? 'default',
                        ],
                    ],
                ],
            ];

            $message = CloudMessage::fromArray($messageArray);
            $this->messaging->send($message);

            Log::info('FCM Notification sent', [
                'notifiable_id' => $notifiable->id ?? null,
                'notification' => get_class($notification),
                'channel_id' => $data['channel_id'] ?? 'default',
                'sound' => $data['sound'] ?? 'default',
            ]);
        } catch (\Kreait\Firebase\Exception\Messaging\NotFound $e) {
            Log::warning('FCM token invalid (not found), clearing token', [
                'notifiable_id' => $notifiable->id ?? null,
                'error' => $e->getMessage(),
            ]);

            if (method_exists($notifiable, 'update')) {
                $notifiable->update(['fcm_token' => null]);
            }
        } catch (\Kreait\Firebase\Exception\MessagingException $e) {
            Log::error('FCM Send Error: ' . $e->getMessage(), [
                'notifiable_id' => $notifiable->id ?? null,
                'notification' => get_class($notification),
                'error' => $e->getMessage(),
            ]);
        } catch (\Exception $e) {
            Log::error('FCM Exception: ' . $e->getMessage(), [
                'notifiable_id' => $notifiable->id ?? null,
                'notification' => get_class($notification),
                'error' => $e->getMessage(),
            ]);
        }
    }
}
