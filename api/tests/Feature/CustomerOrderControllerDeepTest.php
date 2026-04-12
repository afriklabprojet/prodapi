<?php

namespace Tests\Feature;

use App\Models\Delivery;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Prescription;
use App\Models\Product;
use App\Models\Setting;
use App\Models\User;
use App\Models\Courier;
use App\Notifications\OrderStatusNotification;
use App\Services\JekoPaymentService;
use App\Services\WaitingFeeService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

/**
 * @group deep
 */
class CustomerOrderControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    private User $customer;
    private Pharmacy $pharmacy;
    private Product $product;

    protected function setUp(): void
    {
        parent::setUp();

        $this->customer = User::factory()->create([
            'role' => 'customer',
            'phone' => '+22507000001',
            'phone_verified_at' => now(),
        ]);

        $this->pharmacy = Pharmacy::factory()->create(['status' => 'approved']);

        $this->product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Doliprane',
            'price' => 2500,
            'stock_quantity' => 100,
            'is_available' => true,
        ]);
    }

    private function actingAsCustomer()
    {
        return $this->actingAs($this->customer, 'sanctum');
    }

    private function createOrder(array $attributes = []): Order
    {
        return Order::factory()->create(array_merge([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'pending',
            'total_amount' => 10000,
        ], $attributes));
    }

    // ─── INDEX ───────────────────────────────────────────────────────────────

    public function test_index_returns_customer_orders(): void
    {
        $this->createOrder(['reference' => 'ORD-001']);
        $this->createOrder(['reference' => 'ORD-002']);

        $response = $this->actingAsCustomer()->getJson('/api/customer/orders');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(2, 'data');
    }

    public function test_index_paginated_results(): void
    {
        for ($i = 0; $i < 20; $i++) {
            $this->createOrder(['reference' => "ORD-{$i}"]);
        }

        $response = $this->actingAsCustomer()->getJson('/api/customer/orders?per_page=5');

        $response->assertOk()
            ->assertJsonCount(5, 'data')
            ->assertJsonPath('meta.per_page', 5)
            ->assertJsonPath('meta.total', 20);
    }

    public function test_index_max_per_page_is_50(): void
    {
        for ($i = 0; $i < 60; $i++) {
            $this->createOrder(['reference' => "ORD-{$i}"]);
        }

        $response = $this->actingAsCustomer()->getJson('/api/customer/orders?per_page=100');

        $response->assertOk();
        $this->assertLessThanOrEqual(50, count($response->json('data')));
    }

    public function test_index_does_not_show_other_customers_orders(): void
    {
        $otherCustomer = User::factory()->create(['role' => 'customer']);
        Order::factory()->create(['customer_id' => $otherCustomer->id, 'pharmacy_id' => $this->pharmacy->id]);


        $this->createOrder(['reference' => 'ORD-MY']);

        $response = $this->actingAsCustomer()->getJson('/api/customer/orders');

        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.reference', 'ORD-MY');
    }

    // ─── STORE ───────────────────────────────────────────────────────────────

    public function test_store_creates_order_with_cash_payment(): void
    {
        $response = $this->actingAsCustomer()->postJson('/api/customer/orders', [
            'pharmacy_id' => $this->pharmacy->id,
            'items' => [
                [
                    'id' => $this->product->id,
                    'name' => $this->product->name,
                    'quantity' => 2,
                    'price' => $this->product->price,
                ],
            ],
            'delivery_address' => '123 Rue Test, Abidjan',
            'customer_phone' => '+22507000001',
            'payment_mode' => 'cash',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.payment_mode', 'cash');
    }

    public function test_store_creates_order_with_mobile_money(): void
    {
        $response = $this->actingAsCustomer()->postJson('/api/customer/orders', [
            'pharmacy_id' => $this->pharmacy->id,
            'items' => [
                [
                    'id' => $this->product->id,
                    'name' => $this->product->name,
                    'quantity' => 1,
                    'price' => $this->product->price,
                ],
            ],
            'delivery_address' => '123 Rue Test, Abidjan',
            'customer_phone' => '+22507000001',
            'payment_mode' => 'mobile_money',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.payment_mode', 'mobile_money');
    }

    public function test_store_accepts_unit_price_instead_of_price(): void
    {
        $response = $this->actingAsCustomer()->postJson('/api/customer/orders', [
            'pharmacy_id' => $this->pharmacy->id,
            'items' => [
                [
                    'id' => $this->product->id,
                    'name' => $this->product->name,
                    'quantity' => 1,
                    'unit_price' => $this->product->price, // using unit_price
                ],
            ],
            'delivery_address' => '123 Rue Test, Abidjan',
            'customer_phone' => '+22507000001',
            'payment_mode' => 'cash',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true);
    }

    public function test_store_fails_with_empty_items(): void
    {
        $response = $this->actingAsCustomer()->postJson('/api/customer/orders', [
            'pharmacy_id' => $this->pharmacy->id,
            'items' => [],
            'delivery_address' => '123 Rue Test',
            'customer_phone' => '+22507000001',
            'payment_mode' => 'cash',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['items']);
    }

    public function test_store_fails_with_invalid_payment_mode(): void
    {
        $response = $this->actingAsCustomer()->postJson('/api/customer/orders', [
            'pharmacy_id' => $this->pharmacy->id,
            'items' => [
                ['id' => $this->product->id, 'name' => 'Test', 'quantity' => 1, 'price' => 1000],
            ],
            'delivery_address' => '123 Rue Test',
            'customer_phone' => '+22507000001',
            'payment_mode' => 'bitcoin', // Invalid
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['payment_mode']);
    }

    public function test_store_fails_with_nonexistent_pharmacy(): void
    {
        $response = $this->actingAsCustomer()->postJson('/api/customer/orders', [
            'pharmacy_id' => 99999, // Doesn't exist
            'items' => [
                ['id' => $this->product->id, 'name' => 'Test', 'quantity' => 1, 'price' => 1000],
            ],
            'delivery_address' => '123 Rue Test',
            'customer_phone' => '+22507000001',
            'payment_mode' => 'cash',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['pharmacy_id']);
    }

    public function test_store_fails_with_unavailable_product(): void
    {
        $unavailableProduct = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => false,
        ]);

        $response = $this->actingAsCustomer()->postJson('/api/customer/orders', [
            'pharmacy_id' => $this->pharmacy->id,
            'items' => [
                ['id' => $unavailableProduct->id, 'name' => 'Test', 'quantity' => 1, 'price' => 1000],
            ],
            'delivery_address' => '123 Rue Test',
            'customer_phone' => '+22507000001',
            'payment_mode' => 'cash',
        ]);

        $response->assertStatus(422);
    }

    public function test_store_fails_with_insufficient_stock(): void
    {
        $lowStockProduct = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'stock_quantity' => 2,
            'is_available' => true,
        ]);

        $response = $this->actingAsCustomer()->postJson('/api/customer/orders', [
            'pharmacy_id' => $this->pharmacy->id,
            'items' => [
                ['id' => $lowStockProduct->id, 'name' => 'Test', 'quantity' => 10, 'price' => 1000],
            ],
            'delivery_address' => '123 Rue Test',
            'customer_phone' => '+22507000001',
            'payment_mode' => 'cash',
        ]);

        $response->assertStatus(422);
    }

    public function test_store_decrements_product_stock(): void
    {
        $initialStock = $this->product->stock_quantity;

        $response = $this->actingAsCustomer()->postJson('/api/customer/orders', [
            'pharmacy_id' => $this->pharmacy->id,
            'items' => [
                ['id' => $this->product->id, 'name' => $this->product->name, 'quantity' => 3, 'price' => $this->product->price],
            ],
            'delivery_address' => '123 Rue Test',
            'customer_phone' => '+22507000001',
            'payment_mode' => 'cash',
        ]);

        $response->assertStatus(201);

        $this->product->refresh();
        $this->assertEquals($initialStock - 3, $this->product->stock_quantity);
    }

    public function test_store_normalizes_platform_payment_mode_to_mobile_money(): void
    {
        $response = $this->actingAsCustomer()->postJson('/api/customer/orders', [
            'pharmacy_id' => $this->pharmacy->id,
            'items' => [
                ['id' => $this->product->id, 'name' => $this->product->name, 'quantity' => 1, 'price' => $this->product->price],
            ],
            'delivery_address' => '123 Rue Test',
            'customer_phone' => '+22507000001',
            'payment_mode' => 'platform',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.payment_mode', 'mobile_money');
    }

    public function test_store_normalizes_on_delivery_payment_mode_to_cash(): void
    {
        $response = $this->actingAsCustomer()->postJson('/api/customer/orders', [
            'pharmacy_id' => $this->pharmacy->id,
            'items' => [
                ['id' => $this->product->id, 'name' => $this->product->name, 'quantity' => 1, 'price' => $this->product->price],
            ],
            'delivery_address' => '123 Rue Test',
            'customer_phone' => '+22507000001',
            'payment_mode' => 'on_delivery',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.payment_mode', 'cash');
    }

    public function test_store_rejects_disabled_cash_payment_mode(): void
    {
        Setting::set('payment_mode_cash_enabled', false, 'boolean');

        $response = $this->actingAsCustomer()->postJson('/api/customer/orders', [
            'pharmacy_id' => $this->pharmacy->id,
            'items' => [
                ['id' => $this->product->id, 'name' => $this->product->name, 'quantity' => 1, 'price' => $this->product->price],
            ],
            'delivery_address' => '123 Rue Test',
            'customer_phone' => '+22507000001',
            'payment_mode' => 'cash',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_store_links_prescription_to_created_order(): void
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'order_id' => null,
            'status' => 'pending',
        ]);

        $response = $this->actingAsCustomer()->postJson('/api/customer/orders', [
            'pharmacy_id' => $this->pharmacy->id,
            'prescription_id' => $prescription->id,
            'items' => [
                ['id' => $this->product->id, 'name' => $this->product->name, 'quantity' => 1, 'price' => $this->product->price],
            ],
            'delivery_address' => '123 Rue Test',
            'customer_phone' => '+22507000001',
            'payment_mode' => 'cash',
        ]);

        $response->assertStatus(201);
        $prescription->refresh();

        $this->assertNotNull($prescription->order_id);
        $this->assertEquals('processing', $prescription->status);
    }

    public function test_store_accepts_manual_item_without_product_id(): void
    {
        $response = $this->actingAsCustomer()->postJson('/api/customer/orders', [
            'pharmacy_id' => $this->pharmacy->id,
            'items' => [
                ['name' => 'Produit manuel', 'quantity' => 2, 'price' => 1500],
            ],
            'delivery_address' => '123 Rue Test',
            'customer_phone' => '+22507000001',
            'payment_mode' => 'cash',
        ]);

        $response->assertStatus(201);

        $order = Order::latest('id')->first();
        $this->assertDatabaseHas('order_items', [
            'order_id' => $order->id,
            'product_id' => null,
            'product_name' => 'Produit manuel',
            'quantity' => 2,
        ]);
    }

    public function test_store_calculates_delivery_fee_from_coordinates(): void
    {
        $this->pharmacy->update([
            'latitude' => 5.3400,
            'longitude' => -3.9800,
        ]);

        $response = $this->actingAsCustomer()->postJson('/api/customer/orders', [
            'pharmacy_id' => $this->pharmacy->id,
            'items' => [
                ['id' => $this->product->id, 'name' => $this->product->name, 'quantity' => 1, 'price' => $this->product->price],
            ],
            'delivery_address' => 'Cocody Riviera',
            'delivery_latitude' => 5.3600,
            'delivery_longitude' => -3.9500,
            'customer_phone' => '+22507000001',
            'payment_mode' => 'cash',
        ]);

        $response->assertStatus(201);

        $order = Order::latest('id')->first();
        $this->assertGreaterThan(0, (float) $order->delivery_fee);
        $this->assertGreaterThan((float) $order->subtotal, (float) $order->total_amount);
    }

    // ─── SHOW ────────────────────────────────────────────────────────────────

    public function test_show_returns_order_details(): void
    {
        $order = $this->createOrder(['reference' => 'ORD-SHOW-001']);
        $order->items()->create([
            'product_id' => $this->product->id,
            'product_name' => 'Doliprane',
            'quantity' => 2,
            'unit_price' => 2500,
            'total_price' => 5000,
        ]);

        $response = $this->actingAsCustomer()->getJson("/api/customer/orders/{$order->id}");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.reference', 'ORD-SHOW-001')
            ->assertJsonStructure([
                'data' => [
                    'id', 'reference', 'status', 'pharmacy', 'items', 'total_amount',
                ]
            ]);
    }

    public function test_show_includes_delivery_info_when_present(): void
    {
        $order = $this->createOrder();
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
            'status' => 'in_transit', // Valid status
        ]);

        $response = $this->actingAsCustomer()->getJson("/api/customer/orders/{$order->id}");

        $response->assertOk()
            ->assertJsonPath('data.delivery.id', $delivery->id)
            ->assertJsonPath('data.delivery.status', 'in_transit');
    }

    public function test_show_fails_for_other_customer_order(): void
    {
        $otherCustomer = User::factory()->create(['role' => 'customer']);
        $otherOrder = Order::factory()->create([
            'customer_id' => $otherCustomer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $response = $this->actingAsCustomer()->getJson("/api/customer/orders/{$otherOrder->id}");

        $response->assertStatus(404);
    }

    public function test_show_returns_404_for_nonexistent_order(): void
    {
        $response = $this->actingAsCustomer()->getJson('/api/customer/orders/99999');

        $response->assertStatus(404);
    }

    // ─── INITIATE PAYMENT ────────────────────────────────────────────────────

    public function test_initiate_payment_success(): void
    {
        $order = $this->createOrder(['payment_status' => 'pending', 'paid_at' => null]);

        // Create a proper JekoPayment mock object with the required properties
        $mockPayment = new \App\Models\JekoPayment([
            'reference' => 'JEKO-PAY-001',
            'redirect_url' => 'https://pay.jeko.ci/checkout/123',
            'amount_cents' => 1000000,
            'currency' => 'XOF',
            'payment_method' => 'orange',
        ]);
        // Set the payment_method attribute as an enum-like object
        $mockPayment->payment_method = \App\Enums\JekoPaymentMethod::ORANGE;
        $mockPayment->amount = 1000000;

        $this->mock(JekoPaymentService::class, function ($mock) use ($mockPayment) {
            $mock->shouldReceive('createRedirectPayment')
                ->once()
                ->andReturn($mockPayment);
        });

        $response = $this->actingAsCustomer()->postJson("/api/customer/orders/{$order->id}/payment/initiate", [
            'provider' => 'jeko',
            'payment_method' => 'orange',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.reference', 'JEKO-PAY-001')
            ->assertJsonStructure(['data' => ['redirect_url', 'amount', 'currency']]);
    }

    public function test_initiate_payment_fails_for_already_paid_order(): void
    {
        $order = $this->createOrder(['payment_status' => 'paid', 'paid_at' => now()]);

        $response = $this->actingAsCustomer()->postJson("/api/customer/orders/{$order->id}/payment/initiate", [
            'provider' => 'jeko',
            'payment_method' => 'orange',
        ]);

        $response->assertStatus(400)
            ->assertJsonPath('success', false);
    }

    public function test_initiate_payment_fails_for_cancelled_order(): void
    {
        $order = $this->createOrder(['status' => 'cancelled']);

        $response = $this->actingAsCustomer()->postJson("/api/customer/orders/{$order->id}/payment/initiate", [
            'provider' => 'jeko',
            'payment_method' => 'orange',
        ]);

        $response->assertStatus(400)
            ->assertJsonPath('message', 'Cette commande a été annulée');
    }

    public function test_initiate_payment_validation_invalid_provider(): void
    {
        $order = $this->createOrder();

        $response = $this->actingAsCustomer()->postJson("/api/customer/orders/{$order->id}/payment/initiate", [
            'provider' => 'paypal', // Invalid
            'payment_method' => 'orange',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['provider']);
    }

    public function test_initiate_payment_validation_invalid_method(): void
    {
        $order = $this->createOrder();

        $response = $this->actingAsCustomer()->postJson("/api/customer/orders/{$order->id}/payment/initiate", [
            'provider' => 'jeko',
            'payment_method' => 'visa', // Invalid for Jeko
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['payment_method']);
    }

    public function test_initiate_payment_returns_500_when_gateway_throws(): void
    {
        $order = $this->createOrder(['payment_status' => 'pending', 'paid_at' => null]);

        $this->mock(JekoPaymentService::class, function ($mock) {
            $mock->shouldReceive('createRedirectPayment')
                ->once()
                ->andThrow(new \Exception('Gateway down'));
        });

        $response = $this->actingAsCustomer()->postJson("/api/customer/orders/{$order->id}/payment/initiate", [
            'provider' => 'jeko',
            'payment_method' => 'orange',
        ]);

        $response->assertStatus(500)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Erreur lors de l\'initialisation du paiement');
    }

    // ─── CANCEL ──────────────────────────────────────────────────────────────

    public function test_cancel_pending_order(): void
    {
        $order = $this->createOrder(['status' => 'pending']);

        $response = $this->actingAsCustomer()->postJson("/api/customer/orders/{$order->id}/cancel", [
            'reason' => 'J\'ai changé d\'avis',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);

        $order->refresh();
        $this->assertEquals('cancelled', $order->status);
        $this->assertNotNull($order->cancelled_at);
    }

    public function test_cancel_confirmed_order(): void
    {
        $order = $this->createOrder(['status' => 'confirmed']);

        $response = $this->actingAsCustomer()->postJson("/api/customer/orders/{$order->id}/cancel", [
            'reason' => 'Délai trop long',
        ]);

        $response->assertOk();
        $order->refresh();
        $this->assertEquals('cancelled', $order->status);
    }

    public function test_cancel_fails_for_delivered_order(): void
    {
        $order = $this->createOrder(['status' => 'delivered']);

        $response = $this->actingAsCustomer()->postJson("/api/customer/orders/{$order->id}/cancel", [
            'reason' => 'Test cancellation',
        ]);

        $response->assertStatus(400)
            ->assertJsonPath('success', false);
    }

    public function test_cancel_fails_for_other_customer_order(): void
    {
        $otherCustomer = User::factory()->create(['role' => 'customer']);
        $otherOrder = Order::factory()->create([
            'customer_id' => $otherCustomer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'pending',
        ]);

        $response = $this->actingAsCustomer()->postJson("/api/customer/orders/{$otherOrder->id}/cancel", [
            'reason' => 'Trying to cancel someone else\'s order',
        ]);

        $response->assertStatus(403);
    }

    public function test_cancel_requires_reason(): void
    {
        $order = $this->createOrder(['status' => 'pending']);

        $response = $this->actingAsCustomer()->postJson("/api/customer/orders/{$order->id}/cancel", []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['reason']);
    }

    public function test_cancel_also_cancels_associated_delivery(): void
    {
        $order = $this->createOrder(['status' => 'confirmed']);
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'status' => 'assigned',
        ]);

        $response = $this->actingAsCustomer()->postJson("/api/customer/orders/{$order->id}/cancel", [
            'reason' => 'Test cancellation with delivery',
        ]);

        $response->assertOk();

        $delivery->refresh();
        $this->assertEquals('cancelled', $delivery->status);
    }

    public function test_cancel_notifies_pharmacy_and_courier_when_present(): void
    {
        Notification::fake();

        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy->users()->attach($pharmacyUser->id, ['role' => 'owner']);

        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);

        $order = $this->createOrder(['status' => 'confirmed']);
        Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
            'status' => 'assigned',
        ]);

        $response = $this->actingAsCustomer()->postJson("/api/customer/orders/{$order->id}/cancel", [
            'reason' => 'Je ne suis plus disponible',
        ]);

        $response->assertOk();
        Notification::assertSentTo($pharmacyUser, OrderStatusNotification::class);
        Notification::assertSentTo($courierUser, OrderStatusNotification::class);
    }

    public function test_delivery_waiting_status_returns_404_without_delivery(): void
    {
        $order = $this->createOrder(['status' => 'confirmed']);

        $response = $this->actingAsCustomer()
            ->getJson("/api/customer/orders/{$order->id}/delivery-waiting-status");

        $response->assertStatus(404)
            ->assertJsonPath('success', false);
    }

    public function test_delivery_waiting_status_returns_free_period_warning(): void
    {
        $order = $this->createOrder(['status' => 'confirmed']);
        Delivery::factory()->create([
            'order_id' => $order->id,
            'status' => 'in_transit',
        ]);

        $this->mock(WaitingFeeService::class, function ($mock) {
            $mock->shouldReceive('getWaitingInfo')->once()->andReturn([
                'is_waiting' => true,
                'free_minutes' => 3,
                'fee_per_minute' => 100,
                'waiting_minutes' => 1,
                'waiting_fee' => 0,
            ]);
        });

        $response = $this->actingAsCustomer()
            ->getJson("/api/customer/orders/{$order->id}/delivery-waiting-status");

        $response->assertOk()
            ->assertJsonPath('success', true);
        $this->assertStringContainsString('minute(s) gratuite(s)', $response->json('data.warning_message'));
    }

    public function test_delivery_waiting_status_returns_fee_warning_after_free_period(): void
    {
        $order = $this->createOrder(['status' => 'confirmed']);
        Delivery::factory()->create([
            'order_id' => $order->id,
            'status' => 'in_transit',
        ]);

        $this->mock(WaitingFeeService::class, function ($mock) {
            $mock->shouldReceive('getWaitingInfo')->once()->andReturn([
                'is_waiting' => true,
                'free_minutes' => 3,
                'fee_per_minute' => 100,
                'waiting_minutes' => 5,
                'waiting_fee' => 200,
            ]);
        });

        $response = $this->actingAsCustomer()
            ->getJson("/api/customer/orders/{$order->id}/delivery-waiting-status");

        $response->assertOk()
            ->assertJsonPath('success', true);
        $this->assertStringContainsString('Frais d\'attente en cours', $response->json('data.warning_message'));
    }

    // NOTE: test_cancel_marks_pending_payments_as_cancelled removed because
    // the payments table schema only allows 'SUCCESS' or 'FAILED' status values,
    // not 'pending' or 'cancelled'. This is a schema limitation.

    // ─── AUTH ────────────────────────────────────────────────────────────────

    public function test_index_requires_auth(): void
    {
        $this->getJson('/api/customer/orders')->assertUnauthorized();
    }

    public function test_store_requires_auth(): void
    {
        $this->postJson('/api/customer/orders', [])->assertUnauthorized();
    }

    public function test_show_requires_auth(): void
    {
        $order = $this->createOrder();
        $this->getJson("/api/customer/orders/{$order->id}")->assertUnauthorized();
    }

    public function test_cancel_requires_auth(): void
    {
        $order = $this->createOrder();
        $this->postJson("/api/customer/orders/{$order->id}/cancel", [])->assertUnauthorized();
    }

    public function test_initiate_payment_requires_auth(): void
    {
        $order = $this->createOrder();
        $this->postJson("/api/customer/orders/{$order->id}/payment/initiate", [])->assertUnauthorized();
    }
}
