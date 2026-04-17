<?php

namespace App\Jobs;

use App\Models\DeliveryMessage;
use App\Models\User;
use App\Notifications\NewChatMessageNotification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldBeUnique;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendChatNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * Nombre de tentatives
     */
    public int $tries = 3;

    /**
     * Délai entre les tentatives (en secondes)
     */
    public array $backoff = [10, 30, 60];

    /**
     * Timeout du job
     */
    public int $timeout = 30;

    public function __construct(
        public DeliveryMessage $message,
        public array $sender
    ) {
        $this->onQueue('notifications');
    }

    public function handle(): void
    {
        $receiver = $this->resolveReceiver();

        if (!$receiver) {
            Log::warning('ChatNotification: Destinataire non trouvé', [
                'message_id' => $this->message->id,
                'receiver_type' => $this->message->receiver_type,
                'receiver_id' => $this->message->receiver_id,
            ]);
            return;
        }

        // Récupérer l'utilisateur associé au destinataire
        $user = $this->getUserFromReceiver($receiver);

        if (!$user || !method_exists($user, 'notify')) {
            Log::warning('ChatNotification: Utilisateur non notifiable', [
                'message_id' => $this->message->id,
                'receiver_type' => $this->message->receiver_type,
            ]);
            return;
        }

        try {
            $user->notify(new NewChatMessageNotification(
                $this->message->delivery,
                $this->sender['name'],
                $this->sender['type'],
                $this->message->message
            ));

            Log::info('ChatNotification: Envoyée', [
                'message_id' => $this->message->id,
                'user_id' => $user->id,
            ]);
        } catch (\Exception $e) {
            Log::error('ChatNotification: Échec', [
                'message_id' => $this->message->id,
                'error' => $e->getMessage(),
            ]);

            // Re-throw pour retry
            throw $e;
        }
    }

    /**
     * Résoudre l'entité destinataire
     */
    private function resolveReceiver(): mixed
    {
        return match ($this->message->receiver_type) {
            'courier' => \App\Models\Courier::find($this->message->receiver_id),
            'pharmacy' => \App\Models\Pharmacy::find($this->message->receiver_id),
            'client' => User::find($this->message->receiver_id),
            default => null,
        };
    }

    /**
     * Obtenir l'utilisateur notifiable depuis le destinataire
     */
    private function getUserFromReceiver(mixed $receiver): ?User
    {
        return match ($this->message->receiver_type) {
            'courier' => $receiver->user ?? null,
            'pharmacy' => $receiver->user ?? null,
            'client' => $receiver,
            default => null,
        };
    }

    /**
     * Déterminer si le job doit être réessayé
     */
    public function failed(\Throwable $exception): void
    {
        Log::error('ChatNotification: Échec définitif', [
            'message_id' => $this->message->id,
            'error' => $exception->getMessage(),
            'trace' => $exception->getTraceAsString(),
        ]);
    }
}
