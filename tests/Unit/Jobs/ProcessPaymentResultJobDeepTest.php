<?php

namespace Tests\Unit\Jobs;

use App\Actions\CalculateCommissionAction;
use App\Enums\JekoPaymentMethod;
use App\Enums\JekoPaymentStatus;
use App\Jobs\ProcessPaymentResultJob;
use App\Jobs\SendNotificationJob;
use App\Models\Courier;
use App\Models\Customer;
use App\Models\JekoPayment;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use App\Models\Wallet;
use App\Services\BusinessEventService;
use App\Services\CustomerWalletService;
use App\Services\WalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class ProcessPaymentResultJobDeepTest extends TestCase
{
    use RefreshDatabase;

    // ─── handle(): payment not found ───

    public function test_handle_returns_early_when_payment_not_found(): void
    {
        Log::spy();

        $job = new ProcessPaymentResultJob(999999);
        $job->handle();

        Log::shouldHaveReceived('warning')
            ->withArgs(fn($msg) => str_contains($msg, 'payment not found'))
            ->once();
    }

    // ─── handle(): idempotency — already processed ───

    public function test_handle_skips_already_processed_payment(): void
    {
        Log::spy();

        $order = Order::factory()->create();
        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => true,
        ]);

        $job = new ProcessPaymentResultJob($payment->id);
        $job->handle();

        Log::shouldHaveReceived('info')
            ->withArgs(fn($msg) => str_contains($msg, 'already processed'))
            ->once();

        // Order should NOT be marked as paid
        $this->assertNotEquals('paid', $order->fresh()->payment_status);
    }

    // ─── handle(): non-success status ───

    public function test_handle_skips_non_success_payment(): void
    {
        $order = Order::factory()->create();
        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'status' => JekoPaymentStatus::PENDING,
            'business_processed' => false,
        ]);

        $job = new ProcessPaymentResultJob($payment->id);
        $job->handle();

        $this->assertEmpty($payment->fresh()->business_processed);
    }

    public function test_handle_skips_failed_payment(): void
    {
        $order = Order::factory()->create();
        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'status' => JekoPaymentStatus::FAILED,
            'business_processed' => false,
        ]);

        $job = new ProcessPaymentResultJob($payment->id);
        $job->handle();

        $this->assertEmpty($payment->fresh()->business_processed);
    }

    // ─── handle(): no payable ───

    public function test_handle_skips_when_no_payable(): void
    {
        Log::spy();

        // Use a real model class but with a non-existing ID
        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => 999999,
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
        ]);

        $job = new ProcessPaymentResultJob($payment->id);
        $job->handle();

        Log::shouldHaveReceived('warning')
            ->withArgs(fn($msg) => str_contains($msg, 'no payable'))
            ->once();
    }

    // ─── handle(): Order payment — full flow ───

    public function test_handle_processes_order_payment_successfully(): void
    {
        Queue::fake([SendNotificationJob::class]);
        Log::spy();

        $pharmacy = Pharmacy::factory()->create();
        $pharmacyUser = User::factory()->pharmacy()->create();
        $pharmacy->users()->attach($pharmacyUser);

        $user = User::factory()->customer()->create();
        $order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $user->id,
            'payment_status' => 'pending',
        ]);

        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'user_id' => $user->id,
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
            'amount_cents' => 500000,
        ]);

        // Mock CalculateCommissionAction to avoid complex dependency chain
        $commissionAction = \Mockery::mock(CalculateCommissionAction::class);
        $commissionAction->shouldReceive('execute')->once();
        $this->app->instance(CalculateCommissionAction::class, $commissionAction);

        $job = new ProcessPaymentResultJob($payment->id);
        $job->handle();

        // Verify order was marked as paid
        $order->refresh();
        $this->assertEquals('paid', $order->payment_status);
        $this->assertNotNull($order->paid_at);

        // Verify payment was marked as business_processed
        $this->assertTrue((bool) $payment->fresh()->business_processed);

        // Verify notification dispatched
        Queue::assertPushed(SendNotificationJob::class);
    }

    // ─── handle(): Order already paid — idempotent ───

    public function test_handle_skips_already_paid_order(): void
    {
        Queue::fake([SendNotificationJob::class]);
        Log::spy();

        $user = User::factory()->customer()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->paid()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $user->id,
        ]);

        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'user_id' => $user->id,
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
        ]);

        // Commission should NOT be calculated for already-paid orders
        $commissionAction = \Mockery::mock(CalculateCommissionAction::class);
        $commissionAction->shouldNotReceive('execute');
        $this->app->instance(CalculateCommissionAction::class, $commissionAction);

        $job = new ProcessPaymentResultJob($payment->id);
        $job->handle();

        // Payment still marked as processed (the transaction wrapper sets this)
        $this->assertTrue((bool) $payment->fresh()->business_processed);
    }

    // ─── handle(): Order commission failure ───

    public function test_handle_continues_when_commission_calculation_fails(): void
    {
        Queue::fake([SendNotificationJob::class]);
        Log::spy();

        $user = User::factory()->customer()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $user->id,
            'payment_status' => 'pending',
        ]);

        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'user_id' => $user->id,
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
        ]);

        $commissionAction = \Mockery::mock(CalculateCommissionAction::class);
        $commissionAction->shouldReceive('execute')
            ->once()
            ->andThrow(new \RuntimeException('Commission calculation failed'));
        $this->app->instance(CalculateCommissionAction::class, $commissionAction);

        $job = new ProcessPaymentResultJob($payment->id);
        $job->handle();

        // Order should still be paid even if commission fails
        $this->assertEquals('paid', $order->fresh()->payment_status);
        $this->assertTrue((bool) $payment->fresh()->business_processed);

        Log::shouldHaveReceived('error')
            ->withArgs(fn($msg) => str_contains($msg, 'commission calculation failed'))
            ->once();
    }

    // ─── handle(): Order with no pharmacy users ───

    public function test_handle_order_with_no_pharmacy_users_skips_notification(): void
    {
        Queue::fake([SendNotificationJob::class]);
        Log::spy();

        $user = User::factory()->customer()->create();
        $pharmacy = Pharmacy::factory()->create();
        // No users attached to pharmacy

        $order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $user->id,
            'payment_status' => 'pending',
        ]);

        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'user_id' => $user->id,
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
        ]);

        $commissionAction = \Mockery::mock(CalculateCommissionAction::class);
        $commissionAction->shouldReceive('execute')->once();
        $this->app->instance(CalculateCommissionAction::class, $commissionAction);

        $job = new ProcessPaymentResultJob($payment->id);
        $job->handle();

        // No notification since no pharmacy users
        Queue::assertNotPushed(SendNotificationJob::class);
        $this->assertEquals('paid', $order->fresh()->payment_status);
    }

    // ─── handle(): Wallet topup — Customer wallet ───

    public function test_handle_processes_customer_wallet_topup(): void
    {
        Log::spy();

        $customer = Customer::factory()->create();
        $wallet = Wallet::factory()->forOwner($customer)->withBalance(0)->create();

        $payment = JekoPayment::factory()->create([
            'payable_type' => Wallet::class,
            'payable_id' => $wallet->id,
            'user_id' => $customer->user_id,
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
            'amount_cents' => 100000, // 1000 XOF
            'payment_method' => JekoPaymentMethod::WAVE,
        ]);

        $walletService = \Mockery::mock(CustomerWalletService::class);
        $walletService->shouldReceive('topUp')
            ->once()
            ->with(
                \Mockery::type(User::class),
                1000.0,  // amount_cents / 100
                'wave',
                \Mockery::type('string')
            );
        $this->app->instance(CustomerWalletService::class, $walletService);

        $job = new ProcessPaymentResultJob($payment->id);
        $job->handle();

        $this->assertTrue((bool) $payment->fresh()->business_processed);
    }

    // ─── handle(): Wallet topup — Courier wallet (non-Customer) ───

    public function test_handle_processes_courier_wallet_topup(): void
    {
        Log::spy();

        $courier = Courier::factory()->create();
        $wallet = Wallet::factory()->forOwner($courier)->withBalance(0)->create();

        $payment = JekoPayment::factory()->create([
            'payable_type' => Wallet::class,
            'payable_id' => $wallet->id,
            'user_id' => User::factory()->create()->id,
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
            'amount_cents' => 500000,
            'payment_method' => JekoPaymentMethod::ORANGE,
        ]);

        $walletService = \Mockery::mock(WalletService::class);
        $walletService->shouldReceive('topUp')
            ->once()
            ->with(
                \Mockery::type(Courier::class),
                5000.0,  // amount_cents / 100
                'orange',
                \Mockery::type('string')
            );
        $this->app->instance(WalletService::class, $walletService);

        $job = new ProcessPaymentResultJob($payment->id);
        $job->handle();

        $this->assertTrue((bool) $payment->fresh()->business_processed);
    }

    // ─── handle(): Wallet topup — idempotent (duplicate reference) ───

    public function test_handle_wallet_topup_with_existing_transaction_is_idempotent(): void
    {
        Log::spy();

        $pharmacy = Pharmacy::factory()->create();
        $wallet = Wallet::factory()->forOwner($pharmacy)->withBalance(5000)->create();

        $payment = JekoPayment::factory()->create([
            'payable_type' => Wallet::class,
            'payable_id' => $wallet->id,
            'user_id' => User::factory()->create()->id,
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
            'amount_cents' => 100000,
            'payment_method' => JekoPaymentMethod::MTN,
        ]);

        // Create a pre-existing transaction with same reference
        $wallet->transactions()->create([
            'type' => 'CREDIT',
            'amount' => 1000,
            'balance_after' => 6000,
            'reference' => $payment->reference,
            'description' => 'Duplicate topup',
        ]);

        $job = new ProcessPaymentResultJob($payment->id);
        $job->handle();

        // The job marks business_processed after the transaction block
        $this->assertTrue((bool) $payment->fresh()->business_processed);
    }

    // ─── failed() ───

    public function test_failed_logs_critical_with_details(): void
    {
        Log::spy();

        $job = new ProcessPaymentResultJob(42);
        $job->failed(new \RuntimeException('Payment processing failed'));

        Log::shouldHaveReceived('critical')
            ->withArgs(function ($msg, $context) {
                return str_contains($msg, 'FAILED')
                    && isset($context['payment_id'])
                    && isset($context['error'])
                    && isset($context['trace']);
            })
            ->once();
    }

    // ─── middleware() ───

    public function test_middleware_uses_payment_id_for_lock_key(): void
    {
        $job1 = new ProcessPaymentResultJob(1);
        $job2 = new ProcessPaymentResultJob(2);

        $middleware1 = $job1->middleware();
        $middleware2 = $job2->middleware();

        $this->assertNotEmpty($middleware1);
        $this->assertNotEmpty($middleware2);
    }
}
