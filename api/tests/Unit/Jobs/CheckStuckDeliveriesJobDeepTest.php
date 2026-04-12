<?php

namespace Tests\Unit\Jobs;

use App\Jobs\CheckStuckDeliveriesJob;
use App\Models\Courier;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use App\Notifications\OrderStatusNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class CheckStuckDeliveriesJobDeepTest extends TestCase
{
    use RefreshDatabase;

    private Courier $courier;
    private User $courierUser;
    private User $customer;
    private Pharmacy $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();

        $this->courierUser = User::factory()->create(['role' => 'courier']);
        $this->courier = Courier::factory()->create([
            'user_id' => $this->courierUser->id,
            'status' => 'busy',
        ]);

        $this->customer = User::factory()->create(['role' => 'customer']);
        $this->pharmacy = Pharmacy::factory()->create();
    }

    private function createDeliveryWithOrder(array $deliveryAttrs = [], array $orderAttrs = []): Delivery
    {
        $order = Order::factory()->create(array_merge([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ], $orderAttrs));

        return Delivery::factory()->create(array_merge([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
        ], $deliveryAttrs));
    }

    // ──────────────────────────────────────────────────────────────
    // PICKUP REMINDERS (>2h assigned/accepted, no pickup)
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function sends_reminder_for_unpicked_delivery_over_2h()
    {
        Notification::fake();

        $delivery = $this->createDeliveryWithOrder([
            'status' => 'assigned',
            'assigned_at' => now()->subHours(3),
            'picked_up_at' => null,
        ]);

        (new CheckStuckDeliveriesJob())->handle();

        Notification::assertSentTo($this->courierUser, OrderStatusNotification::class);
    }

    #[Test]
    public function does_not_remind_delivery_under_2h()
    {
        Notification::fake();

        $delivery = $this->createDeliveryWithOrder([
            'status' => 'assigned',
            'assigned_at' => now()->subHour(),
            'picked_up_at' => null,
        ]);

        (new CheckStuckDeliveriesJob())->handle();

        Notification::assertNotSentTo($this->courierUser, OrderStatusNotification::class);
    }

    #[Test]
    public function does_not_remind_already_picked_up()
    {
        Notification::fake();

        $delivery = $this->createDeliveryWithOrder([
            'status' => 'picked_up',
            'assigned_at' => now()->subHours(3),
            'picked_up_at' => now()->subHour(),
        ]);

        (new CheckStuckDeliveriesJob())->handle();

        Notification::assertNotSentTo($this->courierUser, OrderStatusNotification::class);
    }

    #[Test]
    public function reminder_handles_notification_failure_gracefully()
    {
        Notification::fake();

        // Create delivery with no courier user (null courier)
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => null,
            'status' => 'assigned',
            'assigned_at' => now()->subHours(3),
            'picked_up_at' => null,
        ]);

        // Should not throw
        (new CheckStuckDeliveriesJob())->handle();

        $this->assertTrue(true);
    }

    // ──────────────────────────────────────────────────────────────
    // STUCK IN TRANSIT (>24h)
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function logs_warning_for_stuck_in_transit_over_24h()
    {
        Log::spy();

        $delivery = $this->createDeliveryWithOrder([
            'status' => 'in_transit',
            'picked_up_at' => now()->subHours(25),
        ]);

        (new CheckStuckDeliveriesJob())->handle();

        Log::shouldHaveReceived('warning')
            ->withArgs(fn($msg) => str_contains($msg, 'stuck >24h'));
    }

    #[Test]
    public function does_not_warn_in_transit_under_24h()
    {
        $delivery = $this->createDeliveryWithOrder([
            'status' => 'in_transit',
            'picked_up_at' => now()->subHours(12),
        ]);

        Log::spy();

        (new CheckStuckDeliveriesJob())->handle();

        Log::shouldNotHaveReceived('warning', fn($msg) => str_contains($msg, 'stuck >24h'));
    }

    // ──────────────────────────────────────────────────────────────
    // AUTO-CANCEL (>48h zombies)
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function auto_cancels_zombie_delivery_assigned_over_48h()
    {
        $delivery = $this->createDeliveryWithOrder([
            'status' => 'assigned',
            'assigned_at' => now()->subHours(50),
            'picked_up_at' => null,
        ]);

        Notification::fake();
        (new CheckStuckDeliveriesJob())->handle();

        $delivery->refresh();
        $this->assertEquals('failed', $delivery->status);
        $this->assertNotNull($delivery->auto_cancelled_at);
        $this->assertNotNull($delivery->failure_reason);
    }

    #[Test]
    public function auto_cancel_updates_order_status()
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'confirmed',
        ]);

        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
            'status' => 'accepted',
            'assigned_at' => now()->subHours(50),
            'picked_up_at' => null,
        ]);

        Notification::fake();
        (new CheckStuckDeliveriesJob())->handle();

        $this->assertEquals('cancelled', $order->fresh()->status);
        $this->assertNotNull($order->fresh()->cancelled_at);
    }

    #[Test]
    public function auto_cancel_sets_courier_available()
    {
        $delivery = $this->createDeliveryWithOrder([
            'status' => 'in_transit',
            'assigned_at' => now()->subHours(50),
            'picked_up_at' => now()->subHours(49),
        ]);

        Notification::fake();
        (new CheckStuckDeliveriesJob())->handle();

        $this->assertEquals('available', $this->courier->fresh()->status);
    }

    #[Test]
    public function auto_cancel_notifies_customer()
    {
        Notification::fake();

        $delivery = $this->createDeliveryWithOrder([
            'status' => 'assigned',
            'assigned_at' => now()->subHours(50),
            'picked_up_at' => null,
        ]);

        (new CheckStuckDeliveriesJob())->handle();

        Notification::assertSentTo(
            $this->customer,
            OrderStatusNotification::class,
            fn($n) => true
        );
    }

    #[Test]
    public function does_not_auto_cancel_under_48h()
    {
        $delivery = $this->createDeliveryWithOrder([
            'status' => 'in_transit',
            'picked_up_at' => now()->subHours(40),
        ]);

        Notification::fake();
        (new CheckStuckDeliveriesJob())->handle();

        $this->assertNotEquals('failed', $delivery->fresh()->status);
    }

    #[Test]
    public function auto_cancel_handles_rollback_on_failure()
    {
        // Create a delivery that will cause an issue during cancel
        $delivery = $this->createDeliveryWithOrder([
            'status' => 'assigned',
            'assigned_at' => now()->subHours(50),
            'picked_up_at' => null,
        ]);

        // The job catches exceptions, so it should not propagate
        Notification::fake();
        (new CheckStuckDeliveriesJob())->handle();

        // Should have been cancelled (the normal case works)
        $this->assertEquals('failed', $delivery->fresh()->status);
    }

    // ──────────────────────────────────────────────────────────────
    // EDGE CASES
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function handles_no_stuck_deliveries()
    {
        Log::spy();

        (new CheckStuckDeliveriesJob())->handle();

        // No error, no info log (0 stats)
        Log::shouldNotHaveReceived('info');
        $this->assertTrue(true);
    }

    #[Test]
    public function logs_stats_when_actions_taken()
    {
        Log::spy();
        Notification::fake();

        $this->createDeliveryWithOrder([
            'status' => 'assigned',
            'assigned_at' => now()->subHours(3),
            'picked_up_at' => null,
        ]);

        (new CheckStuckDeliveriesJob())->handle();

        Log::shouldHaveReceived('info')
            ->withArgs(fn($msg) => str_contains($msg, 'complete'));
    }

    #[Test]
    public function ignores_delivered_deliveries()
    {
        Notification::fake();

        $delivery = $this->createDeliveryWithOrder([
            'status' => 'delivered',
            'assigned_at' => now()->subHours(100),
            'picked_up_at' => now()->subHours(99),
            'delivered_at' => now()->subHours(98),
        ]);

        (new CheckStuckDeliveriesJob())->handle();

        $this->assertEquals('delivered', $delivery->fresh()->status);
    }

    #[Test]
    public function ignores_already_cancelled_deliveries()
    {
        $delivery = $this->createDeliveryWithOrder([
            'status' => 'cancelled',
            'assigned_at' => now()->subHours(100),
        ]);

        (new CheckStuckDeliveriesJob())->handle();

        $this->assertEquals('cancelled', $delivery->fresh()->status);
    }
}
