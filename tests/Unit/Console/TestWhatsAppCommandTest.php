<?php

namespace Tests\Unit\Console;

use App\Console\Commands\TestWhatsApp;
use App\Services\WhatsAppService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery;
use ReflectionClass;
use Tests\TestCase;

class TestWhatsAppCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_command_signature(): void
    {
        $reflection = new ReflectionClass(TestWhatsApp::class);
        $prop = $reflection->getProperty('signature');
        $prop->setAccessible(true);
        $value = $prop->getValue(new TestWhatsApp());

        $this->assertStringContainsString('drpharma:test-whatsapp', $value);
        $this->assertStringContainsString('{phone?', $value);
        $this->assertStringContainsString('--template=', $value);
        $this->assertStringContainsString('--lang=', $value);
        $this->assertStringContainsString('--text=', $value);
    }

    public function test_command_description(): void
    {
        $reflection = new ReflectionClass(TestWhatsApp::class);
        $prop = $reflection->getProperty('description');
        $prop->setAccessible(true);
        $value = $prop->getValue(new TestWhatsApp());

        $this->assertNotEmpty($value);
        $this->assertStringContainsString('WhatsApp', $value);
    }

    public function test_command_fails_when_not_configured(): void
    {
        $mockService = Mockery::mock(WhatsAppService::class);
        $mockService->shouldReceive('isConfigured')->once()->andReturn(false);
        $this->app->instance(WhatsAppService::class, $mockService);

        $this->artisan('drpharma:test-whatsapp', ['phone' => '2250700000000'])
            ->assertExitCode(1);
    }

    public function test_command_sends_text_message_success(): void
    {
        config([
            'whatsapp.enabled' => true,
            'whatsapp.base_url' => 'https://test.api.infobip.com',
            'whatsapp.api_key' => 'test-key',
            'whatsapp.sender_number' => '2250700000000',
            'whatsapp.sms_failover.enabled' => false,
        ]);

        $mockService = Mockery::mock(WhatsAppService::class);
        $mockService->shouldReceive('isConfigured')->once()->andReturn(true);
        $mockService->shouldReceive('sendText')
            ->once()
            ->with('2250700000001', 'Hello World')
            ->andReturn(true);
        $this->app->instance(WhatsAppService::class, $mockService);

        $this->artisan('drpharma:test-whatsapp', [
            'phone' => '2250700000001',
            '--text' => 'Hello World',
        ])
            ->expectsConfirmation('Confirmer l\'envoi ?', 'yes')
            ->assertExitCode(0);
    }

    public function test_command_sends_template_message_success(): void
    {
        config([
            'whatsapp.enabled' => true,
            'whatsapp.base_url' => 'https://test.api.infobip.com',
            'whatsapp.api_key' => 'test-key',
            'whatsapp.sender_number' => '2250700000000',
            'whatsapp.sms_failover.enabled' => false,
        ]);

        $mockService = Mockery::mock(WhatsAppService::class);
        $mockService->shouldReceive('isConfigured')->once()->andReturn(true);
        $mockService->shouldReceive('sendTemplate')
            ->once()
            ->andReturn(true);
        $this->app->instance(WhatsAppService::class, $mockService);

        $this->artisan('drpharma:test-whatsapp', [
            'phone' => '2250700000001',
            '--template' => 'test_template',
            '--lang' => 'fr',
            '--name' => 'Test',
        ])
            ->expectsConfirmation('Confirmer l\'envoi ?', 'yes')
            ->assertExitCode(0);
    }

    public function test_command_sends_text_message_failure(): void
    {
        config([
            'whatsapp.enabled' => true,
            'whatsapp.base_url' => 'https://test.api.infobip.com',
            'whatsapp.api_key' => 'test-key',
            'whatsapp.sender_number' => '2250700000000',
            'whatsapp.sms_failover.enabled' => false,
        ]);

        $mockService = Mockery::mock(WhatsAppService::class);
        $mockService->shouldReceive('isConfigured')->once()->andReturn(true);
        $mockService->shouldReceive('sendText')
            ->once()
            ->andReturn(false);
        $this->app->instance(WhatsAppService::class, $mockService);

        $this->artisan('drpharma:test-whatsapp', [
            'phone' => '2250700000001',
            '--text' => 'Hello',
        ])
            ->expectsConfirmation('Confirmer l\'envoi ?', 'yes')
            ->assertExitCode(1);
    }

    public function test_command_cancelled_by_user(): void
    {
        config([
            'whatsapp.enabled' => true,
            'whatsapp.base_url' => 'https://test.api.infobip.com',
            'whatsapp.api_key' => 'test-key',
            'whatsapp.sender_number' => '2250700000000',
            'whatsapp.sms_failover.enabled' => false,
        ]);

        $mockService = Mockery::mock(WhatsAppService::class);
        $mockService->shouldReceive('isConfigured')->once()->andReturn(true);
        $this->app->instance(WhatsAppService::class, $mockService);

        $this->artisan('drpharma:test-whatsapp', [
            'phone' => '2250700000001',
            '--text' => 'Hello',
        ])
            ->expectsConfirmation('Confirmer l\'envoi ?', 'no')
            ->assertExitCode(0); // Cancelled = SUCCESS
    }
}
