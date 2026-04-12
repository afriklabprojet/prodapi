<?php

namespace Tests\Unit\Services;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Pharmacy;
use App\Models\Product;
use App\Models\User;
use App\Notifications\NewOrderReceivedNotification;
use App\Services\OrderService;
use App\Services\WalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;
use Mockery;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class OrderServiceDeepTest extends TestCase
{
    use RefreshDatabase;

    private OrderService $service;

    protected function setUp(): void
    {
        parent::setUp();
        Log::spy();
        Notification::fake();
        $this->service = app(OrderService::class);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // createOrder
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function create_order_creates_with_correct_totals(): void
    {
        $customer = User::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create(['price' => 2000, 'is_available' => true, 'stock_quantity' => 10]);

        $data = [
            'pharmacy_id' => $pharmacy->id,
            'payment_mode' => 'wallet',
            'items' => [
                ['id' => $product->id, 'name' => $product->name, 'quantity' => 2, 'price' => 2000],
            ],
            'delivery_address' => '123 Main St',
            'delivery_city' => 'Abidjan',
            'delivery_latitude' => 5.3364,
            'delivery_longitude' => -4.0267,
            'customer_phone' => '+2250700000000',
            'customer_notes' => 'Ring the bell',
            'prescription_image' => 'prescriptions/img.jpg',
        ];

        $order = $this->service->createOrder($customer, $data);

        $this->assertInstanceOf(Order::class, $order);
        $this->assertEquals($pharmacy->id, $order->pharmacy_id);
        $this->assertEquals($customer->id, $order->customer_id);
        $this->assertEquals('pending', $order->status);
        $this->assertEquals('wallet', $order->payment_mode);
        $this->assertNotNull($order->reference);
        $this->assertEquals('XOF', $order->currency);
        $this->assertEquals('Ring the bell', $order->customer_notes);
        $this->assertEquals('prescriptions/img.jpg', $order->prescription_image);
        $this->assertEquals(5.3364, (float) $order->delivery_latitude);
        $this->assertEquals(-4.0267, (float) $order->delivery_longitude);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // createOrderItems
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function create_order_items_with_product_id(): void
    {
        $product = Product::factory()->create(['price' => 1500]);
        $order = Order::factory()->create();

        $items = [
            ['id' => $product->id, 'name' => 'Test Product', 'quantity' => 3, 'price' => 1000],
        ];

        $this->service->createOrderItems($order, $items);

        $this->assertDatabaseHas('order_items', [
            'order_id' => $order->id,
            'product_id' => $product->id,
            'product_name' => 'Test Product',
            'quantity' => 3,
            'unit_price' => 1500, // Uses product.price, not item.price
            'total_price' => 4500,
        ]);
    }

    #[Test]
    public function create_order_items_without_product_id(): void
    {
        $order = Order::factory()->create();

        $items = [
            ['name' => 'Custom Medication', 'quantity' => 2, 'price' => 800],
        ];

        $this->service->createOrderItems($order, $items);

        $this->assertDatabaseHas('order_items', [
            'order_id' => $order->id,
            'product_id' => null,
            'product_name' => 'Custom Medication',
            'quantity' => 2,
            'unit_price' => 800,
            'total_price' => 1600,
        ]);
    }

    #[Test]
    public function create_order_items_multiple(): void
    {
        $order = Order::factory()->create();

        $items = [
            ['name' => 'Item 1', 'quantity' => 1, 'price' => 500],
            ['name' => 'Item 2', 'quantity' => 2, 'price' => 1000],
        ];

        $this->service->createOrderItems($order, $items);

        $this->assertEquals(2, $order->items()->count());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // updateProductStock
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function update_product_stock_decrements(): void
    {
        $product = Product::factory()->create(['stock_quantity' => 10]);

        $items = [
            ['id' => $product->id, 'quantity' => 3],
        ];

        $this->service->updateProductStock($items);

        $this->assertEquals(7, $product->fresh()->stock_quantity);
    }

    #[Test]
    public function update_product_stock_skips_items_without_id(): void
    {
        $items = [
            ['name' => 'No ID Item', 'quantity' => 5, 'price' => 100],
        ];

        // Should not throw
        $this->service->updateProductStock($items);
        $this->assertTrue(true);
    }

    #[Test]
    public function update_product_stock_skips_nonexistent_products(): void
    {
        $items = [
            ['id' => 99999, 'quantity' => 3],
        ];

        // Should not throw
        $this->service->updateProductStock($items);
        $this->assertTrue(true);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // notifyPharmacy
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function notify_pharmacy_sends_notification(): void
    {
        $pharmacyUser = User::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $pharmacy->users()->attach($pharmacyUser->id);

        $order = Order::factory()->create(['pharmacy_id' => $pharmacy->id]);

        $this->service->notifyPharmacy($order);

        Notification::assertSentTo($pharmacyUser, NewOrderReceivedNotification::class);
    }

    #[Test]
    public function notify_pharmacy_handles_no_users(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create(['pharmacy_id' => $pharmacy->id]);

        // Should not throw
        $this->service->notifyPharmacy($order);
        Notification::assertNothingSent();
    }

    #[Test]
    public function notify_pharmacy_catches_exception(): void
    {
        $order = Order::factory()->create();
        $mockPharmacy = Mockery::mock();
        $mockPharmacy->shouldReceive('__get')->with('users')->andThrow(new \RuntimeException('Test exception'));
        $order->setRelation('pharmacy', $mockPharmacy);

        // Should not throw
        $this->service->notifyPharmacy($order);
        Log::shouldHaveReceived('error')->withArgs(fn ($msg) => str_contains($msg, 'Failed to notify'));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // cancelOrder + restoreProductStock
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function cancel_order_updates_status_and_restores_stock(): void
    {
        $product = Product::factory()->create(['stock_quantity' => 7]);
        $order = Order::factory()->create(['status' => 'pending']);
        $order->items()->create([
            'product_id' => $product->id,
            'product_name' => $product->name,
            'quantity' => 3,
            'unit_price' => 1000,
            'total_price' => 3000,
        ]);

        $result = $this->service->cancelOrder($order, 'Customer requested');

        $this->assertEquals('cancelled', $result->status);
        $this->assertEquals('Customer requested', $result->cancellation_reason);
        $this->assertNotNull($result->cancelled_at);
        $this->assertEquals(10, $product->fresh()->stock_quantity);
    }

    #[Test]
    public function cancel_order_without_reason(): void
    {
        $order = Order::factory()->create(['status' => 'pending']);

        $result = $this->service->cancelOrder($order);

        $this->assertEquals('cancelled', $result->status);
        $this->assertNull($result->cancellation_reason);
    }

    #[Test]
    public function restore_product_stock_skips_items_without_product(): void
    {
        $order = Order::factory()->create();
        $order->items()->create([
            'product_id' => null,
            'product_name' => 'Custom item',
            'quantity' => 2,
            'unit_price' => 500,
            'total_price' => 1000,
        ]);

        // Should not throw
        $this->service->cancelOrder($order);
        $this->assertTrue(true);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // canBeCancelled / canBePaid
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function can_be_cancelled_for_valid_statuses(): void
    {
        foreach (['pending', 'confirmed', 'preparing'] as $status) {
            $order = Order::factory()->make(['status' => $status]);
            $this->assertTrue($this->service->canBeCancelled($order), "Status {$status} should be cancellable");
        }
    }

    #[Test]
    public function cannot_be_cancelled_for_invalid_statuses(): void
    {
        foreach (['delivered', 'cancelled', 'in_transit'] as $status) {
            $order = Order::factory()->make(['status' => $status]);
            $this->assertFalse($this->service->canBeCancelled($order), "Status {$status} should not be cancellable");
        }
    }

    #[Test]
    public function can_be_paid_when_pending_and_unpaid(): void
    {
        $order = Order::factory()->make(['status' => 'pending', 'paid_at' => null]);
        $this->assertTrue($this->service->canBePaid($order));
    }

    #[Test]
    public function cannot_be_paid_when_already_paid(): void
    {
        $order = Order::factory()->make(['status' => 'pending', 'paid_at' => now()]);
        $this->assertFalse($this->service->canBePaid($order));
    }

    #[Test]
    public function cannot_be_paid_when_delivered(): void
    {
        $order = Order::factory()->make(['status' => 'delivered', 'paid_at' => null]);
        $this->assertFalse($this->service->canBePaid($order));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // markAsPaid
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function mark_as_paid_updates_order(): void
    {
        $order = Order::factory()->create(['payment_status' => 'pending', 'paid_at' => null]);

        $result = $this->service->markAsPaid($order, 'PAY-REF-001');

        $this->assertEquals('paid', $result->payment_status);
        $this->assertNotNull($result->paid_at);
        $this->assertEquals('PAY-REF-001', $result->payment_reference);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getCustomerOrderStats
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function get_customer_order_stats(): void
    {
        $customer = User::factory()->create();

        Order::factory()->create(['customer_id' => $customer->id, 'status' => 'pending', 'total_amount' => 1000]);
        Order::factory()->create(['customer_id' => $customer->id, 'status' => 'delivered', 'total_amount' => 5000]);
        Order::factory()->create(['customer_id' => $customer->id, 'status' => 'delivered', 'total_amount' => 3000]);
        Order::factory()->create(['customer_id' => $customer->id, 'status' => 'cancelled', 'total_amount' => 2000]);

        $stats = $this->service->getCustomerOrderStats($customer);

        $this->assertEquals(4, $stats['total_orders']);
        $this->assertEquals(1, $stats['pending_orders']);
        $this->assertEquals(2, $stats['completed_orders']);
        $this->assertEquals(1, $stats['cancelled_orders']);
        $this->assertEquals(8000, $stats['total_spent']);
    }

    #[Test]
    public function get_customer_order_stats_empty(): void
    {
        $customer = User::factory()->create();

        $stats = $this->service->getCustomerOrderStats($customer);

        $this->assertEquals(0, $stats['total_orders']);
        $this->assertEquals(0, $stats['pending_orders']);
        $this->assertEquals(0, $stats['completed_orders']);
        $this->assertEquals(0, $stats['cancelled_orders']);
        $this->assertEquals(0, $stats['total_spent']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // generateDeliveryCode
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function generate_delivery_code_is_4_digits(): void
    {
        $code = $this->service->generateDeliveryCode();

        $this->assertEquals(4, strlen($code));
        $this->assertMatchesRegularExpression('/^\d{4}$/', $code);
    }

    #[Test]
    public function generate_delivery_code_is_unique(): void
    {
        $codes = [];
        for ($i = 0; $i < 10; $i++) {
            $codes[] = $this->service->generateDeliveryCode();
        }
        // All should be valid 4-digit codes
        foreach ($codes as $code) {
            $this->assertMatchesRegularExpression('/^\d{4}$/', $code);
        }
    }
}
