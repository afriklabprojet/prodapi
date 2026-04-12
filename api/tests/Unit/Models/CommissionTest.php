<?php

namespace Tests\Unit\Models;

use App\Models\Commission;
use App\Models\CommissionLine;
use App\Models\Courier;
use App\Models\Customer;
use App\Models\Order;
use App\Models\Pharmacy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class CommissionTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_belongs_to_order()
    {
        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);
        
        $commission = Commission::factory()->create([
            'order_id' => $order->id,
        ]);

        $this->assertInstanceOf(Order::class, $commission->order);
        $this->assertEquals($order->id, $commission->order->id);
    }

    #[Test]
    public function it_has_many_lines()
    {
        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);
        
        $commission = Commission::factory()->create([
            'order_id' => $order->id,
        ]);

        // Create commission lines
        CommissionLine::create([
            'commission_id' => $commission->id,
            'actor_type' => 'platform',
            'actor_id' => 0,
            'rate' => 5.00,
            'amount' => 100,
        ]);

        CommissionLine::create([
            'commission_id' => $commission->id,
            'actor_type' => Pharmacy::class,
            'actor_id' => $pharmacy->id,
            'rate' => 10.00,
            'amount' => 250,
        ]);

        $this->assertEquals(2, $commission->lines()->count());
    }

    #[Test]
    public function it_gets_platform_amount()
    {
        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);
        
        $commission = Commission::factory()->create([
            'order_id' => $order->id,
            'total_amount' => 500,
        ]);

        CommissionLine::create([
            'commission_id' => $commission->id,
            'actor_type' => 'platform',
            'actor_id' => 0,
            'rate' => 5.00,
            'amount' => 150,
        ]);

        $this->assertEquals(150, $commission->getPlatformAmount());
    }

    #[Test]
    public function it_returns_zero_when_no_platform_commission()
    {
        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);
        
        $commission = Commission::factory()->create([
            'order_id' => $order->id,
        ]);

        $this->assertEquals(0, $commission->getPlatformAmount());
    }

    #[Test]
    public function it_gets_pharmacy_amount()
    {
        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);
        
        $commission = Commission::factory()->create([
            'order_id' => $order->id,
        ]);

        CommissionLine::create([
            'commission_id' => $commission->id,
            'actor_type' => Pharmacy::class,
            'actor_id' => $pharmacy->id,
            'rate' => 8.00,
            'amount' => 300,
        ]);

        $this->assertEquals(300, $commission->getPharmacyAmount());
    }

    #[Test]
    public function it_returns_zero_when_no_pharmacy_commission()
    {
        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);
        
        $commission = Commission::factory()->create([
            'order_id' => $order->id,
        ]);

        $this->assertEquals(0, $commission->getPharmacyAmount());
    }

    #[Test]
    public function it_gets_courier_amount()
    {
        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $courier = Courier::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);
        
        $commission = Commission::factory()->create([
            'order_id' => $order->id,
        ]);

        CommissionLine::create([
            'commission_id' => $commission->id,
            'actor_type' => Courier::class,
            'actor_id' => $courier->id,
            'rate' => 15.00,
            'amount' => 200,
        ]);

        $this->assertEquals(200, $commission->getCourierAmount());
    }

    #[Test]
    public function it_returns_zero_when_no_courier_commission()
    {
        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);
        
        $commission = Commission::factory()->create([
            'order_id' => $order->id,
        ]);

        $this->assertEquals(0, $commission->getCourierAmount());
    }

    #[Test]
    public function it_casts_total_amount_as_decimal()
    {
        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);
        
        $commission = Commission::factory()->create([
            'order_id' => $order->id,
            'total_amount' => '1234.56',
        ]);

        // Should be stored as decimal
        $this->assertEquals('1234.56', $commission->total_amount);
    }
}
