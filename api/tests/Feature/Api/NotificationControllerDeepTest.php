<?php

namespace Tests\Feature\Api;

use App\Models\Customer;
use App\Models\Courier;
use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Notifications\DatabaseNotification;
use Illuminate\Support\Str;
use Tests\TestCase;

/**
 * @group deep
 */
class NotificationControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    protected User $customerUser;
    protected User $pharmacyUser;
    protected User $courierUser;

    protected function setUp(): void
    {
        parent::setUp();

        // Customer user
        $this->customerUser = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $this->customerUser->id]);

        // Pharmacy user
        $this->pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->pharmacyUser->pharmacies()->attach($pharmacy->id, ['role' => 'owner']);

        // Courier user
        $this->courierUser = User::factory()->create(['role' => 'courier']);
        Courier::factory()->create(['user_id' => $this->courierUser->id]);
    }

    protected function createNotification(User $user, array $data = [], ?string $readAt = null): DatabaseNotification
    {
        return DatabaseNotification::create([
            'id' => Str::uuid(),
            'type' => $data['type'] ?? 'App\Notifications\NewOrderNotification',
            'notifiable_type' => User::class,
            'notifiable_id' => $user->id,
            'data' => array_merge([
                'title' => 'Test Notification',
                'message' => 'Test message',
            ], $data),
            'read_at' => $readAt,
        ]);
    }

    // ==================== INDEX TESTS ====================

    public function test_index_returns_paginated_notifications(): void
    {
        // Create 25 notifications
        for ($i = 0; $i < 25; $i++) {
            $this->createNotification($this->customerUser, ['title' => "Notification $i"]);
        }

        $response = $this->actingAs($this->customerUser)
            ->getJson('/api/notifications?per_page=10');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(10, 'data.notifications')
            ->assertJsonPath('data.pagination.per_page', 10)
            ->assertJsonPath('data.pagination.total', 25);
    }

    public function test_index_returns_unread_count(): void
    {
        // 3 unread, 2 read
        $this->createNotification($this->customerUser);
        $this->createNotification($this->customerUser);
        $this->createNotification($this->customerUser);
        $this->createNotification($this->customerUser, [], now()->toDateTimeString());
        $this->createNotification($this->customerUser, [], now()->toDateTimeString());

        $response = $this->actingAs($this->customerUser)
            ->getJson('/api/notifications');

        $response->assertOk()
            ->assertJsonPath('data.unread_count', 3);
    }

    public function test_index_respects_max_per_page(): void
    {
        for ($i = 0; $i < 150; $i++) {
            $this->createNotification($this->customerUser);
        }

        $response = $this->actingAs($this->customerUser)
            ->getJson('/api/notifications?per_page=500'); // Exceeds max

        $response->assertOk()
            ->assertJsonPath('data.pagination.per_page', 100); // Capped at 100
    }

    public function test_index_orders_by_created_at_desc(): void
    {
        $old = $this->createNotification($this->customerUser, ['title' => 'Old notification']);
        $old->created_at = now()->subDays(1);
        $old->save();

        $new = $this->createNotification($this->customerUser, ['title' => 'Recent notification']);

        $response = $this->actingAs($this->customerUser)
            ->getJson('/api/notifications');

        $response->assertOk();
        $notifications = $response->json('data.notifications');
        // First notification should be the most recent one
        $this->assertEquals($new->id, $notifications[0]['id']);
    }

    // ==================== UNREAD TESTS ====================

    public function test_unread_returns_only_unread(): void
    {
        $this->createNotification($this->customerUser, ['title' => 'Unread 1']);
        $this->createNotification($this->customerUser, ['title' => 'Unread 2']);
        $this->createNotification($this->customerUser, ['title' => 'Read'], now()->toDateTimeString());

        $response = $this->actingAs($this->customerUser)
            ->getJson('/api/notifications/unread');

        $response->assertOk()
            ->assertJsonCount(2, 'data.notifications')
            ->assertJsonPath('data.unread_count', 2);
    }

    // ==================== MARK AS READ TESTS ====================

    public function test_mark_single_notification_as_read(): void
    {
        $notification = $this->createNotification($this->customerUser);

        $response = $this->actingAs($this->customerUser)
            ->postJson("/api/notifications/{$notification->id}/read");

        $response->assertOk()
            ->assertJsonPath('success', true);

        $notification->refresh();
        $this->assertNotNull($notification->read_at);
    }

    public function test_mark_as_read_fails_for_nonexistent(): void
    {
        $fakeId = Str::uuid();

        $response = $this->actingAs($this->customerUser)
            ->postJson("/api/notifications/{$fakeId}/read");

        $response->assertStatus(404);
    }

    public function test_cannot_mark_other_users_notification(): void
    {
        $notification = $this->createNotification($this->pharmacyUser);

        $response = $this->actingAs($this->customerUser)
            ->postJson("/api/notifications/{$notification->id}/read");

        $response->assertStatus(404);
    }

    // ==================== MARK ALL AS READ TESTS ====================

    public function test_mark_all_as_read(): void
    {
        $this->createNotification($this->customerUser);
        $this->createNotification($this->customerUser);
        $this->createNotification($this->customerUser);

        $this->assertEquals(3, $this->customerUser->unreadNotifications()->count());

        $response = $this->actingAs($this->customerUser)
            ->postJson('/api/notifications/read-all');

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertEquals(0, $this->customerUser->unreadNotifications()->count());
    }

    // ==================== DELETE TESTS ====================

    public function test_delete_notification(): void
    {
        $notification = $this->createNotification($this->customerUser);

        $response = $this->actingAs($this->customerUser)
            ->deleteJson("/api/notifications/{$notification->id}");

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('notifications', ['id' => $notification->id]);
    }

    public function test_delete_fails_for_nonexistent(): void
    {
        $fakeId = Str::uuid();

        $response = $this->actingAs($this->customerUser)
            ->deleteJson("/api/notifications/{$fakeId}");

        $response->assertStatus(404);
    }

    public function test_cannot_delete_other_users_notification(): void
    {
        $notification = $this->createNotification($this->pharmacyUser);

        $response = $this->actingAs($this->customerUser)
            ->deleteJson("/api/notifications/{$notification->id}");

        $response->assertStatus(404);
        $this->assertDatabaseHas('notifications', ['id' => $notification->id]);
    }

    // ==================== FCM TOKEN TESTS ====================

    public function test_update_fcm_token(): void
    {
        $response = $this->actingAs($this->customerUser)
            ->postJson('/api/notifications/fcm-token', [
                'fcm_token' => 'fKxyz123456789ABC',
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertEquals('fKxyz123456789ABC', $this->customerUser->fresh()->fcm_token);
    }

    public function test_update_fcm_token_validation(): void
    {
        $response = $this->actingAs($this->customerUser)
            ->postJson('/api/notifications/fcm-token', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('fcm_token');
    }

    public function test_remove_fcm_token(): void
    {
        $this->customerUser->update(['fcm_token' => 'existing-token']);

        $response = $this->actingAs($this->customerUser)
            ->deleteJson('/api/notifications/fcm-token');

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertNull($this->customerUser->fresh()->fcm_token);
    }

    // ==================== SOUND SETTINGS TESTS ====================

    public function test_customer_gets_customer_sound_settings(): void
    {
        $response = $this->actingAs($this->customerUser)
            ->getJson('/api/notifications/sounds');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'available_sounds',
                    'notification_types',
                ],
            ]);

        // Just verify the response has notification_types as array
        $types = $response->json('data.notification_types');
        $this->assertIsArray($types);
    }

    public function test_pharmacy_gets_pharmacy_sound_settings(): void
    {
        $response = $this->actingAs($this->pharmacyUser)
            ->getJson('/api/notifications/sounds');

        $response->assertOk();

        $types = $response->json('data.notification_types');
        $this->assertArrayHasKey('new_order_received', $types);
        $this->assertArrayHasKey('delivery_assigned', $types);
    }

    public function test_courier_gets_courier_sound_settings(): void
    {
        $response = $this->actingAs($this->courierUser)
            ->getJson('/api/notifications/sounds');

        $response->assertOk();

        $types = $response->json('data.notification_types');
        $this->assertArrayHasKey('delivery_assigned', $types);
        $this->assertArrayHasKey('courier_arrived', $types);
    }
    public function test_get_preferences_returns_default_values(): void
    {
        $response = $this->actingAs($this->customerUser)
            ->getJson('/api/notifications/preferences');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.order_updates', true)
            ->assertJsonPath('data.promotions', true)
            ->assertJsonPath('data.prescriptions', true)
            ->assertJsonPath('data.delivery_alerts', true);
    }

    public function test_get_preferences_merges_existing_user_preferences(): void
    {
        $this->customerUser->update([
            'notification_preferences' => [
                'promotions' => false,
                'delivery_alerts' => false,
            ],
        ]);

        $response = $this->actingAs($this->customerUser)
            ->getJson('/api/notifications/preferences');

        $response->assertOk()
            ->assertJsonPath('data.promotions', false)
            ->assertJsonPath('data.delivery_alerts', false)
            ->assertJsonPath('data.order_updates', true);
    }

    public function test_update_preferences_updates_partial_values_and_keeps_existing(): void
    {
        $this->customerUser->update([
            'notification_preferences' => [
                'promotions' => true,
                'prescriptions' => true,
            ],
        ]);

        $response = $this->actingAs($this->customerUser)
            ->putJson('/api/notifications/preferences', [
                'promotions' => false,
                'delivery_alerts' => false,
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.promotions', false)
            ->assertJsonPath('data.delivery_alerts', false)
            ->assertJsonPath('message', 'Préférences mises à jour');

        $this->customerUser->refresh();
        $this->assertTrue($this->customerUser->notification_preferences['prescriptions']);
    }

    public function test_update_preferences_validates_boolean_values(): void
    {
        $response = $this->actingAs($this->customerUser)
            ->putJson('/api/notifications/preferences', [
                'promotions' => 'not-a-boolean',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['promotions']);
    }
    // ==================== NOTIFICATION FORMATTING TESTS ====================

    public function test_new_order_notification_formatted_correctly(): void
    {
        $this->createNotification($this->pharmacyUser, [
            'type' => 'new_order_received',
            'customer_name' => 'Jean Dupont',
            'items_count' => 3,
            'total_amount' => 15000,
            'currency' => 'FCFA',
            'payment_mode' => 'cash',
            'order_reference' => 'DR-ABC123DEF456',
        ]);

        $response = $this->actingAs($this->pharmacyUser)
            ->getJson('/api/notifications');

        $response->assertOk();
        $notification = $response->json('data.notifications.0');
        
        $this->assertStringContainsString('Jean Dupont', $notification['data']['title']);
    }

    public function test_delivery_timeout_notification_formatted(): void
    {
        $this->createNotification($this->customerUser, [
            'type' => 'delivery_timeout_cancelled',
            'order_reference' => 'DR-TIMEOUT123',
        ]);

        $response = $this->actingAs($this->customerUser)
            ->getJson('/api/notifications');

        $response->assertOk();
    }

    public function test_chat_message_notification_with_sender(): void
    {
        $this->createNotification($this->customerUser, [
            'type' => 'new_chat_message',
            'sender_name' => 'Pharmacie Central',
            'message_preview' => 'Votre commande est prête',
        ]);

        $response = $this->actingAs($this->customerUser)
            ->getJson('/api/notifications');

        $response->assertOk();
    }

    public function test_kyc_status_approved_notification(): void
    {
        $this->createNotification($this->courierUser, [
            'type' => 'kyc_status',
            'status' => 'approved',
        ]);

        $response = $this->actingAs($this->courierUser)
            ->getJson('/api/notifications');

        $response->assertOk();
    }

    public function test_kyc_status_rejected_notification(): void
    {
        $this->createNotification($this->courierUser, [
            'type' => 'kyc_status',
            'status' => 'rejected',
        ]);

        $response = $this->actingAs($this->courierUser)
            ->getJson('/api/notifications');

        $response->assertOk();
    }

    public function test_order_status_confirmed_notification_is_formatted(): void
    {
        $this->createNotification($this->customerUser, [
            'type' => 'order_status',
            'status' => 'confirmed',
            'order_reference' => 'DR-CONFIRMED123',
        ]);

        $response = $this->actingAs($this->customerUser)
            ->getJson('/api/notifications');

        $response->assertOk();
        $notification = $response->json('data.notifications.0');
        $this->assertStringContainsString('confirmée', $notification['data']['body']);
    }

    public function test_delivery_assigned_notification_is_formatted(): void
    {
        $this->createNotification($this->customerUser, [
            'type' => 'delivery_assigned',
            'courier_name' => 'Koffi Livre',
            'order_reference' => 'DR-ASSIGN456',
            'delivery_data' => [
                'pickup_address' => 'Abidjan Plateau',
            ],
        ]);

        $response = $this->actingAs($this->customerUser)
            ->getJson('/api/notifications');

        $response->assertOk();
        $notification = $response->json('data.notifications.0');
        $this->assertStringContainsString('Livreur', $notification['data']['body']);
    }

    public function test_order_delivered_notification_is_formatted(): void
    {
        $this->createNotification($this->pharmacyUser, [
            'type' => 'order_delivered',
            'customer_name' => 'Aminata',
            'order_reference' => 'DR-DELIVERED789',
        ]);

        $response = $this->actingAs($this->pharmacyUser)
            ->getJson('/api/notifications');

        $response->assertOk();
        $notification = $response->json('data.notifications.0');
        $this->assertStringContainsString('Aminata', $notification['data']['title']);
    }

    public function test_payout_completed_notification_is_formatted(): void
    {
        $this->createNotification($this->pharmacyUser, [
            'type' => 'payout_completed',
            'amount' => 25000,
        ]);

        $response = $this->actingAs($this->pharmacyUser)
            ->getJson('/api/notifications');

        $response->assertOk();
        $notification = $response->json('data.notifications.0');
        $this->assertStringContainsString('25000', $notification['data']['body']);
    }

    public function test_unknown_notification_type_falls_back_to_general_message(): void
    {
        $this->createNotification($this->customerUser, [
            'type' => 'unknown_type',
            'body' => 'Fallback body message',
        ]);

        $response = $this->actingAs($this->customerUser)
            ->getJson('/api/notifications');

        $response->assertOk();
        $notification = $response->json('data.notifications.0');
        $this->assertEquals('Notification', $notification['data']['title']);
        $this->assertEquals('Fallback body message', $notification['data']['body']);
    }

    // ==================== AUTHENTICATION TESTS ====================

    public function test_unauthenticated_cannot_access_notifications(): void
    {
        $this->getJson('/api/notifications')->assertStatus(401);
        $this->getJson('/api/notifications/unread')->assertStatus(401);
        $this->postJson('/api/notifications/read-all')->assertStatus(401);
        $this->getJson('/api/notifications/sounds')->assertStatus(401);
    }

    // ==================== EDGE CASES ====================

    public function test_empty_notifications_list(): void
    {
        $response = $this->actingAs($this->customerUser)
            ->getJson('/api/notifications');

        $response->assertOk()
            ->assertJsonPath('data.notifications', [])
            ->assertJsonPath('data.unread_count', 0);
    }

    public function test_notification_with_minimal_data(): void
    {
        $this->createNotification($this->customerUser, []);

        $response = $this->actingAs($this->customerUser)
            ->getJson('/api/notifications');

        $response->assertOk()
            ->assertJsonCount(1, 'data.notifications');
    }

    public function test_notification_with_nested_order_data(): void
    {
        $this->createNotification($this->pharmacyUser, [
            'order_data' => [
                'customer_name' => 'Nested Customer',
                'items_count' => 5,
                'total_amount' => 25000,
            ],
        ]);

        $response = $this->actingAs($this->pharmacyUser)
            ->getJson('/api/notifications');

        $response->assertOk();
        $notification = $response->json('data.notifications.0');
        $this->assertIsArray($notification['data']);
    }

    // ==================== HELPER OVERRIDE FOR NOTIFICATION TYPE ====================

    protected function createNotificationWithType(User $user, array $data, string $type): DatabaseNotification
    {
        return DatabaseNotification::create([
            'id' => Str::uuid(),
            'type' => $type,
            'notifiable_type' => User::class,
            'notifiable_id' => $user->id,
            'data' => $data,
            'read_at' => null,
        ]);
    }
}
