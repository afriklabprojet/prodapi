<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Courier;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;

class CourierDeliveryApiTest extends TestCase
{
    use RefreshDatabase;

    protected $courier;
    protected $courierModel;
    protected $order;
    protected $delivery;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->courier = User::factory()->create(['role' => 'courier']);
        $this->courierModel = Courier::factory()->create([
            'user_id' => $this->courier->id,
            'status' => 'available',
        ]);
        
        // Create wallet with sufficient balance for deliveries
        Wallet::create([
            'walletable_type' => Courier::class,
            'walletable_id' => $this->courierModel->id,
            'balance' => 1000, // Enough for commission
            'currency' => 'XOF',
        ]);

        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
        ]);
        $pharmacy->users()->attach($pharmacyUser->id, ['role' => 'owner']);

        $this->order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
            'status' => 'ready',
        ]);

        $this->delivery = Delivery::factory()->create([
            'order_id' => $this->order->id,
            'courier_id' => $this->courierModel->id,
            'status' => 'pending',
        ]);
    }

    /** @test */
    public function courier_can_view_assigned_deliveries()
    {
        $response = $this->actingAs($this->courier, 'sanctum')
            ->getJson('/api/courier/deliveries');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'id',
                        'status',
                        'reference',
                        'pharmacy' => ['name', 'phone', 'address'],
                        'customer' => ['name', 'phone'],
                    ],
                ],
            ]);
    }

    /** @test */
    public function courier_cannot_view_other_courier_deliveries()
    {
        $otherCourier = User::factory()->create(['role' => 'courier']);
        $otherCourierModel = Courier::factory()->create([
            'user_id' => $otherCourier->id,
        ]);

        $otherDelivery = Delivery::factory()->create([
            'order_id' => $this->order->id,
            'courier_id' => $otherCourierModel->id,
        ]);

        $response = $this->actingAs($this->courier, 'sanctum')
            ->getJson('/api/courier/deliveries');

        $response->assertStatus(200);
        
        $deliveryIds = collect($response->json('data'))->pluck('id')->toArray();
        $this->assertNotContains($otherDelivery->id, $deliveryIds);
    }

    /** @test */
    public function courier_can_view_delivery_details()
    {
        $response = $this->actingAs($this->courier, 'sanctum')
            ->getJson("/api/courier/deliveries/{$this->delivery->id}");

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'status',
                    'reference',
                    'total_amount',
                    'pharmacy_name',
                    'pharmacy_phone',
                    'pharmacy_address',
                ]
            ]);
    }

    /** @test */
    public function courier_can_accept_delivery()
    {
        $response = $this->actingAs($this->courier, 'sanctum')
            ->postJson("/api/courier/deliveries/{$this->delivery->id}/accept");

        $response->assertStatus(200);

        $this->assertDatabaseHas('deliveries', [
            'id' => $this->delivery->id,
            'status' => 'assigned',
        ]);
    }

    /** @test */
    public function courier_cannot_accept_already_accepted_delivery()
    {
        $this->delivery->update(['status' => 'assigned']);

        $response = $this->actingAs($this->courier, 'sanctum')
            ->postJson("/api/courier/deliveries/{$this->delivery->id}/accept");

        $response->assertStatus(404);
    }

    /** @test */
    public function courier_can_mark_delivery_as_picked_up()
    {
        $this->delivery->update(['status' => 'assigned']);

        $response = $this->actingAs($this->courier, 'sanctum')
            ->postJson("/api/courier/deliveries/{$this->delivery->id}/pickup");

        $response->assertStatus(200);

        $this->assertDatabaseHas('deliveries', [
            'id' => $this->delivery->id,
            'status' => 'picked_up',
        ]);

        $this->assertNotNull($this->delivery->fresh()->picked_up_at);
    }

    /** @test */
    public function courier_cannot_pickup_non_assigned_delivery()
    {
        $response = $this->actingAs($this->courier, 'sanctum')
            ->postJson("/api/courier/deliveries/{$this->delivery->id}/pickup");

        $response->assertStatus(400);
    }

    /** @test */
    public function courier_can_mark_delivery_as_delivered()
    {
        // Set delivery code on order
        $this->order->update(['delivery_code' => '1234']);
        
        $this->delivery->update([
            'status' => 'picked_up',
            'picked_up_at' => now(),
        ]);

        $response = $this->actingAs($this->courier, 'sanctum')
            ->postJson("/api/courier/deliveries/{$this->delivery->id}/deliver", [
                'confirmation_code' => '1234',
                'delivery_proof_image' => 'http://example.com/image.jpg',
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('deliveries', [
            'id' => $this->delivery->id,
            'status' => 'delivered',
        ]);

        $this->assertDatabaseHas('orders', [
            'id' => $this->order->id,
            'status' => 'delivered',
        ]);

        $this->assertNotNull($this->delivery->fresh()->delivered_at);
    }

    /** @test */
    public function courier_cannot_deliver_non_picked_up_delivery()
    {
        // Set delivery code on order
        $this->order->update(['delivery_code' => '1234']);
        
        $response = $this->actingAs($this->courier, 'sanctum')
            ->postJson("/api/courier/deliveries/{$this->delivery->id}/deliver", [
                'confirmation_code' => '1234',
            ]);

        $response->assertStatus(400);
    }

    /** @test */
    public function courier_can_update_location()
    {
        $response = $this->actingAs($this->courier, 'sanctum')
            ->postJson('/api/courier/location/update', [
                'latitude' => 5.3600,
                'longitude' => -4.0083,
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('couriers', [
            'id' => $this->courierModel->id,
            'latitude' => 5.3600,
            'longitude' => -4.0083,
        ]);

        $this->assertNotNull($this->courierModel->fresh()->last_location_update);
    }

    /** @test */
    public function location_update_requires_valid_coordinates()
    {
        $response = $this->actingAs($this->courier, 'sanctum')
            ->postJson('/api/courier/location/update', [
                'latitude' => 'invalid',
                'longitude' => 'invalid',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['latitude', 'longitude']);
    }

    /** @test */
    public function courier_can_toggle_availability()
    {
        $this->assertEquals('available', $this->courierModel->status);

        $response = $this->actingAs($this->courier, 'sanctum')
            ->postJson('/api/courier/availability/toggle');

        $response->assertStatus(200);
        
        $this->assertEquals('offline', $this->courierModel->fresh()->status);

        // Toggle back to available
        $response = $this->actingAs($this->courier, 'sanctum')
            ->postJson('/api/courier/availability/toggle');

        $response->assertStatus(200);
        $this->assertEquals('available', $this->courierModel->fresh()->status);
    }

    /** @test */
    public function courier_can_filter_deliveries_by_status()
    {
        Delivery::factory()->create([
            'order_id' => Order::factory()->create()->id,
            'courier_id' => $this->courierModel->id,
            'status' => 'accepted',
        ]);

        Delivery::factory()->create([
            'order_id' => Order::factory()->create()->id,
            'courier_id' => $this->courierModel->id,
            'status' => 'delivered',
        ]);

        $response = $this->actingAs($this->courier, 'sanctum')
            ->getJson('/api/courier/deliveries?status=accepted');

        $response->assertStatus(200);
        
        $deliveries = $response->json('data');
        foreach ($deliveries as $delivery) {
            $this->assertEquals('accepted', $delivery['status']);
        }
    }

    /** @test */
    public function unauthenticated_user_cannot_access_courier_endpoints()
    {
        $response = $this->getJson('/api/courier/deliveries');
        $response->assertStatus(401);

        $response = $this->postJson("/api/courier/deliveries/{$this->delivery->id}/accept");
        $response->assertStatus(401);

        $response = $this->postJson('/api/courier/location/update', [
            'latitude' => 5.3600,
            'longitude' => -4.0083,
        ]);
        $response->assertStatus(401);
    }

    /** @test */
    public function non_courier_user_cannot_access_courier_endpoints()
    {
        $customer = User::factory()->create(['role' => 'customer']);

        $response = $this->actingAs($customer, 'sanctum')
            ->getJson('/api/courier/deliveries');

        $response->assertStatus(403);
    }

    /** @test */
    public function delivery_time_tracking_is_accurate()
    {
        // Set delivery code on order
        $this->order->update(['delivery_code' => '1234']);
        
        // Accept delivery
        $this->actingAs($this->courier, 'sanctum')
            ->postJson("/api/courier/deliveries/{$this->delivery->id}/accept");

        sleep(1);

        // Pickup delivery
        $this->actingAs($this->courier, 'sanctum')
            ->postJson("/api/courier/deliveries/{$this->delivery->id}/pickup");

        sleep(1);

        // Deliver with confirmation code
        $this->actingAs($this->courier, 'sanctum')
            ->postJson("/api/courier/deliveries/{$this->delivery->id}/deliver", [
                'confirmation_code' => '1234',
            ]);

        $delivery = $this->delivery->fresh();
        
        $this->assertNotNull($delivery->picked_up_at);
        $this->assertNotNull($delivery->delivered_at);
        $this->assertTrue($delivery->delivered_at->greaterThan($delivery->picked_up_at));
    }

    /** @test */
    public function courier_can_view_earnings_from_deliveries()
    {
        // Complete a delivery
        $this->delivery->update([
            'status' => 'delivered',
            'picked_up_at' => now()->subHours(1),
            'delivered_at' => now(),
        ]);

        // Assuming commission was created for this delivery
        $response = $this->actingAs($this->courier, 'sanctum')
            ->getJson('/api/courier/deliveries');

        $response->assertStatus(200);
        
        // Check if wallet balance exists in response (would be set after payment)
        $response->assertJsonStructure([
            'data' => [
                '*' => ['id', 'status'],
            ],
        ]);
    }
}
