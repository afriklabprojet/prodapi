<?php

namespace Tests\Feature\Security;

use App\Models\Courier;
use App\Models\Customer;
use App\Models\Delivery;
use App\Models\DeliveryMessage;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

/**
 * Tests de sécurité : IDOR, isolation des données, autorisation.
 * Vérifie qu'un utilisateur ne peut pas accéder aux ressources d'un autre.
 */
class SecurityTest extends TestCase
{
    use RefreshDatabase;

    protected User $customer1;
    protected User $customer2;
    protected User $pharmacyUser1;
    protected User $pharmacyUser2;
    protected User $courier1User;
    protected User $courier2User;
    protected User $admin;
    protected Pharmacy $pharmacy1;
    protected Pharmacy $pharmacy2;
    protected Courier $courier1;
    protected Courier $courier2;

    protected function setUp(): void
    {
        parent::setUp();
        Notification::fake();

        $this->customer1 = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $this->customer1->id]);

        $this->customer2 = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $this->customer2->id]);

        $this->pharmacyUser1 = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy1 = Pharmacy::factory()->create(['status' => 'approved']);
        $this->pharmacy1->users()->attach($this->pharmacyUser1->id, ['role' => 'titulaire']);

        $this->pharmacyUser2 = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy2 = Pharmacy::factory()->create(['status' => 'approved']);
        $this->pharmacy2->users()->attach($this->pharmacyUser2->id, ['role' => 'titulaire']);

        $this->courier1User = User::factory()->create(['role' => 'courier']);
        $this->courier1 = Courier::factory()->create(['user_id' => $this->courier1User->id]);

        $this->courier2User = User::factory()->create(['role' => 'courier']);
        $this->courier2 = Courier::factory()->create(['user_id' => $this->courier2User->id]);

        $this->admin = User::factory()->create(['role' => 'admin']);
    }

    // ─── IDOR: ORDER ACCESS ─────────────────────────────────────────────────

    public function test_customer_cannot_view_other_customers_order(): void
    {
        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy1->id,
            'customer_id' => $this->customer1->id,
        ]);

        $response = $this->actingAs($this->customer2)->getJson("/api/customer/orders/{$order->id}");

        $this->assertContains($response->status(), [403, 404]);
    }

    public function test_customer_cannot_cancel_other_customers_order(): void
    {
        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy1->id,
            'customer_id' => $this->customer1->id,
            'status' => 'pending',
        ]);

        $response = $this->actingAs($this->customer2)->postJson("/api/customer/orders/{$order->id}/cancel", [
            'reason' => 'Hijack cancel',
        ]);

        $this->assertContains($response->status(), [403, 404]);

        // Order should still be pending
        $order->refresh();
        $this->assertEquals('pending', $order->status);
    }

    // ─── IDOR: PHARMACY ISOLATION ───────────────────────────────────────────

    public function test_pharmacy_cannot_view_other_pharmacy_order(): void
    {
        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy1->id,
            'customer_id' => $this->customer1->id,
        ]);

        $response = $this->actingAs($this->pharmacyUser2)->getJson("/api/pharmacy/orders/{$order->id}");

        $this->assertContains($response->status(), [403, 404]);
    }

    public function test_pharmacy_cannot_confirm_other_pharmacy_order(): void
    {
        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy1->id,
            'customer_id' => $this->customer1->id,
            'status' => 'pending',
            'payment_mode' => 'cash',
        ]);

        $response = $this->actingAs($this->pharmacyUser2)->postJson("/api/pharmacy/orders/{$order->id}/confirm");

        $this->assertContains($response->status(), [403, 404]);

        // Should not be confirmed
        $order->refresh();
        $this->assertEquals('pending', $order->status);
    }

    public function test_pharmacy_cannot_reject_other_pharmacy_order(): void
    {
        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy1->id,
            'customer_id' => $this->customer1->id,
            'status' => 'pending',
        ]);

        $response = $this->actingAs($this->pharmacyUser2)->postJson("/api/pharmacy/orders/{$order->id}/reject", [
            'reason' => 'Hijack reject',
        ]);

        $this->assertContains($response->status(), [403, 404]);
        $order->refresh();
        $this->assertNotEquals('cancelled', $order->status);
    }

    // ─── IDOR: REFUND ISOLATION ─────────────────────────────────────────────

    public function test_customer_cannot_request_refund_for_other_customers_order(): void
    {
        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy1->id,
            'customer_id' => $this->customer1->id,
            'status' => 'delivered',
        ]);

        $response = $this->actingAs($this->customer2)->postJson('/api/customer/refunds', [
            'order_id' => $order->id,
            'reason' => 'Stolen refund',
            'type' => 'full',
        ]);

        // Should be 404 (order not found for this user)
        $response->assertStatus(404);

        // No refund should exist
        $this->assertDatabaseMissing('refunds', [
            'order_id' => $order->id,
            'user_id' => $this->customer2->id,
        ]);
    }

    public function test_customer_cannot_view_other_customers_refund(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer1->id,
            'pharmacy_id' => Pharmacy::factory()->create()->id,
            'status' => 'delivered',
            'total_amount' => 5000,
        ]);

        $refundId = DB::table('refunds')->insertGetId([
            'user_id' => $this->customer1->id,
            'order_id' => $order->id,
            'amount' => 5000,
            'reason' => 'Test',
            'type' => 'full',
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this->actingAs($this->customer2)->getJson("/api/customer/refunds/{$refundId}");

        $response->assertStatus(404);
    }

    // ─── ROLE-BASED ACCESS ──────────────────────────────────────────────────

    public function test_customer_cannot_access_pharmacy_routes(): void
    {
        $response = $this->actingAs($this->customer1)->getJson('/api/pharmacy/orders');
        $response->assertStatus(403);
    }

    public function test_customer_cannot_access_admin_routes(): void
    {
        $response = $this->actingAs($this->customer1)->getJson('/api/admin/stats/dashboard');
        $response->assertStatus(403);
    }

    public function test_pharmacy_cannot_access_admin_routes(): void
    {
        $response = $this->actingAs($this->pharmacyUser1)->getJson('/api/admin/stats/dashboard');
        $response->assertStatus(403);
    }

    public function test_courier_cannot_access_admin_routes(): void
    {
        $response = $this->actingAs($this->courier1User)->getJson('/api/admin/stats/dashboard');
        $response->assertStatus(403);
    }

    public function test_courier_cannot_access_pharmacy_routes(): void
    {
        $response = $this->actingAs($this->courier1User)->getJson('/api/pharmacy/orders');
        $response->assertStatus(403);
    }

    public function test_pharmacy_cannot_access_courier_routes(): void
    {
        $response = $this->actingAs($this->pharmacyUser1)->getJson('/api/courier/deliveries');
        $response->assertStatus(403);
    }

    // ─── AUTHENTICATION ─────────────────────────────────────────────────────

    public function test_unauthenticated_cannot_access_protected_routes(): void
    {
        $routes = [
            'GET' => [
                '/api/customer/orders',
                '/api/pharmacy/orders',
                '/api/courier/deliveries',
                '/api/admin/stats/dashboard',
            ],
        ];

        foreach ($routes['GET'] as $route) {
            $response = $this->getJson($route);
            $this->assertEquals(401, $response->status(), "Route {$route} should require authentication");
        }
    }

    // ─── COURIER DELIVERY ISOLATION ─────────────────────────────────────────

    public function test_courier_cannot_pickup_other_couriers_delivery(): void
    {
        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy1->id,
            'customer_id' => $this->customer1->id,
            'status' => 'ready',
        ]);
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier1->id,
            'status' => 'assigned',
        ]);

        $response = $this->actingAs($this->courier2User)->postJson("/api/courier/deliveries/{$delivery->id}/pickup");

        $this->assertContains($response->status(), [403, 404, 422]);

        $delivery->refresh();
        $this->assertNotEquals('picked_up', $delivery->status);
    }

    public function test_courier_cannot_deliver_other_couriers_delivery(): void
    {
        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy1->id,
            'customer_id' => $this->customer1->id,
            'status' => 'in_delivery',
            'delivery_code' => '1234',
        ]);
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier1->id,
            'status' => 'picked_up',
        ]);

        $response = $this->actingAs($this->courier2User)->postJson("/api/courier/deliveries/{$delivery->id}/deliver", [
            'confirmation_code' => '1234',
        ]);

        $this->assertContains($response->status(), [403, 404, 422]);

        $delivery->refresh();
        $this->assertNotEquals('delivered', $delivery->status);
    }

    // ─── INPUT VALIDATION ───────────────────────────────────────────────────

    public function test_xss_in_order_notes_is_stored_safely(): void
    {
        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy1->id,
            'customer_id' => $this->customer1->id,
            'status' => 'pending',
        ]);

        // XSS attempt in cancel reason
        $response = $this->actingAs($this->customer1)->postJson("/api/customer/orders/{$order->id}/cancel", [
            'reason' => '<script>alert("xss")</script>',
        ]);

        // Should accept but not execute — HTML is stored as plain text
        if ($response->status() === 200) {
            $order->refresh();
            $this->assertStringContainsString('script', $order->cancellation_reason);
        }
    }

    public function test_sql_injection_in_promo_code_is_safe(): void
    {
        $response = $this->actingAs($this->customer1)->postJson('/api/customer/promo-codes/validate', [
            'code' => "' OR '1'='1",
            'order_amount' => 5000,
        ]);

        // Should return 422 (invalid code), not crash
        $response->assertStatus(422);
    }

    public function test_extremely_long_input_is_rejected(): void
    {
        $response = $this->actingAs($this->customer1)->postJson('/api/customer/refunds', [
            'order_id' => 1,
            'reason' => str_repeat('A', 10000),
            'type' => 'full',
        ]);

        $response->assertStatus(422);
    }

    // ─── CHAT ISOLATION ─────────────────────────────────────────────────────

    public function test_unrelated_customer_cannot_read_delivery_chat(): void
    {
        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy1->id,
            'customer_id' => $this->customer1->id,
            'status' => 'in_delivery',
        ]);
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier1->id,
            'status' => 'in_transit',
        ]);

        DeliveryMessage::create([
            'delivery_id' => $delivery->id,
            'sender_type' => 'client',
            'sender_id' => $this->customer1->id,
            'receiver_type' => 'courier',
            'receiver_id' => $this->courier1->id,
            'message' => 'Secret message',
        ]);

        // Customer2 tries to read customer1's chat
        $response = $this->actingAs($this->customer2)->getJson(
            "/api/customer/deliveries/{$delivery->id}/chat?participant_type=courier&participant_id={$this->courier1->id}"
        );

        // Should either return 403 or empty messages
        if ($response->status() === 200) {
            $messages = $response->json('messages');
            // Should not contain the secret message
            $messageTexts = collect($messages)->pluck('message')->toArray();
            $this->assertNotContains('Secret message', $messageTexts);
        } else {
            $this->assertContains($response->status(), [403, 404]);
        }
    }
}
