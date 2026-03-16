<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use App\Models\Prescription;
use App\Channels\SmsChannel;
use App\Channels\WhatsAppChannel;

class NewPrescriptionNotification extends Notification implements ShouldQueue
{
    use Queueable;

    protected $prescription;

    /**
     * Create a new notification instance.
     */
    public function __construct(Prescription $prescription)
    {
        $this->prescription = $prescription;
    }

    /**
     * Get the notification's delivery channels.
     *
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        $channels = ['database'];
        if ($notifiable->fcm_token) {
            $channels[] = \App\Channels\FcmChannel::class;
        }
        // SMS pour les ordonnances
        if ($notifiable->phone) {
            $channels[] = SmsChannel::class;
        }
        // WhatsApp pour les ordonnances
        if ($notifiable->phone && config('whatsapp.notifications.prescription', true)) {
            $channels[] = WhatsAppChannel::class;
        }
        return $channels;
    }

    /**
     * Get the array representation of the notification.
     *
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        return [
            'title' => 'Nouvelle Ordonnance',
            'body' => 'Une nouvelle ordonnance a été reçue du client #' . $this->prescription->customer_id,
            'prescription_id' => $this->prescription->id,
            'type' => 'new_prescription',
        ];
    }

    /**
     * Get the FCM representation of the notification.
     */
    public function toFcm(object $notifiable): array
    {
        return [
            'title' => 'Nouvelle Ordonnance',
            'body' => 'Une nouvelle ordonnance a été reçue.',
            'data' => [
                'type' => 'new_prescription',
                'prescription_id' => (string) $this->prescription->id,
            ],
        ];
    }

    /**
     * Get the SMS representation of the notification.
     */
    public function toSms(object $notifiable): string
    {
        return "DR-PHARMA: 📋 Nouvelle ordonnance reçue (ORD-{$this->prescription->id}). Connectez-vous pour traiter cette demande.";
    }

    /**
     * Get the WhatsApp representation of the notification.
     */
    public function toWhatsApp(object $notifiable): array
    {
        return [
            'type' => 'template',
            'template_name' => 'new_prescription_pharmacy',
            'placeholders' => [
                $notifiable->name ?? 'Pharmacie',
                'ORD-' . $this->prescription->id,
            ],
        ];
    }
}
