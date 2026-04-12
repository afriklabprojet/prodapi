<?php

namespace Tests\Unit\Jobs;

use App\Jobs\CleanupOldDataJob;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class CleanupOldDataJobTest extends TestCase
{
    use RefreshDatabase;

    public function test_job_can_be_instantiated(): void
    {
        $job = new CleanupOldDataJob();
        $this->assertInstanceOf(CleanupOldDataJob::class, $job);
        $this->assertEquals(2, $job->tries);
        $this->assertEquals(300, $job->timeout);
    }

    public function test_job_has_middleware(): void
    {
        $job = new CleanupOldDataJob();
        $middleware = $job->middleware();
        $this->assertNotEmpty($middleware);
    }

    public function test_handle_cleans_old_notifications(): void
    {
        // Insert an old read notification
        DB::table('notifications')->insert([
            'id' => \Illuminate\Support\Str::uuid()->toString(),
            'type' => 'App\\Notifications\\Test',
            'notifiable_type' => 'App\\Models\\User',
            'notifiable_id' => 1,
            'data' => json_encode(['test' => true]),
            'read_at' => now()->subDays(100),
            'created_at' => now()->subDays(100),
            'updated_at' => now()->subDays(100),
        ]);

        // Insert a recent read notification (should not be deleted)
        DB::table('notifications')->insert([
            'id' => \Illuminate\Support\Str::uuid()->toString(),
            'type' => 'App\\Notifications\\Test',
            'notifiable_type' => 'App\\Models\\User',
            'notifiable_id' => 1,
            'data' => json_encode(['test' => true]),
            'read_at' => now()->subDays(10),
            'created_at' => now()->subDays(10),
            'updated_at' => now()->subDays(10),
        ]);

        $job = new CleanupOldDataJob();
        $job->handle();

        $this->assertEquals(1, DB::table('notifications')->count());
    }

    public function test_failed_logs_error(): void
    {
        Log::shouldReceive('error')->once()->with('CleanupOldDataJob failed', \Mockery::type('array'));

        $job = new CleanupOldDataJob();
        $job->failed(new \RuntimeException('Test error'));
    }
}
