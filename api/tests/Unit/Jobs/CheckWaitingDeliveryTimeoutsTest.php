<?php

namespace Tests\Unit\Jobs;

use App\Jobs\CheckWaitingDeliveryTimeouts;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Courier;
use App\Models\User;
use App\Models\Pharmacy;
use App\Models\Customer;
use App\Models\Setting;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class CheckWaitingDeliveryTimeoutsTest extends TestCase
{
    use RefreshDatabase;

    protected $pharmacy;
    protected $customer;
    protected $courier;
    protected $order;
    protected $delivery;

    protected function setUp(): void
    {
        parent::setUp();

        Notification::fake();

        $this->pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        
        $customerUser = User::factory()->create(['role' => 'customer']);
        $this->customer = Customer::factory()->create(['user_id' => $customerUser->id]);

        $courierUser = User::factory()->create(['role' => 'courier']);
        $this->courier = Courier::factory()->create([
            'user_id' => $courierUser->id,
            'status' => 'busy',
        ]);

        $this->order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $customerUser->id,
            'status' => 'in_delivery',
        ]);

        $this->delivery = Delivery::factory()->create([
            'order_id' => $this->order->id,
            'courier_id' => $this->courier->id,
            'status' => 'in_transit',
            'waiting_started_at' => null,
            'waiting_ended_at' => null,
        ]);

        // Set default settings
        Setting::set('waiting_timeout_minutes', 10);
        Setting::set('waiting_fee_per_minute', 100);
        Setting::set('waiting_free_minutes', 2);
    }

    /** @test */
    public function job_can_be_queued()
    {
        Queue::fake();

        CheckWaitingDeliveryTimeouts::dispatch();

        Queue::assertPushed(CheckWaitingDeliveryTimeouts::class);
    }

    /** @test */
    public function it_cancels_deliveries_that_exceeded_timeout()
    {
        // Set waiting started 15 minutes ago (exceeds 10 min timeout)
        $this->delivery->update([
            'waiting_started_at' => Carbon::now()->subMinutes(15),
        ]);

        $job = new CheckWaitingDeliveryTimeouts();
        $job->handle();

        $this->delivery->refresh();

        $this->assertEquals('cancelled', $this->delivery->status);
        $this->assertNotNull($this->delivery->auto_cancelled_at);
    }

    /** @test */
    public function it_does_not_cancel_deliveries_within_timeout()
    {
        // Set waiting started 5 minutes ago (within 10 min timeout)
        $this->delivery->update([
            'waiting_started_at' => Carbon::now()->subMinutes(5),
        ]);

        $job = new CheckWaitingDeliveryTimeouts();
        $job->handle();

        $this->delivery->refresh();

        $this->assertEquals('in_transit', $this->delivery->status);
        $this->assertNull($this->delivery->auto_cancelled_at);
    }

    /** @test */
    public function it_calculates_waiting_fee_correctly()
    {
        // Freeze time to avoid timing issues (use startOfMinute to avoid microsecond drift)
        $now = Carbon::now()->startOfMinute();
        Carbon::setTestNow($now);

        // Set waiting started 15 minutes ago
        // Fee = (15 - 2 free) * 100 = 1300 FCFA
        $this->delivery->update([
            'waiting_started_at' => $now->copy()->subMinutes(15),
        ]);

        $job = new CheckWaitingDeliveryTimeouts();
        $job->handle();

        $this->delivery->refresh();

        $this->assertEquals(1300, $this->delivery->waiting_fee);

        Carbon::setTestNow(); // Reset
    }

    /** @test */
    public function it_respects_free_minutes_in_fee_calculation()
    {
        Setting::set('waiting_free_minutes', 5);

        // Freeze time to avoid timing issues (use startOfMinute to avoid microsecond drift)
        $now = Carbon::now()->startOfMinute();
        Carbon::setTestNow($now);

        // Set waiting started 12 minutes ago
        // Fee = (12 - 5 free) * 100 = 700 FCFA
        $this->delivery->update([
            'waiting_started_at' => $now->copy()->subMinutes(12),
        ]);

        $job = new CheckWaitingDeliveryTimeouts();
        $job->handle();

        $this->delivery->refresh();

        $this->assertEquals(700, $this->delivery->waiting_fee);

        Carbon::setTestNow(); // Reset
    }

    /** @test */
    public function it_updates_order_status_when_cancelled()
    {
        $this->delivery->update([
            'waiting_started_at' => Carbon::now()->subMinutes(15),
        ]);

        $job = new CheckWaitingDeliveryTimeouts();
        $job->handle();

        $this->order->refresh();

        $this->assertEquals('cancelled', $this->order->status);
    }

    /** @test */
    public function it_skips_deliveries_without_waiting_started()
    {
        // No waiting_started_at set
        $this->delivery->update([
            'waiting_started_at' => null,
        ]);

        $job = new CheckWaitingDeliveryTimeouts();
        $job->handle();

        $this->delivery->refresh();

        $this->assertEquals('in_transit', $this->delivery->status);
    }

    /** @test */
    public function it_skips_already_cancelled_deliveries()
    {
        $this->delivery->update([
            'waiting_started_at' => Carbon::now()->subMinutes(15),
            'auto_cancelled_at' => Carbon::now()->subMinutes(5), // Already cancelled
        ]);

        $job = new CheckWaitingDeliveryTimeouts();
        $job->handle();

        $this->delivery->refresh();

        // Should remain in_transit since it was already processed
        $this->assertEquals('in_transit', $this->delivery->status);
    }

    /** @test */
    public function it_uses_configurable_timeout_setting()
    {
        Setting::set('waiting_timeout_minutes', 20);

        // 15 minutes - within 20 min timeout
        $this->delivery->update([
            'waiting_started_at' => Carbon::now()->subMinutes(15),
        ]);

        $job = new CheckWaitingDeliveryTimeouts();
        $job->handle();

        $this->delivery->refresh();

        // Should NOT be cancelled (15 < 20)
        $this->assertEquals('in_transit', $this->delivery->status);
    }

    /** @test */
    public function it_sets_cancellation_reason()
    {
        $this->delivery->update([
            'waiting_started_at' => Carbon::now()->subMinutes(15),
        ]);

        $job = new CheckWaitingDeliveryTimeouts();
        $job->handle();

        $this->delivery->refresh();

        $this->assertStringContainsString('Annulation automatique', $this->delivery->cancellation_reason);
        $this->assertStringContainsString('non disponible', $this->delivery->cancellation_reason);
    }

    /** @test */
    public function it_only_processes_in_transit_deliveries()
    {
        $this->delivery->update([
            'status' => 'assigned', // Not in_transit
            'waiting_started_at' => Carbon::now()->subMinutes(15),
        ]);

        $job = new CheckWaitingDeliveryTimeouts();
        $job->handle();

        $this->delivery->refresh();

        $this->assertEquals('assigned', $this->delivery->status);
        $this->assertNull($this->delivery->auto_cancelled_at);
    }
}
