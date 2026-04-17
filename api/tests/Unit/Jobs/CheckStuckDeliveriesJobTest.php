<?php

namespace Tests\Unit\Jobs;

use App\Jobs\CheckStuckDeliveriesJob;
use App\Models\Courier;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\User;
use App\Models\Pharmacy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class CheckStuckDeliveriesJobTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Log::spy();
        Notification::fake();
    }

    #[Test]
    public function it_sends_reminder_to_courier_for_unpicked_delivery_after_2_hours()
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);
        
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
            'status' => 'confirmed',
        ]);
        
        Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
            'status' => 'assigned',
            'assigned_at' => now()->subHours(3),
            'picked_up_at' => null,
        ]);
        
        (new CheckStuckDeliveriesJob())->handle();
        
        // Should have sent reminder notification
        Notification::assertSentTo($courierUser, \App\Notifications\OrderStatusNotification::class);
    }

    #[Test]
    public function it_does_not_remind_courier_for_recent_assigned_delivery()
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);
        
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
            'status' => 'confirmed',
        ]);
        
        Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
            'status' => 'assigned',
            'assigned_at' => now()->subMinutes(30), // < 2h
            'picked_up_at' => null,
        ]);
        
        (new CheckStuckDeliveriesJob())->handle();
        
        // Should NOT have sent reminder
        Notification::assertNothingSent();
    }

    #[Test]
    public function it_skips_already_picked_up_deliveries()
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);
        
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
            'status' => 'confirmed',
        ]);
        
        Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
            'status' => 'picked_up',
            'assigned_at' => now()->subHours(3),
            'picked_up_at' => now()->subHours(2), // Already picked up
        ]);
        
        (new CheckStuckDeliveriesJob())->handle();
        
        // No reminder for picked up deliveries
        Notification::assertNothingSent();
    }

    #[Test]
    public function it_uses_without_overlapping_middleware()
    {
        $job = new CheckStuckDeliveriesJob();
        $middleware = $job->middleware();
        
        $this->assertNotEmpty($middleware);
        $this->assertInstanceOf(
            \Illuminate\Queue\Middleware\WithoutOverlapping::class,
            $middleware[0]
        );
    }

    #[Test]
    public function it_has_appropriate_timeout_and_tries()
    {
        $job = new CheckStuckDeliveriesJob();
        
        $this->assertEquals(2, $job->tries);
        $this->assertEquals(120, $job->timeout);
    }

    #[Test]
    public function it_handles_deliveries_without_courier()
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
            'status' => 'confirmed',
        ]);
        
        Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => null,
            'status' => 'assigned',
            'assigned_at' => now()->subHours(3),
            'picked_up_at' => null,
        ]);
        
        // Should not throw exception
        (new CheckStuckDeliveriesJob())->handle();
        
        $this->assertTrue(true);
    }

    #[Test]
    public function it_processes_accepted_status_deliveries()
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);
        
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
            'status' => 'confirmed',
        ]);
        
        Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
            'status' => 'accepted',
            'assigned_at' => now()->subHours(3),
            'picked_up_at' => null,
        ]);
        
        (new CheckStuckDeliveriesJob())->handle();
        
        Notification::assertSentTo($courierUser, \App\Notifications\OrderStatusNotification::class);
    }
}
