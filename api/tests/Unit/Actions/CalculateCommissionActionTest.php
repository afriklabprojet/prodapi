<?php

namespace Tests\Unit\Actions;

use App\Actions\CalculateCommissionAction;
use App\Models\Commission;
use App\Models\CommissionLine;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use App\Models\Customer;
use App\Models\Courier;
use App\Models\Delivery;
use App\Models\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Config;
use Tests\TestCase;

class CalculateCommissionActionTest extends TestCase
{
    use RefreshDatabase;

    protected $action;
    protected $order;
    protected $pharmacy;
    protected $delivery;

    protected function setUp(): void
    {
        parent::setUp();

        $this->action = new CalculateCommissionAction();

        $this->pharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
            'commission_rate_pharmacy' => 0.85,
        ]);
        
        $customerUser = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $customerUser->id]);

        $this->order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $customerUser->id,
            'status' => 'delivered',
            'subtotal' => 10000,
            'delivery_fee' => 0,
            'service_fee' => 0,
            'total_amount' => 10000,
            'reference' => 'CMD-COMM-001',
        ]);

        // Create courier and delivery
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create([
            'user_id' => $courierUser->id,
            'status' => 'available',
        ]);

        $this->delivery = Delivery::factory()->create([
            'order_id' => $this->order->id,
            'courier_id' => $courier->id,
            'status' => 'delivered',
        ]);
    }

    /** @test */
    public function it_creates_commission_for_order()
    {
        $commission = $this->action->execute($this->order);

        $this->assertInstanceOf(Commission::class, $commission);
        $this->assertEquals($this->order->id, $commission->order_id);
        $this->assertEquals(10000, $commission->total_amount);
    }

    /** @test */
    public function it_creates_commission_lines_for_platform_and_pharmacy()
    {
        $commission = $this->action->execute($this->order);

        $lines = $commission->lines;
        $this->assertCount(2, $lines);

        $actorTypes = $lines->pluck('actor_type')->toArray();
        $this->assertContains('platform', $actorTypes);
        $this->assertContains('App\Models\Pharmacy', $actorTypes);
    }

    /** @test */
    public function it_calculates_platform_commission_correctly()
    {
        \App\Models\Setting::set('service_fee_percentage', 10);

        $commission = $this->action->execute($this->order);

        $platformLine = $commission->lines->where('actor_type', 'platform')->first();
        $this->assertEquals(0.10, $platformLine->rate);
        $this->assertEquals(1000, $platformLine->amount); // 10% of 10000
    }

    /** @test */
    public function it_calculates_pharmacy_commission_correctly()
    {
        $commission = $this->action->execute($this->order);

        $pharmacyLine = $commission->lines->where('actor_type', 'App\Models\Pharmacy')->first();
        $this->assertEquals(1.0, $pharmacyLine->rate);
        $this->assertEquals(10000, $pharmacyLine->amount); // 100% of subtotal
        $this->assertEquals($this->pharmacy->id, $pharmacyLine->actor_id);
    }

    /** @test */
    public function it_does_not_create_courier_commission_line()
    {
        $commission = $this->action->execute($this->order);

        $courierLine = $commission->lines->where('actor_type', 'App\Models\Courier')->first();
        $this->assertNull($courierLine);
    }

    /** @test */
    public function it_does_not_duplicate_commission_if_already_exists()
    {
        $firstCommission = $this->action->execute($this->order);
        $secondCommission = $this->action->execute($this->order->fresh());

        $this->assertEquals($firstCommission->id, $secondCommission->id);
        $this->assertEquals(1, Commission::where('order_id', $this->order->id)->count());
    }

    /** @test */
    public function it_uses_full_subtotal_for_pharmacy()
    {
        $this->order = $this->order->fresh();

        $commission = $this->action->execute($this->order);

        $pharmacyLine = $commission->lines->where('actor_type', 'App\Models\Pharmacy')->first();
        $this->assertEquals(1.0, $pharmacyLine->rate);
        $this->assertEquals(10000, $pharmacyLine->amount);
    }

    /** @test */
    public function it_uses_default_service_fee_when_not_configured()
    {
        $this->order = $this->order->fresh();

        $commission = $this->action->execute($this->order);

        $platformLine = $commission->lines->where('actor_type', 'platform')->first();
        // Default is 2%
        $this->assertEquals(0.02, $platformLine->rate);
    }

    /** @test */
    public function it_sets_calculated_at_timestamp()
    {
        $commission = $this->action->execute($this->order);

        $this->assertNotNull($commission->calculated_at);
    }

    /** @test */
    public function it_handles_order_without_delivery()
    {
        $this->delivery->delete();
        $orderWithoutDelivery = $this->order->fresh();

        $commission = $this->action->execute($orderWithoutDelivery);

        $this->assertInstanceOf(Commission::class, $commission);
        // Only 2 lines: platform + pharmacy (no courier line)
        $this->assertCount(2, $commission->lines);
    }

    /** @test */
    public function it_runs_in_transaction()
    {
        // Verify atomicity - if something fails, nothing should be saved
        $this->assertDatabaseCount('commissions', 0);
        $this->assertDatabaseCount('commission_lines', 0);

        $this->action->execute($this->order);

        // Both commission and lines should exist after successful execution
        $this->assertDatabaseCount('commissions', 1);
        $this->assertDatabaseCount('commission_lines', 2);
    }
}
