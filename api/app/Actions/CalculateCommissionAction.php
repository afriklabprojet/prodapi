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
     * - La pharmacie reçoit 100% du prix des médicaments
     * - La plateforme reçoit les frais de service (2% par défaut, ajoutés au prix)
     * - Le coursier reçoit les frais de livraison (géré séparément dans DeliveryController)
     */
    public function execute(Order $order): Commission
    {
        return DB::transaction(function () use ($order) {
            // Vérifier si la commande a déjà des commissions
            if ($order->commission) {
                Log::info('Commission already calculated', ['order_id' => $order->id]);
                return $order->commission;
            }

            // Obtenir le taux de commission depuis les paramètres (service_fee_percentage)
            $platformRate = (float) Setting::get('service_fee_percentage', 2) / 100;
            
            // subtotal = prix des médicaments uniquement
            $subtotal = $order->subtotal ?? $order->total_amount;
            
            // La pharmacie reçoit 100% du prix des médicaments
            $pharmacyAmount = $subtotal;
            
            // La plateforme reçoit le pourcentage configuré (2% par défaut)
            $platformAmount = round($subtotal * $platformRate, 0);

            // Créer le record Commission
            $commission = Commission::create([
                'order_id' => $order->id,
                'total_amount' => $subtotal,
                'calculated_at' => now(),
            ]);

            // Créer les lignes de commission
            $commissionLines = [
                // Platform - 2% du prix des médicaments
                [
                    'commission_id' => $commission->id,
                    'actor_type' => 'platform',
                    'actor_id' => null,
                    'rate' => $platformRate,
                    'amount' => $platformAmount,
                ],
                // Pharmacy - 100% du prix des médicaments
                [
                    'commission_id' => $commission->id,
                    'actor_type' => 'App\Models\Pharmacy',
                    'actor_id' => $order->pharmacy_id,
                    'rate' => 1.0, // 100%
                    'amount' => $pharmacyAmount,
                ],
            ];

            foreach ($commissionLines as $lineData) {
                CommissionLine::create($lineData);
            }

            // Créditer les wallets
            $commission->load('lines');
            $this->creditWallets($commission);

            Log::info('Commission calculated and distributed', [
                'order_id' => $order->id,
                'commission_id' => $commission->id,
                'subtotal' => $subtotal,
                'platform_amount' => $platformAmount,
                'pharmacy_amount' => $pharmacyAmount,
            ]);

            return $commission;
        });
    }

    /**
     * Créditer les wallets de chaque acteur
     */
    protected function creditWallets(Commission $commission): void
    {
        $order = Order::find($commission->order_id);

        foreach ($commission->lines as $line) {
            // Wallet de la plateforme
            if ($line->actor_type === 'platform') {
                $wallet = Wallet::platform();
                $wallet->credit(
                    $line->amount,
                    "COMMISSION-{$commission->id}",
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

                    $wallet->credit(
                        $line->amount,
                        "COMMISSION-{$commission->id}",
                        "Commission pour commande #{$order->reference}",
                        ['commission_id' => $commission->id]
                    );
                }
            }
        }
    }
}
