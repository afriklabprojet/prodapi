<?php

namespace Tests\Unit\Jobs;

use App\Jobs\CheckPendingJekoPayments;
use App\Models\JekoPayment;
use App\Models\Order;
use App\Models\User;
use App\Models\Pharmacy;
use App\Models\Customer;
use App\Services\JekoPaymentService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;
use Mockery;

class CheckPendingJekoPaymentsTest extends TestCase
{
    use RefreshDatabase;

    protected $order;
    protected $payment;

    protected function setUp(): void
    {
        parent::setUp();

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $customerUser = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $customerUser->id]);

        $this->order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $customerUser->id,
            'status' => 'pending',
            'total_amount' => 5000,
        ]);

        $this->payment = JekoPayment::factory()->create([
            'payable_type' => 'App\Models\Order',
            'payable_id' => $this->order->id,
            'amount_cents' => 500000,
            'status' => 'pending',
            'reference' => 'JEKO-TEST-123',
            'initiated_at' => Carbon::now()->subMinutes(10),
        ]);
    }

    /** @test */
    public function job_can_be_queued()
    {
        Queue::fake();

        CheckPendingJekoPayments::dispatch();

        Queue::assertPushed(CheckPendingJekoPayments::class);
    }

    /** @test */
    public function job_can_be_constructed_with_timeout()
    {
        $job = new CheckPendingJekoPayments(10);

        $this->assertEquals(10, $job->timeoutMinutes);
    }

    /** @test */
    public function job_uses_default_timeout_of_5_minutes()
    {
        $job = new CheckPendingJekoPayments();

        $this->assertEquals(5, $job->timeoutMinutes);
    }

    /** @test */
    public function it_checks_expired_pending_payments()
    {
        // Mock JekoPaymentService
        $mockService = Mockery::mock(JekoPaymentService::class);
        $mockService->shouldReceive('checkPaymentStatus')
            ->once()
            ->andReturn($this->payment);

        $this->app->instance(JekoPaymentService::class, $mockService);

        $job = new CheckPendingJekoPayments(5);
        $job->handle($mockService);

        // Test passes if no exception thrown
        $this->assertTrue(true);
    }

    /** @test */
    public function it_marks_payment_as_expired_when_still_pending()
    {
        $payment = Mockery::mock(JekoPayment::class)->makePartial();
        $payment->shouldReceive('isSuccess')->andReturn(false);
        $payment->shouldReceive('isFailed')->andReturn(false);
        $payment->shouldReceive('isFinal')->andReturn(false);
        $payment->shouldReceive('markAsExpired')->once();

        $mockService = Mockery::mock(JekoPaymentService::class);
        $mockService->shouldReceive('checkPaymentStatus')
            ->andReturn($payment);

        // Create fresh payment for query
        $this->payment->update([
            'initiated_at' => Carbon::now()->subMinutes(10),
        ]);

        $job = new CheckPendingJekoPayments(5);
        $job->handle($mockService);

        $this->assertTrue(true);
    }

    /** @test */
    public function it_skips_recent_pending_payments()
    {
        // Payment initiated only 2 minutes ago - should not be checked
        $this->payment->update([
            'initiated_at' => Carbon::now()->subMinutes(2),
        ]);

        $mockService = Mockery::mock(JekoPaymentService::class);
        $mockService->shouldNotReceive('checkPaymentStatus');

        $job = new CheckPendingJekoPayments(5);
        $job->handle($mockService);

        $this->assertTrue(true);
    }

    /** @test */
    public function it_handles_successful_payment_resolution()
    {
        $payment = Mockery::mock(JekoPayment::class)->makePartial();
        $payment->reference = 'JEKO-TEST-123';
        $payment->shouldReceive('isSuccess')->andReturn(true);

        $mockService = Mockery::mock(JekoPaymentService::class);
        $mockService->shouldReceive('checkPaymentStatus')
            ->andReturn($payment);

        $job = new CheckPendingJekoPayments(5);
        $job->handle($mockService);

        $this->assertTrue(true);
    }

    /** @test */
    public function it_handles_failed_payment_resolution()
    {
        $payment = Mockery::mock(JekoPayment::class)->makePartial();
        $payment->reference = 'JEKO-TEST-123';
        $payment->shouldReceive('isSuccess')->andReturn(false);
        $payment->shouldReceive('isFailed')->andReturn(true);

        $mockService = Mockery::mock(JekoPaymentService::class);
        $mockService->shouldReceive('checkPaymentStatus')
            ->andReturn($payment);

        $job = new CheckPendingJekoPayments(5);
        $job->handle($mockService);

        $this->assertTrue(true);
    }

    /** @test */
    public function it_handles_exceptions_gracefully()
    {
        $mockService = Mockery::mock(JekoPaymentService::class);
        $mockService->shouldReceive('checkPaymentStatus')
            ->andThrow(new \Exception('API Error'));

        $job = new CheckPendingJekoPayments(5);
        
        // Should not throw - handles exception internally
        $job->handle($mockService);

        $this->assertTrue(true);
    }

    /** @test */
    public function it_processes_multiple_pending_payments()
    {
        // Create additional pending payments
        JekoPayment::factory()->count(3)->create([
            'payable_type' => 'App\Models\Order',
            'payable_id' => $this->order->id,
            'status' => 'pending',
            'initiated_at' => Carbon::now()->subMinutes(10),
        ]);

        $payment = Mockery::mock(JekoPayment::class)->makePartial();
        $payment->shouldReceive('isSuccess')->andReturn(false);
        $payment->shouldReceive('isFailed')->andReturn(true);

        $mockService = Mockery::mock(JekoPaymentService::class);
        $mockService->shouldReceive('checkPaymentStatus')
            ->times(4) // 1 original + 3 new
            ->andReturn($payment);

        $job = new CheckPendingJekoPayments(5);
        $job->handle($mockService);

        $this->assertTrue(true);
    }
}
