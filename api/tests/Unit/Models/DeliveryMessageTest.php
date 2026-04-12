<?php

namespace Tests\Unit\Models;

use App\Models\DeliveryMessage;
use App\Models\Delivery;
use App\Models\Customer;
use App\Models\Courier;
use App\Models\Order;
use App\Models\Pharmacy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeliveryMessageTest extends TestCase
{
    use RefreshDatabase;

    public function test_fillable_fields(): void
    {
        $model = new DeliveryMessage();
        $fillable = $model->getFillable();
        $this->assertContains('delivery_id', $fillable);
        $this->assertContains('sender_type', $fillable);
        $this->assertContains('sender_id', $fillable);
        $this->assertContains('receiver_type', $fillable);
        $this->assertContains('receiver_id', $fillable);
        $this->assertContains('message', $fillable);
        $this->assertContains('read_at', $fillable);
    }

    public function test_casts(): void
    {
        $model = new DeliveryMessage();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('read_at', $casts);
        $this->assertEquals('datetime', $casts['read_at']);
    }

    public function test_has_delivery_relationship(): void
    {
        $model = new DeliveryMessage();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->delivery());
    }

    public function test_scope_for_conversation_filters_messages_between_two_participants(): void
    {
        $customer = Customer::factory()->create();
        $courier = Courier::factory()->create();
        $pharmacy = Pharmacy::factory()->create();

        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
        ]);

        // Message from customer to courier
        $message1 = DeliveryMessage::create([
            'delivery_id' => $delivery->id,
            'sender_type' => Customer::class,
            'sender_id' => $customer->id,
            'receiver_type' => Courier::class,
            'receiver_id' => $courier->id,
            'message' => 'Hello courier!',
        ]);

        // Message from courier to customer
        $message2 = DeliveryMessage::create([
            'delivery_id' => $delivery->id,
            'sender_type' => Courier::class,
            'sender_id' => $courier->id,
            'receiver_type' => Customer::class,
            'receiver_id' => $customer->id,
            'message' => 'Hello customer!',
        ]);

        // Message from customer to pharmacy (different conversation)
        $message3 = DeliveryMessage::create([
            'delivery_id' => $delivery->id,
            'sender_type' => Customer::class,
            'sender_id' => $customer->id,
            'receiver_type' => Pharmacy::class,
            'receiver_id' => $pharmacy->id,
            'message' => 'Hello pharmacy!',
        ]);

        // Test conversation between customer and courier
        $conversation = DeliveryMessage::forConversation(
            $delivery->id,
            Customer::class,
            $customer->id,
            Courier::class,
            $courier->id
        )->get();

        $this->assertCount(2, $conversation);
        $this->assertTrue($conversation->contains($message1));
        $this->assertTrue($conversation->contains($message2));
        $this->assertFalse($conversation->contains($message3));
    }

    public function test_scope_for_conversation_with_reversed_participants(): void
    {
        $customer = Customer::factory()->create();
        $courier = Courier::factory()->create();
        $pharmacy = Pharmacy::factory()->create();

        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
        ]);

        // Message from customer to courier
        DeliveryMessage::create([
            'delivery_id' => $delivery->id,
            'sender_type' => Customer::class,
            'sender_id' => $customer->id,
            'receiver_type' => Courier::class,
            'receiver_id' => $courier->id,
            'message' => 'Test message',
        ]);

        // Should get same results when querying from courier perspective
        $fromCourier = DeliveryMessage::forConversation(
            $delivery->id,
            Courier::class,
            $courier->id,
            Customer::class,
            $customer->id
        )->get();

        $fromCustomer = DeliveryMessage::forConversation(
            $delivery->id,
            Customer::class,
            $customer->id,
            Courier::class,
            $courier->id
        )->get();

        $this->assertEquals($fromCourier->count(), $fromCustomer->count());
    }

    public function test_scope_for_conversation_filters_by_delivery_id(): void
    {
        $customer = Customer::factory()->create();
        $courier = Courier::factory()->create();
        $pharmacy = Pharmacy::factory()->create();

        $order1 = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $order2 = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $delivery1 = Delivery::factory()->create([
            'order_id' => $order1->id,
            'courier_id' => $courier->id,
        ]);

        $delivery2 = Delivery::factory()->create([
            'order_id' => $order2->id,
            'courier_id' => $courier->id,
        ]);

        // Message for delivery 1
        $message1 = DeliveryMessage::create([
            'delivery_id' => $delivery1->id,
            'sender_type' => Customer::class,
            'sender_id' => $customer->id,
            'receiver_type' => Courier::class,
            'receiver_id' => $courier->id,
            'message' => 'Delivery 1 message',
        ]);

        // Message for delivery 2
        $message2 = DeliveryMessage::create([
            'delivery_id' => $delivery2->id,
            'sender_type' => Customer::class,
            'sender_id' => $customer->id,
            'receiver_type' => Courier::class,
            'receiver_id' => $courier->id,
            'message' => 'Delivery 2 message',
        ]);

        $conversation1 = DeliveryMessage::forConversation(
            $delivery1->id,
            Customer::class,
            $customer->id,
            Courier::class,
            $courier->id
        )->get();

        $conversation2 = DeliveryMessage::forConversation(
            $delivery2->id,
            Customer::class,
            $customer->id,
            Courier::class,
            $courier->id
        )->get();

        $this->assertCount(1, $conversation1);
        $this->assertCount(1, $conversation2);
        $this->assertTrue($conversation1->contains($message1));
        $this->assertTrue($conversation2->contains($message2));
    }

    public function test_scope_for_conversation_returns_empty_when_no_messages(): void
    {
        $customer = Customer::factory()->create();
        $courier = Courier::factory()->create();
        $pharmacy = Pharmacy::factory()->create();

        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
        ]);

        $conversation = DeliveryMessage::forConversation(
            $delivery->id,
            Customer::class,
            $customer->id,
            Courier::class,
            $courier->id
        )->get();

        $this->assertCount(0, $conversation);
    }

    public function test_read_at_is_cast_to_datetime(): void
    {
        $customer = Customer::factory()->create();
        $courier = Courier::factory()->create();
        $pharmacy = Pharmacy::factory()->create();

        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
        ]);

        $message = DeliveryMessage::create([
            'delivery_id' => $delivery->id,
            'sender_type' => Customer::class,
            'sender_id' => $customer->id,
            'receiver_type' => Courier::class,
            'receiver_id' => $courier->id,
            'message' => 'Test message',
            'read_at' => now(),
        ]);

        $this->assertInstanceOf(\Illuminate\Support\Carbon::class, $message->read_at);
    }

    public function test_delivery_relationship_returns_delivery(): void
    {
        $customer = Customer::factory()->create();
        $courier = Courier::factory()->create();
        $pharmacy = Pharmacy::factory()->create();

        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
        ]);

        $message = DeliveryMessage::create([
            'delivery_id' => $delivery->id,
            'sender_type' => Customer::class,
            'sender_id' => $customer->id,
            'receiver_type' => Courier::class,
            'receiver_id' => $courier->id,
            'message' => 'Test message',
        ]);

        $this->assertInstanceOf(Delivery::class, $message->delivery);
        $this->assertEquals($delivery->id, $message->delivery->id);
    }
}
