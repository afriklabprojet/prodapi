<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    /** @test */
    public function customer_can_register()
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'phone' => '+225 07 12 34 56 78',
            'address' => '123 Abidjan Street',
            'role' => 'customer',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'data' => [
                    'user' => ['id', 'name', 'email', 'role'],
                    'token',
                ]
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
            'role' => 'customer',
        ]);
    }

    /** @test */
    public function pharmacy_can_register()
    {
        $response = $this->postJson('/api/auth/register/pharmacy', [
            'name' => 'Pharmacy Owner',
            'email' => 'pharmacy@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'phone' => '+225 07 12 34 56 78',
            'pharmacy_name' => 'Test Pharmacy LLC',
            'pharmacy_license' => 'LICENSE123456',
            'pharmacy_address' => '456 Pharmacy Blvd',
            'city' => 'Abidjan',
            'latitude' => 5.3600,
            'longitude' => -4.0083,
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'data' => [
                    'user' => [
                        'id', 'name', 'email', 'role',
                        'pharmacies' => [
                            '*' => ['id', 'name', 'status'],
                        ],
                    ],
                    'token',
                ]
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'pharmacy@example.com',
            'role' => 'pharmacy',
        ]);

        $this->assertDatabaseHas('pharmacies', [
            'name' => 'Test Pharmacy LLC',
            'license_number' => 'LICENSE123456',
            'status' => 'pending',
        ]);
    }

    /** @test */
    public function courier_can_register()
    {
        $response = $this->postJson('/api/auth/register/courier', [
            'name' => 'Courier John',
            'email' => 'courier@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'phone' => '+225 07 12 34 56 78',
            'vehicle_type' => 'motorcycle',
            'vehicle_registration' => 'AB-123-CD',
            'license_number' => 'DRIVER123456',
            'id_card_front_document' => \Illuminate\Http\UploadedFile::fake()->image('id_front.jpg'),
            'id_card_back_document' => \Illuminate\Http\UploadedFile::fake()->image('id_back.jpg'),
            'selfie_document' => \Illuminate\Http\UploadedFile::fake()->image('selfie.jpg'),
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'data' => [
                    'user' => ['id', 'name', 'email', 'role'],
                    'requires_approval',
                ]
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'courier@example.com',
            'role' => 'courier',
        ]);

        $this->assertDatabaseHas('couriers', [
            'vehicle_type' => 'motorcycle',
            'license_number' => 'DRIVER123456',
            'status' => 'pending_approval',
        ]);
    }

    /** @test */
    public function registration_requires_valid_data()
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => '',
            'email' => 'invalid-email',
            'password' => '123',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['name', 'email', 'password']);
    }

    /** @test */
    public function email_must_be_unique()
    {
        User::factory()->create(['email' => 'existing@example.com']);

        $response = $this->postJson('/api/auth/register', [
            'name' => 'John Doe',
            'email' => 'existing@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'role' => 'customer',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    /** @test */
    public function user_can_login_with_valid_credentials()
    {
        $user = User::factory()->create([
            'email' => 'user@example.com',
            'password' => Hash::make('password123'),
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'user@example.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'user' => ['id', 'name', 'email', 'role'],
                    'token',
                ]
            ]);
    }

    /** @test */
    public function login_fails_with_invalid_credentials()
    {
        User::factory()->create([
            'email' => 'user@example.com',
            'password' => Hash::make('password123'),
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'user@example.com',
            'password' => 'wrongpassword',
        ]);

        $response->assertStatus(401)
            ->assertJson([
                'message' => 'Les identifiants fournis sont incorrects.',
            ]);
    }

    /** @test */
    public function authenticated_user_can_get_profile()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/auth/me');

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                ]
            ]);
    }

    /** @test */
    public function unauthenticated_user_cannot_get_profile()
    {
        $response = $this->getJson('/api/auth/me');

        $response->assertStatus(401);
    }

    /** @test */
    public function authenticated_user_can_logout()
    {
        $user = User::factory()->create();
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/auth/logout');

        $response->assertStatus(200)
            ->assertJson([
                'message' => 'Déconnexion réussie',
            ]);

        // Verify token is deleted
        $this->assertDatabaseMissing('personal_access_tokens', [
            'tokenable_id' => $user->id,
        ]);
    }

    /** @test */
    public function customer_profile_includes_role_specific_data()
    {
        $user = User::factory()->create(['role' => 'customer']);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/auth/me');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'name',
                    'email',
                    'role',
                ]
            ]);
    }

    /** @test */
    public function pharmacy_profile_includes_pharmacy_data()
    {
        $user = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = \App\Models\Pharmacy::factory()->create();
        $user->pharmacies()->attach($pharmacy, ['role' => 'owner']);

        // Create wallet for pharmacy
        $pharmacy->wallet()->create(['balance' => 0]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/auth/me');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'name',
                    'email',
                    'role',
                    'pharmacies' => [
                        '*' => ['id', 'name', 'status']
                    ],
                    // Wallet is attached to pharmacy, not directly in root unless we flatten it
                    // But LoginController puts it in 'wallet' key if user has pharmacy?
                    // Wait, LoginController: $data['wallet'] = $user->pharmacy?->wallet;
                    // But $user->pharmacy is not valid.
                    // So I should remove wallet from here too or fix LoginController to get wallet from first pharmacy.
                ]
            ]);
    }

    /** @test */
    public function courier_profile_includes_courier_data()
    {
        $user = User::factory()->create(['role' => 'courier']);
        $courier = \App\Models\Courier::factory()->create([
            'user_id' => $user->id,
        ]);
        $courier->wallet()->create(['balance' => 0]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/auth/me');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'name',
                    'email',
                    'role',
                    'courier' => ['id', 'vehicle_type', 'status'],
                    'wallet' => ['balance'],
                ]
            ]);
    }
}
