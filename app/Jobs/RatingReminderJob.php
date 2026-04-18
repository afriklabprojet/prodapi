<?php

namespace App\Jobs;

use App\Models\Delivery;
use App\Notifications\OrderStatusNotification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Envoie un rappel au client pour noter sa livraison si ce n'est pas encore fait.
 *
 * Logique :
 * - Livraisons avec status='delivered', livrées entre 3h et 48h ago
 * - customer_rated_at est null (pas encore noté)
 * - 1 seul rappel maximum (vérification via metadata)
 *
 * Impact : les notes alimentent le score de fiabilité des livreurs.
 *
 * Fréquence recommandée : toutes les heures
 */
class RatingReminderJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public array $backoff = [60, 180];
    public int $timeout = 120;

    // Envoyer entre 3h et 48h après livraison
    private const REMIND_AFTER_HOURS = 3;
    private const REMIND_BEFORE_HOURS = 48;

    public function middleware(): array
    {
        return [new WithoutOverlapping('rating-reminder')];
    }

    public function handle(): void
    {
        $deliveries = Delivery::where('status', 'delivered')
            ->whereNull('customer_rated_at')
            ->whereNotNull('delivered_at')
            ->where('delivered_at', '<=', now()->subHours(self::REMIND_AFTER_HOURS))
            ->where('delivered_at', '>=', now()->subHours(self::REMIND_BEFORE_HOURS))
            ->where(function ($q) {
                // N'envoyer qu'une seule fois : pas de champ dédié, on utilise metadata
                $q->whereNull('metadata')
                  ->orWhereRaw("JSON_EXTRACT(metadata, '$.rating_reminder_sent') IS NULL");
            })
            ->with(['order.customer'])
            ->limit(100)
            ->get();

        if ($deliveries->isEmpty()) {
            return;
        }

        $sent = 0;

        foreach ($deliveries as $delivery) {
            $customer = $delivery->order?->customer;

            if (! $customer) {
                continue;
            }

            try {
                $customer->notify(new OrderStatusNotification(
                    $delivery->order,
                    'rating_reminder',
                    "Comment s'est passée votre livraison ? Donnez une note à votre livreur — ça prend 5 secondes !"
                ));

                // Marquer comme envoyé dans metadata
                $meta = $delivery->metadata ?? [];
                $meta['rating_reminder_sent'] = now()->toISOString();
                $delivery->update(['metadata' => $meta]);

                $sent++;
            } catch (\Throwable $e) {
                Log::debug('RatingReminderJob: notification failed', [
                    'delivery_id' => $delivery->id,
                    'error'       => $e->getMessage(),
                ]);
            }
        }

        if ($sent > 0) {
            Log::info("RatingReminderJob: {$sent} rappel(s) notation envoyé(s)");
        }
    }
}
