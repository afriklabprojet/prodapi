<?php

namespace Tests\Unit\Services;

use App\Services\NotificationSettingsService;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class NotificationSettingsServiceTest extends TestCase
{
    private NotificationSettingsService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new NotificationSettingsService();
    }

    public function test_get_fcm_config_returns_complete_structure(): void
    {
        Cache::flush();
        $config = NotificationSettingsService::getFcmConfig('new_order');

        $this->assertArrayHasKey('data', $config);
        $this->assertArrayHasKey('android', $config);
        $this->assertArrayHasKey('apns', $config);
        $this->assertEquals('new_order', $config['data']['notification_type']);
        $this->assertEquals('high', $config['android']['priority']);
    }

    public function test_get_fcm_config_assigns_correct_sounds(): void
    {
        Cache::flush();

        $orderConfig = NotificationSettingsService::getFcmConfig('new_order');
        $this->assertEquals('order_received', $orderConfig['data']['sound']);

        $deliveryConfig = NotificationSettingsService::getFcmConfig('delivery_assigned');
        $this->assertEquals('notification_new_order', $deliveryConfig['data']['sound']);

        $chatConfig = NotificationSettingsService::getFcmConfig('chat_message');
        $this->assertEquals('notification_chat', $chatConfig['data']['sound']);

        $defaultConfig = NotificationSettingsService::getFcmConfig('unknown_type');
        $this->assertEquals('default', $defaultConfig['data']['sound']);
    }

    public function test_get_fcm_config_assigns_correct_channels(): void
    {
        Cache::flush();

        $orderConfig = NotificationSettingsService::getFcmConfig('new_order');
        $this->assertEquals('orders_channel', $orderConfig['android']['notification']['channel_id']);

        $deliveryConfig = NotificationSettingsService::getFcmConfig('delivery_assigned');
        $this->assertEquals('new_delivery', $deliveryConfig['android']['notification']['channel_id']);

        $payoutConfig = NotificationSettingsService::getFcmConfig('payout_completed');
        $this->assertEquals('payments_channel', $payoutConfig['android']['notification']['channel_id']);
    }

    public function test_get_config_returns_simplified_structure(): void
    {
        Cache::flush();
        $config = $this->service->getConfig('new_order');

        $this->assertArrayHasKey('sound', $config);
        $this->assertArrayHasKey('vibration', $config);
        $this->assertArrayHasKey('priority', $config);
        $this->assertArrayHasKey('notification_type', $config);
        $this->assertTrue($config['vibration']);
        $this->assertEquals('high', $config['priority']);
    }

    public function test_get_available_sounds_returns_list(): void
    {
        $sounds = $this->service->getAvailableSounds();

        $this->assertIsArray($sounds);
        $this->assertNotEmpty($sounds);

        $ids = array_column($sounds, 'id');
        $this->assertContains('default', $ids);
        $this->assertContains('order_received', $ids);
        $this->assertContains('none', $ids);

        // Each sound has required keys
        foreach ($sounds as $sound) {
            $this->assertArrayHasKey('id', $sound);
            $this->assertArrayHasKey('label', $sound);
            $this->assertArrayHasKey('file', $sound);
        }
    }

    public function test_clear_cache_specific_type(): void
    {
        Cache::flush();
        // Populate cache
        NotificationSettingsService::getFcmConfig('new_order');
        $this->assertTrue(Cache::has('fcm_config_new_order'));

        NotificationSettingsService::clearCache('new_order');
        $this->assertFalse(Cache::has('fcm_config_new_order'));
    }

    public function test_clear_cache_all_types(): void
    {
        Cache::flush();
        // Populate cache
        NotificationSettingsService::getFcmConfig('new_order');
        NotificationSettingsService::getFcmConfig('chat_message');

        NotificationSettingsService::clearCache();
        $this->assertFalse(Cache::has('fcm_config_new_order'));
        $this->assertFalse(Cache::has('fcm_config_chat_message'));
    }

    public function test_apns_sound_format_for_custom_sounds(): void
    {
        Cache::flush();
        $config = NotificationSettingsService::getFcmConfig('new_order');
        $apnsSound = $config['apns']['payload']['aps']['sound'];
        // Custom sound should have .caf extension
        $this->assertStringEndsWith('.caf', $apnsSound);
    }

    public function test_apns_sound_format_for_default_sound(): void
    {
        Cache::flush();
        $config = NotificationSettingsService::getFcmConfig('unknown_type');
        $apnsSound = $config['apns']['payload']['aps']['sound'];
        $this->assertEquals('default', $apnsSound);
    }
}
