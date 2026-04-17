<?php

namespace Tests\Unit\Jobs;

use App\Jobs\ProcessJekoWebhookJob;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Tests\TestCase;

class ProcessJekoWebhookJobTest extends TestCase
{
    public function test_it_can_be_instantiated(): void
    {
        $job = new ProcessJekoWebhookJob(
            payload: ['event' => 'payment.success'],
            signature: 'test-sig',
            webhookId: 'webhook-123'
        );
        $this->assertInstanceOf(ProcessJekoWebhookJob::class, $job);
    }

    public function test_it_has_correct_tries(): void
    {
        $job = new ProcessJekoWebhookJob([], 'sig', 'wh-1');
        $this->assertEquals(5, $job->tries);
    }

    public function test_it_has_correct_timeout(): void
    {
        $job = new ProcessJekoWebhookJob([], 'sig', 'wh-1');
        $this->assertEquals(60, $job->timeout);
    }

    public function test_it_has_correct_max_exceptions(): void
    {
        $job = new ProcessJekoWebhookJob([], 'sig', 'wh-1');
        $this->assertEquals(3, $job->maxExceptions);
    }

    public function test_it_has_backoff_array(): void
    {
        $job = new ProcessJekoWebhookJob([], 'sig', 'wh-1');
        $this->assertEquals([5, 15, 60, 300, 900], $job->backoff);
    }

    public function test_middleware_returns_without_overlapping(): void
    {
        $job = new ProcessJekoWebhookJob([], 'sig', 'wh-42');
        $middleware = $job->middleware();

        $this->assertIsArray($middleware);
        $this->assertNotEmpty($middleware);
        $this->assertInstanceOf(WithoutOverlapping::class, $middleware[0]);
    }

    public function test_unique_id_returns_webhook_id(): void
    {
        $job = new ProcessJekoWebhookJob([], 'sig', 'wh-unique-test');
        $this->assertEquals('wh-unique-test', $job->uniqueId());
    }

    public function test_failed_logs_critical(): void
    {
        \Illuminate\Support\Facades\Log::shouldReceive('critical')
            ->once()
            ->withArgs(function ($msg) {
                return str_contains($msg, 'FAILED permanently');
            });

        $job = new ProcessJekoWebhookJob(
            ['event' => 'test'],
            'sig',
            'wh-failed'
        );
        $job->failed(new \Exception('Test failure'));
    }
}
