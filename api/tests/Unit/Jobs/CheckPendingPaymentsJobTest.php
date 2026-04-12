<?php

namespace Tests\Unit\Jobs;

use App\Jobs\CheckPendingPaymentsJob;
use App\Models\Customer;
use App\Models\JekoPayment;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use App\Services\JekoPaymentService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Queue;
use Mockery;
use Tests\TestCase;

class CheckPendingPaymentsJobTest extends TestCase
{
    use RefreshDatabase;

    protected Order $order;
    protected JekoPayment $payment;

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
            'payment_status' => 'unpaid',
            'total_amount' => 5000,
        ]);

        $this->payment = JekoPayment::factory()->create([
            'payable_type' => 'App\\Models\\Order',
            'payable_id' => $this->order->id,
            'amount_cents' => 500000,
            'status' => 'pending',
            'reference' => 'JEKO-PAY-TEST',
            'jeko_payment_request_id' => 'REQ-123',
            'initiated_at' => Carbon::now()->subMinutes(10),
        ]);
    }

    public function test_job_can_be_dispatched(): void
    {
        Queue::fake();

        CheckPendingPaymentsJob::dispatch();

        Queue::assertPushed(CheckPendingPaymentsJob::class);
    }

    public function test_job_has_correct_tries(): void
    {
        $job = new CheckPendingPaymentsJob();
        $this->assertEquals(3, $job->tries);
    }

    public function test_job_has_correct_timeout(): void
    {
        $job = new CheckPendingPaymentsJob();
        $this->assertEquals(120, $job->timeout);
    }

    public function test_job_has_backoff_strategy(): void
    {
        $job = new CheckPendingPaymentsJob();
        $this->assertIsArray($job->backoff);
        $this->assertNotEmpty($job->backoff);
    }

    public function test_job_has_without_overlapping_middleware(): void
    {
        $job = new CheckPendingPaymentsJob();
        $middleware = $job->middleware();
        $this->assertNotEmpty($middleware);
    }

    public function test_handle_skips_payment_without_request_id(): void
    {
        // Payment without jeko_payment_request_id should be skipped
        $this->payment->update(['jeko_payment_request_id' => null]);

        $mockService = Mockery::mock(JekoPaymentService::class);
        $mockService->shouldNotReceive('checkPaymentStatus');

        Log::shouldReceive('info')->zeroOrMoreTimes();

        $job = new CheckPendingPaymentsJob();
        $job->handle($mockService);

        $this->addToAssertionCount(1);
    }

    public function test_handle_skips_payments_too_recent(): void
    {
        // Payment created less than 2 minutes ago — should be skipped
        $this->payment->forceFill(['created_at' => Carbon::now()->subSeconds(30)])->saveQuietly();

        $mockService = Mockery::mock(JekoPaymentService::class);
        $mockService->shouldNotReceive('checkPaymentStatus');

        Log::shouldReceive('info')->zeroOrMoreTimes();

        $job = new CheckPendingPaymentsJob();
        $job->handle($mockService);

        $this->addToAssertionCount(1);
    }

    public function test_handle_auto_expires_payments_older_than_2_hours(): void
    {
        // Create an old payment older than 2h
        $oldPayment = JekoPayment::factory()->create([
            'payable_type' => 'App\\Models\\Order',
            'payable_id' => $this->order->id,
            'status' => 'pending',
            'reference' => 'JEKO-OLD',
            'jeko_payment_request_id' => 'REQ-OLD',
            'initiated_at' => Carbon::now()->subHours(3),
        ]);
        $oldPayment->forceFill(['created_at' => Carbon::now()->subHours(3)])->saveQuietly();

        $mockService = Mockery::mock(JekoPaymentService::class);
        $mockService->shouldReceive('checkPaymentStatus')->zeroOrMoreTimes();

        Log::shouldReceive('info')->zeroOrMoreTimes();
        Log::shouldReceive('warning')->zeroOrMoreTimes();

        $job = new CheckPendingPaymentsJob();
        $job->handle($mockService);

        $oldPayment->refresh();
        $this->assertEquals('expired', $oldPayment->status->value ?? $oldPayment->status);
    }

    public function test_handle_catches_exception_from_service(): void
    {
        // Ensure the payment is old enough to be picked up by the query (>2min, <2h)
        $this->payment->forceFill(['created_at' => Carbon::now()->subMinutes(5)])->saveQuietly();

        $mockService = Mockery::mock(JekoPaymentService::class);
        $mockService->shouldReceive('checkPaymentStatus')
            ->andThrow(new \RuntimeException('API unavailable'));

        Log::shouldReceive('warning')->once()->withArgs(function ($msg) {
            return str_contains($msg, 'CheckPendingPayments: check failed');
        });
        Log::shouldReceive('info')->zeroOrMoreTimes();

        $job = new CheckPendingPaymentsJob();
        $job->handle($mockService);

        // No exception propagated = pass
        $this->addToAssertionCount(1);
    }

    public function test_failed_logs_error(): void
    {
        Log::shouldReceive('error')->once()->withArgs(function ($msg) {
            return str_contains($msg, 'CheckPendingPaymentsJob failed');
        });

        $job = new CheckPendingPaymentsJob();
        $job->failed(new \RuntimeException('Test failure'));
    }
}
