<?php

namespace Tests\Feature\Api\Auth;

use App\Models\User;
use App\Services\OtpService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery;
use Tests\TestCase;

class VerificationControllerTest extends TestCase
{
    use RefreshDatabase;

    protected function mockOtpService(): void
    {
        $mock = Mockery::mock(OtpService::class);
        $mock->shouldReceive('verifyOtp')->andReturnUsing(fn($id, $otp) => $otp === '123456');
        $mock->shouldReceive('generateOtp')->andReturn('123456');
        $mock->shouldReceive('sendOtp')->andReturn('email');
        $this->app->instance(OtpService::class, $mock);
    }

    public function test_verify_with_valid_otp(): void
    {
        $this->mockOtpService();
        $user = User::factory()->create([
            'email' => 'test@verify.com',
            'phone_verified_at' => null,
        ]);

        $response = $this->postJson('/api/auth/verify', [
            'identifier' => 'test@verify.com',
            'otp' => '123456',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['message', 'user', 'token']);

        $user->refresh();
        $this->assertNotNull($user->phone_verified_at);
    }

    public function test_verify_with_invalid_otp(): void
    {
        $this->mockOtpService();
        User::factory()->create(['email' => 'test@verify.com']);

        $response = $this->postJson('/api/auth/verify', [
            'identifier' => 'test@verify.com',
            'otp' => '000000',
        ]);

        $response->assertStatus(400);
    }

    public function test_verify_requires_fields(): void
    {
        $response = $this->postJson('/api/auth/verify', []);
        $response->assertStatus(422);
    }

    public function test_verify_with_nonexistent_user(): void
    {
        $this->mockOtpService();

        $response = $this->postJson('/api/auth/verify', [
            'identifier' => 'nonexistent@test.com',
            'otp' => '123456',
        ]);

        $response->assertStatus(404);
    }

    public function test_resend_otp_for_existing_user(): void
    {
        $this->mockOtpService();
        User::factory()->create(['email' => 'test@verify.com']);

        $response = $this->postJson('/api/auth/resend', [
            'identifier' => 'test@verify.com',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['message', 'channel']);
    }

    public function test_resend_otp_for_nonexistent_user(): void
    {
        $response = $this->postJson('/api/auth/resend', [
            'identifier' => 'nonexistent@test.com',
        ]);

        $response->assertStatus(404);
    }

    public function test_resend_requires_identifier(): void
    {
        $response = $this->postJson('/api/auth/resend', []);
        $response->assertStatus(422);
    }

    public function test_verify_with_phone_identifier(): void
    {
        $this->mockOtpService();
        User::factory()->create([
            'phone' => '+22507000001',
            'phone_verified_at' => null,
        ]);

        $response = $this->postJson('/api/auth/verify', [
            'identifier' => '+22507000001',
            'otp' => '123456',
        ]);

        $response->assertOk();
    }
}
