<?php

namespace App\Notifications;

use App\Channels\FcmChannel;
use App\Channels\SmsChannel;
use App\Models\Refund;
use App\Services\NotificationSettingsService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Notification envoyée au client à chaque évolution d'une demande de remboursement.
 */
class RefundStatusNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(public Refund $refund)
    {
        $this->queue = 'notifications';
    }

    public function via(object $notifiable): array
    {
        $channels = ['database'];

        if ($notifiable->fcm_token ?? null) {
            $channels[] = FcmChannel::class;
        }
        if ($notifiable->email ?? null) {
            $channels[] = 'mail';
        }
        if ($notifiable->phone ?? null) {
            $channels[] = SmsChannel::class;
        }

        return $channels;
    }

    public function toFcm(object $notifiable): array
    {
        try {
            $fcmConfig = NotificationSettingsService::getFcmConfig('refund_status');
        } catch (\Throwable $e) {
            $fcmConfig = ['data' => [], 'android' => [], 'apns' => []];
        }

        return [
            'title' => $this->title(),
            'body' => $this->body(),
            'data' => array_merge([
                'type' => 'refund_status',
                'refund_id' => (string) $this->refund->id,
                'order_id' => (string) $this->refund->order_id,
                'status' => $this->refund->status,
                'amount' => (string) $this->refund->amount,
                'click_action' => 'REFUND_DETAIL',
            ], $fcmConfig['data'] ?? []),
            'android' => $fcmConfig['android'] ?? [],
            'apns' => $fcmConfig['apns'] ?? [],
        ];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject($this->title())
            ->greeting("Bonjour {$notifiable->name},")
            ->line($this->body())
            ->line("Référence remboursement : #{$this->refund->id}")
            ->line("Montant : " . number_format((float) $this->refund->amount, 0, ',', ' ') . ' FCFA');
    }

    public function toSms(object $notifiable): string
    {
        $amount = number_format((float) $this->refund->amount, 0, ',', ' ');
        return "DR-PHARMA: {$this->title()} - {$amount} FCFA";
    }

    public function toArray(object $notifiable): array
    {
        return [
            'refund_id' => $this->refund->id,
            'order_id' => $this->refund->order_id,
            'status' => $this->refund->status,
            'amount' => $this->refund->amount,
            'reason' => $this->refund->reason,
        ];
    }

    private function title(): string
    {
        return match ($this->refund->status) {
            Refund::STATUS_APPROVED => '✅ Remboursement approuvé',
            Refund::STATUS_REJECTED => '❌ Remboursement refusé',
            Refund::STATUS_PROCESSED => '💰 Remboursement effectué',
            default => 'ℹ️ Mise à jour de votre demande',
        };
    }

    private function body(): string
    {
        $amount = number_format((float) $this->refund->amount, 0, ',', ' ');
        return match ($this->refund->status) {
            Refund::STATUS_APPROVED => "Votre demande de {$amount} FCFA a été approuvée. Le remboursement sera traité sous peu.",
            Refund::STATUS_REJECTED => "Votre demande a été refusée. Motif : " . ($this->refund->admin_note ?? '—'),
            Refund::STATUS_PROCESSED => "Votre wallet vient d'être crédité de {$amount} FCFA.",
            default => "Votre demande de remboursement de {$amount} FCFA a été mise à jour.",
        };
    }
}
