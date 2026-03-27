<?php

namespace App\Services;

use App\Models\Customer;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use App\Enums\JekoPaymentMethod;
use App\Exceptions\InsufficientBalanceException;
use App\Exceptions\InvalidAmountException;
use App\Exceptions\MinimumWithdrawalException;
use App\Models\Order;
use App\Services\JekoPaymentService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class CustomerWalletService
{
    /**
     * Récupérer ou créer le profil client + wallet
     */
    public function getOrCreateWallet(User $user): Wallet
    {
        $customer = $user->customer ?? Customer::create(['user_id' => $user->id]);

        return Wallet::firstOrCreate(
            [
                'walletable_type' => Customer::class,
                'walletable_id' => $customer->id,
            ],
            [
                'balance' => 0,
                'currency' => 'XOF',
            ]
        );
    }

    /**
     * Recharger le wallet du client via mobile money
     */
    public function topUp(
        User $user,
        float $amount,
        string $paymentMethod,
        ?string $paymentReference = null
    ): WalletTransaction {
        if ($amount <= 0) {
            throw new InvalidAmountException('Le montant doit être positif');
        }

        $wallet = $this->getOrCreateWallet($user);
        $reference = 'CTOP-' . strtoupper(Str::random(8));

        return DB::transaction(function () use ($wallet, $amount, $reference, $paymentMethod, $paymentReference) {
            $transaction = $wallet->credit(
                $amount,
                $reference,
                "Rechargement via {$paymentMethod}",
                [
                    'payment_method' => $paymentMethod,
                    'payment_reference' => $paymentReference,
                ]
            );

            $transaction->update([
                'category' => 'topup',
                'payment_method' => $paymentMethod,
                'status' => 'completed',
            ]);

            return $transaction->fresh();
        });
    }

    /**
     * Débiter le wallet pour un paiement de commande
     */
    public function payOrder(User $user, float $amount, string $orderReference): WalletTransaction
    {
        if ($amount <= 0) {
            throw new InvalidAmountException('Le montant doit être positif');
        }

        $wallet = $this->getOrCreateWallet($user);

        if (!$wallet->hasSufficientBalance($amount)) {
            throw new InsufficientBalanceException('Solde insuffisant');
        }

        $reference = 'CPAY-' . strtoupper(Str::random(8));

        return DB::transaction(function () use ($wallet, $amount, $reference, $orderReference) {
            $transaction = $wallet->debit(
                $amount,
                $reference,
                "Paiement commande {$orderReference}",
                ['order_reference' => $orderReference]
            );

            $transaction->update([
                'category' => 'order_payment',
                'status' => 'completed',
            ]);

            // Marquer la commande comme payée dans la même transaction atomique
            $order = Order::where('reference', $orderReference)->first();
            if ($order && $order->payment_status !== 'paid') {
                $order->update([
                    'payment_status' => 'paid',
                    'payment_reference' => $reference,
                    'paid_at' => now(),
                ]);

                Log::info('Order marked as paid via wallet', [
                    'order_id' => $order->id,
                    'order_reference' => $orderReference,
                    'wallet_reference' => $reference,
                    'amount' => $amount,
                ]);
            }

            return $transaction->fresh();
        });
    }

    /**
     * Rembourser un client (annulation commande, erreur, etc.)
     */
    public function refund(User $user, float $amount, string $reason, ?string $orderReference = null): WalletTransaction
    {
        if ($amount <= 0) {
            throw new InvalidAmountException('Le montant doit être positif');
        }

        $wallet = $this->getOrCreateWallet($user);
        $reference = 'CREF-' . strtoupper(Str::random(8));

        return DB::transaction(function () use ($wallet, $amount, $reference, $reason, $orderReference) {
            $transaction = $wallet->credit(
                $amount,
                $reference,
                "Remboursement: {$reason}",
                array_filter([
                    'reason' => $reason,
                    'order_reference' => $orderReference,
                ])
            );

            $transaction->update([
                'category' => 'refund',
                'status' => 'completed',
            ]);

            return $transaction->fresh();
        });
    }

    /**
     * Demander un retrait vers mobile money via Jeko payout
     */
    public function requestWithdrawal(
        User $user,
        float $amount,
        string $paymentMethod,
        string $phoneNumber
    ): WalletTransaction {
        $wallet = $this->getOrCreateWallet($user);
        $minWithdrawal = WalletService::getMinimumWithdrawalAmount();

        if ($amount < $minWithdrawal) {
            throw new MinimumWithdrawalException($minWithdrawal);
        }

        if (!$wallet->hasSufficientBalance($amount)) {
            throw new InsufficientBalanceException('Solde insuffisant pour ce retrait');
        }

        $reference = 'CWTH-' . strtoupper(Str::random(8));

        // Étape 1: Débiter le wallet (transaction atomique)
        $transaction = $wallet->debit(
            $amount,
            $reference,
            "Retrait vers {$paymentMethod} ({$phoneNumber})",
            [
                'payment_method' => $paymentMethod,
                'phone_number' => $phoneNumber,
            ]
        );

        $transaction->update([
            'category' => 'withdrawal',
            'payment_method' => $paymentMethod,
            'status' => 'processing',
        ]);

        // Étape 2: Lancer le payout Jeko (hors transaction DB pour que le débit persiste)
        try {
            $jekoMethod = JekoPaymentMethod::from($paymentMethod);
            $jekoService = app(JekoPaymentService::class);
            $amountCents = (int) ($amount * 100);

            $jekoPayment = $jekoService->createPayout(
                $wallet,
                $amountCents,
                $phoneNumber,
                $jekoMethod,
                $user,
                "Retrait client #{$wallet->id} - {$reference}"
            );

            // Stocker la référence Jeko dans les metadata
            $transaction->update([
                'metadata' => array_merge($transaction->metadata ?? [], [
                    'jeko_reference' => $jekoPayment->reference,
                    'jeko_status' => $jekoPayment->status->value,
                ]),
            ]);

            Log::info('Customer withdrawal payout initiated', [
                'wallet_id' => $wallet->id,
                'amount' => $amount,
                'jeko_reference' => $jekoPayment->reference,
            ]);
        } catch (\Exception $e) {
            // En cas d'échec Jeko, rembourser le wallet (hors transaction DB pour que le remboursement persiste)
            try {
                $wallet->credit(
                    $amount,
                    'REFUND-' . $reference,
                    "Remboursement retrait échoué: {$e->getMessage()}",
                    ['original_reference' => $reference]
                );
            } catch (\Exception $refundException) {
                Log::critical('Customer withdrawal refund FAILED', [
                    'wallet_id' => $wallet->id,
                    'amount' => $amount,
                    'original_error' => $e->getMessage(),
                    'refund_error' => $refundException->getMessage(),
                ]);
            }

            $transaction->update(['status' => 'failed']);

            Log::error('Customer withdrawal payout failed, wallet refunded', [
                'wallet_id' => $wallet->id,
                'amount' => $amount,
                'error' => $e->getMessage(),
            ]);

            // Message user-friendly au lieu de l'erreur technique
            $userMessage = match (true) {
                str_contains($e->getMessage(), 'Cannot POST') => 'Le service de retrait est temporairement indisponible. Veuillez réessayer plus tard ou contacter le support.',
                str_contains($e->getMessage(), 'disbursement') => 'Le service de retrait est temporairement indisponible. Veuillez réessayer plus tard.',
                str_contains($e->getMessage(), 'timeout') => 'Le service de paiement met trop de temps à répondre. Veuillez réessayer.',
                str_contains($e->getMessage(), 'connexion') => 'Impossible de contacter le service de paiement. Vérifiez votre connexion.',
                default => 'Une erreur est survenue lors du retrait. Veuillez réessayer ou contacter le support.',
            };

            throw new \Exception($userMessage);
        }

        return $transaction->fresh();
    }

    /**
     * Historique des transactions
     */
    public function getTransactionHistory(User $user, int $limit = 50, ?string $category = null): \Illuminate\Database\Eloquent\Collection
    {
        $wallet = $this->getOrCreateWallet($user);

        $query = $wallet->transactions()->orderByDesc('created_at');

        if ($category) {
            $query->where('category', $category);
        }

        return $query->limit($limit)->get();
    }

    /**
     * Solde et informations du wallet
     */
    public function getBalance(User $user): array
    {
        $wallet = $this->getOrCreateWallet($user);

        $pendingWithdrawals = $wallet->transactions()
            ->where('category', 'withdrawal')
            ->whereIn('status', ['pending', 'processing'])
            ->sum('amount');

        return [
            'balance' => (float) $wallet->balance,
            'currency' => $wallet->currency,
            'pending_withdrawals' => (float) $pendingWithdrawals,
            'available_balance' => (float) max(0, $wallet->balance - $pendingWithdrawals),
            'minimum_withdrawal' => WalletService::getMinimumWithdrawalAmount(),
        ];
    }

    /**
     * Statistiques du wallet client
     */
    public function getStatistics(User $user): array
    {
        $wallet = $this->getOrCreateWallet($user);

        $stats = $wallet->transactions()
            ->selectRaw("
                category,
                SUM(CASE WHEN type = 'CREDIT' THEN amount ELSE 0 END) as total_credits,
                SUM(CASE WHEN type = 'DEBIT' THEN amount ELSE 0 END) as total_debits,
                COUNT(*) as count
            ")
            ->groupBy('category')
            ->get()
            ->keyBy('category');

        return [
            'total_topups' => (float) ($stats->get('topup')->total_credits ?? 0),
            'total_order_payments' => (float) ($stats->get('order_payment')->total_debits ?? 0),
            'total_refunds' => (float) ($stats->get('refund')->total_credits ?? 0),
            'total_withdrawals' => (float) ($stats->get('withdrawal')->total_debits ?? 0),
            'orders_paid' => (int) ($stats->get('order_payment')->count ?? 0),
        ];
    }
}
