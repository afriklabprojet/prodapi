<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class WhatsAppWebhookControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    // ──────────────────────────────────────────────────────────────
    // DELIVERY REPORT
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function delivery_report_handles_delivered()
    {
        Log::spy();

        $response = $this->postJson('/api/webhooks/whatsapp/delivery', [
            'results' => [[
                'messageId' => 'WA-123',
                'to' => '+2250700000000',
                'sentAt' => '2024-01-01T10:00:00+00:00',
                'doneAt' => '2024-01-01T10:00:05+00:00',
                'channel' => 'WHATSAPP',
                'status' => [
                    'groupName' => 'DELIVERED',
                    'name' => 'DELIVERED',
                    'description' => 'Message delivered',
                ],
            ]],
        ]);

        $response->assertOk()
            ->assertJson(['status' => 'ok']);
    }

    #[Test]
    public function delivery_report_handles_seen()
    {
        Log::spy();

        $response = $this->postJson('/api/webhooks/whatsapp/delivery', [
            'results' => [[
                'messageId' => 'WA-SEEN',
                'to' => '+2250700000001',
                'status' => [
                    'groupName' => 'SEEN',
                    'name' => 'SEEN',
                ],
            ]],
        ]);

        $response->assertOk();
    }

    #[Test]
    public function delivery_report_handles_failed()
    {
        Log::spy();

        $response = $this->postJson('/api/webhooks/whatsapp/delivery', [
            'results' => [[
                'messageId' => 'WA-FAIL',
                'to' => '+2250700000002',
                'status' => [
                    'groupName' => 'FAILED',
                    'name' => 'FAILED',
                ],
                'error' => [
                    'groupName' => 'PROVIDER_ERROR',
                    'name' => 'DELIVERY_FAILED',
                ],
            ]],
        ]);

        $response->assertOk();
    }

    #[Test]
    public function delivery_report_handles_rejected()
    {
        Log::spy();

        $response = $this->postJson('/api/webhooks/whatsapp/delivery', [
            'results' => [[
                'messageId' => 'WA-REJ',
                'to' => '+2250700000003',
                'status' => [
                    'groupName' => 'REJECTED',
                    'name' => 'REJECTED',
                ],
            ]],
        ]);

        $response->assertOk();
    }

    #[Test]
    public function delivery_report_handles_expired()
    {
        Log::spy();

        $response = $this->postJson('/api/webhooks/whatsapp/delivery', [
            'results' => [[
                'messageId' => 'WA-EXP',
                'to' => '+2250700000004',
                'status' => [
                    'groupName' => 'EXPIRED',
                    'name' => 'EXPIRED',
                ],
            ]],
        ]);

        $response->assertOk();
    }

    #[Test]
    public function delivery_report_handles_empty_results()
    {
        $response = $this->postJson('/api/webhooks/whatsapp/delivery', [
            'results' => [],
        ]);

        $response->assertOk();
    }

    #[Test]
    public function delivery_report_handles_multiple_results()
    {
        Log::spy();

        $response = $this->postJson('/api/webhooks/whatsapp/delivery', [
            'results' => [
                [
                    'messageId' => 'WA-A',
                    'to' => '+2250700000010',
                    'status' => ['groupName' => 'DELIVERED', 'name' => 'OK'],
                ],
                [
                    'messageId' => 'WA-B',
                    'to' => '+2250700000011',
                    'status' => ['groupName' => 'SEEN', 'name' => 'SEEN'],
                ],
            ],
        ]);

        $response->assertOk();
    }

    // ──────────────────────────────────────────────────────────────
    // INCOMING MESSAGE
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function incoming_message_handles_order_keyword()
    {
        Log::spy();

        $response = $this->postJson('/api/webhooks/whatsapp/incoming', [
            'results' => [[
                'from' => '+2250700000000',
                'to' => '+2250700000001',
                'messageId' => 'IN-WA-1',
                'message' => ['text' => 'COMMANDE'],
                'receivedAt' => '2024-01-01T10:00:00+00:00',
            ]],
        ]);

        $response->assertOk()
            ->assertJson(['status' => 'ok']);
    }

    #[Test]
    public function incoming_message_handles_stop_keyword()
    {
        Log::spy();
        Notification::fake();

        $response = $this->postJson('/api/webhooks/whatsapp/incoming', [
            'results' => [[
                'from' => '+2250700000020',
                'to' => '+2250700000001',
                'messageId' => 'IN-WA-STOP',
                'message' => ['text' => 'STOP'],
            ]],
        ]);

        $response->assertOk();
    }

    #[Test]
    public function incoming_message_handles_help_keyword()
    {
        Log::spy();

        $response = $this->postJson('/api/webhooks/whatsapp/incoming', [
            'results' => [[
                'from' => '+2250700000030',
                'to' => '+2250700000001',
                'messageId' => 'IN-WA-HELP',
                'message' => ['text' => 'AIDE'],
            ]],
        ]);

        $response->assertOk();
    }

    #[Test]
    public function incoming_message_handles_unknown_text()
    {
        Log::spy();
        Notification::fake();

        $response = $this->postJson('/api/webhooks/whatsapp/incoming', [
            'results' => [[
                'from' => '+2250700000040',
                'to' => '+2250700000001',
                'messageId' => 'IN-WA-UNK',
                'message' => ['text' => 'Bonjour, je veux acheter du paracétamol'],
            ]],
        ]);

        $response->assertOk();
    }

    #[Test]
    public function incoming_message_handles_empty_results()
    {
        $response = $this->postJson('/api/webhooks/whatsapp/incoming', [
            'results' => [],
        ]);

        $response->assertOk();
    }
}
