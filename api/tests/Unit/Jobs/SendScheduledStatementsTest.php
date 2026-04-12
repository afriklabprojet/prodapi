<?php

namespace Tests\Unit\Jobs;

use App\Jobs\SendScheduledStatements;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class SendScheduledStatementsTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_can_be_instantiated(): void
    {
        $job = new SendScheduledStatements();
        $this->assertInstanceOf(SendScheduledStatements::class, $job);
    }

    public function test_it_has_correct_tries(): void
    {
        $job = new SendScheduledStatements();
        $this->assertEquals(3, $job->tries);
    }

    public function test_it_has_correct_timeout(): void
    {
        $job = new SendScheduledStatements();
        $this->assertEquals(300, $job->timeout);
    }

    public function test_it_has_correct_backoff(): void
    {
        $job = new SendScheduledStatements();
        $this->assertEquals(60, $job->backoff);
    }

    public function test_handle_logs_start_and_end(): void
    {
        Log::shouldReceive('info')
            ->withArgs(fn($msg) => str_contains($msg, 'Début'))
            ->once();
        
        Log::shouldReceive('info')
            ->withArgs(fn($msg) => str_contains($msg, '0 relevés'))
            ->once();

        Log::shouldReceive('info')
            ->withArgs(fn($msg) => str_contains($msg, 'Terminé'))
            ->once();

        $job = new SendScheduledStatements();
        $job->handle();
    }
}
