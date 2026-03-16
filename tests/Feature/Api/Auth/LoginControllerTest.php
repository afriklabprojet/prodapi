<?php

namespace Tests\Feature\Api\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class LoginControllerTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function user_can_login_with_email()
    {
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'test@example.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'token',
                    'user',
                ],
            ]);
    }

    /** @test */
    public function user_can_login_with_phone()
    {
        $user = User::factory()->create([
            'phone' => '+22507000000',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => '+22507000000',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'token',
                ],
            ]);
    }

    /** @test */
    public function login_fails_with_wrong_password()
    {
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('password123'),
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'test@example.com',
            'password' => 'wrongpassword',
        ]);

        $response->assertStatus(401)
            ->assertJson([
                'success' => false,
                'error_code' => 'INVALID_CREDENTIALS',
            ]);
    }

    /** @test */
    public function login_fails_with_nonexistent_user()
    {
        $response = $this->postJson('/api/auth/login', [
            'email' => 'nonexistent@example.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(401);
    }

    /** @test */
    public function login_requires_email_field()
    {
        $response = $this->postJson('/api/auth/login', [
            'password' => 'password123',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    /** @test */
    public function login_requires_password_field()
    {
        $response = $this->postJson('/api/auth/login', [
            'email' => 'test@example.com',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['password']);
    }

    /** @test */
    public function email_is_case_insensitive()
    {
        $user = User::factory()->create([
            'email' => 'test@example.com',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'TEST@EXAMPLE.COM',
            'password' => 'password123',
        ]);

        $response->assertStatus(200);
    }

    /** @test */
    public function courier_cannot_login_as_customer()
    {
        $user = User::factory()->create([
            'email' => 'courier@example.com',
            'password' => Hash::make('password123'),
            'role' => 'courier',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'courier@example.com',
            'password' => 'password123',
            'role' => 'customer',
        ]);

        $response->assertStatus(422);
    }

    /** @test */
    public function customer_cannot_login_as_courier()
    {
        $user = User::factory()->create([
            'email' => 'customer@example.com',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'customer@example.com',
            'password' => 'password123',
            'role' => 'courier',
        ]);

        $response->assertStatus(422);
    }

    /** @test */
    public function phone_spaces_are_removed()
    {
        $user = User::factory()->create([
            'phone' => '+22507000000',
            'password' => Hash::make('password123'),
            'role' => 'customer',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => '+225 07 00 00 00',
            'password' => 'password123',
        ]);

        $response->assertStatus(200);
    }
}
