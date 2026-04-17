<?php

namespace Tests\Unit\Jobs;

use App\Jobs\DailyAdminDigestJob;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class DailyAdminDigestJobTest extends TestCase
{
    use RefreshDatabase;

    public function test_job_can_be_instantiated(): void
    {
        $job = new DailyAdminDigestJob();
        $this->assertInstanceOf(DailyAdminDigestJob::class, $job);
        $this->assertEquals(2, $job->tries);
        $this->assertEquals(120, $job->timeout);
    }

    public function test_job_has_middleware(): void
    {
        $job = new DailyAdminDigestJob();
        $middleware = $job->middleware();
        $this->assertNotEmpty($middleware);
    }

    public function test_handle_sends_digest_email(): void
    {
        Mail::fake();

        $job = new DailyAdminDigestJob();
        $job->handle();

        Mail::assertSent(\App\Mail\AdminAlertMail::class);
    }

    public function test_handle_continues_when_email_fails(): void
    {
        Mail::shouldReceive('to->send')->once()->andThrow(new \Exception('SMTP error'));
        Log::shouldReceive('info')->atLeast()->once();
        Log::shouldReceive('warning')->once();

        $job = new DailyAdminDigestJob();
        $job->handle();
    }

    public function test_failed_logs_error(): void
    {
        Log::shouldReceive('error')->once()->with('DailyAdminDigestJob failed', \Mockery::type('array'));

        $job = new DailyAdminDigestJob();
        $job->failed(new \RuntimeException('Test error'));
    }
}
