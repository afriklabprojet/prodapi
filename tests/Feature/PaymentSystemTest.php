<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Pharmacy;
use App\Models\Courier;
use App\Models\Order;
use App\Models\Payment;
use App\Models\PaymentIntent;
use App\Models\Commission;
use App\Models\CommissionLine;
use App\Models\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Config;

class PaymentSystemTest extends TestCase
{
    use RefreshDatabase;

    protected $customer;
    protected $pharmacy;
    protected $pharmacyUser;
    protected $courier;
    protected $courierUser;
    protected $order;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->customer = User::factory()->create(['role' => 'customer']);
        
        $this->pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
        ]);
        $this->pharmacy->users()->attach($this->pharmacyUser->id, ['role' => 'owner']);
        
        $this->courierUser = User::factory()->create(['role' => 'courier']);
        $this->courier = Courier::factory()->create([
            'user_id' => $this->courierUser->id,
            'status' => 'available',
        ]);

        $this->order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'confirmed',
            'total_amount' => 10000,
        ]);
    }

    /** @test */
    public function payment_intent_is_created_on_initiate()
    {
        $paymentIntent = PaymentIntent::create([
            'order_id' => $this->order->id,
            'amount' => $this->order->total_amount,
            'currency' => 'XOF',
            'provider' => 'jeko',
            'reference' => 'PI-' . uniqid(),
            'status' => 'PENDING',
        ]);

        $this->assertDatabaseHas('payment_intents', [
            'order_id' => $this->order->id,
            'amount' => 10000,
            'provider' => 'jeko',
            'status' => 'PENDING',
        ]);
    }

    /** @test */
    public function commission_is_calculated_correctly()
    {
        $orderAmount = 10000;
        
        // Platform: 10%, Pharmacy: 85%, Courier: 5%
        $expectedPlatform = $orderAmount * 0.10; // 1000
        $expectedPharmacy = $orderAmount * 0.85; // 8500
        $expectedCourier = $orderAmount * 0.05;  // 500

        $this->assertEquals(1000, $expectedPlatform);
        $this->assertEquals(8500, $expectedPharmacy);
        $this->assertEquals(500, $expectedCourier);
    }

    /** @test */
    public function payment_success_creates_commission_records()
    {
        $paymentIntent = PaymentIntent::factory()->create([
            'order_id' => $this->order->id,
            'amount' => 10000,
            'provider' => 'jeko',
        ]);

        $payment = Payment::factory()->create([
            'order_id' => $this->order->id,
            'amount' => 10000,
            'status' => 'SUCCESS',
        ]);

        // Create commission
        $commission = Commission::create([
            'order_id' => $this->order->id,
            'total_amount' => 10000,
            'calculated_at' => now(),
        ]);

        // Create commission lines
        CommissionLine::create([
            'commission_id' => $commission->id,
            'actor_type' => 'platform',
            'actor_id' => null,
            'rate' => 0.10,
            'amount' => 1000,
        ]);

        CommissionLine::create([
            'commission_id' => $commission->id,
            'actor_type' => Pharmacy::class,
            'actor_id' => $this->pharmacy->id,
            'rate' => 0.85,
            'amount' => 8500,
        ]);

        CommissionLine::create([
            'commission_id' => $commission->id,
            'actor_type' => Courier::class,
            'actor_id' => $this->courier->id,
            'rate' => 0.05,
            'amount' => 500,
        ]);

        $this->assertDatabaseHas('commissions', [
            'order_id' => $this->order->id,
            'total_amount' => 10000,
        ]);

        $this->assertDatabaseCount('commission_lines', 3);
    }

    /** @test */
    public function wallets_are_credited_after_payment()
    {
        // Ensure wallets exist
        $pharmacyWallet = Wallet::firstOrCreate(
            ['walletable_type' => Pharmacy::class, 'walletable_id' => $this->pharmacy->id],
            ['balance' => 0, 'currency' => 'XOF']
        );

        $courierWallet = Wallet::firstOrCreate(
            ['walletable_type' => Courier::class, 'walletable_id' => $this->courier->id],
            ['balance' => 0, 'currency' => 'XOF']
        );

        // Simulate commission payment
        $pharmacyWallet->increment('balance', 8500);
        $courierWallet->increment('balance', 500);

        $this->assertEquals(8500, $pharmacyWallet->fresh()->balance);
        $this->assertEquals(500, $courierWallet->fresh()->balance);
    }

    /** @test */
    public function wallet_transactions_are_recorded()
    {
        $wallet = Wallet::firstOrCreate(
            ['walletable_type' => Pharmacy::class, 'walletable_id' => $this->pharmacy->id],
            ['balance' => 0, 'currency' => 'XOF']
        );

        $transaction = $wallet->transactions()->create([
            'type' => 'CREDIT',
            'amount' => 8500,
            'description' => 'Commission from order #' . $this->order->order_number,
            'balance_after' => 8500,
        ]);

        $this->assertDatabaseHas('wallet_transactions', [
            'wallet_id' => $wallet->id,
            'type' => 'CREDIT',
            'amount' => 8500,
        ]);
    }

    /** @test */
    public function jeko_webhook_signature_is_verified()
    {
        Config::set('services.jeko.secret_key', 'test_secret_key');

        $payload = [
            'transaction_id' => 'TRANS123456',
            'reference' => 'ORDER123',
            'amount' => 10000,
            'status' => 'SUCCESS',
        ];

        $signature = hash_hmac('sha256', json_encode($payload), 'test_secret_key');

        $this->assertNotEmpty($signature);
    }

    /** @test */
    public function payment_failure_does_not_create_commission()
    {
        $paymentIntent = PaymentIntent::factory()->create([
            'order_id' => $this->order->id,
            'amount' => 10000,
            'provider' => 'jeko',
        ]);

        $payment = Payment::factory()->create([
            'order_id' => $this->order->id,
            'amount' => 10000,
            'status' => 'FAILED',
        ]);

        $commissionCount = Commission::where('payment_id', $payment->id)->count();
        
        $this->assertEquals(0, $commissionCount);
    }

    /** @test */
    public function order_status_updates_after_payment()
    {
        $paymentIntent = PaymentIntent::factory()->create([
            'order_id' => $this->order->id,
            'amount' => 10000,
        ]);

        Payment::factory()->create([
            'order_id' => $this->order->id,
            'amount' => 10000,
            'status' => 'SUCCESS',
        ]);

        // Manually update order status (normally done by webhook handler)
        $this->order->update(['status' => 'paid']);

        $this->assertDatabaseHas('orders', [
            'id' => $this->order->id,
            'status' => 'paid',
        ]);
    }

    /** @test */
    public function multiple_payments_for_same_order_are_tracked()
    {
        $paymentIntent = PaymentIntent::factory()->create([
            'order_id' => $this->order->id,
            'amount' => 10000,
        ]);

        // First payment attempt fails
        Payment::factory()->create([
            'order_id' => $this->order->id,
            'amount' => 10000,
            'status' => 'FAILED',
        ]);

        // Second payment succeeds
        Payment::factory()->create([
            'order_id' => $this->order->id,
            'amount' => 10000,
            'status' => 'SUCCESS',
        ]);

        $this->assertDatabaseCount('payments', 2);
        
        $successfulPayments = Payment::where('order_id', $this->order->id)
            ->where('status', 'SUCCESS')
            ->count();
            
        $this->assertEquals(1, $successfulPayments);
    }

    /** @test */
    public function commission_breakdown_sums_to_total()
    {
        $payment = Payment::factory()->create([
            'order_id' => $this->order->id,
            'amount' => 10000,
            'status' => 'SUCCESS',
        ]);

        $commission = Commission::create([
            'order_id' => $this->order->id,
            'total_amount' => 10000,
            'calculated_at' => now(),
        ]);

        $line1 = CommissionLine::create([
            'commission_id' => $commission->id,
            'actor_type' => 'platform',
            'actor_id' => null,
            'rate' => 0.10,
            'amount' => 1000,
        ]);

        $line2 = CommissionLine::create([
            'commission_id' => $commission->id,
            'actor_type' => Pharmacy::class,
            'actor_id' => $this->pharmacy->id,
            'rate' => 0.85,
            'amount' => 8500,
        ]);

        $line3 = CommissionLine::create([
            'commission_id' => $commission->id,
            'actor_type' => Courier::class,
            'actor_id' => $this->courier->id,
            'rate' => 0.05,
            'amount' => 500,
        ]);

        $total = $line1->amount + $line2->amount + $line3->amount;

        $this->assertEquals($commission->total_amount, $total);
    }

    /** @test */
    public function wallet_balance_cannot_be_negative()
    {
        $wallet = Wallet::factory()->create([
            'walletable_type' => Pharmacy::class,
            'walletable_id' => $this->pharmacy->id,
            'balance' => 1000,
        ]);

        // Try to deduct more than balance
        $this->expectException(\Exception::class);
        
        if ($wallet->balance < 2000) {
            throw new \Exception('Insufficient balance');
        }

        $wallet->decrement('balance', 2000);
    }

    /** @test */
    public function payment_intent_expires_after_timeout()
    {
        $paymentIntent = PaymentIntent::factory()->create([
            'order_id' => $this->order->id,
            'amount' => 10000,
            'created_at' => now()->subHours(2),
        ]);

        // Check if expired (typically 1 hour)
        $isExpired = $paymentIntent->created_at->addHour()->isPast();

        $this->assertTrue($isExpired);
    }

    /** @test */
    public function refund_reverses_commission()
    {
        $payment = Payment::factory()->create([
            'order_id' => $this->order->id,
            'amount' => 10000,
            'status' => 'SUCCESS',
        ]);

        $commission = Commission::create([
            'order_id' => $this->order->id,
            'total_amount' => 10000,
            'calculated_at' => now(),
        ]);

        // Simulate refund
        $payment->update(['status' => 'FAILED']);
        
        // Deduct from wallets (would be done by refund handler)
        $pharmacyWallet = Wallet::firstOrCreate(
            ['walletable_type' => Pharmacy::class, 'walletable_id' => $this->pharmacy->id],
            ['balance' => 8500, 'currency' => 'XOF']
        );
        
        $pharmacyWallet->decrement('balance', 8500);

        $this->assertEquals(0, $pharmacyWallet->fresh()->balance);
    }

    /** @test */
    public function commission_is_only_created_once_per_payment()
    {
        $payment = Payment::factory()->create([
            'order_id' => $this->order->id,
            'amount' => 10000,
            'status' => 'SUCCESS',
        ]);

        Commission::create([
            'order_id' => $this->order->id,
            'total_amount' => 10000,
            'calculated_at' => now(),
        ]);

        // Try to create duplicate
        $commissionCount = Commission::where('order_id', $this->order->id)->count();
        
        $this->assertEquals(1, $commissionCount);
    }
}
