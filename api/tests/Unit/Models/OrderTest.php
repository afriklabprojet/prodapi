<?php

namespace Tests\Unit\Models;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Pharmacy;
use App\Models\User;
use App\Models\Customer;
use App\Models\Delivery;
use App\Models\Payment;
use App\Models\Commission;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OrderTest extends TestCase
{
    use RefreshDatabase;

    protected $pharmacy;
    protected $customer;
    protected $order;

    protected function setUp(): void
    {
        parent::setUp();

        $this->pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $user = User::factory()->create(['role' => 'customer']);
        $this->customer = Customer::factory()->create(['user_id' => $user->id]);
        
        $this->order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $user->id,
            'status' => 'pending',
        ]);
    }

    /** @test */
    public function it_belongs_to_a_pharmacy()
    {
        $this->assertInstanceOf(Pharmacy::class, $this->order->pharmacy);
        $this->assertEquals($this->pharmacy->id, $this->order->pharmacy->id);
    }

    /** @test */
    public function it_belongs_to_a_customer()
    {
        $this->assertInstanceOf(User::class, $this->order->customer);
    }

    /** @test */
    public function it_has_many_items()
    {
        OrderItem::factory()->count(3)->create([
            'order_id' => $this->order->id,
        ]);

        $this->assertCount(3, $this->order->items);
        $this->assertInstanceOf(OrderItem::class, $this->order->items->first());
    }

    /** @test */
    public function it_has_one_delivery()
    {
        $delivery = Delivery::factory()->create([
            'order_id' => $this->order->id,
        ]);

        $this->assertInstanceOf(Delivery::class, $this->order->delivery);
        $this->assertEquals($delivery->id, $this->order->delivery->id);
    }

    /** @test */
    public function it_generates_unique_reference()
    {
        $ref1 = Order::generateReference();
        $ref2 = Order::generateReference();

        $this->assertNotEquals($ref1, $ref2);
        $this->assertStringStartsWith('DR-', $ref1);
        $this->assertStringStartsWith('DR-', $ref2);
    }

    /** @test */
    public function it_auto_generates_delivery_code_on_creation()
    {
        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $this->customer->user_id,
            'delivery_code' => null,
        ]);

        $this->assertNotNull($order->delivery_code);
        $this->assertEquals(4, strlen($order->delivery_code));
    }

    /** @test */
    public function delivery_code_is_4_digits()
    {
        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $this->customer->user_id,
        ]);

        $this->assertMatchesRegularExpression('/^\d{4}$/', $order->delivery_code);
    }

    /** @test */
    public function it_casts_amounts_to_decimal()
    {
        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $this->customer->user_id,
            'subtotal' => 1000.50,
            'total_amount' => 1200.75,
        ]);

        $this->assertIsString($order->subtotal);
        $this->assertEquals('1000.50', $order->subtotal);
    }

    /** @test */
    public function it_casts_dates_correctly()
    {
        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $this->customer->user_id,
            'confirmed_at' => now(),
            'delivered_at' => now(),
        ]);

        $this->assertInstanceOf(\Carbon\Carbon::class, $order->confirmed_at);
        $this->assertInstanceOf(\Carbon\Carbon::class, $order->delivered_at);
    }

    /** @test */
    public function scope_paid_returns_paid_orders()
    {
        Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $this->customer->user_id,
            'status' => 'confirmed',
        ]);
        
        Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $this->customer->user_id,
            'status' => 'delivered',
        ]);
        
        Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $this->customer->user_id,
            'status' => 'pending', // Not paid
        ]);

        $paidOrders = Order::paid()->get();

        $this->assertEquals(2, $paidOrders->count());
        foreach ($paidOrders as $order) {
            $this->assertContains($order->status, ['confirmed', 'preparing', 'ready_for_pickup', 'on_the_way', 'delivered']);
        }
    }

    /** @test */
    public function scope_for_pharmacy_filters_by_pharmacy()
    {
        $otherPharmacy = Pharmacy::factory()->create();
        
        Order::factory()->create([
            'pharmacy_id' => $otherPharmacy->id,
            'customer_id' => $this->customer->user_id,
        ]);

        $orders = Order::forPharmacy($this->pharmacy->id)->get();

        $this->assertEquals(1, $orders->count());
        $this->assertEquals($this->pharmacy->id, $orders->first()->pharmacy_id);
    }

    /** @test */
    public function it_soft_deletes()
    {
        $this->order->delete();

        $this->assertSoftDeleted($this->order);
        $this->assertNull(Order::find($this->order->id));
        $this->assertNotNull(Order::withTrashed()->find($this->order->id));
    }

    /** @test */
    public function it_has_many_payments()
    {
        Payment::factory()->count(2)->create([
            'order_id' => $this->order->id,
        ]);

        $this->assertCount(2, $this->order->payments);
    }

    /** @test */
    public function it_has_one_commission()
    {
        Commission::factory()->create([
            'order_id' => $this->order->id,
        ]);

        $this->assertInstanceOf(Commission::class, $this->order->commission);
    }

    /** @test */
    public function it_stores_delivery_coordinates()
    {
        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $this->customer->user_id,
            'delivery_latitude' => 5.3600123,
            'delivery_longitude' => -4.0083456,
        ]);

        // Check precision is maintained
        $this->assertEquals(5.3600123, (float)$order->delivery_latitude);
        $this->assertEquals(-4.0083456, (float)$order->delivery_longitude);
    }

    /** @test */
    public function it_stores_cancellation_info()
    {
        $this->order->update([
            'status' => 'cancelled',
            'cancelled_at' => now(),
            'cancellation_reason' => 'Customer requested',
        ]);

        $this->order->refresh();

        $this->assertEquals('cancelled', $this->order->status);
        $this->assertNotNull($this->order->cancelled_at);
        $this->assertEquals('Customer requested', $this->order->cancellation_reason);
    }

    /** @test */
    public function it_has_fillable_attributes()
    {
        $order = new Order();
        
        $this->assertContains('reference', $order->getFillable());
        $this->assertContains('pharmacy_id', $order->getFillable());
        $this->assertContains('customer_id', $order->getFillable());
        $this->assertContains('status', $order->getFillable());
        $this->assertContains('total_amount', $order->getFillable());
    }
}
