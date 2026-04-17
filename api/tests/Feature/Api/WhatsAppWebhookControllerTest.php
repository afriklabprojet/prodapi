<?php

namespace Tests\Feature\Api;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class WhatsAppWebhookControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_delivery_report_accepts_valid_payload(): void
    {
        Log::shouldReceive('info')->zeroOrMoreTimes();
        Log::shouldReceive('error')->zeroOrMoreTimes();
        Log::shouldReceive('warning')->zeroOrMoreTimes();

        $response = $this->postJson('/api/webhooks/whatsapp/delivery', [
            'results' => [
                [
                    'messageId' => 'wa-msg-123',
                    'to' => '+2250700000000',
                    'status' => [
                        'groupId' => 3,
                        'groupName' => 'DELIVERED',
                    ],
                ],
            ],
        ]);

        $response->assertOk();
    }

    public function test_delivery_report_handles_empty_results(): void
    {
        Log::shouldReceive('info')->zeroOrMoreTimes();
        Log::shouldReceive('error')->zeroOrMoreTimes();
        Log::shouldReceive('warning')->zeroOrMoreTimes();

        $response = $this->postJson('/api/webhooks/whatsapp/delivery', [
            'results' => [],
        ]);

        $response->assertOk();
    }

    public function test_incoming_message_accepts_valid_payload(): void
    {
        Log::shouldReceive('info')->zeroOrMoreTimes();
        Log::shouldReceive('error')->zeroOrMoreTimes();
        Log::shouldReceive('warning')->zeroOrMoreTimes();

        $response = $this->postJson('/api/webhooks/whatsapp/incoming', [
            'results' => [
                [
                    'messageId' => 'wa-in-456',
                    'from' => '+2250700000000',
                    'to' => '+2250000000000',
                    'message' => [
                        'text' => 'Bonjour',
                    ],
                    'receivedAt' => '2024-01-01T12:00:00.000+0000',
                ],
            ],
        ]);

        $response->assertOk();
    }

    public function test_incoming_message_handles_empty_payload(): void
    {
        Log::shouldReceive('info')->zeroOrMoreTimes();
        Log::shouldReceive('error')->zeroOrMoreTimes();
        Log::shouldReceive('warning')->zeroOrMoreTimes();

        $response = $this->postJson('/api/webhooks/whatsapp/incoming', [
            'results' => [],
        ]);

        $response->assertOk();
    }
}
