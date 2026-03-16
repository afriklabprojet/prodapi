<?php

namespace App\Services;

use App\Models\Commission;
use App\Models\Order;
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
                $delivery = $order->delivery;
                $courier = $delivery?->courier;

                // Rates (default or from pharmacy)
                $ratePlatform = $this->normalizeRate($pharmacy->commission_rate_platform ?? 10);
                $ratePharmacy = $this->normalizeRate($pharmacy->commission_rate_pharmacy ?? 85);
                $rateCourier = $this->normalizeRate($pharmacy->commission_rate_courier ?? 5);

                $total = $order->total_amount;
                
                // Adjust rates if no courier (Pickup)
                if (!$courier) {
                    $ratePharmacy += $rateCourier;
                    $rateCourier = 0;
                }

                $amountPlatform = $total * $ratePlatform;
                $amountPharmacy = $total * $ratePharmacy;
                $amountCourier = $total * $rateCourier;

                // Create Commission Record
                $commission = Commission::create([
                    'order_id' => $order->id,
                    'total_amount' => $total,
                    'calculated_at' => now(),
                ]);

                // Lines
                $commission->lines()->create([
                    'actor_type' => 'platform',
                    'actor_id' => 0, // 0 for platform
                    'rate' => $ratePlatform,
                    'amount' => $amountPlatform,
                ]);

                $commission->lines()->create([
                    'actor_type' => \App\Models\Pharmacy::class,
                    'actor_id' => $pharmacy->id,
                    'rate' => $ratePharmacy,
                    'amount' => $amountPharmacy,
                ]);

                if ($courier && $amountCourier > 0) {
                    $commission->lines()->create([
                        'actor_type' => \App\Models\Courier::class,
                        'actor_id' => $courier->id,
                        'rate' => $rateCourier,
                        'amount' => $amountCourier,
                    ]);
                }

                // Update Wallets
                $this->creditWallet(Wallet::platform(), $amountPlatform, $order, 'Commission Plateforme');
                
                $pharmacyWallet = $pharmacy->wallet()->firstOrCreate([], ['currency' => 'XOF', 'balance' => 0]);
                $this->creditWallet($pharmacyWallet, $amountPharmacy, $order, 'Vente');

                if ($courier && $amountCourier > 0) {
                    $courierWallet = $courier->wallet()->firstOrCreate([], ['currency' => 'XOF', 'balance' => 0]);
                    $this->creditWallet($courierWallet, $amountCourier, $order, 'Livraison');
                }
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

    private function normalizeRate($rate)
    {
        // If rate is > 1 (e.g. 10, 85), treat as percentage (10%, 85%)
        // If rate is <= 1 (e.g. 0.10, 0.85), treat as decimal
        if ($rate > 1) {
            return $rate / 100;
        }
        return $rate;
    }
}
