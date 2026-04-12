<?php

namespace Tests\Feature\Api;

use App\Models\Customer;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class RefundControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Order $order;

    protected function setUp(): void
    {
        parent::setUp();

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->user = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $this->user->id]);

        $this->order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $this->user->id,
            'status' => 'delivered',
            'total_amount' => 5000,
        ]);
    }

    public function test_customer_can_list_refunds(): void
    {
        DB::table('refunds')->insert([
            'user_id' => $this->user->id,
            'order_id' => $this->order->id,
            'amount' => 5000,
            'reason' => 'Produit endommage',
            'type' => 'full',
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this->actingAs($this->user)->getJson('/api/customer/refunds');

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_customer_can_view_refund_detail(): void
    {
        $id = DB::table('refunds')->insertGetId([
            'user_id' => $this->user->id,
            'order_id' => $this->order->id,
            'amount' => 5000,
            'reason' => 'Produit casse',
            'type' => 'full',
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this->actingAs($this->user)->getJson("/api/customer/refunds/{$id}");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.type', 'full');
    }

    public function test_customer_cannot_view_other_user_refund(): void
    {
        $otherUser = User::factory()->create(['role' => 'customer']);
        $id = DB::table('refunds')->insertGetId([
            'user_id' => $otherUser->id,
            'order_id' => $this->order->id,
            'amount' => 5000,
            'reason' => 'Test',
            'type' => 'full',
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this->actingAs($this->user)->getJson("/api/customer/refunds/{$id}");

        $response->assertStatus(404);
    }

    public function test_customer_can_request_full_refund(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/customer/refunds', [
            'order_id' => $this->order->id,
            'reason' => 'Produit endommage',
            'type' => 'full',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.type', 'full')
            ->assertJsonPath('data.status', 'pending');

        $this->assertDatabaseHas('refunds', [
            'order_id' => $this->order->id,
            'user_id' => $this->user->id,
            'type' => 'full',
            'status' => 'pending',
        ]);
    }

    public function test_customer_can_request_partial_refund(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/customer/refunds', [
            'order_id' => $this->order->id,
            'reason' => 'Produit manquant',
            'type' => 'partial',
            'amount' => 2000,
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.type', 'partial');
    }

    public function test_partial_refund_capped_at_order_amount(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/customer/refunds', [
            'order_id' => $this->order->id,
            'reason' => 'Over-claim',
            'type' => 'partial',
            'amount' => 99999,
        ]);

        $response->assertStatus(201);
        $this->assertEquals(5000, $response->json('data.amount'));
    }

    public function test_duplicate_refund_returns_422(): void
    {
        $this->actingAs($this->user)->postJson('/api/customer/refunds', [
            'order_id' => $this->order->id,
            'reason' => 'Test',
            'type' => 'full',
        ]);

        $response = $this->actingAs($this->user)->postJson('/api/customer/refunds', [
            'order_id' => $this->order->id,
            'reason' => 'Retry',
            'type' => 'full',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_refund_for_other_users_order_returns_404(): void
    {
        $otherUser = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $otherUser->id]);
        $otherOrder = Order::factory()->create([
            'pharmacy_id' => $this->order->pharmacy_id,
            'customer_id' => $otherUser->id,
            'status' => 'delivered',
        ]);

        $response = $this->actingAs($this->user)->postJson('/api/customer/refunds', [
            'order_id' => $otherOrder->id,
            'reason' => 'Steal refund',
            'type' => 'full',
        ]);

        $response->assertStatus(404)
            ->assertJsonPath('success', false);
    }

    public function test_partial_refund_requires_amount(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/customer/refunds', [
            'order_id' => $this->order->id,
            'reason' => 'Produit manquant',
            'type' => 'partial',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('amount');
    }

    public function test_refund_validates_order_exists(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/customer/refunds', [
            'order_id' => 99999,
            'reason' => 'Test',
            'type' => 'full',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('order_id');
    }

    public function test_refund_validates_reason_required(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/customer/refunds', [
            'order_id' => $this->order->id,
            'type' => 'full',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('reason');
    }

    public function test_refund_validates_type(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/customer/refunds', [
            'order_id' => $this->order->id,
            'reason' => 'Test',
            'type' => 'invalid',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('type');
    }

    public function test_unauthenticated_cannot_request_refund(): void
    {
        $response = $this->postJson('/api/customer/refunds', [
            'order_id' => $this->order->id,
            'reason' => 'Test',
            'type' => 'full',
        ]);

        $response->assertStatus(401);
    }
}
