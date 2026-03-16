<?php

namespace Tests\Unit\Services;

use App\Models\User;
use App\Models\Customer;
use App\Models\Order;
use App\Models\Product;
use App\Models\Pharmacy;
use App\Services\OrderService;
use App\Services\WalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OrderServiceTest extends TestCase
{
    use RefreshDatabase;

    protected OrderService $orderService;
    protected Pharmacy $pharmacy;
    protected User $customer;

    protected function setUp(): void
    {
        parent::setUp();
        
        $walletService = new WalletService();
        $this->orderService = new OrderService($walletService);
        
        $this->pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->customer = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $this->customer->id]);
    }

    /** @test */
    public function it_validates_products_availability()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'stock_quantity' => 10,
        ]);

        $items = [
            ['id' => $product->id, 'quantity' => 5, 'price' => 1000],
        ];

        $result = $this->orderService->validateProductsAvailability($items);
        
        $this->assertNull($result);
    }

    /** @test */
    public function it_rejects_unavailable_products()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => false,
            'stock_quantity' => 10,
        ]);

        $items = [
            ['id' => $product->id, 'quantity' => 5, 'price' => 1000],
        ];

        $result = $this->orderService->validateProductsAvailability($items);
        
        $this->assertNotNull($result);
        $this->assertFalse($result['success']);
    }

    /** @test */
    public function it_rejects_insufficient_stock()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'stock_quantity' => 5,
        ]);

        $items = [
            ['id' => $product->id, 'quantity' => 10, 'price' => 1000],
        ];

        $result = $this->orderService->validateProductsAvailability($items);
        
        $this->assertNotNull($result);
        $this->assertFalse($result['success']);
    }

    /** @test */
    public function it_calculates_subtotal_correctly()
    {
        $items = [
            ['quantity' => 2, 'price' => 1000],
            ['quantity' => 3, 'price' => 500],
        ];

        $subtotal = $this->orderService->calculateSubtotal($items);
        
        // 2*1000 + 3*500 = 3500
        $this->assertEquals(3500, $subtotal);
    }

    /** @test */
    public function it_uses_product_price_when_available()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'price' => 1500, // Different from item price
        ]);

        $items = [
            ['id' => $product->id, 'quantity' => 2, 'price' => 1000],
        ];

        $subtotal = $this->orderService->calculateSubtotal($items);
        
        // Should use product price: 2*1500 = 3000
        $this->assertEquals(3000, $subtotal);
    }

    /** @test */
    public function it_calculates_order_totals()
    {
        $items = [
            ['quantity' => 2, 'price' => 1000],
            ['quantity' => 1, 'price' => 500],
        ];

        $totals = $this->orderService->calculateOrderTotals($items);
        
        $this->assertArrayHasKey('subtotal', $totals);
        $this->assertArrayHasKey('delivery_fee', $totals);
        $this->assertArrayHasKey('total_amount', $totals);
        
        $this->assertEquals(2500, $totals['subtotal']);
        $this->assertEquals($totals['subtotal'] + $totals['delivery_fee'], $totals['total_amount']);
    }

    /** @test */
    public function it_creates_order()
    {
        $data = [
            'pharmacy_id' => $this->pharmacy->id,
            'payment_mode' => 'cash',
            'items' => [
                ['quantity' => 2, 'price' => 1000],
            ],
            'delivery_address' => '123 Test Street',
            'delivery_city' => 'Abidjan',
            'customer_phone' => '+225 0707070707',
            'customer_notes' => 'Test notes',
        ];

        $order = $this->orderService->createOrder($this->customer, $data);
        
        $this->assertInstanceOf(Order::class, $order);
        $this->assertEquals('pending', $order->status);
        $this->assertEquals($this->pharmacy->id, $order->pharmacy_id);
        $this->assertEquals($this->customer->id, $order->customer_id);
        $this->assertEquals('123 Test Street', $order->delivery_address);
        $this->assertEquals('XOF', $order->currency);
    }

    /** @test */
    public function it_generates_unique_order_reference()
    {
        $data = [
            'pharmacy_id' => $this->pharmacy->id,
            'payment_mode' => 'cash',
            'items' => [
                ['quantity' => 1, 'price' => 1000],
            ],
            'delivery_address' => 'Test Address',
            'customer_phone' => '+225 0707070707',
        ];

        $order1 = $this->orderService->createOrder($this->customer, $data);
        $order2 = $this->orderService->createOrder($this->customer, $data);
        
        $this->assertNotEquals($order1->reference, $order2->reference);
    }

    /** @test */
    public function it_creates_order_items()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'price' => 1500,
        ]);

        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $this->customer->id,
        ]);

        $items = [
            ['id' => $product->id, 'quantity' => 2, 'price' => 1000, 'name' => 'Test Product'],
        ];

        $this->orderService->createOrderItems($order, $items);
        
        $order->refresh();
        $this->assertEquals(1, $order->items()->count());
        $this->assertEquals(2, $order->items()->first()->quantity);
    }

    /** @test */
    public function it_handles_items_without_product_id()
    {
        $items = [
            ['quantity' => 1, 'price' => 1000],
        ];

        $result = $this->orderService->validateProductsAvailability($items);
        
        // Should pass validation - item without product_id is custom item
        $this->assertNull($result);
    }

    /** @test */
    public function it_handles_prescription_image()
    {
        $data = [
            'pharmacy_id' => $this->pharmacy->id,
            'payment_mode' => 'cash',
            'items' => [
                ['quantity' => 1, 'price' => 1000],
            ],
            'delivery_address' => 'Test Address',
            'customer_phone' => '+225 0707070707',
            'prescription_image' => 'prescriptions/test.jpg',
        ];

        $order = $this->orderService->createOrder($this->customer, $data);
        
        $this->assertEquals('prescriptions/test.jpg', $order->prescription_image);
    }

    /** @test */
    public function it_stores_delivery_coordinates()
    {
        $data = [
            'pharmacy_id' => $this->pharmacy->id,
            'payment_mode' => 'cash',
            'items' => [
                ['quantity' => 1, 'price' => 1000],
            ],
            'delivery_address' => 'Test Address',
            'customer_phone' => '+225 0707070707',
            'delivery_latitude' => 5.3600,
            'delivery_longitude' => -4.0083,
        ];

        $order = $this->orderService->createOrder($this->customer, $data);
        
        $this->assertEquals(5.3600, $order->delivery_latitude);
        $this->assertEquals(-4.0083, $order->delivery_longitude);
    }
}
