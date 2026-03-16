<?php

namespace Tests\Unit\Listeners;

use App\Listeners\CalculateOrderCommission;
use App\Events\PaymentConfirmed;
use App\Actions\CalculateCommissionAction;
use App\Models\Payment;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use App\Models\Customer;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Queue;
use Mockery;
use Tests\TestCase;

class CalculateOrderCommissionTest extends TestCase
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
    public function it_can_be_constructed_with_action()
    {
        $action = Mockery::mock(CalculateCommissionAction::class);
        $listener = new CalculateOrderCommission($action);

        $this->assertInstanceOf(CalculateOrderCommission::class, $listener);
    }

    /** @test */
    public function it_implements_should_queue()
    {
        $action = Mockery::mock(CalculateCommissionAction::class);
        $listener = new CalculateOrderCommission($action);

        $this->assertInstanceOf(\Illuminate\Contracts\Queue\ShouldQueue::class, $listener);
    }

    /** @test */
    public function it_executes_calculate_commission_action()
    {
        $action = Mockery::mock(CalculateCommissionAction::class);
        $action->shouldReceive('execute')
            ->once()
            ->with(Mockery::on(function ($order) {
                return $order->id === $this->order->id;
            }));

        $listener = new CalculateOrderCommission($action);
        $event = new PaymentConfirmed($this->payment);

        $listener->handle($event);
    }

    /** @test */
    public function it_logs_commission_calculation_start()
    {
        Log::shouldReceive('info')
            ->once()
            ->with('Calculating commission for order', Mockery::on(function ($context) {
                return $context['order_id'] === $this->order->id;
            }));

        Log::shouldReceive('info')
            ->once()
            ->with('Commission calculated successfully', Mockery::any());

        $action = Mockery::mock(CalculateCommissionAction::class);
        $action->shouldReceive('execute')->once();

        $listener = new CalculateOrderCommission($action);
        $event = new PaymentConfirmed($this->payment);

        $listener->handle($event);
    }

    /** @test */
    public function it_logs_error_on_failure()
    {
        Log::shouldReceive('info')->once();
        Log::shouldReceive('error')
            ->once()
            ->with('Failed to calculate commission', Mockery::on(function ($context) {
                return isset($context['payment_id']) && isset($context['error']);
            }));

        $action = Mockery::mock(CalculateCommissionAction::class);
        $action->shouldReceive('execute')
            ->andThrow(new \Exception('Calculation failed'));

        $listener = new CalculateOrderCommission($action);
        $event = new PaymentConfirmed($this->payment);

        $this->expectException(\Exception::class);
        $listener->handle($event);
    }

    /** @test */
    public function it_rethrows_exception_for_queue_retry()
    {
        $action = Mockery::mock(CalculateCommissionAction::class);
        $action->shouldReceive('execute')
            ->andThrow(new \Exception('Database error'));

        $listener = new CalculateOrderCommission($action);
        $event = new PaymentConfirmed($this->payment);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Database error');

        $listener->handle($event);
    }

    /** @test */
    public function listener_is_triggered_by_event()
    {
        Event::fake();

        PaymentConfirmed::dispatch($this->payment);

        Event::assertDispatched(PaymentConfirmed::class, function ($event) {
            return $event->payment->id === $this->payment->id;
        });
    }
}
