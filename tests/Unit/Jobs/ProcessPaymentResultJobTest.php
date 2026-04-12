<?php

namespace Tests\Unit\Jobs;

use App\Jobs\ProcessPaymentResultJob;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Tests\TestCase;

class ProcessPaymentResultJobTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_can_be_instantiated(): void
    {
        $job = new ProcessPaymentResultJob(1);
        $this->assertInstanceOf(ProcessPaymentResultJob::class, $job);
    }

    public function test_it_has_correct_tries(): void
    {
        $job = new ProcessPaymentResultJob(1);
        $this->assertEquals(5, $job->tries);
    }

    public function test_it_has_correct_timeout(): void
    {
        $job = new ProcessPaymentResultJob(1);
        $this->assertEquals(60, $job->timeout);
    }

    public function test_it_has_correct_max_exceptions(): void
    {
        $job = new ProcessPaymentResultJob(1);
        $this->assertEquals(3, $job->maxExceptions);
    }

    public function test_it_has_backoff_array(): void
    {
        $job = new ProcessPaymentResultJob(1);
        $this->assertIsArray($job->backoff);
        $this->assertEquals([5, 30, 60, 300, 600], $job->backoff);
    }

    public function test_middleware_returns_without_overlapping(): void
    {
        $job = new ProcessPaymentResultJob(42);
        $middleware = $job->middleware();

        $this->assertIsArray($middleware);
        $this->assertNotEmpty($middleware);
        $this->assertInstanceOf(WithoutOverlapping::class, $middleware[0]);
    }

    public function test_handle_skips_when_payment_not_found(): void
    {
        \Illuminate\Support\Facades\Log::shouldReceive('warning')
            ->once()
            ->withArgs(function ($msg) {
                return str_contains($msg, 'payment not found');
            });

        $job = new ProcessPaymentResultJob(999999);
        $job->handle();
    }

    public function test_failed_logs_critical(): void
    {
        \Illuminate\Support\Facades\Log::shouldReceive('critical')
            ->once()
            ->withArgs(function ($msg) {
                return str_contains($msg, 'FAILED');
            });

        $job = new ProcessPaymentResultJob(1);
        $job->failed(new \Exception('Test failure'));
    }
}
