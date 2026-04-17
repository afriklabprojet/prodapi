<?php

namespace Tests\Feature\Api\Customer;

use App\Models\Courier;
use App\Models\Customer;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RatingControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Order $order;

    protected function setUp(): void
    {
        parent::setUp();

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->user = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $this->user->id]);

        $this->order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $this->user->id,
            'status' => 'delivered',
        ]);
    }

    public function test_customer_can_rate_delivered_order(): void
    {
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);
        Delivery::factory()->create([
            'order_id' => $this->order->id,
            'courier_id' => $courier->id,
            'status' => 'delivered',
        ]);

        $response = $this->actingAs($this->user)->postJson("/api/customer/orders/{$this->order->id}/rate", [
            'courier_rating' => 5,
            'courier_comment' => 'Très bon service',
            'pharmacy_rating' => 4,
        ]);

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_cannot_rate_non_delivered_order(): void
    {
        $this->order->update(['status' => 'pending']);

        $response = $this->actingAs($this->user)->postJson("/api/customer/orders/{$this->order->id}/rate", [
            'pharmacy_rating' => 4,
        ]);

        $response->assertStatus(404);
    }

    public function test_rating_validates_range(): void
    {
        $response = $this->actingAs($this->user)->postJson("/api/customer/orders/{$this->order->id}/rate", [
            'courier_rating' => 6,
        ]);

        $response->assertStatus(422);
    }

    public function test_cannot_rate_other_users_order(): void
    {
        $otherUser = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $otherUser->id]);

        $response = $this->actingAs($otherUser)->postJson("/api/customer/orders/{$this->order->id}/rate", [
            'pharmacy_rating' => 4,
        ]);

        $response->assertStatus(404);
    }

    public function test_customer_can_view_order_rating(): void
    {
        $response = $this->actingAs($this->user)->getJson("/api/customer/orders/{$this->order->id}/rating");

        $response->assertOk();
    }

    public function test_unauthenticated_cannot_rate(): void
    {
        $response = $this->postJson("/api/customer/orders/{$this->order->id}/rate", [
            'pharmacy_rating' => 4,
        ]);

        $response->assertStatus(401);
    }
}
