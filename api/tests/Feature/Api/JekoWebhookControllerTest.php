<?php

namespace Tests\Feature\Api;

use App\Jobs\ProcessJekoWebhookJob;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class JekoWebhookControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_webhook_returns_200_and_dispatches_job(): void
    {
        Queue::fake();

        $payload = [
            'id' => 'webhook-123',
            'status' => 'SUCCESS',
            'apiTransactionableDetails' => [
                'id' => 'txn-456',
                'reference' => 'JEKO-REF-001',
            ],
        ];

        $response = $this->postJson('/api/webhooks/jeko', $payload);

        $response->assertOk()->assertJsonPath('status', 'ok');
        Queue::assertPushed(ProcessJekoWebhookJob::class);
    }

    public function test_duplicate_webhook_is_ignored(): void
    {
        Queue::fake();
        Cache::put('jeko_webhook_received:webhook-dup', true, 172800);

        $payload = [
            'id' => 'webhook-dup',
            'status' => 'SUCCESS',
            'apiTransactionableDetails' => ['reference' => 'JEKO-REF-002'],
        ];

        $response = $this->postJson('/api/webhooks/jeko', $payload);

        $response->assertOk()->assertJsonPath('duplicate', true);
    }

    public function test_webhook_health_check(): void
    {
        $response = $this->getJson('/api/webhooks/jeko/health');

        $response->assertOk()
            ->assertJsonPath('status', 'ok')
            ->assertJsonStructure(['status', 'timestamp']);
    }

    public function test_webhook_accepts_empty_payload(): void
    {
        Queue::fake();

        $response = $this->postJson('/api/webhooks/jeko', []);

        $response->assertOk();
    }
}
