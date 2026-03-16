<?php

namespace App\Notifications;

use App\Channels\FcmChannel;
use App\Channels\WhatsAppChannel;
use App\Models\Delivery;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

class NewChatMessageNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public Delivery $delivery,
        public string $senderName,
        public string $senderType,
        public string $message
    ) {}

    public function via($notifiable): array
    {
        $channels = [FcmChannel::class, 'database'];

        // WhatsApp pour les messages chat (désactivé par défaut - peut être verbeux)
        if ($notifiable->phone && config('whatsapp.notifications.chat', false)) {
            $channels[] = WhatsAppChannel::class;
        }

        return $channels;
    }

    public function toFcm($notifiable): array
    {
        $senderLabel = match($this->senderType) {
            'courier' => 'Livreur',
            'pharmacy' => 'Pharmacie',
            'client' => 'Client',
            default => 'Utilisateur',
        };

        return [
            'title' => "💬 Nouveau message - {$senderLabel}",
            'body' => "{$this->senderName}: " . substr($this->message, 0, 100) . (strlen($this->message) > 100 ? '...' : ''),
            'data' => [
                'type' => 'chat_message',
                'delivery_id' => (string) $this->delivery->id,
                'sender_type' => $this->senderType,
                'sender_name' => $this->senderName,
            ],
        ];
    }

    public function toArray($notifiable): array
    {
        return [
            'type' => 'chat_message',
            'delivery_id' => $this->delivery->id,
            'sender_type' => $this->senderType,
            'sender_name' => $this->senderName,
            'message' => $this->message,
            'message_preview' => substr($this->message, 0, 100),
        ];
    }

    /**
     * Get the WhatsApp representation of the notification.
     */
    public function toWhatsApp($notifiable): array
    {
        $senderLabel = match($this->senderType) {
            'courier' => 'Livreur',
            'pharmacy' => 'Pharmacie',
            'client' => 'Client',
            default => 'Utilisateur',
        };

        return [
            'type' => 'template',
            'template_name' => 'new_chat_message',
            'placeholders' => [
                $senderLabel,
                $this->senderName,
                substr($this->message, 0, 100),
            ],
        ];
    }
}
