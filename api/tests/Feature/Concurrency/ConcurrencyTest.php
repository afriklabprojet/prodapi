<?php

namespace Tests\Feature\Concurrency;

use App\Models\Courier;
use App\Models\Customer;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

/**
 * Tests de concurrence et conditions de course.
 * Vérifie l'intégrité des données lors d'opérations simultanées.
 */
class ConcurrencyTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Notification::fake();
    }

    // ─── DOUBLE DELIVERY ACCEPTANCE ─────────────────────────────────────────

    public function test_only_one_courier_can_accept_delivery(): void
    {
        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $customer = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $customer->id]);

        $order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $customer->id,
            'status' => 'ready',
        ]);

        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => null,
            'status' => 'pending',
        ]);

        // Two couriers
        /** @var User $courier1User */
        $courier1User = User::factory()->create(['role' => 'courier']);
        $courier1 = Courier::factory()->create(['user_id' => $courier1User->id, 'status' => 'available']);
        /** @var User $courier2User */
        $courier2User = User::factory()->create(['role' => 'courier']);
        $courier2 = Courier::factory()->create(['user_id' => $courier2User->id, 'status' => 'available']);

        // First courier accepts
        $response1 = $this->actingAs($courier1User)->postJson("/api/courier/deliveries/{$delivery->id}/accept");

        // Second courier tries to accept same delivery
        $response2 = $this->actingAs($courier2User)->postJson("/api/courier/deliveries/{$delivery->id}/accept");

        // Exactly one should succeed
        $success = ($response1->status() === 200 ? 1 : 0) + ($response2->status() === 200 ? 1 : 0);
        $this->assertLessThanOrEqual(1, $success, 'At most one courier should successfully accept');

        // Delivery should have exactly one courier
        $delivery->refresh();
        $this->assertNotNull($delivery->courier_id);
    }

    // ─── DOUBLE REFUND ──────────────────────────────────────────────────────

    public function test_cannot_create_duplicate_refund(): void
    {
        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        /** @var User $user */
        $user = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $user->id]);

        $order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $user->id,
            'status' => 'delivered',
            'total_amount' => 5000,
        ]);

        // First refund request
        $response1 = $this->actingAs($user)->postJson('/api/customer/refunds', [
            'order_id' => $order->id,
            'reason' => 'Premier remboursement',
            'type' => 'full',
        ]);

        $response1->assertStatus(201);

        // Duplicate refund
        $response2 = $this->actingAs($user)->postJson('/api/customer/refunds', [
            'order_id' => $order->id,
            'reason' => 'Deuxieme tentative',
            'type' => 'full',
        ]);

        $response2->assertStatus(422);

        // Only one refund should exist
        $count = DB::table('refunds')->where('order_id', $order->id)->count();
        $this->assertEquals(1, $count);
    }

    // ─── STOCK CONSISTENCY ──────────────────────────────────────────────────

    public function test_product_stock_cannot_go_negative(): void
    {
        $pharmacy = Pharmacy::factory()->create(['status' => 'approved', 'is_active' => true, 'is_open' => true]);
        /** @var User $pharmacyUser */
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy->users()->attach($pharmacyUser->id, ['role' => 'titulaire']);

        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'stock_quantity' => 1,
            'price' => 1000,
            'is_available' => true,
        ]);

        /** @var User $customer */
        $customer = User::factory()->create(['role' => 'customer', 'phone_verified_at' => now()]);
        Customer::factory()->create(['user_id' => $customer->id]);

        // Order with quantity > stock
        $response = $this->actingAs($customer)->postJson('/api/customer/orders', [
            'pharmacy_id' => $pharmacy->id,
            'items' => [
                ['id' => $product->id, 'name' => $product->name, 'quantity' => 5, 'price' => $product->price],
            ],
            'delivery_address' => '123 Rue Test',
            'customer_phone' => '+2250700000000',
            'payment_mode' => 'cash',
        ]);

        // Either accepts (and stock is managed) or rejects (stock insufficient)
        if ($response->status() === 201) {
            $product->refresh();
            $this->assertGreaterThanOrEqual(0, $product->stock_quantity, 'Stock should not go negative');
        } else {
            // Order was rejected — stock should remain unchanged
            $product->refresh();
            $this->assertEquals(1, $product->stock_quantity, 'Stock unchanged when order rejected');
        }
    }

    // ─── PROMO CODE USAGE LIMITS ────────────────────────────────────────────

    public function test_promo_code_respects_max_uses(): void
    {
        DB::table('promo_codes')->insert([
            'code' => 'ONCE',
            'description' => 'Single use',
            'type' => 'fixed',
            'value' => 500,
            'max_uses' => 1,
            'max_uses_per_user' => 1,
            'current_uses' => 0,
            'is_active' => true,
            'starts_at' => now()->subDay(),
            'expires_at' => now()->addMonth(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        /** @var User $user1 */
        $user1 = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $user1->id]);

        /** @var User $user2 */
        $user2 = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $user2->id]);

        // First user validates
        $response1 = $this->actingAs($user1)->postJson('/api/customer/promo-codes/validate', [
            'code' => 'ONCE',
            'order_amount' => 5000,
        ]);

        // Manually increment usage count (normally done during order creation)
        DB::table('promo_codes')->where('code', 'ONCE')->update(['current_uses' => 1]);

        // Second user should be blocked
        $response2 = $this->actingAs($user2)->postJson('/api/customer/promo-codes/validate', [
            'code' => 'ONCE',
            'order_amount' => 5000,
        ]);

        $response2->assertStatus(422);
    }

    // ─── ORDER STATUS TRANSITION INTEGRITY ──────────────────────────────────

    public function test_order_cannot_skip_states(): void
    {
        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        /** @var User $pharmacyUser */
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy->users()->attach($pharmacyUser->id, ['role' => 'titulaire']);

        $order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => User::factory()->create(['role' => 'customer'])->id,
            'status' => 'pending',
        ]);

        // Can't mark ready before confirming
        $response = $this->actingAs($pharmacyUser)->postJson("/api/pharmacy/orders/{$order->id}/ready");

        $this->assertContains($response->status(), [400, 422]);

        $order->refresh();
        $this->assertEquals('pending', $order->status);
    }

    public function test_delivery_cannot_skip_from_pending_to_picked_up(): void
    {
        /** @var User $courierUser */
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);

        $order = Order::factory()->create([
            'status' => 'ready',
        ]);
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
            'status' => 'pending',
        ]);

        // Can't pickup without accepting first
        $response = $this->actingAs($courierUser)->postJson("/api/courier/deliveries/{$delivery->id}/pickup");

        $this->assertContains($response->status(), [400, 422]);
    }

    // ─── DOUBLE CONFIRM ─────────────────────────────────────────────────────

    public function test_pharmacy_cannot_double_confirm(): void
    {
        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        /** @var User $pharmacyUser */
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy->users()->attach($pharmacyUser->id, ['role' => 'titulaire']);

        $order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => User::factory()->create(['role' => 'customer'])->id,
            'status' => 'pending',
            'payment_mode' => 'cash',
        ]);

        // First confirm
        $this->actingAs($pharmacyUser)->postJson("/api/pharmacy/orders/{$order->id}/confirm")
            ->assertOk();

        // Second confirm
        $response = $this->actingAs($pharmacyUser)->postJson("/api/pharmacy/orders/{$order->id}/confirm");
        $this->assertContains($response->status(), [400, 409, 422]);
    }
}
