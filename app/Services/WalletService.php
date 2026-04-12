<?php

namespace App\Services;

use App\Models\Wallet;
use App\Models\WalletTransaction;
use App\Models\Courier;
use App\Models\Delivery;
use App\Models\Setting;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use App\Exceptions\InsufficientBalanceException;
use App\Exceptions\InvalidAmountException;
use App\Exceptions\MinimumWithdrawalException;

class WalletService
{
    /**
     * Montant de la commission Dr Pharma par livraison (par défaut)
     * Utilisez getCommissionAmount() pour obtenir la valeur paramétrable
     */
    public const DEFAULT_COMMISSION_AMOUNT = 200; // FCFA

    /**
     * Récupérer le montant de la commission depuis les paramètres
     */
    public static function getCommissionAmount(): int
    {
        return (int) Setting::get('courier_commission_amount', self::DEFAULT_COMMISSION_AMOUNT);
    }

    /**
     * Récupérer le solde minimum requis depuis les paramètres
     */
    public static function getMinimumWalletBalance(): int
    {
        return (int) Setting::get('minimum_wallet_balance', self::DEFAULT_COMMISSION_AMOUNT);
    }

    /**
     * Récupérer les frais de livraison de base (départ) depuis les paramètres
     */
    public static function getDeliveryFeeBase(): int
    {
        return (int) Setting::get('delivery_fee_base', 200);
    }

    /**
     * Récupérer les frais par kilomètre depuis les paramètres
     */
    public static function getDeliveryFeePerKm(): int
    {
        return (int) Setting::get('delivery_fee_per_km', 100);
    }

    /**
     * Récupérer le minimum des frais de livraison
     */
    public static function getDeliveryFeeMin(): int
    {
        return (int) Setting::get('delivery_fee_min', 300);
    }

    /**
     * Récupérer le maximum des frais de livraison
     */
    public static function getDeliveryFeeMax(): int
    {
        return (int) Setting::get('delivery_fee_max', 5000);
    }

    /**
     * Calculer les frais de livraison selon la distance
     * Formule: frais_base + (distance_km * frais_par_km)
     * Avec min et max appliqués
     * 
     * @param float $distanceKm Distance en kilomètres
     * @return int Frais de livraison en FCFA
     */
    public static function calculateDeliveryFee(float $distanceKm): int
    {
        $base = self::getDeliveryFeeBase();
        $perKm = self::getDeliveryFeePerKm();
        $min = self::getDeliveryFeeMin();
        $max = self::getDeliveryFeeMax();

        // Calcul: base + (distance * tarif/km)
        $fee = $base + (int) ceil($distanceKm * $perKm);

        // Appliquer min et max
        $fee = max($min, $fee);
        $fee = min($max, $fee);

        return $fee;
    }

    /**
     * Récupérer tous les paramètres de tarification livraison
     */
    public static function getDeliveryPricing(): array
    {
        return [
            'base_fee' => self::getDeliveryFeeBase(),
            'fee_per_km' => self::getDeliveryFeePerKm(),
            'min_fee' => self::getDeliveryFeeMin(),
            'max_fee' => self::getDeliveryFeeMax(),
        ];
    }

    // ========================
    // FRAIS DE SERVICE & PAIEMENT
    // ========================

    /**
     * Vérifier si les frais de service sont activés
     */
    public static function isServiceFeeEnabled(): bool
    {
        return (bool) Setting::get('apply_service_fee', true);
    }

    /**
     * Vérifier si les frais de paiement sont activés
     */
    public static function isPaymentFeeEnabled(): bool
    {
        return (bool) Setting::get('apply_payment_fee', true);
    }

    /**
     * Récupérer le pourcentage des frais de service (commission plateforme)
     * Par défaut: 2% ajouté au prix des médicaments
     */
    public static function getServiceFeePercentage(): float
    {
        return (float) Setting::get('service_fee_percentage', 2);
    }

    /**
     * Récupérer le minimum des frais de service
     */
    public static function getServiceFeeMin(): int
    {
        return (int) Setting::get('service_fee_min', 100);
    }

    /**
     * Récupérer le maximum des frais de service
     */
    public static function getServiceFeeMax(): int
    {
        return (int) Setting::get('service_fee_max', 2000);
    }

    /**
     * Récupérer les frais fixes de paiement
     */
    public static function getPaymentProcessingFee(): int
    {
        return (int) Setting::get('payment_processing_fee', 50);
    }

    /**
     * Récupérer le pourcentage des frais de paiement
     */
    public static function getPaymentProcessingPercentage(): float
    {
        return (float) Setting::get('payment_processing_percentage', 1.5);
    }

    /**
     * Calculer les frais de service pour un montant donné
     * Formule: (subtotal * percentage / 100) avec min et max appliqués
     * 
     * @param int $subtotal Sous-total des médicaments en FCFA
     * @return int Frais de service en FCFA
     */
    public static function calculateServiceFee(int $subtotal): int
    {
        if (!self::isServiceFeeEnabled()) {
            return 0;
        }

        $percentage = self::getServiceFeePercentage();
        $min = self::getServiceFeeMin();
        $max = self::getServiceFeeMax();

        // Calcul: subtotal * percentage / 100
        $fee = (int) ceil($subtotal * $percentage / 100);

        // Appliquer min et max
        $fee = max($min, $fee);
        $fee = min($max, $fee);

        return $fee;
    }

    /**
     * Calculer les frais de paiement pour un montant donné
     * Formule: frais_fixes + (amount * percentage / 100)
     * Appliqué uniquement pour les paiements en ligne (mobile_money, card)
     * 
     * @param int $amount Montant total (subtotal + delivery + service_fee) en FCFA
     * @param string $paymentMode Mode de paiement ('cash', 'mobile_money', 'card')
     * @return int Frais de paiement en FCFA
     */
    public static function calculatePaymentFee(int $amount, string $paymentMode): int
    {
        // Pas de frais pour les paiements en espèces
        if ($paymentMode === 'cash') {
            return 0;
        }

        if (!self::isPaymentFeeEnabled()) {
            return 0;
        }

        $fixedFee = self::getPaymentProcessingFee();
        $percentage = self::getPaymentProcessingPercentage();

        // Calcul: frais_fixes + (amount * percentage / 100)
        $percentageFee = (int) ceil($amount * $percentage / 100);
        
        return $fixedFee + $percentageFee;
    }

    /**
     * Récupérer tous les paramètres de tarification (service + paiement)
     */
    public static function getServicePricing(): array
    {
        return [
            'service_fee' => [
                'enabled' => self::isServiceFeeEnabled(),
                'percentage' => self::getServiceFeePercentage(),
                'min' => self::getServiceFeeMin(),
                'max' => self::getServiceFeeMax(),
            ],
            'payment_fee' => [
                'enabled' => self::isPaymentFeeEnabled(),
                'fixed_fee' => self::getPaymentProcessingFee(),
                'percentage' => self::getPaymentProcessingPercentage(),
            ],
        ];
    }

    /**
     * Calculer tous les frais pour une commande
     * 
     * @param int $subtotal Sous-total des médicaments
     * @param int $deliveryFee Frais de livraison
     * @param string $paymentMode Mode de paiement
     * @return array Détail de tous les frais
     */
    public static function calculateAllFees(int $subtotal, int $deliveryFee, string $paymentMode): array
    {
        $serviceFee = self::calculateServiceFee($subtotal);
        $subtotalWithFees = $subtotal + $deliveryFee + $serviceFee;
        $paymentFee = self::calculatePaymentFee($subtotalWithFees, $paymentMode);
        $totalAmount = $subtotalWithFees + $paymentFee;

        return [
            'subtotal' => $subtotal,                // Prix des médicaments (pharmacie reçoit ce montant)
            'delivery_fee' => $deliveryFee,         // Frais de livraison
            'service_fee' => $serviceFee,           // Frais de service plateforme
            'payment_fee' => $paymentFee,           // Frais de paiement (si paiement en ligne)
            'total_amount' => $totalAmount,         // Total payé par le client
            'pharmacy_amount' => $subtotal,         // Montant que la pharmacie reçoit (prix exact des médicaments)
        ];
    }

    /**
     * Récupérer le montant minimum de retrait depuis les paramètres
     */
    public static function getMinimumWithdrawalAmount(): int
    {
        return (int) Setting::get('minimum_withdrawal_amount', 500);
    }

    /**
     * Récupérer ou créer le wallet d'un coursier
     */
    public function getOrCreateWallet(Courier $courier): Wallet
    {
        return Wallet::firstOrCreate(
            [
                'walletable_type' => Courier::class,
                'walletable_id' => $courier->id,
            ],
            [
                'balance' => 0,
                'currency' => 'XOF',
            ]
        );
    }

    /**
     * Récupérer le wallet de la plateforme Dr Pharma
     */
    public function getPlatformWallet(): Wallet
    {
        return Wallet::platform();
    }

    /**
     * Vérifier si le coursier peut effectuer une livraison
     */
    public function canCompleteDelivery(Courier $courier): bool
    {
        $wallet = $this->getOrCreateWallet($courier);
        return $wallet->balance >= self::getCommissionAmount();
    }

    /**
     * Recharger le wallet d'un coursier
     */
    public function topUp(
        Courier $courier,
        float $amount,
        string $paymentMethod,
        ?string $paymentReference = null
    ): WalletTransaction {
        if ($amount <= 0) {
            throw new InvalidAmountException('Le montant doit être positif');
        }

        $wallet = $this->getOrCreateWallet($courier);
        $reference = 'TOP-' . strtoupper(Str::random(8));

        return DB::transaction(function () use ($wallet, $amount, $reference, $paymentMethod, $paymentReference) {
            $balanceBefore = $wallet->balance;
            
            $transaction = $wallet->credit(
                $amount,
                $reference,
                "Rechargement via {$paymentMethod}",
                [
                    'payment_method' => $paymentMethod,
                    'payment_reference' => $paymentReference,
                ]
            );

            // Mettre à jour les champs supplémentaires
            $transaction->update([
                'category' => 'topup',
                'payment_method' => $paymentMethod,
                'status' => 'completed',
            ]);

            return $transaction->fresh();
        });
    }

    /**
     * Créditer les gains de livraison au coursier
     */
    public function creditDeliveryEarning(Courier $courier, Delivery $delivery, float $amount): WalletTransaction
    {
        if ($amount <= 0) {
            throw new InvalidAmountException('Le montant des gains doit être positif');
        }

        $wallet = $this->getOrCreateWallet($courier);
        $reference = $delivery->order->reference ?? 'DEL-' . $delivery->id;

        return DB::transaction(function () use ($wallet, $amount, $reference, $delivery) {
            $transaction = $wallet->credit(
                $amount,
                $reference,
                "Livraison - Commande {$reference}",
                [
                    'delivery_id' => $delivery->id,
                    'order_id' => $delivery->order_id,
                ]
            );

            // Mettre à jour les champs supplémentaires
            $transaction->update([
                'category' => 'delivery_earning',
                'delivery_id' => $delivery->id,
                'status' => 'completed',
            ]);

            return $transaction->fresh();
        });
    }

    /**
     * Créditer un bonus au coursier (challenge, promotion, etc.)
     */
    public function creditBonus(Courier $courier, float $amount, string $description, ?int $challengeId = null): WalletTransaction
    {
        if ($amount <= 0) {
            throw new InvalidAmountException('Le montant du bonus doit être positif');
        }

        $wallet = $this->getOrCreateWallet($courier);
        $reference = 'BONUS-' . strtoupper(Str::random(8));

        return DB::transaction(function () use ($wallet, $amount, $reference, $description, $challengeId) {
            $transaction = $wallet->credit(
                $amount,
                $reference,
                $description,
                $challengeId ? ['challenge_id' => $challengeId] : []
            );

            // Mettre à jour les champs supplémentaires
            $transaction->update([
                'category' => 'bonus',
                'status' => 'completed',
            ]);

            return $transaction->fresh();
        });
    }

    /**
     * Prélever la commission lors de la validation d'une livraison
     */
    public function deductCommission(Courier $courier, Delivery $delivery): WalletTransaction
    {
        $wallet = $this->getOrCreateWallet($courier);
        $commissionAmount = self::getCommissionAmount();
        
        if (!$wallet->hasSufficientBalance($commissionAmount)) {
            throw new InsufficientBalanceException('Solde insuffisant. Veuillez recharger.');
        }

        $reference = 'COM-' . strtoupper(Str::random(8));

        return DB::transaction(function () use ($wallet, $delivery, $reference, $commissionAmount) {
            // 1. Débiter le wallet du coursier
            $courierTransaction = $wallet->debit(
                $commissionAmount,
                $reference,
                "Commission livraison #{$delivery->id}",
                ['delivery_id' => $delivery->id]
            );

            $courierTransaction->update([
                'category' => 'commission',
                'delivery_id' => $delivery->id,
                'status' => 'completed',
            ]);

            // 2. Créditer le wallet de la plateforme
            $platformWallet = $this->getPlatformWallet();
            $platformTransaction = $platformWallet->credit(
                $commissionAmount,
                $reference . '-PLT',
                "Commission livraison #{$delivery->id} (Coursier: {$wallet->walletable->user->name})",
                [
                    'delivery_id' => $delivery->id,
                    'courier_id' => $wallet->walletable_id,
                    'source_transaction_id' => $courierTransaction->id,
                ]
            );

            $platformTransaction->update([
                'category' => 'commission',
                'delivery_id' => $delivery->id,
                'status' => 'completed',
            ]);

            return $courierTransaction->fresh();
        });
    }

    /**
     * Demander un retrait vers Mobile Money
     */
    public function requestWithdrawal(
        Courier $courier,
        float $amount,
        string $paymentMethod,
        string $phoneNumber
    ): WalletTransaction {
        $wallet = $this->getOrCreateWallet($courier);
        $minWithdrawal = self::getMinimumWithdrawalAmount();
        
        if (!$wallet->hasSufficientBalance($amount)) {
            throw new InsufficientBalanceException('Solde insuffisant pour ce retrait');
        }

        if ($amount < $minWithdrawal) {
            throw new MinimumWithdrawalException($minWithdrawal);
        }

        $reference = 'WTH-' . strtoupper(Str::random(8));

        return DB::transaction(function () use ($wallet, $amount, $reference, $paymentMethod, $phoneNumber) {
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
                'status' => 'pending', // En attente de traitement par l'admin
            ]);

            return $transaction->fresh();
        });
    }

    /**
     * Obtenir l'historique des transactions
     */
    public function getTransactionHistory(Courier $courier, int $limit = 50): \Illuminate\Database\Eloquent\Collection
    {
        $wallet = $this->getOrCreateWallet($courier);
        
        return $wallet->transactions()
            ->with('wallet')
            ->orderByDesc('created_at')
            ->limit($limit)
            ->get();
    }

    /**
     * Obtenir le solde actuel
     */
    public function getBalance(Courier $courier): array
    {
        $wallet = $this->getOrCreateWallet($courier);
        $commissionAmount = self::getCommissionAmount();
        
        // Calculer les retraits en attente
        $pendingWithdrawals = $wallet->transactions()
            ->where('category', 'withdrawal')
            ->where('status', 'pending')
            ->sum('amount');

        return [
            'balance' => (float) $wallet->balance,
            'currency' => $wallet->currency,
            'pending_withdrawals' => (float) $pendingWithdrawals,
            'available_balance' => (float) ($wallet->balance - $pendingWithdrawals),
            'can_deliver' => $wallet->balance >= $commissionAmount,
            'commission_amount' => $commissionAmount,
            'minimum_balance' => self::getMinimumWalletBalance(),
            'delivery_fee_base' => self::getDeliveryFeeBase(),
        ];
    }

    /**
     * Obtenir les statistiques du wallet
     */
    public function getStatistics(Courier $courier): array
    {
        $wallet = $this->getOrCreateWallet($courier);
        
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

        // Gains du jour (livraisons créditées aujourd'hui)
        $todayEarnings = (float) $wallet->transactions()
            ->where('category', 'delivery_earning')
            ->where('type', 'CREDIT')
            ->whereDate('created_at', now()->toDateString())
            ->sum('amount');

        return [
            'total_topups' => (float) ($stats->get('topup')->total_credits ?? 0),
            'total_delivery_earnings' => (float) ($stats->get('delivery_earning')->total_credits ?? 0),
            'total_commissions' => (float) ($stats->get('commission')->total_debits ?? 0),
            'total_withdrawals' => (float) ($stats->get('withdrawal')->total_debits ?? 0),
            'deliveries_count' => (int) ($stats->get('commission')->count ?? 0),
            'today_earnings' => $todayEarnings,
        ];
    }
}
