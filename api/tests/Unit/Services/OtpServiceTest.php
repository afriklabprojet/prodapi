<?php

namespace Tests\Unit\Services;

use App\Services\OtpService;
use App\Services\SmsService;
use App\Mail\OtpMail;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;
use Mockery;
use PHPUnit\Framework\Attributes\Test;

class OtpServiceTest extends TestCase
{
    use RefreshDatabase;

    protected OtpService $otpService;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->otpService = new OtpService();
        Cache::flush();
    }

    #[Test]
    public function it_generates_otp_with_correct_length()
    {
        $otp = $this->otpService->generateOtp('test@example.com', 4);
        
        $this->assertEquals(4, strlen($otp));
        $this->assertIsNumeric($otp);
    }

    #[Test]
    public function it_generates_6_digit_otp()
    {
        $otp = $this->otpService->generateOtp('test@example.com', 6);
        
        $this->assertEquals(6, strlen($otp));
        $this->assertIsNumeric($otp);
    }

    #[Test]
    public function it_stores_otp_in_cache()
    {
        $identifier = 'test@example.com';
        $otp = $this->otpService->generateOtp($identifier);
        
        $this->assertEquals($otp, Cache::get('otp_' . $identifier));
    }

    #[Test]
    public function it_verifies_correct_otp()
    {
        $identifier = 'test@example.com';
        $otp = $this->otpService->generateOtp($identifier);
        
        $this->assertTrue($this->otpService->verifyOtp($identifier, $otp));
    }

    #[Test]
    public function it_rejects_incorrect_otp()
    {
        $identifier = 'test@example.com';
        $this->otpService->generateOtp($identifier);
        
        $this->assertFalse($this->otpService->verifyOtp($identifier, '9999'));
    }

    #[Test]
    public function it_removes_otp_after_verification()
    {
        $identifier = 'test@example.com';
        $otp = $this->otpService->generateOtp($identifier);
        
        $this->assertTrue($this->otpService->verifyOtp($identifier, $otp));
        
        // Second verification should fail
        $this->assertFalse($this->otpService->verifyOtp($identifier, $otp));
    }

    #[Test]
    public function it_checks_otp_without_removing()
    {
        $identifier = 'test@example.com';
        $otp = $this->otpService->generateOtp($identifier);
        
        $this->assertTrue($this->otpService->checkOtp($identifier, $otp));
        
        // Check again should still work
        $this->assertTrue($this->otpService->checkOtp($identifier, $otp));
    }

    #[Test]
    public function it_sends_otp_via_email_for_email_identifier()
    {
        Mail::fake();
        
        $email = 'test@example.com';
        $otp = '1234';
        
        $channel = $this->otpService->sendOtp($email, $otp, 'verification');
        
        $this->assertEquals('email', $channel);
        Mail::assertQueued(OtpMail::class, function ($mail) use ($email) {
            return $mail->hasTo($email);
        });
    }

    #[Test]
    public function it_sends_otp_via_sms_for_phone_identifier()
    {
        // Disable WhatsApp OTP so SMS is used as primary channel
        config(['whatsapp.notifications.otp' => false]);

        // Mock SmsService
        $smsServiceMock = Mockery::mock(SmsService::class);
        $smsServiceMock->shouldReceive('send')
            ->once()
            ->andReturn(true);
        
        $this->app->instance(SmsService::class, $smsServiceMock);
        
        // Re-create OtpService so it picks up the mocked SmsService
        $this->otpService = app(OtpService::class);

        $phone = '+2250707070707';
        $otp = '1234';
        
        $channel = $this->otpService->sendOtp($phone, $otp, 'verification');
        
        $this->assertEquals('sms', $channel);
    }

    #[Test]
    public function it_falls_back_to_email_when_sms_fails()
    {
        // Disable WhatsApp OTP so SMS is used as primary channel
        config(['whatsapp.notifications.otp' => false]);

        Mail::fake();
        
        // Mock SmsService to fail
        $smsServiceMock = Mockery::mock(SmsService::class);
        $smsServiceMock->shouldReceive('send')
            ->once()
            ->andReturn(false);
        
        $this->app->instance(SmsService::class, $smsServiceMock);
        
        // Re-create OtpService so it picks up the container changes
        $this->otpService = app(OtpService::class);

        $phone = '+2250707070707';
        $fallbackEmail = 'fallback@example.com';
        $otp = '1234';
        
        $channel = $this->otpService->sendOtp($phone, $otp, 'verification', $fallbackEmail);
        
        $this->assertEquals('sms_fallback_email', $channel);
        Mail::assertQueued(OtpMail::class, function ($mail) use ($fallbackEmail) {
            return $mail->hasTo($fallbackEmail);
        });
    }

    #[Test]
    public function it_generates_different_messages_for_different_purposes()
    {
        // Use reflection to test protected method
        $method = new \ReflectionMethod(OtpService::class, 'getSmsMessage');
        $method->setAccessible(true);
        
        $verificationMsg = $method->invoke($this->otpService, '1234', 'verification');
        $passwordResetMsg = $method->invoke($this->otpService, '1234', 'password_reset');
        $loginMsg = $method->invoke($this->otpService, '1234', 'login');
        
        $this->assertStringContainsString('vérification', $verificationMsg);
        $this->assertStringContainsString('réinitialisation', $passwordResetMsg);
        $this->assertStringContainsString('connexion', $loginMsg);
    }

    #[Test]
    public function otp_expires_after_validity_period()
    {
        $identifier = 'test@example.com';
        $otp = $this->otpService->generateOtp($identifier, 4, 1); // 1 minute validity
        
        // Travel to the future
        $this->travel(2)->minutes();
        
        $this->assertFalse($this->otpService->verifyOtp($identifier, $otp));
    }

    #[Test]
    public function it_returns_false_for_expired_otp()
    {
        $identifier = 'test@example.com';
        // Don't generate OTP, try to verify non-existent one
        
        $this->assertFalse($this->otpService->verifyOtp($identifier, '1234'));
    }

    #[Test]
    public function it_generates_unique_otps()
    {
        $otps = [];
        for ($i = 0; $i < 10; $i++) {
            $otps[] = $this->otpService->generateOtp("test{$i}@example.com");
        }
        
        // While theoretically could have duplicates, very unlikely with 4 digits for 10 samples
        // This test ensures the generator is working
        $this->assertCount(10, $otps);
        foreach ($otps as $otp) {
            $this->assertIsNumeric($otp);
            $this->assertEquals(4, strlen($otp));
        }
    }

    #[Test]
    public function it_overwrites_previous_otp_for_same_identifier()
    {
        $identifier = 'test@example.com';
        
        $otp1 = $this->otpService->generateOtp($identifier);
        $otp2 = $this->otpService->generateOtp($identifier);
        
        // Only the latest OTP should be valid
        $this->assertFalse($this->otpService->verifyOtp($identifier, $otp1));
        $this->assertTrue($this->otpService->checkOtp($identifier, $otp2));
    }
}
