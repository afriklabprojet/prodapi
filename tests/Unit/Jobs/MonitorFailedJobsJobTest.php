<?php

namespace Tests\Unit\Jobs;

use App\Jobs\MonitorFailedJobsJob;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class MonitorFailedJobsJobTest extends TestCase
{
    use RefreshDatabase;

    public function test_job_can_be_instantiated(): void
    {
        $job = new MonitorFailedJobsJob();
        $this->assertInstanceOf(MonitorFailedJobsJob::class, $job);
        $this->assertEquals(1, $job->tries);
        $this->assertEquals(30, $job->timeout);
    }

    public function test_job_has_middleware(): void
    {
        $job = new MonitorFailedJobsJob();
        $middleware = $job->middleware();
        $this->assertNotEmpty($middleware);
    }

    public function test_handle_does_nothing_when_no_failed_jobs(): void
    {
        Mail::fake();
        Log::shouldReceive('warning')->never();

        $job = new MonitorFailedJobsJob();
        $job->handle();

        Mail::assertNothingSent();
    }

    public function test_handle_sends_alert_when_failed_jobs_exist(): void
    {
        Mail::fake();

        // Insert a recent failed job
        DB::table('failed_jobs')->insert([
            'uuid' => 'test-uuid-123',
            'connection' => 'database',
            'queue' => 'default',
            'payload' => json_encode(['displayName' => 'App\\Jobs\\TestJob']),
            'exception' => "RuntimeException: Test error\nat line 1",
            'failed_at' => now()->subMinutes(30),
        ]);

        Log::shouldReceive('warning')->once();
        Log::shouldReceive('info')->never();

        $job = new MonitorFailedJobsJob();
        $job->handle();

        Mail::assertSent(\App\Mail\AdminAlertMail::class);
    }
}
