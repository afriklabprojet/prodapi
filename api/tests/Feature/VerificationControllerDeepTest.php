<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\OtpService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class VerificationControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create([
            'email' => 'test@example.com',
            'phone' => '+2250700000000',
            'phone_verified_at' => null,
        ]);
    }

    // ──────────────────────────────────────────────────────────────
    // VERIFY OTP
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function verify_succeeds_with_valid_otp_by_email()
    {
        $mock = $this->mock(OtpService::class);
        $mock->shouldReceive('verifyOtp')->with('test@example.com', '123456')->andReturn(true);

        $response = $this->postJson('/api/auth/verify', [
            'identifier' => 'test@example.com',
            'otp' => '123456',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['message', 'user', 'token']);

        $this->assertNotNull($this->user->fresh()->phone_verified_at);
    }

    #[Test]
    public function verify_succeeds_with_valid_otp_by_phone()
    {
        $mock = $this->mock(OtpService::class);
        $mock->shouldReceive('verifyOtp')->with('+2250700000000', '654321')->andReturn(true);

        $response = $this->postJson('/api/auth/verify', [
            'identifier' => '+2250700000000',
            'otp' => '654321',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['message', 'user', 'token']);
    }

    #[Test]
    public function verify_fails_with_invalid_otp()
    {
        $mock = $this->mock(OtpService::class);
        $mock->shouldReceive('verifyOtp')->andReturn(false);

        $response = $this->postJson('/api/auth/verify', [
            'identifier' => 'test@example.com',
            'otp' => '000000',
        ]);

        $response->assertStatus(400);
    }

    #[Test]
    public function verify_fails_with_unknown_identifier()
    {
        $mock = $this->mock(OtpService::class);
        $mock->shouldReceive('verifyOtp')->andReturn(true);

        $response = $this->postJson('/api/auth/verify', [
            'identifier' => 'unknown@example.com',
            'otp' => '123456',
        ]);

        $response->assertNotFound();
    }

    #[Test]
    public function verify_requires_identifier_and_code()
    {
        $response = $this->postJson('/api/auth/verify', []);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['identifier', 'otp']);
    }

    // ──────────────────────────────────────────────────────────────
    // RESEND OTP
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function resend_sends_otp_to_existing_user()
    {
        $mock = $this->mock(OtpService::class);
        $mock->shouldReceive('generateOtp')->once()->andReturn('123456');
        $mock->shouldReceive('sendOtp')->once()->andReturn('sms');

        $response = $this->postJson('/api/auth/resend', [
            'identifier' => 'test@example.com',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['message', 'channel']);
    }

    #[Test]
    public function resend_returns_404_for_unknown_user()
    {
        $response = $this->postJson('/api/auth/resend', [
            'identifier' => 'nonexistent@example.com',
        ]);

        $response->assertNotFound();
    }

    #[Test]
    public function resend_requires_identifier()
    {
        $response = $this->postJson('/api/auth/resend', []);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['identifier']);
    }

    #[Test]
    public function resend_returns_channel_info()
    {
        $mock = $this->mock(OtpService::class);
        $mock->shouldReceive('generateOtp')->andReturn('654321');
        $mock->shouldReceive('sendOtp')->andReturn('whatsapp');

        $response = $this->postJson('/api/auth/resend', [
            'identifier' => '+2250700000000',
        ]);

        $response->assertOk()
            ->assertJsonPath('channel', 'whatsapp');
    }

    // ──────────────────────────────────────────────────────────────
    // VERIFY WITH FIREBASE
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function verify_with_firebase_requires_all_fields()
    {
        $response = $this->postJson('/api/auth/verify-firebase', []);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['phone', 'firebase_uid', 'firebase_id_token']);
    }

    #[Test]
    public function verify_with_firebase_returns_404_for_unknown_phone()
    {
        // Mock Firebase auth to pass validation
        $firebaseAuth = \Mockery::mock();
        $verifiedToken = \Mockery::mock();
        $claims = \Mockery::mock();
        $claims->shouldReceive('get')->with('sub')->andReturn('firebase-uid-123');
        $claims->shouldReceive('get')->with('phone_number')->andReturn('+2250799999999');
        $verifiedToken->shouldReceive('claims')->andReturn($claims);
        $firebaseAuth->shouldReceive('verifyIdToken')->andReturn($verifiedToken);
        $this->app->instance('firebase.auth', $firebaseAuth);

        $response = $this->postJson('/api/auth/verify-firebase', [
            'phone' => '+2250799999999',
            'firebase_uid' => 'firebase-uid-123',
            'firebase_id_token' => 'valid-token',
        ]);

        $response->assertNotFound();
    }

    #[Test]
    public function verify_with_firebase_rejects_mismatched_uid()
    {
        $firebaseAuth = \Mockery::mock();
        $verifiedToken = \Mockery::mock();
        $claims = \Mockery::mock();
        $claims->shouldReceive('get')->with('sub')->andReturn('different-uid');
        $verifiedToken->shouldReceive('claims')->andReturn($claims);
        $firebaseAuth->shouldReceive('verifyIdToken')->andReturn($verifiedToken);
        $this->app->instance('firebase.auth', $firebaseAuth);

        $response = $this->postJson('/api/auth/verify-firebase', [
            'phone' => '+2250700000000',
            'firebase_uid' => 'firebase-uid-123',
            'firebase_id_token' => 'token',
        ]);

        $response->assertForbidden();
    }

    #[Test]
    public function verify_with_firebase_rejects_mismatched_phone()
    {
        $firebaseAuth = \Mockery::mock();
        $verifiedToken = \Mockery::mock();
        $claims = \Mockery::mock();
        $claims->shouldReceive('get')->with('sub')->andReturn('uid-123');
        $claims->shouldReceive('get')->with('phone_number')->andReturn('+1234567890');
        $verifiedToken->shouldReceive('claims')->andReturn($claims);
        $firebaseAuth->shouldReceive('verifyIdToken')->andReturn($verifiedToken);
        $this->app->instance('firebase.auth', $firebaseAuth);

        $response = $this->postJson('/api/auth/verify-firebase', [
            'phone' => '+2250700000000',
            'firebase_uid' => 'uid-123',
            'firebase_id_token' => 'token',
        ]);

        $response->assertForbidden();
    }

    #[Test]
    public function verify_with_firebase_handles_token_exception()
    {
        $firebaseAuth = \Mockery::mock();
        $firebaseAuth->shouldReceive('verifyIdToken')
            ->andThrow(new \Exception('Invalid token'));
        $this->app->instance('firebase.auth', $firebaseAuth);

        $response = $this->postJson('/api/auth/verify-firebase', [
            'phone' => '+2250700000000',
            'firebase_uid' => 'uid-123',
            'firebase_id_token' => 'bad-token',
        ]);

        $response->assertForbidden();
    }

    #[Test]
    public function verify_with_firebase_succeeds_and_creates_token()
    {
        $firebaseAuth = \Mockery::mock();
        $verifiedToken = \Mockery::mock();
        $claims = \Mockery::mock();
        $claims->shouldReceive('get')->with('sub')->andReturn('uid-valid');
        $claims->shouldReceive('get')->with('phone_number')->andReturn('+2250700000000');
        $verifiedToken->shouldReceive('claims')->andReturn($claims);
        $firebaseAuth->shouldReceive('verifyIdToken')->andReturn($verifiedToken);
        $this->app->instance('firebase.auth', $firebaseAuth);

        $response = $this->postJson('/api/auth/verify-firebase', [
            'phone' => '+2250700000000',
            'firebase_uid' => 'uid-valid',
            'firebase_id_token' => 'valid-id-token',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['user', 'token']);

        $this->assertNotNull($this->user->fresh()->phone_verified_at);
        $this->assertEquals('uid-valid', $this->user->fresh()->firebase_uid);
    }
}
