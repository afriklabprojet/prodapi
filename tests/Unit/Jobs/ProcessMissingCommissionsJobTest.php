<?php

namespace Tests\Unit\Jobs;

use App\Jobs\ProcessMissingCommissionsJob;
use App\Models\Order;
use App\Services\CommissionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class ProcessMissingCommissionsJobTest extends TestCase
{
    use RefreshDatabase;

    public function test_job_can_be_instantiated(): void
    {
        $job = new ProcessMissingCommissionsJob();
        $this->assertInstanceOf(ProcessMissingCommissionsJob::class, $job);
        $this->assertEquals(2, $job->tries);
        $this->assertEquals(180, $job->timeout);
    }

    public function test_job_has_middleware(): void
    {
        $job = new ProcessMissingCommissionsJob();
        $middleware = $job->middleware();
        $this->assertNotEmpty($middleware);
    }

    public function test_handle_does_nothing_when_no_missing_commissions(): void
    {
        $service = $this->createMock(CommissionService::class);
        $service->expects($this->never())->method('calculateAndDistribute');

        $job = new ProcessMissingCommissionsJob();
        $job->handle($service);
    }

    public function test_failed_logs_error(): void
    {
        Log::shouldReceive('error')->once()->with('ProcessMissingCommissionsJob failed', \Mockery::type('array'));

        $job = new ProcessMissingCommissionsJob();
        $job->failed(new \RuntimeException('Test error'));
    }
}
