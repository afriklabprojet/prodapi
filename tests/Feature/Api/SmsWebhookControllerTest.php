<?php

namespace Tests\Feature\Api;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class SmsWebhookControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_delivery_report_accepts_valid_payload(): void
    {
        Log::shouldReceive('info')->zeroOrMoreTimes();
        Log::shouldReceive('error')->zeroOrMoreTimes();
        Log::shouldReceive('warning')->zeroOrMoreTimes();

        $response = $this->postJson('/api/webhooks/sms/delivery', [
            'results' => [
                [
                    'bulkId' => 'bulk-123',
                    'messageId' => 'msg-456',
                    'to' => '+2250700000000',
                    'status' => [
                        'groupId' => 3,
                        'groupName' => 'DELIVERED',
                        'id' => 5,
                        'name' => 'DELIVERED_TO_HANDSET',
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

        $response = $this->postJson('/api/webhooks/sms/delivery', [
            'results' => [],
        ]);

        $response->assertOk();
    }

    public function test_incoming_message_accepts_valid_payload(): void
    {
        Log::shouldReceive('info')->zeroOrMoreTimes();
        Log::shouldReceive('error')->zeroOrMoreTimes();
        Log::shouldReceive('warning')->zeroOrMoreTimes();

        $response = $this->postJson('/api/webhooks/sms/incoming', [
            'results' => [
                [
                    'messageId' => 'msg-789',
                    'from' => '+2250700000000',
                    'to' => '+2250000000000',
                    'text' => 'STOP',
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

        $response = $this->postJson('/api/webhooks/sms/incoming', [
            'results' => [],
        ]);

        $response->assertOk();
    }
}
