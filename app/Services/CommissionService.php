<?php

namespace App\Services;

use App\Models\Commission;
use App\Models\Order;
use App\Models\Payment;
use App\Models\Setting;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CommissionService
{
    public function calculateAndDistribute(Order $order)
    {
        if ($order->commission()->exists()) {
            return;
        }

        try {
            DB::transaction(function () use ($order) {
                $pharmacy = $order->pharmacy;

                // Pharmacie reçoit 100% du montant des médicaments (subtotal)
                $amountPharmacy = (float) $order->subtotal;

                // Plateforme reçoit les frais de service fixes (100 FCFA par commande)
                $amountPlatform = (float) ($order->service_fee ?? Setting::get('service_fee_fixed', 100));

                // Le livreur est rémunéré séparément via WalletService (delivery_fee × 85%)
                // Aucune commission livreur ici

                // Create Commission Record
                $commission = Commission::create([
                    'order_id' => $order->id,
                    'total_amount' => $order->total_amount,
                    'calculated_at' => now(),
                ]);

                // Ligne plateforme : frais de service
                $commission->lines()->create([
                    'actor_type' => 'platform',
                    'actor_id' => 0,
                    'rate' => 0,
                    'amount' => $amountPlatform,
                ]);

                // Ligne pharmacie : 100% des médicaments
                $commission->lines()->create([
                    'actor_type' => \App\Models\Pharmacy::class,
                    'actor_id' => $pharmacy->id,
                    'rate' => 1,
                    'amount' => $amountPharmacy,
                ]);

                // Crédit wallets
                if ($amountPlatform > 0) {
                    $this->creditWallet(Wallet::platform(), $amountPlatform, $order, 'Frais de service');
                }

                $pharmacyWallet = $pharmacy->wallet()->firstOrCreate([], ['currency' => 'XOF', 'balance' => 0]);
                $this->creditWallet($pharmacyWallet, $amountPharmacy, $order, 'Vente médicaments');
            });

            Log::info("Commissions distributed for order {$order->reference}");

        } catch (\Exception $e) {
            Log::error("Failed to distribute commissions for order {$order->id}: " . $e->getMessage());
            throw $e;
        }
    }

    protected function creditWallet(Wallet $wallet, float $amount, Order $order, string $description)
    {
        $wallet->credit(
            $amount,
            $order->reference,
            "$description - Commande {$order->reference}",
            ['order_id' => $order->id]
        );
    }

    /**
     * Distribuer les commissions pour un paiement confirmé
     */
    public function distributeForPayment(Payment $payment): void
    {
        $order = $payment->order;
        if ($order) {
            $this->calculateAndDistribute($order);
        }
    }

    private function normalizeRate($rate)
    {
        // If rate is > 1 (e.g. 10, 85), treat as percentage (10%, 85%)
        // If rate is <= 1 (e.g. 0.10, 0.85), treat as decimal
        $rate = (float) $rate;
        if ($rate > 1) {
            return $rate / 100;
        }
        return $rate;
    }
}
