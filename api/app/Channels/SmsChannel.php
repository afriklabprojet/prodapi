<?php

namespace App\Channels;

use App\Services\SmsService;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\Log;

/**
 * Canal de notification SMS utilisant SmsService centralisé (Infobip)
 * 
 * Les notifications utilisant ce canal doivent implémenter une méthode toSms()
 * qui retourne le texte du SMS à envoyer.
 */
class SmsChannel
{
    public function __construct(
        protected SmsService $smsService
    ) {}

    /**
     * Send the given notification via SMS.
     */
    public function send(object $notifiable, Notification $notification): void
    {
        // Vérifier que la notification implémente toSms()
        if (!method_exists($notification, 'toSms')) {
            return;
        }

        /** @var string|null $message */
        $message = $notification->toSms($notifiable);

        if (!$message) {
            return;
        }

        $phone = $this->getPhoneNumber($notifiable);

        if (!$phone) {
            Log::warning('No phone number found for SMS notification', [
                'notifiable_type' => get_class($notifiable),
                'notifiable_id' => $notifiable->id ?? null,
                'notification' => get_class($notification),
            ]);
            return;
        }

        // Options supplémentaires si la notification les fournit
        $options = method_exists($notification, 'toSmsOptions')
            ? $notification->toSmsOptions($notifiable)
            : [];

        $sent = $this->smsService->send($phone, $message, $options);

        if (!$sent) {
            Log::warning('SMS notification failed to send', [
                'phone' => $phone,
                'notification' => get_class($notification),
            ]);
        }
    }

    /**
     * Get phone number from notifiable
     */
    protected function getPhoneNumber(object $notifiable): ?string
    {
        // Try routeNotificationForSms() first (standard Laravel pattern)
        if (method_exists($notifiable, 'routeNotificationForSms')) {
            return $notifiable->routeNotificationForSms($notifiable);
        }

        // Fallback: try common phone fields
        return $notifiable->phone
            ?? $notifiable->mobile
            ?? $notifiable->phone_number
            ?? null;
    }
}
