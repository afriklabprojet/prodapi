<?php

namespace Tests\Unit\Events;

use App\Events\PaymentConfirmed;
use App\Models\Payment;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use App\Models\Customer;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Tests\TestCase;

class PaymentConfirmedTest extends TestCase
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

    /** @test */
    public function it_can_be_constructed_with_payment()
    {
        $event = new PaymentConfirmed($this->payment);

        $this->assertInstanceOf(PaymentConfirmed::class, $event);
        $this->assertEquals($this->payment->id, $event->payment->id);
    }

    /** @test */
    public function it_contains_payment_data()
    {
        $event = new PaymentConfirmed($this->payment);

        $this->assertEquals($this->order->id, $event->payment->order_id);
        $this->assertEquals(15000, $event->payment->amount);
        $this->assertEquals('SUCCESS', $event->payment->status);
    }

    /** @test */
    public function event_can_be_dispatched()
    {
        Event::fake();

        PaymentConfirmed::dispatch($this->payment);

        Event::assertDispatched(PaymentConfirmed::class, function ($event) {
            return $event->payment->id === $this->payment->id;
        });
    }

    /** @test */
    public function event_uses_dispatchable_trait()
    {
        $event = new PaymentConfirmed($this->payment);

        $this->assertTrue(method_exists($event, 'dispatch'));
    }

    /** @test */
    public function event_serializes_models()
    {
        $event = new PaymentConfirmed($this->payment);
        
        // SerializesModels trait is used
        $this->assertTrue(in_array(
            \Illuminate\Queue\SerializesModels::class,
            class_uses_recursive($event)
        ));
    }
}
