<?php

namespace Tests\Feature\Api\Customer;

use App\Models\User;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Product;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OrderControllerTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private Pharmacy $pharmacy;
    private string $token;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->user = User::factory()->create([
            'role' => 'customer',
        ]);
        
        $this->pharmacy = Pharmacy::factory()->create([
            'is_active' => true,
        ]);
        
        $this->token = $this->user->createToken('test-token')->plainTextToken;
    }

    /** @test */
    public function user_can_list_their_orders()
    {
        Order::factory()->count(3)->create([
            'customer_id' => $this->user->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->getJson('/api/customer/orders');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data',
                'meta' => ['current_page', 'last_page', 'per_page', 'total'],
            ]);
    }

    /** @test */
    public function user_can_show_specific_order()
    {
        $order = Order::factory()->create([
            'customer_id' => $this->user->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->getJson("/api/customer/orders/{$order->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);
    }

    /** @test */
    public function user_cannot_see_other_users_orders()
    {
        $otherUser = User::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $otherUser->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->getJson("/api/customer/orders/{$order->id}");

        $response->assertStatus(404);
    }

    /** @test */
    public function user_can_cancel_pending_order()
    {
        $order = Order::factory()->create([
            'customer_id' => $this->user->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'pending',
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->postJson("/api/customer/orders/{$order->id}/cancel", [
                'reason' => 'Je ne veux plus cette commande',
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'status' => 'cancelled',
        ]);
    }

    /** @test */
    public function user_cannot_cancel_delivered_order()
    {
        $order = Order::factory()->create([
            'customer_id' => $this->user->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'delivered',
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->postJson("/api/customer/orders/{$order->id}/cancel", [
                'reason' => 'Test',
            ]);

        // Policy denies cancel for delivered orders (403 Forbidden)
        $response->assertStatus(403);
    }

    /** @test */
    public function orders_are_paginated()
    {
        Order::factory()->count(20)->create([
            'customer_id' => $this->user->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->getJson('/api/customer/orders?per_page=10');

        $response->assertStatus(200)
            ->assertJsonPath('meta.per_page', 10);
    }

    /** @test */
    public function max_per_page_is_limited_to_50()
    {
        Order::factory()->count(60)->create([
            'customer_id' => $this->user->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->getJson('/api/customer/orders?per_page=100');

        $response->assertStatus(200)
            ->assertJsonPath('meta.per_page', 50);
    }

    /** @test */
    public function order_includes_pharmacy_info()
    {
        Order::factory()->create([
            'customer_id' => $this->user->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->getJson('/api/customer/orders');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'pharmacy' => ['id', 'name'],
                    ],
                ],
            ]);
    }
}
