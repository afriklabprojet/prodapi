<?php

namespace Tests\Unit\Services;

use App\Models\Courier;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use App\Models\Setting;
use App\Services\WalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class WalletServiceTest extends TestCase
{
    use RefreshDatabase;

    protected WalletService $walletService;
    protected Courier $courier;
    protected Wallet $wallet;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->walletService = new WalletService();
        
        $this->courier = Courier::factory()->create();
        $this->wallet = Wallet::factory()->create([
            'walletable_type' => Courier::class,
            'walletable_id' => $this->courier->id,
            'balance' => 5000,
        ]);
    }

    /** @test */
    public function it_returns_default_commission_amount()
    {
        $amount = WalletService::getCommissionAmount();
        
        $this->assertEquals(WalletService::DEFAULT_COMMISSION_AMOUNT, $amount);
    }

    /** @test */
    public function it_returns_configured_commission_amount()
    {
        Setting::set('courier_commission_amount', 300);
        
        $amount = WalletService::getCommissionAmount();
        
        $this->assertEquals(300, $amount);
    }

    /** @test */
    public function it_calculates_delivery_fee_correctly()
    {
        // Set pricing
        Setting::set('delivery_fee_base', 200);
        Setting::set('delivery_fee_per_km', 100);
        Setting::set('delivery_fee_min', 300);
        Setting::set('delivery_fee_max', 5000);
        
        // 5km distance: 200 + (5 * 100) = 700 FCFA
        $fee = WalletService::calculateDeliveryFee(5.0);
        $this->assertEquals(700, $fee);
    }

    /** @test */
    public function it_applies_minimum_delivery_fee()
    {
        Setting::set('delivery_fee_base', 200);
        Setting::set('delivery_fee_per_km', 100);
        Setting::set('delivery_fee_min', 500);
        Setting::set('delivery_fee_max', 5000);
        
        // 0.5km distance: 200 + (0.5 * 100) = 250, but min is 500
        $fee = WalletService::calculateDeliveryFee(0.5);
        $this->assertEquals(500, $fee);
    }

    /** @test */
    public function it_applies_maximum_delivery_fee()
    {
        Setting::set('delivery_fee_base', 200);
        Setting::set('delivery_fee_per_km', 100);
        Setting::set('delivery_fee_min', 300);
        Setting::set('delivery_fee_max', 2000);
        
        // 50km distance: 200 + (50 * 100) = 5200, but max is 2000
        $fee = WalletService::calculateDeliveryFee(50.0);
        $this->assertEquals(2000, $fee);
    }

    /** @test */
    public function it_returns_delivery_pricing_settings()
    {
        Setting::set('delivery_fee_base', 250);
        Setting::set('delivery_fee_per_km', 150);
        Setting::set('delivery_fee_min', 400);
        Setting::set('delivery_fee_max', 3000);
        
        $pricing = WalletService::getDeliveryPricing();
        
        $this->assertEquals([
            'base_fee' => 250,
            'fee_per_km' => 150,
            'min_fee' => 400,
            'max_fee' => 3000,
        ], $pricing);
    }

    /** @test */
    public function it_gets_wallet_balance()
    {
        $balance = $this->walletService->getBalance($this->courier);
        
        $this->assertEquals(5000, $balance['balance']);
        $this->assertEquals('XOF', $balance['currency']);
    }

    /** @test */
    public function it_checks_if_courier_can_deliver()
    {
        // With 5000 balance and 200 commission, courier can deliver
        $this->assertTrue($this->walletService->canCompleteDelivery($this->courier));
        
        // Set balance to 0
        $this->wallet->update(['balance' => 0]);
        $this->assertFalse($this->walletService->canCompleteDelivery($this->courier));
    }

    /** @test */
    public function it_tops_up_wallet()
    {
        $transaction = $this->walletService->topUp(
            $this->courier,
            1000,
            'orange_money',
            'PAY-123'
        );
        
        $this->assertInstanceOf(WalletTransaction::class, $transaction);
        $this->assertEquals(1000, $transaction->amount);
        $this->assertEquals('CREDIT', $transaction->type);
        
        $this->wallet->refresh();
        $this->assertEquals(6000, $this->wallet->balance);
    }

    /** @test */
    public function it_credits_delivery_earning()
    {
        $order = Order::factory()->create(['delivery_fee' => 1000]);
        $delivery = Delivery::factory()->create([
            'courier_id' => $this->courier->id,
            'order_id' => $order->id,
        ]);
        
        $transaction = $this->walletService->creditDeliveryEarning(
            $this->courier,
            $delivery,
            1000
        );
        
        $this->assertInstanceOf(WalletTransaction::class, $transaction);
        $this->assertEquals(1000, $transaction->amount);
        
        $this->wallet->refresh();
        $this->assertEquals(6000, $this->wallet->balance);
    }

    /** @test */
    public function it_deducts_commission()
    {
        $order = Order::factory()->create();
        $delivery = Delivery::factory()->create([
            'courier_id' => $this->courier->id,
            'order_id' => $order->id,
        ]);
        
        $transaction = $this->walletService->deductCommission($this->courier, $delivery);
        
        $this->assertInstanceOf(WalletTransaction::class, $transaction);
        $this->assertEquals(WalletService::getCommissionAmount(), $transaction->amount);
        $this->assertEquals('DEBIT', $transaction->type);
        
        $this->wallet->refresh();
        $this->assertEquals(5000 - WalletService::getCommissionAmount(), $this->wallet->balance);
    }

    /** @test */
    public function it_requests_withdrawal()
    {
        $transaction = $this->walletService->requestWithdrawal(
            $this->courier,
            2000,
            'orange_money',
            '0787654321'
        );
        
        $this->assertInstanceOf(WalletTransaction::class, $transaction);
        $this->assertEquals('pending', $transaction->status);
        $this->assertEquals(2000, $transaction->amount);
    }

    /** @test */
    public function it_rejects_withdrawal_with_insufficient_balance()
    {
        $this->expectException(\Exception::class);
        
        $this->walletService->requestWithdrawal(
            $this->courier,
            10000, // More than balance
            'orange_money',
            '0787654321'
        );
    }

    /** @test */
    public function it_gets_statistics()
    {
        // Create some transactions
        WalletTransaction::factory()->count(5)->create([
            'wallet_id' => $this->wallet->id,
            'type' => 'credit',
            'category' => 'topup',
            'amount' => 1000,
            'status' => 'completed',
        ]);
        
        $stats = $this->walletService->getStatistics($this->courier);
        
        $this->assertArrayHasKey('total_topups', $stats);
        $this->assertArrayHasKey('total_delivery_earnings', $stats);
        $this->assertArrayHasKey('total_commissions', $stats);
        $this->assertArrayHasKey('deliveries_count', $stats);
    }

    /** @test */
    public function it_gets_transaction_history()
    {
        WalletTransaction::factory()->count(10)->create([
            'wallet_id' => $this->wallet->id,
        ]);
        
        $transactions = $this->walletService->getTransactionHistory($this->courier, 5);
        
        $this->assertCount(5, $transactions);
    }

    /** @test */
    public function it_checks_service_fee_settings()
    {
        Setting::set('apply_service_fee', true);
        $this->assertTrue(WalletService::isServiceFeeEnabled());
        
        Setting::set('apply_service_fee', false);
        $this->assertFalse(WalletService::isServiceFeeEnabled());
    }

    /** @test */
    public function it_checks_payment_fee_settings()
    {
        Setting::set('apply_payment_fee', true);
        $this->assertTrue(WalletService::isPaymentFeeEnabled());
        
        Setting::set('apply_payment_fee', false);
        $this->assertFalse(WalletService::isPaymentFeeEnabled());
    }

    /** @test */
    public function it_returns_service_fee_configuration()
    {
        Setting::set('service_fee_percentage', 5);
        Setting::set('service_fee_min', 200);
        Setting::set('service_fee_max', 3000);
        
        $this->assertEquals(5.0, WalletService::getServiceFeePercentage());
        $this->assertEquals(200, WalletService::getServiceFeeMin());
        $this->assertEquals(3000, WalletService::getServiceFeeMax());
    }
}
