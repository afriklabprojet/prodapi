<?php

namespace App\Notifications;

use App\Channels\FcmChannel;
use App\Services\NotificationSettingsService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

/**
 * Notification envoyée à la pharmacie pour les lots (DLC) expirant bientôt.
 *
 * @param array $urgent  Lots expirant dans ≤ 7 jours
 * @param array $warning Lots expirant dans 8-30 jours
 */
class InventoryBatchExpiryNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public array $urgent,
        public array $warning
    ) {
        $this->queue = 'notifications';
    }

    public function via(object $notifiable): array
    {
        $channels = ['database'];

        if ($notifiable->fcm_token) {
            $channels[] = FcmChannel::class;
        }

        return $channels;
    }

    public function toFcm(object $notifiable): array
    {
        $urgentCount = count($this->urgent);
        $warningCount = count($this->warning);
        $total = $urgentCount + $warningCount;

        if ($urgentCount > 0) {
            $title = "⚠️ DLC critique — {$urgentCount} lot(s) expirent dans 7 jours";
            $body  = $urgentCount === 1
                ? "Le lot « {$this->urgent[0]['name']} » expire le {$this->urgent[0]['expiry_date']}. Retirez-le du circuit de vente."
                : "{$urgentCount} lots expirent dans moins d'une semaine. Action requise immédiatement.";
        } else {
            $title = "📦 DLC — {$warningCount} lot(s) expirent dans 30 jours";
            $body  = "Pensez à planifier le réapprovisionnement pour {$warningCount} lot(s).";
        }

        return [
            'title' => $title,
            'body'  => $body,
            'data'  => [
                'type'          => 'inventory_batch_expiry',
                'urgent_count'  => $urgentCount,
                'warning_count' => $warningCount,
            ],
        ];
    }

    public function toArray(object $notifiable): array
    {
        return [
            'type'          => 'inventory_batch_expiry',
            'urgent'        => $this->urgent,
            'warning'       => $this->warning,
            'urgent_count'  => count($this->urgent),
            'warning_count' => count($this->warning),
        ];
    }
}
