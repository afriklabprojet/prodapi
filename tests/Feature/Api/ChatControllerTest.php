<?php

namespace Tests\Feature\Api;

use App\Models\Courier;
use App\Models\Customer;
use App\Models\Delivery;
use App\Models\DeliveryMessage;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class ChatControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $customerUser;
    protected User $courierUser;
    protected Courier $courier;
    protected Delivery $delivery;

    protected function setUp(): void
    {
        parent::setUp();

        Notification::fake();

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->customerUser = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $this->customerUser->id]);

        $this->courierUser = User::factory()->create(['role' => 'courier']);
        $this->courier = Courier::factory()->create(['user_id' => $this->courierUser->id]);

        $order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $this->customerUser->id,
            'status' => 'in_delivery',
        ]);

        $this->delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
            'status' => 'in_transit',
        ]);
    }

    public function test_customer_can_get_empty_chat_messages(): void
    {
        $response = $this->actingAs($this->customerUser)->getJson(
            "/api/customer/deliveries/{$this->delivery->id}/chat?participant_type=courier&participant_id={$this->courier->id}"
        );

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['messages', 'delivery']);

        $this->assertCount(0, $response->json('messages'));
    }

    public function test_customer_can_get_existing_messages(): void
    {
        DeliveryMessage::create([
            'delivery_id' => $this->delivery->id,
            'sender_type' => 'client',
            'sender_id' => $this->customerUser->id,
            'receiver_type' => 'courier',
            'receiver_id' => $this->courier->id,
            'message' => 'Bonjour',
        ]);

        $response = $this->actingAs($this->customerUser)->getJson(
            "/api/customer/deliveries/{$this->delivery->id}/chat?participant_type=courier&participant_id={$this->courier->id}"
        );

        $response->assertOk();
        $this->assertCount(1, $response->json('messages'));
        $this->assertEquals('Bonjour', $response->json('messages.0.message'));
        $this->assertTrue($response->json('messages.0.is_mine'));
    }

    public function test_customer_can_send_message(): void
    {
        $response = $this->actingAs($this->customerUser)->postJson(
            "/api/customer/deliveries/{$this->delivery->id}/chat",
            [
                'receiver_type' => 'courier',
                'receiver_id' => $this->courier->id,
                'message' => 'Je suis au portail bleu',
            ]
        );

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('message.message', 'Je suis au portail bleu')
            ->assertJsonPath('message.is_mine', true);

        $this->assertDatabaseHas('delivery_messages', [
            'delivery_id' => $this->delivery->id,
            'message' => 'Je suis au portail bleu',
            'sender_type' => 'client',
        ]);
    }

    public function test_courier_can_send_message(): void
    {
        $response = $this->actingAs($this->courierUser)->postJson(
            "/api/courier/deliveries/{$this->delivery->id}/chat",
            [
                'receiver_type' => 'client',
                'receiver_id' => $this->customerUser->id,
                'message' => 'Je suis en route',
            ]
        );

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('message.message', 'Je suis en route');

        $this->assertDatabaseHas('delivery_messages', [
            'delivery_id' => $this->delivery->id,
            'message' => 'Je suis en route',
            'sender_type' => 'courier',
        ]);
    }

    public function test_customer_can_get_unread_count(): void
    {
        DeliveryMessage::create([
            'delivery_id' => $this->delivery->id,
            'sender_type' => 'courier',
            'sender_id' => $this->courier->id,
            'receiver_type' => 'client',
            'receiver_id' => $this->customerUser->id,
            'message' => 'Unread msg',
        ]);

        $response = $this->actingAs($this->customerUser)->getJson(
            "/api/customer/deliveries/{$this->delivery->id}/chat/unread"
        );

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('unread_count', 1);
    }

    public function test_reading_messages_marks_them_as_read(): void
    {
        DeliveryMessage::create([
            'delivery_id' => $this->delivery->id,
            'sender_type' => 'courier',
            'sender_id' => $this->courier->id,
            'receiver_type' => 'client',
            'receiver_id' => $this->customerUser->id,
            'message' => 'To be read',
        ]);

        $this->actingAs($this->customerUser)->getJson(
            "/api/customer/deliveries/{$this->delivery->id}/chat?participant_type=courier&participant_id={$this->courier->id}"
        );

        $msg = DeliveryMessage::first();
        $this->assertNotNull($msg->read_at);
    }

    public function test_send_message_validates_required_fields(): void
    {
        $response = $this->actingAs($this->customerUser)->postJson(
            "/api/customer/deliveries/{$this->delivery->id}/chat",
            []
        );

        $response->assertStatus(422);
    }

    public function test_send_message_validates_message_length(): void
    {
        $response = $this->actingAs($this->customerUser)->postJson(
            "/api/customer/deliveries/{$this->delivery->id}/chat",
            [
                'receiver_type' => 'courier',
                'receiver_id' => $this->courier->id,
                'message' => str_repeat('a', 1001),
            ]
        );

        $response->assertStatus(422)->assertJsonValidationErrors('message');
    }

    public function test_unauthenticated_cannot_access_chat(): void
    {
        $response = $this->getJson("/api/customer/deliveries/{$this->delivery->id}/chat?participant_type=courier&participant_id=1");

        $response->assertStatus(401);
    }
}
