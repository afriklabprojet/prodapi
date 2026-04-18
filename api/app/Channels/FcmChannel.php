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
     * Sends a HYBRID message (notification + data):
     * - `notification` block → displayed by Android OS directly when app is killed/sleeping
     *   with the correct channel_id (sound + importance from NotificationChannel)
     * - `data` block → processed by Flutter background handler for custom urgent alerts
     *   (full-screen intent, insistent sound loop)
     * 
     * This guarantees the user hears the sound even if:
     * - App is killed (OS handles notif natively with channel sound)
     * - Phone is in Doze mode (high priority wakes device)
     * - Dart background isolate fails (notification block is backup)
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

        // toFcm() is duck-typed and guarded by method_exists() above.
        // Use call_user_func to avoid static analyzers flagging it as undefined.
        $payload = call_user_func([$notification, 'toFcm'], $notifiable);

        if (!$payload || empty($payload['title'])) {
            return;
        }

        try {
            $title = $payload['title'];
            $body = $payload['body'] ?? '';

            // Build data payload — include title/body so Flutter can show local notification
            $data = array_merge($payload['data'] ?? [], [
                'title' => $title,
                'body' => $body,
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

            // Android config: force HIGH priority + short TTL for immediate delivery,
            // even in Doze mode. The channel_id ensures the correct sound.
            $androidConfig = array_merge([
                'priority' => 'high',
                'ttl' => '0s', // Deliver NOW, no buffering
            ], $payload['android'] ?? []);

            // Build the HYBRID message (notification + data)
            $messageArray = [
                'token' => $fcmToken,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                ],
                'data' => $data,
                'android' => $androidConfig,
                'apns' => $payload['apns'] ?? [
                    'headers' => [
                        'apns-priority' => '10',
                        'apns-push-type' => 'alert',
                    ],
                    'payload' => [
                        'aps' => [
                            'alert' => [
                                'title' => $title,
                                'body' => $body,
                            ],
                            'sound' => ($data['sound'] ?? 'default') === 'default'
                                ? 'default'
                                : "{$data['sound']}.caf",
                            'badge' => 1,
                            'content-available' => 1,
                            'interruption-level' => 'time-sensitive',
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
