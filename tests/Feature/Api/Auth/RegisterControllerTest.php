<?php

namespace Tests\Feature\Api\Auth;

use App\Models\User;
use App\Services\OtpService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Mockery;

class RegisterControllerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Mock OtpService
        $this->mock(OtpService::class, function ($mock) {
            $mock->shouldReceive('generateOtp')->andReturn('123456');
            $mock->shouldReceive('sendOtp')->andReturn('sms');
        });
    }

    /** @test */
    public function customer_can_register()
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'phone' => '+22507000001',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'user' => ['id', 'name', 'email', 'phone', 'role'],
                    'token',
                ],
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
            'phone' => '+22507000001',
            'role' => 'customer',
        ]);
    }

    /** @test */
    public function registration_requires_name()
    {
        $response = $this->postJson('/api/auth/register', [
            'email' => 'john@example.com',
            'phone' => '+22507000001',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['name']);
    }

    /** @test */
    public function registration_requires_valid_email()
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'John Doe',
            'email' => 'invalid-email',
            'phone' => '+22507000001',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    /** @test */
    public function registration_requires_unique_email()
    {
        User::factory()->create(['email' => 'existing@example.com']);

        $response = $this->postJson('/api/auth/register', [
            'name' => 'John Doe',
            'email' => 'existing@example.com',
            'phone' => '+22507000002',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    /** @test */
    public function registration_requires_unique_phone()
    {
        User::factory()->create(['phone' => '+22507000001']);

        $response = $this->postJson('/api/auth/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'phone' => '+22507000001',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['phone']);
    }

    /** @test */
    public function registration_requires_password_confirmation()
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'phone' => '+22507000001',
            'password' => 'password123',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['password']);
    }

    /** @test */
    public function registration_requires_minimum_password_length()
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'phone' => '+22507000001',
            'password' => 'short',
            'password_confirmation' => 'short',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['password']);
    }

    /** @test */
    public function email_is_normalized_to_lowercase()
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'John Doe',
            'email' => 'JOHN@EXAMPLE.COM',
            'phone' => '+22507000001',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
        ]);
    }

    /** @test */
    public function new_user_has_customer_role()
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'phone' => '+22507000001',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
            'role' => 'customer',
        ]);
    }

    /** @test */
    public function registration_returns_token()
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'phone' => '+22507000001',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => ['token'],
            ]);
    }
}
