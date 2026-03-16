<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\NewOrderNotification;
use App\Notifications\OrderStatusNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NotificationApiTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create();
    }

    /** @test */
    public function user_can_list_notifications()
    {
        // Create some notifications for the user
        \Illuminate\Support\Facades\DB::table('notifications')->insert([
            'id' => \Illuminate\Support\Str::uuid(),
            'type' => 'App\Notifications\TestNotification',
            'notifiable_type' => 'App\Models\User',
            'notifiable_id' => $this->user->id,
            'data' => json_encode(['message' => 'Test notification 1']),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/notifications');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data',
            ]);
    }

    /** @test */
    public function user_can_get_unread_notifications()
    {
        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/notifications/unread');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data',
            ]);
    }

    /** @test */
    public function user_can_mark_all_as_read()
    {
        Sanctum::actingAs($this->user);

        $response = $this->postJson('/api/notifications/read-all');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);
    }

    /** @test */
    public function user_can_update_fcm_token()
    {
        Sanctum::actingAs($this->user);

        $response = $this->postJson('/api/notifications/fcm-token', [
            'fcm_token' => 'test_fcm_token_12345',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertDatabaseHas('users', [
            'id' => $this->user->id,
            'fcm_token' => 'test_fcm_token_12345',
        ]);
    }

    /** @test */
    public function user_can_remove_fcm_token()
    {
        $this->user->update(['fcm_token' => 'existing_token']);

        Sanctum::actingAs($this->user);

        $response = $this->deleteJson('/api/notifications/fcm-token');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertDatabaseHas('users', [
            'id' => $this->user->id,
            'fcm_token' => null,
        ]);
    }

    /** @test */
    public function unauthenticated_user_cannot_access_notifications()
    {
        $response = $this->getJson('/api/notifications');

        $response->assertStatus(401);
    }
}
