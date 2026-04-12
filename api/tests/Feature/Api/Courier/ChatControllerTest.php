<?php

namespace Tests\Feature\Api\Courier;

use App\Models\Courier;
use App\Models\Customer;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ChatControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $courierUser;
    protected Delivery $delivery;
    protected User $customerUser;

    protected function setUp(): void
    {
        parent::setUp();

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->customerUser = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $this->customerUser->id]);

        $this->courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $this->courierUser->id]);

        $order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $this->customerUser->id,
            'status' => 'in_delivery',
        ]);

        $this->delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
            'status' => 'in_transit',
        ]);
    }

    public function test_courier_can_list_messages(): void
    {
        $response = $this->actingAs($this->courierUser)->getJson(
            "/api/courier/orders/{$this->delivery->id}/messages"
        );

        $response->assertOk();
    }

    public function test_send_message_validates_required_fields(): void
    {
        $response = $this->actingAs($this->courierUser)->postJson(
            "/api/courier/orders/{$this->delivery->id}/messages",
            []
        );

        $response->assertStatus(422);
    }

    public function test_send_message_validates_receiver_type(): void
    {
        $response = $this->actingAs($this->courierUser)->postJson(
            "/api/courier/orders/{$this->delivery->id}/messages",
            [
                'receiver_type' => 'invalid',
                'receiver_id' => $this->customerUser->id,
                'message' => 'Test',
            ]
        );

        $response->assertStatus(422)->assertJsonValidationErrors('receiver_type');
    }

    public function test_send_message_validates_message_length(): void
    {
        $response = $this->actingAs($this->courierUser)->postJson(
            "/api/courier/orders/{$this->delivery->id}/messages",
            [
                'receiver_type' => 'client',
                'receiver_id' => $this->customerUser->id,
                'message' => str_repeat('a', 1001),
            ]
        );

        $response->assertStatus(422)->assertJsonValidationErrors('message');
    }

    public function test_unauthenticated_cannot_send_message(): void
    {
        $response = $this->postJson(
            "/api/courier/orders/{$this->delivery->id}/messages",
            [
                'receiver_type' => 'client',
                'receiver_id' => 1,
                'message' => 'Test',
            ]
        );

        $response->assertStatus(401);
    }
}
