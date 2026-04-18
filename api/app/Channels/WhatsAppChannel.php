<?php

namespace App\Channels;

use App\Services\WhatsAppService;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\Log;

class WhatsAppChannel
{
    protected WhatsAppService $whatsapp;

    public function __construct(WhatsAppService $whatsapp)
    {
        $this->whatsapp = $whatsapp;
    }

    /**
     * Send the given notification via WhatsApp.
     *
     * Notifications using this channel must implement a toWhatsApp() method
     * that returns an array with the WhatsApp message configuration.
     *
     * Supported return formats:
     *
     * 1. Simple text (free-form, only within 24h window):
     *    ['type' => 'text', 'text' => 'Hello!']
     *
     * 2. Template message (anytime):
     *    [
     *        'type' => 'template',
     *        'template_name' => 'order_confirmed',
     *        'language' => 'fr',
     *        'placeholders' => ['John', 'CMD-001', '5000 FCFA'],
     *        'header' => ['type' => 'TEXT', 'placeholder' => 'Commande'],  // optional
     *        'buttons' => [['type' => 'QUICK_REPLY', 'parameter' => 'yes']], // optional
     *    ]
     *
     * 3. Image message (free-form):
     *    ['type' => 'image', 'url' => 'https://...', 'caption' => 'My image']
     *
     * 4. Document message (free-form):
     *    ['type' => 'document', 'url' => 'https://...', 'filename' => 'invoice.pdf']
     *
     * @param object $notifiable
     * @param \Illuminate\Notifications\Notification $notification
     * @return void
     */
    public function send(object $notifiable, Notification $notification): void
    {
        // Check if notification implements toWhatsApp() method
        if (! method_exists($notification, 'toWhatsApp')) {
            return;
        }

        /** @var array|null $message */
        $message = call_user_func([$notification, 'toWhatsApp'], $notifiable);

        if (! $message || ! is_array($message)) {
            return;
        }

        $phone = $this->getPhoneNumber($notifiable);

        if (! $phone) {
            Log::warning('No phone number found for WhatsApp notification', [
                'notifiable_type' => get_class($notifiable),
                'notifiable_id' => $notifiable->id ?? null,
                'notification' => get_class($notification),
            ]);
            return;
        }

        try {
            $type = $message['type'] ?? 'text';

            $result = match ($type) {
                'template' => $this->sendTemplate($phone, $message),
                'text' => $this->sendText($phone, $message),
                'image' => $this->sendImage($phone, $message),
                'document' => $this->sendDocument($phone, $message),
                default => $this->sendText($phone, $message),
            };

            if ($result) {
                Log::info('WhatsApp notification sent', [
                    'type' => $type,
                    'phone' => $this->maskPhone($phone),
                    'notification' => get_class($notification),
                ]);
            } else {
                Log::error('WhatsApp notification failed', [
                    'type' => $type,
                    'phone' => $this->maskPhone($phone),
                    'notification' => get_class($notification),
                ]);
            }
        } catch (\Exception $e) {
            Log::error('WhatsApp notification exception', [
                'phone' => $this->maskPhone($phone),
                'notification' => get_class($notification),
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Send a template message
     */
    protected function sendTemplate(string $phone, array $message): bool
    {
        return $this->whatsapp->sendTemplate(
            to: $phone,
            templateName: $message['template_name'],
            language: $message['language'] ?? config('whatsapp.default_language', 'fr'),
            placeholders: $message['placeholders'] ?? [],
            header: $message['header'] ?? null,
            buttons: $message['buttons'] ?? null,
        );
    }

    /**
     * Send a free-form text message
     */
    protected function sendText(string $phone, array $message): bool
    {
        $text = $message['text'] ?? $message['message'] ?? '';

        if (empty($text)) {
            Log::warning('WhatsApp text message is empty');
            return false;
        }

        return $this->whatsapp->sendText(
            to: $phone,
            text: $text,
            previewUrl: $message['preview_url'] ?? false,
        );
    }

    /**
     * Send an image message
     */
    protected function sendImage(string $phone, array $message): bool
    {
        return $this->whatsapp->sendImage(
            to: $phone,
            imageUrl: $message['url'],
            caption: $message['caption'] ?? null,
        );
    }

    /**
     * Send a document message
     */
    protected function sendDocument(string $phone, array $message): bool
    {
        return $this->whatsapp->sendDocument(
            to: $phone,
            documentUrl: $message['url'],
            filename: $message['filename'] ?? 'document.pdf',
            caption: $message['caption'] ?? null,
        );
    }

    /**
     * Get phone number from notifiable
     */
    protected function getPhoneNumber(object $notifiable): ?string
    {
        // Check for a dedicated whatsapp number first
        if (isset($notifiable->whatsapp_number) && $notifiable->whatsapp_number) {
            return $notifiable->whatsapp_number;
        }

        // Then try standard phone fields
        return $notifiable->phone
            ?? $notifiable->mobile
            ?? $notifiable->phone_number
            ?? null;
    }

    /**
     * Mask phone number for logging
     */
    protected function maskPhone(string $phone): string
    {
        if (strlen($phone) <= 6) {
            return '***' . substr($phone, -3);
        }

        return substr($phone, 0, 4) . str_repeat('*', strlen($phone) - 7) . substr($phone, -3);
    }
}
