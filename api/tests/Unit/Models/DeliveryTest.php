<?php

namespace Tests\Unit\Models;

use App\Models\Courier;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class DeliveryTest extends TestCase
{
    use RefreshDatabase;

    private Delivery $delivery;
    private Order $order;
    private Courier $courier;

    protected function setUp(): void
    {
        parent::setUp();
        
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        $courierUser = User::factory()->create(['role' => 'courier']);
        $this->courier = Courier::factory()->create(['user_id' => $courierUser->id]);
        
        $this->order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);
        
        $this->delivery = Delivery::factory()->create([
            'order_id' => $this->order->id,
            'courier_id' => $this->courier->id,
        ]);
    }

    #[Test]
    public function it_belongs_to_order()
    {
        $this->assertInstanceOf(Order::class, $this->delivery->order);
        $this->assertEquals($this->order->id, $this->delivery->order->id);
    }

    #[Test]
    public function it_belongs_to_courier()
    {
        $this->assertInstanceOf(Courier::class, $this->delivery->courier);
        $this->assertEquals($this->courier->id, $this->delivery->courier->id);
    }

    #[Test]
    public function it_identifies_waiting_delivery()
    {
        $this->delivery->update([
            'waiting_started_at' => now()->subMinutes(5),
            'waiting_ended_at' => null,
            'auto_cancelled_at' => null,
        ]);

        $this->assertTrue($this->delivery->isWaiting());
    }

    #[Test]
    public function it_identifies_non_waiting_delivery()
    {
        $this->delivery->update([
            'waiting_started_at' => null,
            'waiting_ended_at' => null,
            'auto_cancelled_at' => null,
        ]);

        $this->assertFalse($this->delivery->isWaiting());
    }

    #[Test]
    public function it_identifies_ended_waiting()
    {
        $this->delivery->update([
            'waiting_started_at' => now()->subMinutes(10),
            'waiting_ended_at' => now(),
            'auto_cancelled_at' => null,
        ]);

        $this->assertFalse($this->delivery->isWaiting());
    }

    #[Test]
    public function it_identifies_auto_cancelled_delivery()
    {
        $this->delivery->update([
            'auto_cancelled_at' => now(),
        ]);

        $this->assertTrue($this->delivery->wasAutoCancelled());
    }

    #[Test]
    public function it_identifies_not_auto_cancelled_delivery()
    {
        $this->delivery->update([
            'auto_cancelled_at' => null,
        ]);

        $this->assertFalse($this->delivery->wasAutoCancelled());
    }

    #[Test]
    public function it_scopes_in_progress_deliveries()
    {
        // Create deliveries with different statuses
        $assignedDelivery = Delivery::factory()->create([
            'order_id' => Order::factory()->create()->id,
            'status' => 'assigned'
        ]);
        
        $completedDelivery = Delivery::factory()->create([
            'order_id' => Order::factory()->create()->id,
            'status' => 'delivered'
        ]);
        
        $cancelledDelivery = Delivery::factory()->create([
            'order_id' => Order::factory()->create()->id,
            'status' => 'cancelled'
        ]);

        $inProgressIds = Delivery::inProgress()->pluck('id')->toArray();

        $this->assertContains($assignedDelivery->id, $inProgressIds);
        $this->assertNotContains($completedDelivery->id, $inProgressIds);
        $this->assertNotContains($cancelledDelivery->id, $inProgressIds);
    }

    #[Test]
    public function it_scopes_deliveries_for_courier()
    {
        $otherCourier = Courier::factory()->create();
        
        $otherDelivery = Delivery::factory()->create([
            'order_id' => Order::factory()->create()->id,
            'courier_id' => $otherCourier->id,
        ]);

        $courierDeliveries = Delivery::forCourier($this->courier->id)->get();

        $this->assertTrue($courierDeliveries->contains($this->delivery));
        $this->assertFalse($courierDeliveries->contains($otherDelivery));
    }

    #[Test]
    public function it_scopes_waiting_deliveries()
    {
        $waitingDelivery = Delivery::factory()->create([
            'order_id' => Order::factory()->create()->id,
            'waiting_started_at' => now()->subMinutes(5),
            'waiting_ended_at' => null,
            'auto_cancelled_at' => null,
        ]);
        
        $notWaitingDelivery = Delivery::factory()->create([
            'order_id' => Order::factory()->create()->id,
            'waiting_started_at' => null,
        ]);
        
        $cancelledDelivery = Delivery::factory()->create([
            'order_id' => Order::factory()->create()->id,
            'waiting_started_at' => now()->subMinutes(30),
            'auto_cancelled_at' => now(),
        ]);

        $waitingIds = Delivery::waiting()->pluck('id')->toArray();

        $this->assertContains($waitingDelivery->id, $waitingIds);
        $this->assertNotContains($notWaitingDelivery->id, $waitingIds);
        $this->assertNotContains($cancelledDelivery->id, $waitingIds);
    }

    #[Test]
    public function it_casts_coordinates_as_decimal()
    {
        $this->delivery->update([
            'pickup_latitude' => 6.1292837,
            'pickup_longitude' => 1.2345678,
        ]);

        $this->delivery->refresh();

        $this->assertIsString($this->delivery->pickup_latitude);
        $this->assertIsString($this->delivery->pickup_longitude);
    }

    #[Test]
    public function it_casts_timestamps_as_datetime()
    {
        $this->delivery->update([
            'assigned_at' => now(),
            'accepted_at' => now(),
            'picked_up_at' => now(),
            'delivered_at' => now(),
        ]);

        $this->delivery->refresh();

        $this->assertInstanceOf(\Illuminate\Support\Carbon::class, $this->delivery->assigned_at);
        $this->assertInstanceOf(\Illuminate\Support\Carbon::class, $this->delivery->accepted_at);
        $this->assertInstanceOf(\Illuminate\Support\Carbon::class, $this->delivery->picked_up_at);
        $this->assertInstanceOf(\Illuminate\Support\Carbon::class, $this->delivery->delivered_at);
    }

    #[Test]
    public function it_uses_soft_deletes()
    {
        $deliveryId = $this->delivery->id;
        $this->delivery->delete();

        $this->assertSoftDeleted('deliveries', ['id' => $deliveryId]);
        $this->assertNotNull(Delivery::withTrashed()->find($deliveryId));
    }
}
