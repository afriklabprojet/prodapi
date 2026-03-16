<?php

namespace Tests\Feature\Api\Pharmacy;

use App\Models\User;
use App\Models\Pharmacy;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Customer;
use App\Models\Delivery;
use App\Services\WaitingFeeService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OrderControllerTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $pharmacy;
    protected $customer;
    protected $order;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
        ]);
        $this->pharmacy->users()->attach($this->user->id);

        $this->customer = Customer::factory()->create();
        $this->order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $this->customer->id,
            'status' => 'pending',
            'total_amount' => 5000,
        ]);
    }

    /** @test */
    public function pharmacy_can_list_orders()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/pharmacy/orders');

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'data' => [
                    '*' => [
                        'id',
                        'reference',
                        'customer',
                        'status',
                        'payment_mode',
                        'total_amount',
                        'items_count',
                        'delivery_address',
                    ],
                ],
            ]);
    }

    /** @test */
    public function pharmacy_can_filter_orders_by_status()
    {
        // Create orders with different statuses
        Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $this->customer->id,
            'status' => 'confirmed',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/pharmacy/orders?status=pending');

        $response->assertOk();
        foreach ($response->json('data') as $order) {
            $this->assertEquals('pending', $order['status']);
        }
    }

    /** @test */
    public function pharmacy_can_view_order_details()
    {
        // Create order items
        OrderItem::factory()->create([
            'order_id' => $this->order->id,
            'product_name' => 'Doliprane',
            'quantity' => 2,
            'unit_price' => 1500,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/pharmacy/orders/{$this->order->id}");

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'data' => [
                    'id',
                    'reference',
                    'status',
                    'customer',
                    'items',
                    'subtotal',
                    'delivery_fee',
                    'total_amount',
                    'payment_mode',
                    'delivery_address',
                ],
            ]);
    }

    /** @test */
    public function pharmacy_can_confirm_pending_order()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/pharmacy/orders/{$this->order->id}/confirm");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Commande confirmée avec succès');

        $this->assertDatabaseHas('orders', [
            'id' => $this->order->id,
            'status' => 'confirmed',
        ]);
    }

    /** @test */
    public function pharmacy_cannot_confirm_non_pending_order()
    {
        $this->order->update(['status' => 'confirmed']);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/pharmacy/orders/{$this->order->id}/confirm");

        $response->assertStatus(400)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Cette commande ne peut pas être confirmée');
    }

    /** @test */
    public function pharmacy_can_mark_order_as_ready()
    {
        $this->order->update(['status' => 'confirmed']);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/pharmacy/orders/{$this->order->id}/ready");

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    /** @test */
    public function pharmacy_can_cancel_order()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/pharmacy/orders/{$this->order->id}/reject", [
                'reason' => 'Produit non disponible',
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    /** @test */
    public function pharmacy_cannot_access_other_pharmacy_orders()
    {
        $otherPharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $otherOrder = Order::factory()->create([
            'pharmacy_id' => $otherPharmacy->id,
            'customer_id' => $this->customer->id,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/pharmacy/orders/{$otherOrder->id}");

        $response->assertNotFound();
    }

    /** @test */
    public function non_pharmacy_user_cannot_access_orders()
    {
        $customer = User::factory()->create(['role' => 'customer']);

        $response = $this->actingAs($customer, 'sanctum')
            ->getJson('/api/pharmacy/orders');

        $response->assertStatus(403);
    }

    /** @test */
    public function unauthenticated_user_cannot_access_orders()
    {
        $response = $this->getJson('/api/pharmacy/orders');

        $response->assertUnauthorized();
    }

    /** @test */
    public function pharmacy_can_get_pending_orders_count()
    {
        // Create more pending orders
        Order::factory()->count(3)->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $this->customer->id,
            'status' => 'pending',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/pharmacy/orders?status=pending');

        $response->assertOk();
        $this->assertCount(4, $response->json('data')); // 1 from setUp + 3 new
    }

    /** @test */
    public function order_details_include_items()
    {
        OrderItem::factory()->count(3)->create([
            'order_id' => $this->order->id,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/pharmacy/orders/{$this->order->id}");

        $response->assertOk();
        $this->assertCount(3, $response->json('data.items'));
    }
}
