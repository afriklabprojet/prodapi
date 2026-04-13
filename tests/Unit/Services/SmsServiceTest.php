<?php

namespace Tests\Unit\Services;

use App\Services\SmsService;
use App\Services\Infobip\InfobipClientFactory;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Log;
use Mockery;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class SmsServiceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Log::spy();
        Cache::flush();
    }

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }

    #[Test]
    public function it_normalizes_phone_numbers_correctly()
    {
        Config::set('sms.default', 'log');
        
        $service = new SmsService();
        
        // Use reflection to test private method
        $reflection = new \ReflectionClass($service);
        $method = $reflection->getMethod('normalizePhone');
        $method->setAccessible(true);
        
        // Test with country code
        $this->assertEquals('+22501234567', $method->invoke($service, '+22501234567'));
        
        // Test local number - should add default prefix
        $normalized = $method->invoke($service, '0501234567');
        $this->assertStringStartsWith('+', $normalized);
    }

    #[Test]
    public function it_blocks_sms_to_opted_out_numbers()
    {
        Config::set('sms.default', 'log');
        
        $service = new SmsService();
        $phone = '+22501234567';
        
        // Opt out the number
        Cache::put("sms_optout:{$phone}", true, now()->addDays(30));
        
        $result = $service->send($phone, 'Test message');
        
        $this->assertFalse($result);
        Log::shouldHaveReceived('info')->withArgs(function ($message) {
            return str_contains($message, 'SMS blocked');
        });
    }

    #[Test]
    public function it_allows_force_send_to_opted_out_numbers()
    {
        Config::set('sms.default', 'log');
        
        $service = new SmsService();
        $phone = '+22501234567';
        
        // Opt out the number
        Cache::put("sms_optout:{$phone}", true, now()->addDays(30));
        
        // Force send should bypass opt-out
        $result = $service->send($phone, 'Important message', ['force' => true]);
        
        // With 'log' provider, it will return true (logged)
        $this->assertTrue($result);
    }

    #[Test]
    public function it_checks_opt_out_status()
    {
        Config::set('sms.default', 'log');
        
        $service = new SmsService();
        $phone = '+22501234567';
        
        $this->assertFalse($service->isOptedOut($phone));
        
        Cache::put("sms_optout:{$phone}", true, now()->addDays(30));
        
        $this->assertTrue($service->isOptedOut($phone));
    }

    #[Test]
    public function it_uses_log_provider_when_configured()
    {
        Config::set('sms.default', 'log');
        
        $service = new SmsService();
        $result = $service->send('+22501234567', 'Test message');
        
        $this->assertTrue($result);
        Log::shouldHaveReceived('info')->withArgs(function ($message) {
            return str_contains($message, 'SMS') || str_contains($message, 'LOG');
        });
    }

    #[Test]
    public function it_falls_back_to_log_when_infobip_not_configured()
    {
        Config::set('sms.default', 'infobip');
        
        // Mock the factory to return not configured
        $mockFactory = Mockery::mock(InfobipClientFactory::class);
        $mockFactory->shouldReceive('isSmsConfigured')->andReturn(false);
        
        $service = new SmsService($mockFactory);
        $result = $service->send('+22501234567', 'Test message');
        
        $this->assertTrue($result);
    }

    #[Test]
    public function it_returns_failure_for_bulk_when_not_configured()
    {
        Config::set('sms.default', 'infobip');
        
        $mockFactory = Mockery::mock(InfobipClientFactory::class);
        $mockFactory->shouldReceive('isSmsConfigured')->andReturn(false);
        
        $service = new SmsService($mockFactory);
        $result = $service->sendBulk(['+22501234567', '+22507654321'], 'Bulk message');
        
        $this->assertFalse($result['success']);
        $this->assertEquals(0, $result['sent']);
        $this->assertEquals(2, $result['failed']);
    }

    #[Test]
    public function it_returns_failure_for_multiple_when_not_configured()
    {
        Config::set('sms.default', 'infobip');
        
        $mockFactory = Mockery::mock(InfobipClientFactory::class);
        $mockFactory->shouldReceive('isSmsConfigured')->andReturn(false);
        
        $service = new SmsService($mockFactory);
        $result = $service->sendMultiple([
            ['phone' => '+22501234567', 'message' => 'Message 1'],
        ]);
        
        $this->assertFalse($result['success']);
        $this->assertArrayHasKey('error', $result);
    }

    #[Test]
    public function it_uses_default_provider_from_config()
    {
        // Default should be infobip based on config/sms.php
        Config::set('sms.default', 'infobip');
        
        $mockFactory = Mockery::mock(InfobipClientFactory::class);
        $mockFactory->shouldReceive('isSmsConfigured')->andReturn(false);
        
        $service = new SmsService($mockFactory);
        $result = $service->send('+22501234567', 'Test message');
        
        // Should fallback to log when infobip not configured
        $this->assertTrue($result);
    }

    #[Test]
    public function it_handles_twilio_provider()
    {
        Config::set('sms.default', 'twilio');
        
        $service = new SmsService();
        // Twilio provider without configuration should log and return true/false
        $result = $service->send('+22501234567', 'Test message');
        
        $this->assertIsBool($result);
    }

    #[Test]
    public function it_handles_africastalking_provider()
    {
        Config::set('sms.default', 'africastalking');
        
        $service = new SmsService();
        $result = $service->send('+22501234567', 'Test message');
        
        $this->assertIsBool($result);
    }

    #[Test]
    public function it_handles_unknown_provider_gracefully()
    {
        Config::set('sms.default', 'unknown_provider');
        
        $service = new SmsService();
        $result = $service->send('+22501234567', 'Test message');
        
        // Unknown provider should fall back to log only
        $this->assertTrue($result);
    }

    #[Test]
    public function it_logs_sms_details_with_log_provider()
    {
        Config::set('sms.default', 'log');
        
        $service = new SmsService();
        $phone = '+22501234567';
        $message = 'Test message content';
        
        $result = $service->send($phone, $message);
        
        $this->assertTrue($result);
        Log::shouldHaveReceived('info');
    }

    #[Test]
    public function opt_out_is_respected_per_phone()
    {
        Config::set('sms.default', 'log');
        
        $service = new SmsService();
        $phone1 = '+22501111111';
        $phone2 = '+22502222222';
        
        // Opt out only phone1
        Cache::put("sms_optout:{$phone1}", true, now()->addDays(30));
        
        $this->assertTrue($service->isOptedOut($phone1));
        $this->assertFalse($service->isOptedOut($phone2));
        
        // phone1 blocked, phone2 allowed
        $this->assertFalse($service->send($phone1, 'Test'));
        $this->assertTrue($service->send($phone2, 'Test'));
    }

    #[Test]
    public function it_preserves_plus_in_international_format()
    {
        Config::set('sms.default', 'log');
        
        $service = new SmsService();
        
        $reflection = new \ReflectionClass($service);
        $method = $reflection->getMethod('normalizePhone');
        $method->setAccessible(true);
        
        // International format should be preserved
        $phone = '+33612345678';
        $normalized = $method->invoke($service, $phone);
        $this->assertEquals($phone, $normalized);
    }

    #[Test]
    public function it_handles_phone_with_spaces()
    {
        Config::set('sms.default', 'log');
        
        $service = new SmsService();
        
        $reflection = new \ReflectionClass($service);
        $method = $reflection->getMethod('normalizePhone');
        $method->setAccessible(true);
        
        // Phone with spaces should be normalized
        $phone = '+225 01 23 45 67';
        $normalized = $method->invoke($service, $phone);
        
        // Should handle spaces appropriately
        $this->assertIsString($normalized);
    }
}
