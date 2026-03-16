<?php

namespace Tests\Unit\Listeners;

use App\Listeners\DistributeCommissions;
use App\Events\PaymentConfirmed;
use App\Services\CommissionService;
use App\Models\Payment;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use App\Models\Customer;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery;
use Tests\TestCase;

class DistributeCommissionsTest extends TestCase
{
    use RefreshDatabase;

    protected $payment;
    protected $order;

    protected function setUp(): void
    {
        parent::setUp();

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $customerUser = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $customerUser->id]);

        $this->order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $customerUser->id,
            'status' => 'confirmed',
            'total_amount' => 15000,
        ]);

        $this->payment = Payment::factory()->create([
            'order_id' => $this->order->id,
            'amount' => 15000,
            'status' => 'SUCCESS',
        ]);
    }

    protected function tearDown(): void
    {
        if ($container = Mockery::getContainer()) {
            $this->addToAssertionCount($container->mockery_getExpectationCount());
        }
        Mockery::close();
        parent::tearDown();
    }

    /** @test */
    public function it_can_be_constructed_with_commission_service()
    {
        $service = Mockery::mock(CommissionService::class);
        $listener = new DistributeCommissions($service);

        $this->assertInstanceOf(DistributeCommissions::class, $listener);
    }

    /** @test */
    public function it_implements_should_queue()
    {
        $service = Mockery::mock(CommissionService::class);
        $listener = new DistributeCommissions($service);

        $this->assertInstanceOf(\Illuminate\Contracts\Queue\ShouldQueue::class, $listener);
    }

    /** @test */
    public function it_calls_calculate_and_distribute_on_commission_service()
    {
        $service = Mockery::mock(CommissionService::class);
        $service->shouldReceive('calculateAndDistribute')
            ->once()
            ->with(Mockery::on(function ($order) {
                return $order->id === $this->order->id;
            }));

        $listener = new DistributeCommissions($service);
        $event = new PaymentConfirmed($this->payment);

        $listener->handle($event);
    }

    /** @test */
    public function it_does_not_distribute_if_order_is_null()
    {
        // Create payment without order
        $paymentWithoutOrder = Mockery::mock(Payment::class)->shouldIgnoreMissing();
        $paymentWithoutOrder->shouldReceive('getAttribute')
            ->with('order')
            ->andReturn(null);
        $paymentWithoutOrder->order = null;

        $event = new PaymentConfirmed($paymentWithoutOrder);

        $service = Mockery::mock(CommissionService::class);
        $service->shouldNotReceive('calculateAndDistribute');

        $listener = new DistributeCommissions($service);
        $listener->handle($event);
    }

    /** @test */
    public function it_handles_payment_with_valid_order()
    {
        $service = Mockery::mock(CommissionService::class);
        $service->shouldReceive('calculateAndDistribute')
            ->once()
            ->andReturnNull();

        $listener = new DistributeCommissions($service);
        $event = new PaymentConfirmed($this->payment);

        // Should not throw
        $listener->handle($event);
        $this->assertTrue(true);
    }

    /** @test */
    public function it_uses_interacts_with_queue_trait()
    {
        $service = Mockery::mock(CommissionService::class);
        $listener = new DistributeCommissions($service);

        $this->assertTrue(in_array(
            \Illuminate\Queue\InteractsWithQueue::class,
            class_uses_recursive($listener)
        ));
    }
}
