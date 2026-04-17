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
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Annule automatiquement les commandes bloquées / non finalisées.
 * 
 * Cibles :
 * 1. Commandes 'pending' non payées (paiement en ligne) → 30 min
 * 2. Commandes 'pending' cash non confirmées par la pharmacie → 2h
 * 3. Commandes 'confirmed' / 'preparing' sans progression → 6h
 * 4. Commandes 'ready' sans livreur assigné → 12h
 * 
 * Exécuté toutes les 5 minutes via le scheduler.
 */
class CancelStaleOrdersJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public array $backoff = [30, 60, 120];
    public int $timeout = 180;

    // Délais avant annulation automatique (en minutes)
    private const PENDING_UNPAID_MINUTES = 30;       // Paiement en ligne non payé
    private const PENDING_CASH_MINUTES = 120;         // Cash: pharmacie ne confirme pas (2h)
    private const CONFIRMED_PREPARING_MINUTES = 360;  // Confirmée/en préparation sans avancer (6h)
    private const READY_NO_COURIER_MINUTES = 720;     // Prête mais pas de livreur (12h)

    public function middleware(): array
    {
        return [new WithoutOverlapping('cancel-stale-orders')];
    }

    public function handle(): void
    {
        $totalCancelled = 0;
        $totalFailed = 0;

        // 1. Commandes pending + paiement en ligne non payé (30 min)
        [$c, $f] = $this->cancelBatch(
            Order::where('status', 'pending')
                ->where('payment_mode', 'platform')
                ->where('payment_status', '!=', 'paid')
                ->where('created_at', '<', now()->subMinutes(self::PENDING_UNPAID_MINUTES))
                ->whereNull('cancelled_at')
                ->with(['pharmacy', 'customer', 'delivery'])
                ->limit(50)
                ->get(),
            "Annulation automatique : paiement non effectué après " . self::PENDING_UNPAID_MINUTES . " minutes",
            'pending_unpaid'
        );
        $totalCancelled += $c;
        $totalFailed += $f;

        // 2. Commandes pending + cash non confirmées par la pharmacie (2h)
        [$c, $f] = $this->cancelBatch(
            Order::where('status', 'pending')
                ->where(function ($q) {
                    $q->where('payment_mode', 'cash')
                      ->orWhere('payment_status', 'paid');
                })
                ->where('created_at', '<', now()->subMinutes(self::PENDING_CASH_MINUTES))
                ->whereNull('cancelled_at')
                ->with(['pharmacy', 'customer', 'delivery'])
                ->limit(50)
                ->get(),
            "Annulation automatique : commande non confirmée par la pharmacie après " . (self::PENDING_CASH_MINUTES / 60) . "h",
            'pending_unconfirmed'
        );
        $totalCancelled += $c;
        $totalFailed += $f;

        // 3. Commandes confirmed/preparing bloquées (6h)
        [$c, $f] = $this->cancelBatch(
            Order::whereIn('status', ['confirmed', 'preparing'])
                ->where('updated_at', '<', now()->subMinutes(self::CONFIRMED_PREPARING_MINUTES))
                ->whereNull('cancelled_at')
                ->with(['pharmacy', 'customer', 'delivery'])
                ->limit(50)
                ->get(),
            "Annulation automatique : commande bloquée en préparation depuis " . (self::CONFIRMED_PREPARING_MINUTES / 60) . "h sans progression",
            'stuck_preparing'
        );
        $totalCancelled += $c;
        $totalFailed += $f;

        // 4. Commandes ready sans livreur (12h)
        [$c, $f] = $this->cancelBatch(
            Order::where('status', 'ready')
                ->where('updated_at', '<', now()->subMinutes(self::READY_NO_COURIER_MINUTES))
                ->whereNull('cancelled_at')
                ->whereDoesntHave('delivery', fn ($q) => $q->whereIn('status', ['assigned', 'picked_up', 'in_transit', 'in_delivery']))
                ->with(['pharmacy', 'customer', 'delivery'])
                ->limit(50)
                ->get(),
            "Annulation automatique : aucun livreur disponible après " . (self::READY_NO_COURIER_MINUTES / 60) . "h",
            'ready_no_courier'
        );
        $totalCancelled += $c;
        $totalFailed += $f;

        if ($totalCancelled > 0 || $totalFailed > 0) {
            Log::info('CancelStaleOrders: batch complete', [
                'cancelled' => $totalCancelled,
                'failed' => $totalFailed,
            ]);
        }
    }

    /**
     * Annule un batch de commandes avec la raison donnée.
     * 
     * @return array{int, int} [cancelled, failed]
     */
    private function cancelBatch($orders, string $reason, string $category): array
    {
        if ($orders->isEmpty()) {
            return [0, 0];
        }

        $cancelled = 0;
        $failed = 0;

        foreach ($orders as $order) {
            try {
                $this->cancelOrder($order, $reason);
                $cancelled++;
            } catch (\Throwable $e) {
                $failed++;
                Log::warning("CancelStaleOrders [{$category}]: failed", [
                    'order_id' => $order->id,
                    'reference' => $order->reference,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        if ($cancelled > 0) {
            Log::info("CancelStaleOrders [{$category}]: {$cancelled} annulée(s)", [
                'category' => $category,
                'cancelled' => $cancelled,
            ]);
        }

        return [$cancelled, $failed];
    }

    /**
     * Annule une commande et ses entités associées
     */
    private function cancelOrder(Order $order, string $reason): void
    {
        DB::beginTransaction();
        try {
            // 1. Annuler la commande
            $order->update([
                'status' => 'cancelled',
                'cancellation_reason' => $reason,
                'cancelled_at' => now(),
            ]);

            // 2. Annuler la livraison associée si elle existe
            if ($order->delivery) {
                $order->delivery->update([
                    'status' => 'cancelled',
                    'cancellation_reason' => $reason,
                    'auto_cancelled_at' => now(),
                ]);

                // Libérer le livreur s'il est assigné
                if ($order->delivery->courier) {
                    $order->delivery->courier->update(['status' => 'available']);
                }
            }

            // 3. Restaurer le stock si la commande avait été confirmée
            if (in_array($order->getOriginal('status'), ['confirmed', 'preparing', 'ready'])) {
                foreach ($order->items as $item) {
                    if ($item->product_id) {
                        \App\Models\Product::where('id', $item->product_id)
                            ->increment('stock_quantity', $item->quantity);
                    }
                }
            }

            // 4. Marquer les paiements en attente comme expirés
            $order->payments()
                ->whereIn('status', ['pending', 'initiated', 'processing'])
                ->update([
                    'status' => 'expired',
                ]);

            $order->paymentIntents()
                ->where('status', 'pending')
                ->update(['status' => 'cancelled']);

            DB::commit();

            // 4. Notifier le client (silencieux si erreur)
            try {
                if ($order->customer) {
                    $order->customer->notify(new OrderStatusNotification(
                        $order,
                        'cancelled',
                        "Votre commande {$order->reference} a été annulée automatiquement. Motif : {$reason}"
                    ));
                }
            } catch (\Throwable $e) {
                Log::debug('CancelStaleOrders: notification failed', [
                    'order_id' => $order->id,
                    'error' => $e->getMessage(),
                ]);
            }

            // 5. Notifier la pharmacie (silencieux si erreur)
            try {
                if ($order->pharmacy) {
                    foreach ($order->pharmacy->users as $pharmacyUser) {
                        $pharmacyUser->notify(new OrderStatusNotification(
                            $order,
                            'cancelled',
                            "La commande {$order->reference} a été annulée automatiquement. Motif : {$reason}"
                        ));
                    }
                }
            } catch (\Throwable $e) {
                Log::debug('CancelStaleOrders: pharmacy notification failed', [
                    'order_id' => $order->id,
                    'error' => $e->getMessage(),
                ]);
            }

            Log::info('CancelStaleOrders: order cancelled', [
                'order_id' => $order->id,
                'reference' => $order->reference,
                'age_minutes' => now()->diffInMinutes($order->created_at),
            ]);

        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }
    }

    public function failed(\Throwable $exception): void
    {
        Log::error('CancelStaleOrdersJob failed', [
            'error' => $exception->getMessage(),
        ]);
    }
}
