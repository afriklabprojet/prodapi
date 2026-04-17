<?php

namespace Tests\Feature\Api\Courier;

use App\Models\User;
use App\Models\Courier;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Customer;
use App\Services\WalletService;
use App\Services\WaitingFeeService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Mockery;
use PHPUnit\Framework\Attributes\Test;

class DeliveryControllerTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $courier;
    protected $pharmacy;
    protected $customer;
    protected $order;
    protected $delivery;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'courier']);
        $this->courier = Courier::factory()->create([
            'user_id' => $this->user->id,
            'status' => 'available',
        ]);

        $this->pharmacy = Pharmacy::factory()->create();
        $this->customer = Customer::factory()->create();
        $this->order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $this->customer->id,
            'status' => 'confirmed',
            'delivery_fee' => 1000,
            'delivery_code' => '1234',
        ]);

        $this->delivery = Delivery::factory()->create([
            'order_id' => $this->order->id,
            'courier_id' => null,
            'status' => 'pending',
        ]);
    }

    #[Test]
    public function courier_can_list_pending_deliveries()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/deliveries?status=pending');

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'data' => [
                    '*' => [
                        'id',
                        'status',
                        'pharmacy_name',
                        'customer_name',
                        'delivery_address',
                        'total_amount',
                        'delivery_fee',
                    ],
                ],
                'meta' => [
                    'current_page',
                    'last_page',
                    'per_page',
                    'total',
                ],
            ]);
    }

    #[Test]
    public function courier_can_list_active_deliveries()
    {
        // Assign delivery to courier
        $this->delivery->update([
            'courier_id' => $this->courier->id,
            'status' => 'assigned',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/deliveries?status=active');

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    #[Test]
    public function courier_can_list_delivery_history()
    {
        $this->delivery->update([
            'courier_id' => $this->courier->id,
            'status' => 'delivered',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/deliveries?status=history');

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    #[Test]
    public function courier_can_view_delivery_details()
    {
        $this->delivery->update([
            'courier_id' => $this->courier->id,
            'status' => 'assigned',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/courier/deliveries/{$this->delivery->id}");

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'data' => [
                    'id',
                    'status',
                    'pharmacy_name',
                    'customer_name',
                    'delivery_address',
                ],
            ]);
    }

    #[Test]
    public function courier_can_accept_pending_delivery()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/courier/deliveries/{$this->delivery->id}/accept");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Livraison acceptée');

        $this->assertDatabaseHas('deliveries', [
            'id' => $this->delivery->id,
            'courier_id' => $this->courier->id,
            'status' => 'assigned',
        ]);
    }

    #[Test]
    public function courier_cannot_accept_already_assigned_delivery()
    {
        $otherCourier = Courier::factory()->create();
        $this->delivery->update([
            'courier_id' => $otherCourier->id,
            'status' => 'assigned',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/courier/deliveries/{$this->delivery->id}/accept");

        $response->assertNotFound();
    }

    #[Test]
    public function courier_can_batch_accept_deliveries()
    {
        $delivery2 = Delivery::factory()->create([
            'order_id' => Order::factory()->create([
                'pharmacy_id' => $this->pharmacy->id,
                'customer_id' => $this->customer->id,
            ])->id,
            'status' => 'pending',
            'courier_id' => null,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/courier/deliveries/batch-accept', [
                'delivery_ids' => [$this->delivery->id, $delivery2->id],
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.accepted_count', 2);
    }

    #[Test]
    public function courier_cannot_batch_accept_more_than_5_deliveries()
    {
        // Create 4 active deliveries
        for ($i = 0; $i < 4; $i++) {
            Delivery::factory()->create([
                'courier_id' => $this->courier->id,
                'status' => 'assigned',
                'order_id' => Order::factory()->create([
                    'pharmacy_id' => $this->pharmacy->id,
                    'customer_id' => $this->customer->id,
                ])->id,
            ]);
        }

        // Try to accept 2 more (total would be 6)
        $delivery2 = Delivery::factory()->create([
            'status' => 'pending',
            'courier_id' => null,
            'order_id' => Order::factory()->create([
                'pharmacy_id' => $this->pharmacy->id,
                'customer_id' => $this->customer->id,
            ])->id,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/courier/deliveries/batch-accept', [
                'delivery_ids' => [$this->delivery->id, $delivery2->id],
            ]);

        $response->assertStatus(400)
            ->assertJsonPath('success', false);
    }

    #[Test]
    public function courier_can_pickup_delivery()
    {
        $this->delivery->update([
            'courier_id' => $this->courier->id,
            'status' => 'assigned',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/courier/deliveries/{$this->delivery->id}/pickup");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Commande récupérée');

        $this->assertDatabaseHas('deliveries', [
            'id' => $this->delivery->id,
            'status' => 'picked_up',
        ]);
    }

    #[Test]
    public function courier_cannot_pickup_pending_delivery()
    {
        $this->delivery->update([
            'courier_id' => $this->courier->id,
            'status' => 'pending',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/courier/deliveries/{$this->delivery->id}/pickup");

        $response->assertStatus(400)
            ->assertJsonPath('success', false);
    }

    #[Test]
    public function courier_can_deliver_with_correct_code()
    {
        $this->delivery->update([
            'courier_id' => $this->courier->id,
            'status' => 'picked_up',
        ]);

        // Mock WalletService
        $this->mock(WalletService::class, function ($mock) {
            $mock->shouldReceive('canCompleteDelivery')->andReturn(true);
            $mock->shouldReceive('creditDeliveryEarning')->andReturn(new \App\Models\WalletTransaction());
            $mock->shouldReceive('deductCommission')->andReturn(new \App\Models\WalletTransaction());
            $mock->shouldReceive('getBalance')->andReturn(['balance' => 5000, 'currency' => 'XOF']);
        });

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/courier/deliveries/{$this->delivery->id}/deliver", [
                'confirmation_code' => '1234',
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    #[Test]
    public function courier_cannot_deliver_with_wrong_code()
    {
        $this->delivery->update([
            'courier_id' => $this->courier->id,
            'status' => 'picked_up',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/courier/deliveries/{$this->delivery->id}/deliver", [
                'confirmation_code' => '9999',
            ]);

        $response->assertStatus(400)
            ->assertJsonPath('success', false);
    }

    #[Test]
    public function courier_can_update_location()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/courier/location/update', [
                'latitude' => 5.3167,
                'longitude' => -4.0167,
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Position mise à jour');
    }

    #[Test]
    public function location_update_requires_coordinates()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/courier/location/update', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['latitude', 'longitude']);
    }

    #[Test]
    public function courier_can_toggle_availability()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/courier/availability/toggle');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => ['status', 'is_online'],
            ]);
    }

    #[Test]
    public function courier_can_set_explicit_availability_status()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/courier/availability/toggle', [
                'status' => 'offline',
            ]);

        $response->assertOk()
            ->assertJsonPath('data.status', 'offline')
            ->assertJsonPath('data.is_online', false);
    }

    #[Test]
    public function courier_can_get_profile()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/profile');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'data',
            ]);
    }

    #[Test]
    public function courier_can_get_optimized_route()
    {
        $this->delivery->update([
            'courier_id' => $this->courier->id,
            'status' => 'assigned',
            'pickup_latitude' => 5.3167,
            'pickup_longitude' => -4.0167,
            'dropoff_latitude' => 5.3200,
            'dropoff_longitude' => -4.0200,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/deliveries/route');

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'data' => [
                    'stops',
                    'pickup_count',
                    'delivery_count',
                    'total_distance_km',
                    'total_estimated_earnings',
                ],
            ]);
    }

    #[Test]
    public function non_courier_cannot_access_deliveries()
    {
        $customer = User::factory()->create(['role' => 'customer']);

        $response = $this->actingAs($customer, 'sanctum')
            ->getJson('/api/courier/deliveries');

        $response->assertStatus(403);
    }

    #[Test]
    public function unauthenticated_user_cannot_access_deliveries()
    {
        $response = $this->getJson('/api/courier/deliveries');

        $response->assertUnauthorized();
    }
}
