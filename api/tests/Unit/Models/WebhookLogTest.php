<?php

namespace Tests\Unit\Models;

use App\Models\WebhookLog;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class WebhookLogTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_has_fillable_fields(): void
    {
        $model = new WebhookLog();
        $fillable = $model->getFillable();
        $this->assertContains('provider', $fillable);
        $this->assertContains('webhook_id', $fillable);
        $this->assertContains('event_type', $fillable);
        $this->assertContains('reference', $fillable);
        $this->assertContains('status', $fillable);
        $this->assertContains('payload', $fillable);
        $this->assertContains('ip_address', $fillable);
        $this->assertContains('processed', $fillable);
        $this->assertContains('error_message', $fillable);
        $this->assertContains('attempts', $fillable);
    }

    #[Test]
    public function it_casts_payload_as_array(): void
    {
        $model = new WebhookLog();
        $casts = $model->getCasts();
        $this->assertSame('array', $casts['payload']);
    }

    #[Test]
    public function it_casts_processed_as_boolean(): void
    {
        $model = new WebhookLog();
        $casts = $model->getCasts();
        $this->assertSame('boolean', $casts['processed']);
    }

    #[Test]
    public function it_casts_attempts_as_integer(): void
    {
        $model = new WebhookLog();
        $casts = $model->getCasts();
        $this->assertSame('integer', $casts['attempts']);
    }

    #[Test]
    public function it_can_be_created_in_database(): void
    {
        $log = WebhookLog::create([
            'provider' => 'jeko',
            'webhook_id' => 'WH123456',
            'event_type' => 'payment.success',
            'reference' => 'PAY-123',
            'status' => 'received',
            'payload' => ['amount' => 5000, 'currency' => 'XOF'],
            'ip_address' => '192.168.1.1',
            'processed' => false,
            'attempts' => 0,
        ]);

        $this->assertDatabaseHas('webhook_logs', [
            'provider' => 'jeko',
            'webhook_id' => 'WH123456',
        ]);
    }

    #[Test]
    public function it_stores_payload_as_json(): void
    {
        $payload = ['transaction_id' => 'TXN123', 'amount' => 10000];
        
        $log = WebhookLog::create([
            'provider' => 'jeko',
            'webhook_id' => 'WH789',
            'event_type' => 'payment.confirmed',
            'payload' => $payload,
            'processed' => false,
            'attempts' => 0,
        ]);

        $log->refresh();
        $this->assertEquals($payload, $log->payload);
    }

    #[Test]
    public function it_scopes_unprocessed_logs(): void
    {
        $unprocessed = WebhookLog::create([
            'provider' => 'jeko',
            'webhook_id' => 'WH001',
            'event_type' => 'payment.pending',
            'processed' => false,
            'attempts' => 0,
        ]);

        $processed = WebhookLog::create([
            'provider' => 'jeko',
            'webhook_id' => 'WH002',
            'event_type' => 'payment.success',
            'processed' => true,
            'attempts' => 1,
        ]);

        $unprocessedIds = WebhookLog::unprocessed()->pluck('id')->toArray();

        $this->assertContains($unprocessed->id, $unprocessedIds);
        $this->assertNotContains($processed->id, $unprocessedIds);
    }

    #[Test]
    public function it_scopes_by_provider(): void
    {
        $jekoLog = WebhookLog::create([
            'provider' => 'jeko',
            'webhook_id' => 'WH-JEKO',
            'event_type' => 'payment.success',
            'processed' => false,
            'attempts' => 0,
        ]);

        $otherLog = WebhookLog::create([
            'provider' => 'stripe',
            'webhook_id' => 'WH-STRIPE',
            'event_type' => 'charge.succeeded',
            'processed' => false,
            'attempts' => 0,
        ]);

        $jekoIds = WebhookLog::forProvider('jeko')->pluck('id')->toArray();

        $this->assertContains($jekoLog->id, $jekoIds);
        $this->assertNotContains($otherLog->id, $jekoIds);
    }

    #[Test]
    public function it_marks_as_processed(): void
    {
        $log = WebhookLog::create([
            'provider' => 'jeko',
            'webhook_id' => 'WH-MARK',
            'event_type' => 'payment.success',
            'processed' => false,
            'attempts' => 0,
        ]);

        $log->markProcessed();
        $log->refresh();

        $this->assertTrue($log->processed);
        $this->assertEquals(1, $log->attempts);
    }

    #[Test]
    public function it_increments_attempts_on_mark_processed(): void
    {
        $log = WebhookLog::create([
            'provider' => 'jeko',
            'webhook_id' => 'WH-INC',
            'event_type' => 'payment.success',
            'processed' => false,
            'attempts' => 2,
        ]);

        $log->markProcessed();
        $log->refresh();

        $this->assertEquals(3, $log->attempts);
    }

    #[Test]
    public function it_marks_as_failed_with_error(): void
    {
        $log = WebhookLog::create([
            'provider' => 'jeko',
            'webhook_id' => 'WH-FAIL',
            'event_type' => 'payment.failed',
            'processed' => false,
            'attempts' => 0,
        ]);

        $log->markFailed('Connection timeout');
        $log->refresh();

        $this->assertEquals('Connection timeout', $log->error_message);
        $this->assertEquals(1, $log->attempts);
        $this->assertFalse($log->processed);
    }

    #[Test]
    public function it_increments_attempts_on_mark_failed(): void
    {
        $log = WebhookLog::create([
            'provider' => 'jeko',
            'webhook_id' => 'WH-FAIL2',
            'event_type' => 'payment.error',
            'processed' => false,
            'attempts' => 1,
        ]);

        $log->markFailed('Server error');
        $log->refresh();

        $this->assertEquals(2, $log->attempts);
    }
}
