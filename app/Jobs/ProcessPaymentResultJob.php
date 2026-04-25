<?php

namespace App\Jobs;

use App\Models\JekoPayment;
use App\Models\Order;
use App\Models\Wallet;
use App\Services\BusinessEventService;
use App\Services\JekoPaymentService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Traite le résultat d'un paiement (succès métier) de manière asynchrone.
 * Idempotent : vérifie l'état actuel avant d'agir.
 * Retry-safe : peut être rejoué sans double-exécution.
 */
class ProcessPaymentResultJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 5;
    public array $backoff = [5, 30, 60, 300, 600];
    public int $timeout = 60;
    public int $maxExceptions = 3;

    public function __construct(
        private readonly int $paymentId,
    ) {}

    public function middleware(): array
    {
        return [
            (new WithoutOverlapping('payment-result-' . $this->paymentId))
                ->releaseAfter(30)
                ->expireAfter(300),
        ];
    }

    public function handle(): void
    {
        $payment = JekoPayment::find($this->paymentId);

        if (!$payment) {
            Log::warning('ProcessPaymentResult: payment not found', ['id' => $this->paymentId]);
            return;
        }

        // Idempotency : si déjà traité côté métier, skip
        if ($payment->business_processed) {
            Log::info('ProcessPaymentResult: already processed (idempotent)', [
                'reference' => $payment->reference,
            ]);
            return;
        }

        if (!$payment->isSuccess()) {
            return;
        }

        $payable = $payment->payable;
        if (!$payable) {
            Log::warning('ProcessPaymentResult: no payable', ['reference' => $payment->reference]);
            return;
        }

        DB::transaction(function () use ($payment, $payable) {
            $payableClass = get_class($payable);

            if ($payableClass === Order::class) {
                $this->processOrderPayment($payable, $payment);
            } elseif ($payableClass === Wallet::class) {
                $this->processWalletTopup($payable, $payment);
            }

            // Marquer comme traité côté business (idempotency flag)
            $payment->update(['business_processed' => true]);

            // Track payment success event
            BusinessEventService::paymentSuccess(
                $payment->user_id,
                $payment->reference,
                (float) $payment->amount / 100,
                $payableClass === Order::class ? 'order' : 'topup'
            );
        });

        Log::info('ProcessPaymentResult: completed', [
            'reference' => $payment->reference,
            'payable_type' => get_class($payable),
        ]);
    }

    private function processOrderPayment(Order $order, JekoPayment $payment): void
    {
        // Idempotent : ne pas re-payer une commande déjà payée
        if ($order->payment_status === 'paid') {
            return;
        }

        if (method_exists($order, 'markAsPaid')) {
            $order->markAsPaid($payment->reference);
        } else {
            $order->update([
                'payment_status' => 'paid',
                'payment_reference' => $payment->reference,
                'paid_at' => now(),
            ]);
        }

        // Calculer et distribuer les commissions (crédite le wallet pharmacie)
        try {
            app(\App\Actions\CalculateCommissionAction::class)->execute($order);
        } catch (\Throwable $e) {
            Log::error('ProcessPaymentResult: commission calculation failed', [
                'order_id' => $order->id,
                'error' => $e->getMessage(),
            ]);
        }

        // Notification asynchrone
        $order->load(['items', 'customer', 'pharmacy.users']);
        $pharmacy = $order->pharmacy;

        if ($pharmacy) {
            foreach ($pharmacy->users as $pharmacyUser) {
                SendNotificationJob::dispatch(
                    $pharmacyUser,
                    new \App\Notifications\NewOrderReceivedNotification($order),
                    ['order_id' => $order->id, 'pharmacy_id' => $pharmacy->id]
                )->onQueue('notifications');
            }
        }

        // Dispatcher le livreur après confirmation du paiement (modes non-cash)
        \App\Jobs\DispatchDeliveryJob::dispatch($order)->delay(now()->addSeconds(5));
    }

    private function processWalletTopup(Wallet $wallet, JekoPayment $payment): void
    {
        // Idempotent : vérifier si un topup avec cette référence existe déjà
        $existing = $wallet->transactions()
            ->where('reference', $payment->reference)
            ->exists();

        if ($existing) {
            Log::info('ProcessPaymentResult: wallet topup already exists (idempotent)', [
                'reference' => $payment->reference,
            ]);
            return;
        }

        $walletableClass = get_class($wallet->walletable);

        // FEES: si les frais ont été ajoutés au montant chargé via Jeko (frais à la charge du client),
        // on crédite uniquement le montant demandé (net) au wallet.
        $metadata = $payment->metadata ?? [];
        $netAmount = isset($metadata['requested_amount'])
            ? (float) $metadata['requested_amount']
            : (float) $payment->amount / 100;

        // Utiliser le bon service selon le type de wallet
        if ($walletableClass === \App\Models\Customer::class) {
            $service = app(\App\Services\CustomerWalletService::class);
            $service->topUp(
                $wallet->walletable->user,
                $netAmount,
                $payment->payment_method->value,
                $payment->reference
            );
        } elseif ($walletableClass === \App\Models\Courier::class) {
            $walletService = app(\App\Services\WalletService::class);
            $walletService->topUp(
                $wallet->walletable,
                $netAmount,
                $payment->payment_method->value,
                $payment->reference
            );
        } else {
            Log::warning('ProcessPaymentResult: unsupported walletable type for topup', [
                'walletable_type' => $walletableClass,
                'wallet_id' => $wallet->id,
                'payment_id' => $payment->id,
            ]);
        }
    }

    public function failed(\Throwable $exception): void
    {
        Log::critical('ProcessPaymentResult: FAILED', [
            'payment_id' => $this->paymentId,
            'error' => $exception->getMessage(),
            'trace' => $exception->getTraceAsString(),
        ]);
    }
}
