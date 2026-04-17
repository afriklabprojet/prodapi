<?php

namespace Tests\Unit\Jobs;

use App\Jobs\ReconcileWalletBalancesJob;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class ReconcileWalletBalancesJobTest extends TestCase
{
    use RefreshDatabase;

    public function test_job_can_be_instantiated(): void
    {
        $job = new ReconcileWalletBalancesJob();
        $this->assertInstanceOf(ReconcileWalletBalancesJob::class, $job);
        $this->assertEquals(2, $job->tries);
        $this->assertEquals(300, $job->timeout);
    }

    public function test_job_has_middleware(): void
    {
        $job = new ReconcileWalletBalancesJob();
        $middleware = $job->middleware();
        $this->assertNotEmpty($middleware);
    }

    public function test_handle_completes_with_no_wallets(): void
    {
        Mail::fake();
        Log::shouldReceive('info')->atLeast()->once();

        $job = new ReconcileWalletBalancesJob();
        $job->handle();

        Mail::assertNothingSent();
    }

    public function test_failed_logs_error(): void
    {
        Log::shouldReceive('error')->once()->with('ReconcileWalletBalancesJob failed', \Mockery::type('array'));

        $job = new ReconcileWalletBalancesJob();
        $job->failed(new \RuntimeException('Test error'));
    }
}
