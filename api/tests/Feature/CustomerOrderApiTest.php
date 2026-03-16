<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Pharmacy;
use App\Models\Product;
use App\Models\Order;
use App\Models\OrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;

class CustomerOrderApiTest extends TestCase
{
    use RefreshDatabase;

    protected $customer;
    protected $pharmacy;
    protected $product;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->customer = User::factory()->create([
            'role' => 'customer',
            'phone_verified_at' => now(), // Required for creating orders
        ]);
        
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
        ]);
        $this->pharmacy->users()->attach($pharmacyUser->id, ['role' => 'owner']);
        
        $this->product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'price' => 5000,
            'stock_quantity' => 10,
            'is_available' => true,
        ]);
    }

    /** @test */
    public function customer_can_create_order()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/orders', [
                'pharmacy_id' => $this->pharmacy->id,
                'delivery_address' => '123 Test Street, Abidjan',
                'delivery_latitude' => 5.3600,
                'delivery_longitude' => -4.0083,
                'customer_phone' => '0102030405',
                'payment_mode' => 'cash',
                'notes' => 'Please deliver in the morning',
                'items' => [
                    [
                        'id' => $this->product->id,
                        'name' => $this->product->name,
                        'quantity' => 2,
                        'price' => $this->product->price,
                    ],
                ],
            ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'data' => [
                    'order_id',
                    'reference',
                    'status',
                    'total_amount',
                ]
            ]);

        $this->assertDatabaseHas('orders', [
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'pending',
        ]);

        $this->assertDatabaseHas('order_items', [
            'product_id' => $this->product->id,
            'quantity' => 2,
        ]);
    }

    /** @test */
    public function order_creation_requires_valid_data()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/orders', [
                'pharmacy_id' => null,
                'delivery_address' => '',
                'items' => [],
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['pharmacy_id', 'delivery_address', 'items']);
    }

    /** @test */
    public function order_requires_at_least_one_item()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/orders', [
                'pharmacy_id' => $this->pharmacy->id,
                'delivery_address' => '123 Test Street',
                'items' => [],
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['items']);
    }

    /** @test */
    public function cannot_order_unavailable_product()
    {
        $unavailableProduct = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => false,
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/orders', [
                'pharmacy_id' => $this->pharmacy->id,
                'delivery_address' => '123 Test Street',
                'customer_phone' => '0102030405',
                'payment_mode' => 'cash',
                'items' => [
                    [
                        'id' => $unavailableProduct->id,
                        'name' => $unavailableProduct->name,
                        'quantity' => 1,
                        'price' => $unavailableProduct->price,
                    ],
                ],
            ]);

        $response->assertStatus(422);
    }

    /** @test */
    public function cannot_order_out_of_stock_product()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'stock_quantity' => 0,
            'is_available' => true,
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/orders', [
                'pharmacy_id' => $this->pharmacy->id,
                'delivery_address' => '123 Test Street',
                'customer_phone' => '0102030405',
                'payment_mode' => 'cash',
                'items' => [
                    [
                        'id' => $product->id,
                        'name' => $product->name,
                        'quantity' => 6, // Exceeds stock of 5
                        'price' => $product->price,
                    ],
                ],
            ]);

        $response->assertStatus(422);
    }

    /** @test */
    public function cannot_order_quantity_exceeding_stock()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/orders', [
                'pharmacy_id' => $this->pharmacy->id,
                'delivery_address' => '123 Test Street',
                'customer_phone' => '0102030405',
                'payment_mode' => 'cash',
                'items' => [
                    [
                        'id' => $this->product->id,
                        'name' => $this->product->name,
                        'quantity' => 20, // Stock is only 10
                        'price' => $this->product->price,
                    ],
                ],
            ]);

        $response->assertStatus(422);
    }

    /** @test */
    public function customer_can_view_own_orders()
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->getJson('/api/customer/orders');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'id',
                        'reference',
                        'status',
                        'total_amount',
                        'pharmacy',
                    ],
                ],
            ]);
    }

    /** @test */
    public function customer_cannot_view_other_customer_orders()
    {
        $otherCustomer = User::factory()->create(['role' => 'customer']);
        $order = Order::factory()->create([
            'customer_id' => $otherCustomer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->getJson('/api/customer/orders');

        $response->assertStatus(200)
            ->assertJsonCount(0, 'data');
    }

    /** @test */
    public function customer_can_view_order_details()
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        OrderItem::factory()->create([
            'order_id' => $order->id,
            'product_id' => $this->product->id,
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->getJson("/api/customer/orders/{$order->id}");

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'reference',
                    'status',
                    'total_amount',
                    'items' => [
                        '*' => ['product_name', 'quantity', 'unit_price'],
                    ],
                    'pharmacy',
                    'delivery',
                ]
            ]);
    }

    /** @test */
    public function customer_cannot_view_other_customer_order_details()
    {
        $otherCustomer = User::factory()->create(['role' => 'customer']);
        $order = Order::factory()->create([
            'customer_id' => $otherCustomer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->getJson("/api/customer/orders/{$order->id}");

        $response->assertStatus(404);
    }

    /** @test */
    public function customer_can_initiate_payment()
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'pending',
            'total_amount' => 10000,
        ]);

        // Mock payment gateway
        $this->mock(\App\Services\PaymentService::class, function ($mock) {
            $paymentIntent = new \App\Models\PaymentIntent();
            $paymentIntent->provider_payment_url = 'https://payment-gateway.com/pay/12345';
            $paymentIntent->provider = 'jeko';
            $paymentIntent->amount = 10000;
            $paymentIntent->reference = 'ref_123';
            $paymentIntent->status = 'PENDING';

            $mock->shouldReceive('initiatePayment')
                ->once()
                ->andReturn($paymentIntent);
        });

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/customer/orders/{$order->id}/payment/initiate", [
                'provider' => 'jeko',
            ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'payment_url',
                    'provider',
                ]
            ]);
    }

    /** @test */
    public function customer_can_cancel_pending_order()
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'pending',
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/customer/orders/{$order->id}/cancel", [
                'reason' => 'Changed my mind',
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'status' => 'cancelled',
        ]);
    }

    /** @test */
    public function customer_cannot_cancel_confirmed_order()
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'confirmed',
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/customer/orders/{$order->id}/cancel", [
                'reason' => 'Too late',
            ]);

        $response->assertStatus(400);
    }

    /** @test */
    public function customer_cannot_cancel_delivered_order()
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'delivered',
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/customer/orders/{$order->id}/cancel", [
                'reason' => 'Too late',
            ]);

        // 403 from policy (not authorized to cancel delivered orders)
        $response->assertStatus(403);
    }

    /** @test */
    public function unauthenticated_user_cannot_create_order()
    {
        $response = $this->postJson('/api/customer/orders', [
            'pharmacy_id' => $this->pharmacy->id,
            'delivery_address' => '123 Test Street',
            'items' => [
                [
                    'id' => $this->product->id,
                    'quantity' => 1,
                    'price' => $this->product->price,
                ],
            ],
        ]);

        $response->assertStatus(401);
    }

    /** @test */
    public function order_total_is_calculated_correctly()
    {
        $product1 = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'price' => 5000,
            'stock_quantity' => 10,
            'is_available' => true,
        ]);

        $product2 = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'price' => 3000,
            'stock_quantity' => 10,
            'is_available' => true,
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/orders', [
                'pharmacy_id' => $this->pharmacy->id,
                'delivery_address' => '123 Test Street',
                'customer_phone' => '0102030405',
                'payment_mode' => 'cash',
                'items' => [
                    [
                        'id' => $product1->id,
                        'name' => $product1->name,
                        'quantity' => 2,
                        'price' => 100,
                    ],
                    [
                        'id' => $product2->id,
                        'name' => $product2->name,
                        'quantity' => 3,
                        'price' => 200,
                    ],
                ],
            ]);

        $response->assertStatus(201);

        // Verify order was created with correct total
        // subtotal = (5000 * 2) + (3000 * 3) = 19000
        // delivery_fee = 300 (min, no coordinates)
        // service_fee = ceil(19000 * 2%) = 380
        // payment_fee = 0 (cash)
        // total = 19000 + 300 + 380 = 19680
        $data = $response->json('data');
        $this->assertEquals('19680.00', $data['total_amount']);
    }
}
