<?php

namespace Tests\Unit\Jobs;

use App\Jobs\CancelStaleOrdersJob;
use App\Models\Order;
use App\Models\User;
use App\Models\Pharmacy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class CancelStaleOrdersJobTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Log::spy();
        Notification::fake();
        
        // Disable observers to avoid external service calls (Firestore, etc.)
        Order::unsetEventDispatcher();
    }
    
    protected function tearDown(): void
    {
        // Re-enable observers
        Order::observe(\App\Observers\OrderObserver::class);
        parent::tearDown();
    }

    #[Test]
    public function it_cancels_pending_unpaid_orders_after_30_minutes()
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        
        // Old unpaid order (should be cancelled)
        $staleOrder = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
            'status' => 'pending',
            'payment_mode' => 'platform',
            'payment_status' => 'pending',
            'cancelled_at' => null,
        ]);
        
        // Use DB to bypass mass assignment protection for created_at
        \Illuminate\Support\Facades\DB::table('orders')
            ->where('id', $staleOrder->id)
            ->update(['created_at' => now()->subMinutes(35)]);
        
        // Recent unpaid order (should NOT be cancelled)
        $recentOrder = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
            'status' => 'pending',
            'payment_mode' => 'platform',
            'payment_status' => 'pending',
            'cancelled_at' => null,
        ]);
        
        // Verify setup
        $staleOrder->refresh();
        $this->assertNull($staleOrder->cancelled_at);
        $this->assertEquals('pending', $staleOrder->status);
        $this->assertLessThan(now()->subMinutes(30), $staleOrder->created_at);
        
        (new CancelStaleOrdersJob())->handle();
        
        $staleOrder->refresh();
        $recentOrder->refresh();
        
        $this->assertEquals('cancelled', $staleOrder->status);
        $this->assertEquals('pending', $recentOrder->status);
    }

    #[Test]
    public function it_cancels_pending_cash_orders_after_2_hours()
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        
        // Old cash order not confirmed (should be cancelled)
        $staleCashOrder = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
            'status' => 'pending',
            'payment_mode' => 'cash',
            'payment_status' => 'pending',
        ]);
        
        // Use DB to bypass mass assignment protection
        \Illuminate\Support\Facades\DB::table('orders')
            ->where('id', $staleCashOrder->id)
            ->update(['created_at' => now()->subMinutes(125)]);
        
        // Recent cash order (should NOT be cancelled)
        $recentCashOrder = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
            'status' => 'pending',
            'payment_mode' => 'cash',
            'payment_status' => 'pending',
        ]);
        
        (new CancelStaleOrdersJob())->handle();
        
        $staleCashOrder->refresh();
        $recentCashOrder->refresh();
        
        $this->assertEquals('cancelled', $staleCashOrder->status);
        $this->assertEquals('pending', $recentCashOrder->status);
    }

    #[Test]
    public function it_does_not_cancel_confirmed_orders()
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        
        $confirmedOrder = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
            'status' => 'confirmed',
            'payment_mode' => 'platform',
            'payment_status' => 'paid',
            'created_at' => now()->subHours(1),
        ]);
        
        (new CancelStaleOrdersJob())->handle();
        
        $confirmedOrder->refresh();
        
        // Still confirmed (not cancelled by the "pending unpaid" rule)
        $this->assertEquals('confirmed', $confirmedOrder->status);
    }

    #[Test]
    public function it_does_not_cancel_already_cancelled_orders()
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        
        $cancelledOrder = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
            'status' => 'cancelled',
            'payment_mode' => 'platform',
            'payment_status' => 'pending',
            'created_at' => now()->subMinutes(60),
            'cancelled_at' => now()->subMinutes(30),
        ]);
        
        (new CancelStaleOrdersJob())->handle();
        
        $cancelledOrder->refresh();
        
        $this->assertEquals('cancelled', $cancelledOrder->status);
    }

    #[Test]
    public function it_logs_cancellation_stats()
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        
        Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
            'status' => 'pending',
            'payment_mode' => 'platform',
            'payment_status' => 'pending',
            'created_at' => now()->subMinutes(40),
        ]);
        
        (new CancelStaleOrdersJob())->handle();
        
        Log::shouldHaveReceived('info');
    }

    #[Test]
    public function it_uses_without_overlapping_middleware()
    {
        $job = new CancelStaleOrdersJob();
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
        $job = new CancelStaleOrdersJob();
        
        $this->assertEquals(3, $job->tries);
        $this->assertEquals(180, $job->timeout);
    }

    #[Test]
    public function it_does_not_cancel_paid_pending_orders_within_30_minutes()
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        
        // Paid order (should NOT be cancelled by unpaid rule)
        $paidOrder = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
            'status' => 'pending',
            'payment_mode' => 'platform',
            'payment_status' => 'paid',
            'created_at' => now()->subMinutes(25), // < 30 min
        ]);
        
        (new CancelStaleOrdersJob())->handle();
        
        $paidOrder->refresh();
        
        $this->assertEquals('pending', $paidOrder->status);
    }
}
