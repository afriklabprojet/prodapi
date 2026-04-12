<?php

namespace Tests\Unit\Jobs;

use App\Jobs\ProcessJekoWebhookJob;
use App\Services\JekoPaymentService;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class ProcessJekoWebhookJobDeepTest extends TestCase
{
    // ─── handle(): successful webhook processing ───

    public function test_handle_calls_jeko_service_with_payload_and_signature(): void
    {
        $payload = ['event' => 'payment.success', 'id' => 'txn-123'];
        $signature = 'valid-hmac-sig';
        $webhookId = 'wh-success-1';

        $service = \Mockery::mock(JekoPaymentService::class);
        $service->shouldReceive('handleWebhook')
            ->once()
            ->with($payload, $signature)
            ->andReturn(true);

        Log::shouldReceive('info')
            ->atLeast()
            ->once()
            ->withArgs(fn($msg) => str_contains($msg, 'start') || str_contains($msg, 'complete'));

        $job = new ProcessJekoWebhookJob($payload, $signature, $webhookId);
        $job->handle($service);
    }

    // ─── handle(): webhook returns false ───

    public function test_handle_logs_warning_when_webhook_returns_false(): void
    {
        $payload = ['event' => 'payment.failed'];
        $signature = 'sig';
        $webhookId = 'wh-fail-1';

        $service = \Mockery::mock(JekoPaymentService::class);
        $service->shouldReceive('handleWebhook')
            ->once()
            ->andReturn(false);

        Log::shouldReceive('info')->atLeast()->once();
        Log::shouldReceive('warning')
            ->once()
            ->withArgs(fn($msg) => str_contains($msg, 'returned false'));

        $job = new ProcessJekoWebhookJob($payload, $signature, $webhookId);
        $job->handle($service);
    }

    // ─── handle(): logs attempt number ───

    public function test_handle_logs_start_with_webhook_id_and_attempt(): void
    {
        $webhookId = 'wh-attempt-test';

        $service = \Mockery::mock(JekoPaymentService::class);
        $service->shouldReceive('handleWebhook')->once()->andReturn(true);

        Log::shouldReceive('info')
            ->atLeast()
            ->once()
            ->withArgs(function ($msg, $ctx = []) use ($webhookId) {
                if (str_contains($msg, 'start')) {
                    return ($ctx['webhook_id'] ?? '') === $webhookId;
                }
                return true;
            });

        $job = new ProcessJekoWebhookJob(['event' => 'test'], 'sig', $webhookId);
        $job->handle($service);
    }

    // ─── handle(): logs completion with result ───

    public function test_handle_logs_complete_with_result(): void
    {
        $webhookId = 'wh-complete-test';

        $service = \Mockery::mock(JekoPaymentService::class);
        $service->shouldReceive('handleWebhook')->once()->andReturn(true);

        Log::shouldReceive('info')
            ->atLeast()
            ->once()
            ->withArgs(function ($msg, $ctx = []) {
                if (str_contains($msg, 'complete')) {
                    return isset($ctx['result']) && $ctx['result'] === true;
                }
                return true;
            });

        $job = new ProcessJekoWebhookJob(['event' => 'test'], 'sig', $webhookId);
        $job->handle($service);
    }

    // ─── failed() ───

    public function test_failed_logs_critical_with_webhook_details(): void
    {
        Log::shouldReceive('critical')
            ->once()
            ->withArgs(function ($msg, $ctx) {
                return str_contains($msg, 'FAILED permanently')
                    && $ctx['webhook_id'] === 'wh-crash'
                    && $ctx['payload_keys'] === ['event', 'amount']
                    && isset($ctx['error'])
                    && isset($ctx['trace']);
            });

        $job = new ProcessJekoWebhookJob(
            ['event' => 'payment.error', 'amount' => 5000],
            'sig',
            'wh-crash'
        );
        $job->failed(new \RuntimeException('Service unavailable'));
    }

    // ─── uniqueId() ───

    public function test_unique_id_returns_webhook_id(): void
    {
        $job = new ProcessJekoWebhookJob([], 'sig', 'wh-unique-123');
        $this->assertEquals('wh-unique-123', $job->uniqueId());
    }

    // ─── middleware() ───

    public function test_middleware_uses_webhook_id_for_overlapping(): void
    {
        $job = new ProcessJekoWebhookJob([], 'sig', 'wh-overlap-test');
        $middleware = $job->middleware();

        $this->assertIsArray($middleware);
        $this->assertNotEmpty($middleware);
        $this->assertInstanceOf(WithoutOverlapping::class, $middleware[0]);
    }

    // ─── Constructor properties ───

    public function test_job_properties_are_correct(): void
    {
        $job = new ProcessJekoWebhookJob([], 'sig', 'wh-1');

        $this->assertEquals(5, $job->tries);
        $this->assertEquals([5, 15, 60, 300, 900], $job->backoff);
        $this->assertEquals(60, $job->timeout);
        $this->assertEquals(3, $job->maxExceptions);
    }

    // ─── handle(): service throws exception ───

    public function test_handle_propagates_service_exceptions(): void
    {
        $service = \Mockery::mock(JekoPaymentService::class);
        $service->shouldReceive('handleWebhook')
            ->once()
            ->andThrow(new \RuntimeException('External API error'));

        Log::shouldReceive('info')->atLeast()->once();

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('External API error');

        $job = new ProcessJekoWebhookJob(['event' => 'test'], 'sig', 'wh-throw');
        $job->handle($service);
    }

    // ─── Payload preserved in job ───

    public function test_payload_keys_available_in_failed(): void
    {
        $payload = ['event' => 'payment.success', 'id' => '123', 'amount' => ['amount' => '5000']];
        
        Log::shouldReceive('critical')
            ->once()
            ->withArgs(function ($msg, $ctx) {
                return count($ctx['payload_keys']) === 3
                    && in_array('event', $ctx['payload_keys'])
                    && in_array('id', $ctx['payload_keys'])
                    && in_array('amount', $ctx['payload_keys']);
            });

        $job = new ProcessJekoWebhookJob($payload, 'sig', 'wh-keys');
        $job->failed(new \Exception('Test'));
    }
}
