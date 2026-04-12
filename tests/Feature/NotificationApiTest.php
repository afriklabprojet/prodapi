<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\NewOrderNotification;
use App\Notifications\OrderStatusNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class NotificationApiTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create();
    }

    #[Test]
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

    #[Test]
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

    #[Test]
    public function user_can_mark_all_as_read()
    {
        Sanctum::actingAs($this->user);

        $response = $this->postJson('/api/notifications/read-all');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);
    }

    #[Test]
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

    #[Test]
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

    #[Test]
    public function unauthenticated_user_cannot_access_notifications()
    {
        $response = $this->getJson('/api/notifications');

        $response->assertStatus(401);
    }

    #[Test]
    public function user_can_mark_single_notification_as_read()
    {
        $notificationId = \Illuminate\Support\Str::uuid()->toString();
        
        \Illuminate\Support\Facades\DB::table('notifications')->insert([
            'id' => $notificationId,
            'type' => 'App\Notifications\TestNotification',
            'notifiable_type' => 'App\Models\User',
            'notifiable_id' => $this->user->id,
            'data' => json_encode(['message' => 'Test notification']),
            'read_at' => null,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Sanctum::actingAs($this->user);

        $response = $this->postJson("/api/notifications/{$notificationId}/read");

        $response->assertStatus(200)
            ->assertJson(['success' => true]);

        $this->assertDatabaseHas('notifications', [
            'id' => $notificationId,
        ]);
        
        // Verify read_at is not null
        $notification = \Illuminate\Support\Facades\DB::table('notifications')
            ->where('id', $notificationId)
            ->first();
        $this->assertNotNull($notification->read_at);
    }

    #[Test]
    public function user_can_delete_notification()
    {
        $notificationId = \Illuminate\Support\Str::uuid()->toString();
        
        \Illuminate\Support\Facades\DB::table('notifications')->insert([
            'id' => $notificationId,
            'type' => 'App\Notifications\TestNotification',
            'notifiable_type' => 'App\Models\User',
            'notifiable_id' => $this->user->id,
            'data' => json_encode(['message' => 'Delete me']),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Sanctum::actingAs($this->user);

        $response = $this->deleteJson("/api/notifications/{$notificationId}");

        $response->assertStatus(200)
            ->assertJson(['success' => true]);

        $this->assertDatabaseMissing('notifications', [
            'id' => $notificationId,
        ]);
    }

    #[Test]
    public function user_cannot_access_other_users_notifications()
    {
        $otherUser = User::factory()->create();
        $notificationId = \Illuminate\Support\Str::uuid()->toString();
        
        \Illuminate\Support\Facades\DB::table('notifications')->insert([
            'id' => $notificationId,
            'type' => 'App\Notifications\TestNotification',
            'notifiable_type' => 'App\Models\User',
            'notifiable_id' => $otherUser->id,
            'data' => json_encode(['message' => 'Not your notification']),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Sanctum::actingAs($this->user);

        $response = $this->postJson("/api/notifications/{$notificationId}/read");

        $response->assertStatus(404);
    }

    #[Test]
    public function user_can_get_sound_settings()
    {
        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/notifications/sounds');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'available_sounds',
                    'notification_types',
                ],
            ]);
    }

    #[Test]
    public function fcm_token_validation_fails_without_token()
    {
        Sanctum::actingAs($this->user);

        $response = $this->postJson('/api/notifications/fcm-token', []);

        $response->assertStatus(422);
    }

    #[Test]
    public function notifications_are_paginated()
    {
        // Create 25 notifications
        for ($i = 0; $i < 25; $i++) {
            \Illuminate\Support\Facades\DB::table('notifications')->insert([
                'id' => \Illuminate\Support\Str::uuid(),
                'type' => 'App\Notifications\TestNotification',
                'notifiable_type' => 'App\Models\User',
                'notifiable_id' => $this->user->id,
                'data' => json_encode(['message' => "Notification {$i}"]),
                'created_at' => now()->subMinutes($i),
                'updated_at' => now()->subMinutes($i),
            ]);
        }

        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/notifications?per_page=10');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'notifications',
                    'unread_count',
                    'pagination' => [
                        'current_page',
                        'last_page',
                        'per_page',
                        'total',
                    ],
                ],
            ]);

        $data = $response->json('data');
        $this->assertCount(10, $data['notifications']);
        $this->assertEquals(25, $data['pagination']['total']);
    }

    #[Test]
    public function notifications_unread_count_is_accurate()
    {
        // Create 3 read and 2 unread notifications
        for ($i = 0; $i < 3; $i++) {
            \Illuminate\Support\Facades\DB::table('notifications')->insert([
                'id' => \Illuminate\Support\Str::uuid(),
                'type' => 'App\Notifications\TestNotification',
                'notifiable_type' => 'App\Models\User',
                'notifiable_id' => $this->user->id,
                'data' => json_encode(['message' => "Read notification {$i}"]),
                'read_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
        for ($i = 0; $i < 2; $i++) {
            \Illuminate\Support\Facades\DB::table('notifications')->insert([
                'id' => \Illuminate\Support\Str::uuid(),
                'type' => 'App\Notifications\TestNotification',
                'notifiable_type' => 'App\Models\User',
                'notifiable_id' => $this->user->id,
                'data' => json_encode(['message' => "Unread notification {$i}"]),
                'read_at' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/notifications');

        $response->assertStatus(200);
        $this->assertEquals(2, $response->json('data.unread_count'));
    }
}
