<?php

namespace Tests\Unit\Services;

use App\Mail\OtpMail;
use App\Services\OtpService;
use App\Services\SmsService;
use App\Services\WhatsAppService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Mockery;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class OtpServiceDeepTest extends TestCase
{
    private OtpService $service;

    protected function setUp(): void
    {
        parent::setUp();
        Log::spy();
        Cache::flush();
        Mail::fake();
        $this->service = new OtpService();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════

    private function callPrivate(object $obj, string $method, array $args = []): mixed
    {
        $ref = new \ReflectionMethod($obj, $method);
        $ref->setAccessible(true);
        return $ref->invoke($obj, ...$args);
    }

    private function mockWhatsAppService(bool $configured = true, bool $sendResult = true): WhatsAppService
    {
        $mock = Mockery::mock(WhatsAppService::class);
        $mock->shouldReceive('isConfigured')->andReturn($configured);
        if ($configured) {
            $mock->shouldReceive('sendTemplate')->andReturn($sendResult);
        }
        return $mock;
    }

    private function mockSmsService(bool $result = true): SmsService
    {
        $mock = Mockery::mock(SmsService::class);
        $mock->shouldReceive('send')->andReturn($result);
        return $mock;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // sendWhatsAppOtp
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function send_whatsapp_otp_success(): void
    {
        $whatsApp = $this->mockWhatsAppService(true, true);
        $this->app->instance(WhatsAppService::class, $whatsApp);

        $result = $this->callPrivate($this->service, 'sendWhatsAppOtp', ['+2250700000000', '1234', 'verification']);
        $this->assertTrue($result);
    }

    #[Test]
    public function send_whatsapp_otp_not_configured(): void
    {
        $whatsApp = $this->mockWhatsAppService(false);
        $this->app->instance(WhatsAppService::class, $whatsApp);

        $result = $this->callPrivate($this->service, 'sendWhatsAppOtp', ['+2250700000000', '1234', 'verification']);
        $this->assertFalse($result);
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, 'not configured'));
    }

    #[Test]
    public function send_whatsapp_otp_returns_false_from_service(): void
    {
        $whatsApp = $this->mockWhatsAppService(true, false);
        $this->app->instance(WhatsAppService::class, $whatsApp);

        $result = $this->callPrivate($this->service, 'sendWhatsAppOtp', ['+2250700000000', '1234', 'verification']);
        $this->assertFalse($result);
        Log::shouldHaveReceived('warning');
    }

    #[Test]
    public function send_whatsapp_otp_catches_exception(): void
    {
        $whatsApp = Mockery::mock(WhatsAppService::class);
        $whatsApp->shouldReceive('isConfigured')->andThrow(new \Exception('boom'));
        $this->app->instance(WhatsAppService::class, $whatsApp);

        $result = $this->callPrivate($this->service, 'sendWhatsAppOtp', ['+2250700000000', '1234', 'verification']);
        $this->assertFalse($result);
        Log::shouldHaveReceived('error');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // sendEmailOtp
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function send_email_otp_success(): void
    {
        $result = $this->callPrivate($this->service, 'sendEmailOtp', ['test@example.com', '1234', 'verification']);
        $this->assertTrue($result);
        Mail::assertQueued(OtpMail::class, fn ($mail) => $mail->hasTo('test@example.com'));
    }

    #[Test]
    public function send_email_otp_catches_exception_and_logs_otp_in_testing(): void
    {
        Mail::shouldReceive('to')->andThrow(new \Exception('Mail failed'));

        $result = $this->callPrivate($this->service, 'sendEmailOtp', ['test@example.com', '5678', 'login']);
        $this->assertFalse($result);
        Log::shouldHaveReceived('error')->withArgs(fn ($msg) => str_contains($msg, 'Failed to send OTP email'));
        // In testing environment, OTP is logged
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, '5678'));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // sendSmsOtp
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function send_sms_otp_success(): void
    {
        $this->app->instance(SmsService::class, $this->mockSmsService(true));

        $result = $this->callPrivate($this->service, 'sendSmsOtp', ['+2250700000000', '1234', 'verification']);
        $this->assertTrue($result);
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, 'OTP SMS sent'));
    }

    #[Test]
    public function send_sms_otp_returns_false(): void
    {
        $this->app->instance(SmsService::class, $this->mockSmsService(false));

        $result = $this->callPrivate($this->service, 'sendSmsOtp', ['+2250700000000', '1234', 'verification']);
        $this->assertFalse($result);
        Log::shouldHaveReceived('warning');
    }

    #[Test]
    public function send_sms_otp_catches_exception_and_logs_otp(): void
    {
        $sms = Mockery::mock(SmsService::class);
        $sms->shouldReceive('send')->andThrow(new \Exception('SMS fail'));
        $this->app->instance(SmsService::class, $sms);

        $result = $this->callPrivate($this->service, 'sendSmsOtp', ['+2250700000000', '9999', 'login']);
        $this->assertFalse($result);
        Log::shouldHaveReceived('error');
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, '9999'));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getSmsMessage
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function get_sms_message_for_verification(): void
    {
        $msg = $this->callPrivate($this->service, 'getSmsMessage', ['1234', 'verification']);
        $this->assertStringContainsString('vérification', $msg);
        $this->assertStringContainsString('1234', $msg);
    }

    #[Test]
    public function get_sms_message_for_password_reset(): void
    {
        $msg = $this->callPrivate($this->service, 'getSmsMessage', ['5555', 'password_reset']);
        $this->assertStringContainsString('réinitialisation', $msg);
        $this->assertStringContainsString('5555', $msg);
    }

    #[Test]
    public function get_sms_message_for_login(): void
    {
        $msg = $this->callPrivate($this->service, 'getSmsMessage', ['0000', 'login']);
        $this->assertStringContainsString('connexion', $msg);
        $this->assertStringContainsString('0000', $msg);
    }

    #[Test]
    public function get_sms_message_for_unknown_purpose(): void
    {
        $msg = $this->callPrivate($this->service, 'getSmsMessage', ['7777', 'random_purpose']);
        $this->assertStringContainsString('code est', $msg);
        $this->assertStringContainsString('7777', $msg);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // sendOtp — WhatsApp-first flow
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function send_otp_email_identifier_sends_email(): void
    {
        $channel = $this->service->sendOtp('user@example.com', '1234');
        $this->assertEquals('email', $channel);
        Mail::assertQueued(OtpMail::class);
    }

    #[Test]
    public function send_otp_phone_whatsapp_enabled_success(): void
    {
        Config::set('whatsapp.notifications.otp', true);
        $whatsApp = $this->mockWhatsAppService(true, true);
        $this->app->instance(WhatsAppService::class, $whatsApp);

        $channel = $this->service->sendOtp('+2250700000000', '1234');
        $this->assertEquals('whatsapp', $channel);
    }

    #[Test]
    public function send_otp_phone_whatsapp_fails_fallback_sms(): void
    {
        Config::set('whatsapp.notifications.otp', true);
        // WhatsApp configured but sendTemplate returns false
        $whatsApp = $this->mockWhatsAppService(true, false);
        $this->app->instance(WhatsAppService::class, $whatsApp);
        $this->app->instance(SmsService::class, $this->mockSmsService(true));

        $channel = $this->service->sendOtp('+2250700000000', '1234');
        $this->assertEquals('whatsapp_fallback_sms', $channel);
    }

    #[Test]
    public function send_otp_phone_whatsapp_and_sms_fail_fallback_email(): void
    {
        Config::set('whatsapp.notifications.otp', true);
        $whatsApp = $this->mockWhatsAppService(true, false);
        $this->app->instance(WhatsAppService::class, $whatsApp);
        $this->app->instance(SmsService::class, $this->mockSmsService(false));

        $channel = $this->service->sendOtp('+2250700000000', '1234', 'verification', 'fallback@test.com');
        $this->assertEquals('whatsapp_fallback_email', $channel);
        Mail::assertQueued(OtpMail::class, fn ($mail) => $mail->hasTo('fallback@test.com'));
    }

    #[Test]
    public function send_otp_phone_whatsapp_and_sms_fail_no_email_returns_whatsapp(): void
    {
        Config::set('whatsapp.notifications.otp', true);
        $whatsApp = $this->mockWhatsAppService(true, false);
        $this->app->instance(WhatsAppService::class, $whatsApp);
        $this->app->instance(SmsService::class, $this->mockSmsService(false));

        $channel = $this->service->sendOtp('+2250700000000', '1234', 'verification', null);
        $this->assertEquals('whatsapp', $channel);
    }

    #[Test]
    public function send_otp_phone_sms_first_when_whatsapp_disabled(): void
    {
        Config::set('whatsapp.notifications.otp', false);
        $this->app->instance(SmsService::class, $this->mockSmsService(true));

        $channel = $this->service->sendOtp('+2250700000000', '1234');
        $this->assertEquals('sms', $channel);
    }

    #[Test]
    public function send_otp_phone_sms_fails_fallback_email(): void
    {
        Config::set('whatsapp.notifications.otp', false);
        $this->app->instance(SmsService::class, $this->mockSmsService(false));

        $channel = $this->service->sendOtp('+2250700000000', '1234', 'verification', 'backup@test.com');
        $this->assertEquals('sms_fallback_email', $channel);
        Mail::assertQueued(OtpMail::class);
    }

    #[Test]
    public function send_otp_phone_sms_fails_no_fallback_returns_sms(): void
    {
        Config::set('whatsapp.notifications.otp', false);
        $this->app->instance(SmsService::class, $this->mockSmsService(false));

        $channel = $this->service->sendOtp('+2250700000000', '1234', 'verification', null);
        $this->assertEquals('sms', $channel);
    }
}
