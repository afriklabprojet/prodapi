<?php

namespace Tests\Feature\Api;

use App\Models\Customer;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NotificationControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $this->user->id]);
    }

    public function test_user_can_list_notifications(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/notifications');

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_user_can_list_unread_notifications(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/notifications/unread');

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_user_can_mark_all_as_read(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/notifications/read-all');

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_user_can_update_fcm_token(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/notifications/fcm-token', [
            'fcm_token' => 'test-fcm-token-123456',
        ]);

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_fcm_token_requires_string(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/notifications/fcm-token', []);

        $response->assertStatus(422)->assertJsonValidationErrors('fcm_token');
    }

    public function test_user_can_remove_fcm_token(): void
    {
        $response = $this->actingAs($this->user)->deleteJson('/api/notifications/fcm-token');

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_user_can_get_sound_settings(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/notifications/sounds');

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_user_can_get_preferences(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/notifications/preferences');

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_user_can_update_preferences(): void
    {
        $response = $this->actingAs($this->user)->putJson('/api/notifications/preferences', [
            'order_updates' => true,
            'promotions' => false,
        ]);

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_unauthenticated_cannot_access_notifications(): void
    {
        $response = $this->getJson('/api/notifications');

        $response->assertStatus(401);
    }
}
