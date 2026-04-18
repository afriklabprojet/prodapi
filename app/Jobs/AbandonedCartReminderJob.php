<?php

namespace App\Jobs;

use App\Models\Order;
use App\Notifications\OrderStatusNotification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

/**
 * Envoie un rappel push/SMS aux clients ayant une commande 'pending' non payée
 * depuis 10-25 minutes (avant que CancelStaleOrdersJob ne l'annule à 30min).
 *
 * Objectif : relancer le client qui a quitté le tunnel de paiement.
 *
 * Fréquence recommandée : toutes les 15 minutes
 */
class AbandonedCartReminderJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public array $backoff = [60, 120];
    public int $timeout = 120;

    // Fenêtre de relance : entre 10 et 25 minutes après création
    private const REMIND_AFTER_MINUTES = 10;
    private const REMIND_BEFORE_MINUTES = 25;

    public function middleware(): array
    {
        return [new WithoutOverlapping('abandoned-cart-reminder')];
    }

    public function handle(): void
    {
        // Commandes pending non payées, créées entre 10 et 25 min ago
        // Exclure les commandes cash (pas de paiement en ligne attendu)
        $orders = Order::where('status', 'pending')
            ->where('payment_status', 'pending')
            ->whereNotIn('payment_mode', ['cash', 'cash_on_delivery'])
            ->where('created_at', '>=', now()->subMinutes(self::REMIND_BEFORE_MINUTES))
            ->where('created_at', '<=', now()->subMinutes(self::REMIND_AFTER_MINUTES))
            ->whereNull('cancelled_at')
            ->with(['customer'])
            ->limit(100)
            ->get();

        if ($orders->isEmpty()) {
            return;
        }

        $reminded = 0;

        foreach ($orders as $order) {
            try {
                $user = $order->customer;
                if (! $user) {
                    continue;
                }

                $user->notify(new OrderStatusNotification(
                    $order,
                    'abandoned_cart',
                    "Votre commande #{$order->reference} vous attend ! Finalisez votre paiement avant qu'elle expire."
                ));

                $reminded++;
            } catch (\Throwable $e) {
                Log::debug('AbandonedCartReminderJob: notification failed', [
                    'order_id' => $order->id,
                    'error'    => $e->getMessage(),
                ]);
            }
        }

        if ($reminded > 0) {
            Log::info("AbandonedCartReminderJob: {$reminded} rappel(s) panier abandonné envoyé(s)");
        }
    }
}
