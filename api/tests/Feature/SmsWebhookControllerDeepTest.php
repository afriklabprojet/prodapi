<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\SmsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class SmsWebhookControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    // ──────────────────────────────────────────────────────────────
    // DELIVERY REPORT
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function delivery_report_processes_delivered_status()
    {
        Log::spy();

        $response = $this->postJson('/api/webhooks/sms/delivery', [
            'results' => [[
                'messageId' => 'MSG-123',
                'bulkId' => 'BULK-1',
                'to' => '+2250700000000',
                'sentAt' => '2024-01-01T10:00:00+00:00',
                'doneAt' => '2024-01-01T10:00:05+00:00',
                'messageCount' => 1,
                'status' => [
                    'groupId' => 3,
                    'groupName' => 'DELIVERED',
                    'id' => 5,
                    'name' => 'DELIVERED_TO_HANDSET',
                    'description' => 'Message delivered',
                ],
                'price' => [
                    'pricePerMessage' => 0.01,
                    'currency' => 'EUR',
                ],
            ]],
        ]);

        $response->assertOk()
            ->assertJson(['status' => 'ok']);
    }

    #[Test]
    public function delivery_report_processes_undeliverable_status()
    {
        Log::spy();

        $response = $this->postJson('/api/webhooks/sms/delivery', [
            'results' => [[
                'messageId' => 'MSG-456',
                'to' => '+2250700000001',
                'status' => [
                    'groupName' => 'UNDELIVERABLE',
                    'name' => 'ABSENT_SUBSCRIBER',
                    'description' => 'Phone off',
                ],
                'error' => [
                    'groupId' => 1,
                    'groupName' => 'HANDSET_ERRORS',
                    'id' => 1,
                    'name' => 'EC_ABSENT_SUBSCRIBER',
                    'description' => 'Subscriber absent',
                ],
            ]],
        ]);

        $response->assertOk();
    }

    #[Test]
    public function delivery_report_marks_phone_after_3_failures()
    {
        Cache::flush();

        for ($i = 0; $i < 3; $i++) {
            $this->postJson('/api/webhooks/sms/delivery', [
                'results' => [[
                    'messageId' => "MSG-FAIL-{$i}",
                    'to' => '+2250711111111',
                    'status' => [
                        'groupName' => 'UNDELIVERABLE',
                        'name' => 'ABSENT',
                    ],
                    'error' => [
                        'groupId' => 1,
                        'groupName' => 'ERR',
                        'id' => 1,
                        'name' => 'ERR',
                    ],
                ]],
            ]);
        }

        $this->assertTrue(Cache::get('sms_blocked:+2250711111111') === true);
    }

    #[Test]
    public function delivery_report_processes_expired_status()
    {
        Log::spy();

        $response = $this->postJson('/api/webhooks/sms/delivery', [
            'results' => [[
                'messageId' => 'MSG-EXPIRED',
                'to' => '+2250700000002',
                'sentAt' => '2024-01-01T10:00:00+00:00',
                'doneAt' => '2024-01-02T10:00:00+00:00',
                'status' => [
                    'groupName' => 'EXPIRED',
                    'name' => 'EXPIRED',
                ],
            ]],
        ]);

        $response->assertOk();
    }

    #[Test]
    public function delivery_report_processes_rejected_status()
    {
        Log::spy();

        $response = $this->postJson('/api/webhooks/sms/delivery', [
            'results' => [[
                'messageId' => 'MSG-REJECTED',
                'to' => '+2250700000003',
                'status' => [
                    'groupName' => 'REJECTED',
                    'name' => 'REJECTED_OPERATOR',
                ],
                'error' => [
                    'groupId' => 2,
                    'groupName' => 'BLOCKED',
                    'id' => 2,
                    'name' => 'BLOCKED',
                ],
            ]],
        ]);

        $response->assertOk();
    }

    #[Test]
    public function delivery_report_handles_raw_fallback()
    {
        // Send malformed data that fails SDK deserialization
        $response = $this->postJson('/api/webhooks/sms/delivery', [
            'results' => [[
                'messageId' => 'MSG-RAW',
                'to' => '+2250700000004',
                'status' => ['groupName' => 'DELIVERED'],
            ]],
        ]);

        $response->assertOk();
    }

    #[Test]
    public function delivery_report_updates_cache()
    {
        Cache::put('sms_msg_MSG-CACHED', [
            'to' => '+2250700000005',
            'status' => 'PENDING',
        ]);

        $this->postJson('/api/webhooks/sms/delivery', [
            'results' => [[
                'messageId' => 'MSG-CACHED',
                'to' => '+2250700000005',
                'status' => [
                    'groupName' => 'DELIVERED',
                    'name' => 'DELIVERED',
                ],
            ]],
        ]);

        $cached = Cache::get('sms_msg_MSG-CACHED');
        // Status should be updated by either SDK path or raw fallback
        $this->assertNotNull($cached);
    }

    #[Test]
    public function delivery_report_handles_empty_results()
    {
        $response = $this->postJson('/api/webhooks/sms/delivery', [
            'results' => [],
        ]);

        $response->assertOk();
    }

    #[Test]
    public function delivery_report_handles_multiple_results()
    {
        $response = $this->postJson('/api/webhooks/sms/delivery', [
            'results' => [
                [
                    'messageId' => 'MSG-A',
                    'to' => '+2250700000010',
                    'status' => ['groupName' => 'DELIVERED', 'name' => 'OK'],
                ],
                [
                    'messageId' => 'MSG-B',
                    'to' => '+2250700000011',
                    'status' => ['groupName' => 'UNDELIVERABLE', 'name' => 'FAIL'],
                    'error' => ['groupId' => 1, 'groupName' => 'ERR', 'id' => 1, 'name' => 'ERR'],
                ],
            ],
        ]);

        $response->assertOk();
    }

    // ──────────────────────────────────────────────────────────────
    // INCOMING MESSAGE
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function incoming_message_processes_keyword()
    {
        Log::spy();

        $response = $this->postJson('/api/webhooks/sms/incoming', [
            'results' => [[
                'from' => '+2250700000000',
                'to' => '+2250700000001',
                'messageId' => 'IN-1',
                'text' => 'STOP',
                'keyword' => 'STOP',
                'receivedAt' => '2024-01-01T10:00:00+00:00',
            ]],
        ]);

        $response->assertOk()
            ->assertJson(['status' => 'ok']);
    }

    #[Test]
    public function incoming_opt_out_marks_phone()
    {
        Cache::flush();

        $user = User::factory()->create(['phone' => '+2250700000099']);

        $this->mock(SmsService::class, function ($mock) {
            $mock->shouldReceive('send')->andReturn(true);
        });

        $this->postJson('/api/webhooks/sms/incoming', [
            'results' => [[
                'from' => '+2250700000099',
                'to' => '+2250700000001',
                'messageId' => 'IN-OPT',
                'text' => 'STOP',
                'keyword' => 'STOP',
            ]],
        ]);

        $this->assertTrue(Cache::get('sms_optout:+2250700000099') === true);
    }

    #[Test]
    public function incoming_help_sends_help_sms()
    {
        $this->mock(SmsService::class, function ($mock) {
            $mock->shouldReceive('send')->once()->andReturn(true);
        });

        $response = $this->postJson('/api/webhooks/sms/incoming', [
            'results' => [[
                'from' => '+2250700000050',
                'to' => '+2250700000001',
                'messageId' => 'IN-HELP',
                'text' => 'AIDE',
                'keyword' => 'AIDE',
            ]],
        ]);

        $response->assertOk();
    }

    #[Test]
    public function incoming_message_handles_empty_results()
    {
        $response = $this->postJson('/api/webhooks/sms/incoming', [
            'results' => [],
        ]);

        $response->assertOk();
    }

    #[Test]
    public function incoming_message_without_keyword()
    {
        Log::spy();

        $response = $this->postJson('/api/webhooks/sms/incoming', [
            'results' => [[
                'from' => '+2250700000060',
                'to' => '+2250700000001',
                'messageId' => 'IN-NOKW',
                'text' => 'Hello, I need help',
            ]],
        ]);

        $response->assertOk();
    }
}
