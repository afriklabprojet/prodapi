<?php

namespace Tests\Unit\Jobs;

use App\Jobs\CourierActivityHealthCheckJob;
use App\Models\Courier;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class CourierActivityHealthCheckJobTest extends TestCase
{
    use RefreshDatabase;

    public function test_job_can_be_instantiated(): void
    {
        $job = new CourierActivityHealthCheckJob();
        $this->assertInstanceOf(CourierActivityHealthCheckJob::class, $job);
        $this->assertEquals(2, $job->tries);
        $this->assertEquals(120, $job->timeout);
    }

    public function test_job_has_middleware(): void
    {
        $job = new CourierActivityHealthCheckJob();
        $middleware = $job->middleware();
        $this->assertNotEmpty($middleware);
    }

    public function test_handle_forces_stale_couriers_offline(): void
    {
        Notification::fake();

        $user = User::factory()->create(['role' => 'courier']);
        $courier = Courier::create([
            'user_id' => $user->id,
            'status' => 'available',
            'last_location_update' => now()->subHours(3),
            'kyc_status' => 'verified',
            'name' => 'Test Courier',
        ]);

        $job = new CourierActivityHealthCheckJob();
        $job->handle();

        $courier->refresh();
        $this->assertEquals('offline', $courier->status);
    }

    public function test_handle_frees_busy_couriers_without_active_deliveries(): void
    {
        Notification::fake();

        $user = User::factory()->create(['role' => 'courier']);
        $courier = Courier::create([
            'user_id' => $user->id,
            'status' => 'busy',
            'kyc_status' => 'verified',
            'name' => 'Test Courier',
        ]);

        $job = new CourierActivityHealthCheckJob();
        $job->handle();

        $courier->refresh();
        $this->assertEquals('available', $courier->status);
    }

    public function test_failed_logs_error(): void
    {
        Log::shouldReceive('error')->once()->with('CourierActivityHealthCheckJob failed', \Mockery::type('array'));

        $job = new CourierActivityHealthCheckJob();
        $job->failed(new \RuntimeException('Test error'));
    }
}
