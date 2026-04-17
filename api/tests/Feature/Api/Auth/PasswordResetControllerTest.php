<?php

namespace Tests\Feature\Api\Auth;

use App\Models\User;
use App\Services\OtpService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Mockery;
use Tests\TestCase;

class PasswordResetControllerTest extends TestCase
{
    use RefreshDatabase;

    protected function mockOtpService(): void
    {
        $mock = Mockery::mock(OtpService::class);
        $mock->shouldReceive('generateOtp')->andReturn('1234');
        $mock->shouldReceive('sendOtp')->andReturn('email');
        $mock->shouldReceive('checkOtp')->andReturnUsing(fn($id, $otp) => $otp === '1234');
        $mock->shouldReceive('verifyOtp')->andReturnUsing(fn($id, $otp) => $otp === '1234');
        $this->app->instance(OtpService::class, $mock);
    }

    public function test_forgot_password_sends_otp(): void
    {
        $this->mockOtpService();
        User::factory()->create(['email' => 'user@test.com']);

        $response = $this->postJson('/api/auth/forgot-password', [
            'email' => 'user@test.com',
        ]);

        $response->assertOk()->assertJsonFragment(['message' => 'Code de réinitialisation envoyé']);
    }

    public function test_forgot_password_returns_ok_for_nonexistent_email(): void
    {
        $response = $this->postJson('/api/auth/forgot-password', [
            'email' => 'nonexistent@test.com',
        ]);

        // Returns success to prevent user enumeration
        $response->assertOk();
    }

    public function test_forgot_password_requires_email(): void
    {
        $response = $this->postJson('/api/auth/forgot-password', []);
        $response->assertStatus(422);
    }

    public function test_verify_reset_otp_with_valid_code(): void
    {
        $this->mockOtpService();
        User::factory()->create(['email' => 'user@test.com']);

        $response = $this->postJson('/api/auth/verify-reset-otp', [
            'email' => 'user@test.com',
            'otp' => '1234',
        ]);

        $response->assertOk()->assertJsonFragment(['message' => 'Code valide']);
    }

    public function test_verify_reset_otp_with_invalid_code(): void
    {
        $this->mockOtpService();

        $response = $this->postJson('/api/auth/verify-reset-otp', [
            'email' => 'user@test.com',
            'otp' => '0000',
        ]);

        $response->assertStatus(400);
    }

    public function test_verify_reset_otp_requires_fields(): void
    {
        $response = $this->postJson('/api/auth/verify-reset-otp', []);
        $response->assertStatus(422);
    }

    public function test_reset_password_with_valid_otp(): void
    {
        $this->mockOtpService();
        $user = User::factory()->create(['email' => 'user@test.com']);

        $response = $this->postJson('/api/auth/reset-password', [
            'email' => 'user@test.com',
            'otp' => '1234',
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertOk()->assertJsonFragment(['message' => 'Mot de passe réinitialisé avec succès']);

        $user->refresh();
        $this->assertTrue(Hash::check('NewPassword123!', $user->password));
    }

    public function test_reset_password_with_invalid_otp(): void
    {
        $this->mockOtpService();
        User::factory()->create(['email' => 'user@test.com']);

        $response = $this->postJson('/api/auth/reset-password', [
            'email' => 'user@test.com',
            'otp' => '0000',
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(400);
    }

    public function test_reset_password_requires_confirmation(): void
    {
        $response = $this->postJson('/api/auth/reset-password', [
            'email' => 'user@test.com',
            'otp' => '1234',
            'password' => 'NewPassword123!',
        ]);

        $response->assertStatus(422);
    }

    public function test_update_password_for_authenticated_user(): void
    {
        $user = User::factory()->create([
            'password' => Hash::make('OldPassword123!'),
        ]);

        $response = $this->actingAs($user)->postJson('/api/auth/password', [
            'current_password' => 'OldPassword123!',
            'new_password' => 'NewPassword456!',
            'new_password_confirmation' => 'NewPassword456!',
        ]);

        $response->assertOk();
        $user->refresh();
        $this->assertTrue(Hash::check('NewPassword456!', $user->password));
    }

    public function test_update_password_fails_with_wrong_current(): void
    {
        $user = User::factory()->create([
            'password' => Hash::make('OldPassword123!'),
        ]);

        $response = $this->actingAs($user)->postJson('/api/auth/password', [
            'current_password' => 'WrongPassword!',
            'new_password' => 'NewPassword456!',
            'new_password_confirmation' => 'NewPassword456!',
        ]);

        $response->assertStatus(422);
    }

    public function test_update_password_fails_when_same_as_current(): void
    {
        $user = User::factory()->create([
            'password' => Hash::make('OldPassword123!'),
        ]);

        $response = $this->actingAs($user)->postJson('/api/auth/password', [
            'current_password' => 'OldPassword123!',
            'new_password' => 'OldPassword123!',
            'new_password_confirmation' => 'OldPassword123!',
        ]);

        $response->assertStatus(422);
    }

    public function test_update_password_requires_auth(): void
    {
        $response = $this->postJson('/api/auth/password', [
            'current_password' => 'old',
            'new_password' => 'new',
            'new_password_confirmation' => 'new',
        ]);

        $response->assertStatus(401);
    }
}
