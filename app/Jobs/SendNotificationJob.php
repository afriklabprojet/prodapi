<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Notifications\Notification;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Envoie une notification de manière asynchrone avec retry.
 * Si la notification échoue après toutes les tentatives,
 * on log sans bloquer le flux business.
 */
class SendNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public array $backoff = [10, 30, 60];
    public int $timeout = 30;
    public int $maxExceptions = 2;

    /**
     * @param object $notifiable  User/Model cible
     * @param Notification $notification  Notification à envoyer
     * @param array $context  Contexte pour le logging
     */
    public function __construct(
        private readonly object $notifiable,
        private readonly Notification $notification,
        private readonly array $context = [],
    ) {}

    public function handle(): void
    {
        try {
            $this->notifiable->notify($this->notification);

            Log::info('SendNotification: sent', array_merge([
                'notification' => get_class($this->notification),
                'notifiable_type' => get_class($this->notifiable),
                'notifiable_id' => $this->notifiable->id ?? null,
            ], $this->context));
        } catch (\Throwable $e) {
            Log::warning('SendNotification: attempt failed', [
                'notification' => get_class($this->notification),
                'attempt' => $this->attempts(),
                'error' => $e->getMessage(),
            ]);
            throw $e; // Permet le retry
        }
    }

    public function failed(\Throwable $exception): void
    {
        Log::error('SendNotification: FAILED permanently', array_merge([
            'notification' => get_class($this->notification),
            'notifiable_type' => get_class($this->notifiable),
            'notifiable_id' => $this->notifiable->id ?? null,
            'error' => $exception->getMessage(),
        ], $this->context));
    }
}
