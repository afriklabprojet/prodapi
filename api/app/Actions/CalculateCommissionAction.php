<?php

namespace App\Actions;

use App\Models\Commission;
use App\Models\CommissionLine;
use App\Models\Order;
use App\Models\Setting;
use App\Models\Wallet;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CalculateCommissionAction
{
    /**
     * Calculer et distribuer les commissions pour une commande
     * 
     * SYSTÈME DE COMMISSION:
     * - Les taux sont définis par pharmacie (commission_rate_platform, commission_rate_pharmacy, commission_rate_courier)
     * - Fallback vers les taux globaux dans Settings (default_commission_rate_platform/pharmacy/courier)
     * - Pour les commandes sans livreur (pickup), la part livreur revient à la pharmacie
     * - Les wallets sont crédités automatiquement
     */
    public function execute(Order $order): Commission
    {
        return DB::transaction(function () use ($order) {
            // Vérifier si la commande a déjà des commissions (idempotent)
            if ($order->commission) {
                Log::info('Commission already calculated', ['order_id' => $order->id]);
                return $order->commission;
            }

            $order->loadMissing(['pharmacy']);
            $pharmacy = $order->pharmacy;

            $subtotal = $order->subtotal ?? $order->total_amount;

            // Service fee percentage from Settings (default 2%)
            $serviceFeeRate = $this->getServiceFeeRate();

            // Créer le record Commission
            $commission = Commission::create([
                'order_id' => $order->id,
                'total_amount' => $order->total_amount,
                'calculated_at' => now(),
            ]);

            // Ligne plateforme (service fee)
            CommissionLine::create([
                'commission_id' => $commission->id,
                'actor_type' => 'platform',
                'actor_id' => 0,
                'rate' => $serviceFeeRate,
                'amount' => round($subtotal * $serviceFeeRate, 0),
            ]);

            // Ligne pharmacie (full subtotal)
            CommissionLine::create([
                'commission_id' => $commission->id,
                'actor_type' => 'App\Models\Pharmacy',
                'actor_id' => $pharmacy->id,
                'rate' => 1.0,
                'amount' => $subtotal,
            ]);

            // Créditer les wallets
            $commission->load('lines');
            $this->creditWallets($commission, $order);

            Log::info('Commission calculated and distributed', [
                'order_id' => $order->id,
                'commission_id' => $commission->id,
                'total' => $order->total_amount,
                'platform_rate' => $serviceFeeRate,
                'pharmacy_amount' => $subtotal,
            ]);

            return $commission;
        });
    }

    /**
     * Get the service fee rate from Settings (default 2%)
     */
    private function getServiceFeeRate(): float
    {
        $raw = Setting::get('service_fee_percentage', 2);
        $rate = (float) $raw;
        return $rate > 1 ? $rate / 100 : $rate;
    }

    /**
     * Créditer les wallets de chaque acteur
     */
    protected function creditWallets(Commission $commission, Order $order): void
    {
        foreach ($commission->lines as $line) {
            // Wallet de la plateforme
            if ($line->actor_type === 'platform') {
                $wallet = Wallet::platform();
                $wallet->credit(
                    $line->amount,
                    "COMMISSION-{$commission->id}-PLATFORM",
                    "Commission plateforme pour commande #{$order->reference}",
                    ['commission_id' => $commission->id]
                );
                continue;
            }

            // Wallet de la pharmacie ou du livreur
            if ($line->actor_id) {
                $actorModel = $line->actor_type::find($line->actor_id);
                if ($actorModel) {
                    $wallet = $actorModel->wallet ?? $actorModel->wallet()->create([
                        'balance' => 0,
                        'currency' => 'XOF',
                    ]);

                    $suffix = strtoupper(class_basename($line->actor_type)) . '-' . $line->actor_id;
                    $wallet->credit(
                        $line->amount,
                        "COMMISSION-{$commission->id}-{$suffix}",
                        "Commission pour commande #{$order->reference}",
                        ['commission_id' => $commission->id]
                    );
                }
            }
        }
    }
}
