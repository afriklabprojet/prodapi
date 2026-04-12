<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use App\Models\Prescription;
use App\Channels\SmsChannel;
use App\Channels\WhatsAppChannel;

class PrescriptionStatusNotification extends Notification implements ShouldQueue
{
    use Queueable;

    protected $prescription;
    protected $status;

    /**
     * Create a new notification instance.
     */
    public function __construct(Prescription $prescription, string $status)
    {
        $this->prescription = $prescription;
        $this->status = $status;
    }

    /**
     * Get the notification's delivery channels.
     */
    public function via(object $notifiable): array
    {
        $channels = ['database'];
        if ($notifiable->fcm_token) {
            $channels[] = \App\Channels\FcmChannel::class;
        }
        // SMS pour les mises à jour d'ordonnance
        if ($notifiable->phone) {
            $channels[] = SmsChannel::class;
        }
        // WhatsApp pour les mises à jour d'ordonnance
        if ($notifiable->phone && config('whatsapp.notifications.prescription', true)) {
            $channels[] = WhatsAppChannel::class;
        }
        return $channels;
    }

    /**
     * Get the array representation of the notification.
     */
    public function toArray(object $notifiable): array
    {
        return [
            'title' => 'Mise à jour Ordonnance',
            'body' => $this->getMessage(),
            'prescription_id' => $this->prescription->id,
            'status' => $this->status,
            'type' => 'prescription_status',
        ];
    }

    /**
     * Get the FCM representation of the notification.
     */
    public function toFcm(object $notifiable): array
    {
        $fcmConfig = \App\Services\NotificationSettingsService::getFcmConfig('prescription_status');

        return [
            'title' => 'Mise à jour Ordonnance',
            'body' => $this->getMessage(),
            'data' => array_merge($fcmConfig['data'], [
                'type' => 'prescription_status',
                'prescription_id' => (string) $this->prescription->id,
                'status' => $this->status,
            ]),
            'android' => $fcmConfig['android'],
            'apns' => $fcmConfig['apns'],
        ];
    }

    private function getMessage(): string
    {
        switch ($this->status) {
            case 'quoted':
                return 'Une pharmacie a envoyé un devis pour votre ordonnance.';
            case 'validated':
                return 'Votre ordonnance a été validée.';
            case 'rejected':
                return 'Votre ordonnance a été refusée.';
            default:
                return 'Le statut de votre ordonnance a changé: ' . $this->status;
        }
    }

    /**
     * Get the SMS representation of the notification.
     */
    public function toSms(object $notifiable): string
    {
        return "DR-PHARMA: " . $this->getMessage();
    }

    /**
     * Get the WhatsApp representation of the notification.
     */
    public function toWhatsApp(object $notifiable): ?array
    {
        if ($this->status === 'quoted') {
            return [
                'type' => 'template',
                'template_name' => 'prescription_ready',
                'placeholders' => [
                    $notifiable->name ?? 'Client',
                    (string) ($this->prescription->items_count ?? 0),
                    ($this->prescription->estimated_amount ?? 0) . ' FCFA',
                ],
            ];
        }

        // Pour les autres statuts, message texte libre (dans la fenêtre 24h)
        return [
            'type' => 'text',
            'text' => "DR-PHARMA 💊\n\n" . $this->getMessage(),
        ];
    }
}
