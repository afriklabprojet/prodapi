<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Courier;
use App\Models\Pharmacy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class LoginControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    // ──────────────────────────────────────────────────────────────
    // LOGIN
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function login_with_email()
    {
        $user = User::factory()->create([
            'email' => 'user@test.com',
            'password' => Hash::make('secret123'),
            'role' => 'customer',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'user@test.com',
            'password' => 'secret123',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['data' => ['user', 'token']]);
    }

    #[Test]
    public function login_with_phone_number()
    {
        $user = User::factory()->create([
            'phone' => '+2250700000000',
            'password' => Hash::make('secret123'),
            'role' => 'customer',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => '+2250700000000',
            'password' => 'secret123',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['data' => ['user', 'token']]);
    }

    #[Test]
    public function login_with_phone_without_country_code()
    {
        $user = User::factory()->create([
            'phone' => '+2250700000000',
            'password' => Hash::make('secret123'),
            'role' => 'customer',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => '0700000000',
            'password' => 'secret123',
        ]);

        $response->assertOk();
    }

    #[Test]
    public function login_fails_with_wrong_password()
    {
        User::factory()->create([
            'email' => 'user@test.com',
            'password' => Hash::make('correct'),
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'user@test.com',
            'password' => 'wrong',
        ]);

        $response->assertUnauthorized();
    }

    #[Test]
    public function login_fails_with_nonexistent_email()
    {
        $response = $this->postJson('/api/auth/login', [
            'email' => 'nobody@test.com',
            'password' => 'secret',
        ]);

        $response->assertUnauthorized();
    }

    #[Test]
    public function login_requires_email_and_password()
    {
        $response = $this->postJson('/api/auth/login', []);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['email', 'password']);
    }

    #[Test]
    public function login_checks_courier_status()
    {
        $user = User::factory()->create([
            'email' => 'courier@test.com',
            'password' => Hash::make('secret123'),
            'role' => 'courier',
        ]);
        Courier::factory()->create([
            'user_id' => $user->id,
            'status' => 'suspended',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'courier@test.com',
            'password' => 'secret123',
        ]);

        $response->assertStatus(422);
    }

    #[Test]
    public function login_checks_pharmacy_status()
    {
        $user = User::factory()->create([
            'email' => 'pharma@test.com',
            'password' => Hash::make('secret123'),
            'role' => 'pharmacy',
        ]);
        $pharmacy = Pharmacy::factory()->create(['status' => 'suspended']);
        $user->pharmacies()->attach($pharmacy->id, ['role' => 'owner']);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'pharma@test.com',
            'password' => 'secret123',
        ]);

        $response->assertForbidden();
    }

    // ──────────────────────────────────────────────────────────────
    // LOGOUT
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function logout_revokes_current_token()
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/auth/logout');

        $response->assertOk();
        $this->assertDatabaseMissing('personal_access_tokens', [
            'tokenable_id' => $user->id,
        ]);
    }

    #[Test]
    public function logout_requires_auth()
    {
        $response = $this->postJson('/api/auth/logout');

        $response->assertUnauthorized();
    }

    // ──────────────────────────────────────────────────────────────
    // ME (PROFILE)
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function me_returns_customer_data()
    {
        /** @var User $user */
        $user = User::factory()->create([
            'role' => 'customer',
            'must_change_password' => false,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/auth/me');

        $response->assertOk()
            ->assertJsonPath('data.id', $user->id)
            ->assertJsonPath('data.role', 'customer');
    }

    #[Test]
    public function me_returns_courier_data_with_wallet()
    {
        /** @var User $user */
        $user = User::factory()->create([
            'role' => 'courier',
            'must_change_password' => false,
        ]);
        $courier = Courier::factory()->create(['user_id' => $user->id]);
        $courier->wallet()->create(['balance' => 5000, 'currency' => 'XOF']);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/auth/me');

        $response->assertOk()
            ->assertJsonPath('data.role', 'courier')
            ->assertJsonStructure(['data' => ['courier', 'wallet']]);
    }

    #[Test]
    public function me_returns_pharmacy_data()
    {
        /** @var User $user */
        $user = User::factory()->create([
            'role' => 'pharmacy',
            'must_change_password' => false,
        ]);
        $pharmacy = Pharmacy::factory()->create();
        $user->pharmacies()->attach($pharmacy->id, ['role' => 'owner']);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/auth/me');

        $response->assertOk()
            ->assertJsonPath('data.role', 'pharmacy');
    }

    #[Test]
    public function me_requires_auth()
    {
        $response = $this->getJson('/api/auth/me');

        $response->assertUnauthorized();
    }

    // ──────────────────────────────────────────────────────────────
    // UPDATE PROFILE
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function update_profile_changes_name()
    {
        /** @var User $user */
        $user = User::factory()->create([
            'must_change_password' => false,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/auth/me/update', [
                'name' => 'New Name',
            ]);

        $response->assertOk();
        $this->assertEquals('New Name', $user->fresh()->name);
    }

    #[Test]
    public function update_profile_phone_change_invalidates_verification()
    {
        /** @var User $user */
        $user = User::factory()->create([
            'phone' => '+2250700000000',
            'phone_verified_at' => now(),
            'must_change_password' => false,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/auth/me/update', [
                'phone' => '+2250711111111',
            ]);

        $response->assertOk();
        $this->assertNull($user->fresh()->phone_verified_at);
    }

    // ──────────────────────────────────────────────────────────────
    // AVATAR
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function upload_avatar()
    {
        Storage::fake('public');

        /** @var User $user */
        $user = User::factory()->create([
            'must_change_password' => false,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/auth/avatar', [
                'avatar' => UploadedFile::fake()->image('avatar.jpg', 300, 300),
            ]);

        $response->assertOk();
        $this->assertNotNull($user->fresh()->avatar);
    }

    #[Test]
    public function delete_avatar()
    {
        Storage::fake('public');

        /** @var User $user */
        $user = User::factory()->create([
            'avatar' => 'avatars/old.jpg',
            'must_change_password' => false,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->deleteJson('/api/auth/avatar');

        $response->assertOk();
        $this->assertNull($user->fresh()->avatar);
    }

    // ──────────────────────────────────────────────────────────────
    // SESSIONS
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function sessions_lists_active_tokens()
    {
        $user = User::factory()->create([
            'must_change_password' => false,
        ]);
        $user->createToken('device-1');
        $currentToken = $user->createToken('device-2');

        $response = $this->withHeader('Authorization', 'Bearer ' . $currentToken->plainTextToken)
            ->getJson('/api/auth/sessions');

        $response->assertOk();
    }

    #[Test]
    public function revoke_other_sessions()
    {
        $user = User::factory()->create([
            'must_change_password' => false,
        ]);
        $user->createToken('device-1');
        $currentToken = $user->createToken('current');

        $response = $this->withHeader('Authorization', 'Bearer ' . $currentToken->plainTextToken)
            ->postJson('/api/auth/sessions/revoke-others');

        $response->assertOk();

        // Only the current token should remain
        $this->assertEquals(1, $user->tokens()->count());
    }
}
