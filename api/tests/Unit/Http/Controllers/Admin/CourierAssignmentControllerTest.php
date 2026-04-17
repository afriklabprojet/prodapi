<?php

namespace Tests\Unit\Http\Controllers\Admin;

use App\Http\Controllers\Admin\CourierAssignmentController;
use App\Models\Courier;
use App\Models\Customer;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use App\Services\CourierAssignmentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery;
use Tests\TestCase;

class CourierAssignmentControllerTest extends TestCase
{
    use RefreshDatabase;

    private function createAdminUser(): User
    {
        return User::factory()->create(['role' => 'admin', 'must_change_password' => false]);
    }

    private function createOrder(): Order
    {
        $pharmacy = Pharmacy::factory()->create([
            'latitude' => 5.3456,
            'longitude' => -3.9876,
        ]);
        $customer = Customer::factory()->create();

        return Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $customer->id,
            'delivery_latitude' => 5.3500,
            'delivery_longitude' => -3.9800,
        ]);
    }

    // ═══════════════════════════════════════════════════════════════
    //  getAvailableCouriers
    // ═══════════════════════════════════════════════════════════════

    public function test_get_available_couriers_returns_courier_list(): void
    {
        $admin = $this->createAdminUser();
        $order = $this->createOrder();

        $mockService = Mockery::mock(CourierAssignmentService::class);
        $mockService->shouldReceive('getAvailableCouriersInRadius')
            ->once()
            ->andReturn(new \Illuminate\Database\Eloquent\Collection([['id' => 1, 'name' => 'Courier A']]));
        $this->app->instance(CourierAssignmentService::class, $mockService);

        $response = $this->actingAs($admin, 'sanctum')
            ->getJson("/api/admin/orders/{$order->id}/couriers/available");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['success', 'data']);
    }

    // ═══════════════════════════════════════════════════════════════
    //  autoAssign
    // ═══════════════════════════════════════════════════════════════

    public function test_auto_assign_success(): void
    {
        $admin = $this->createAdminUser();
        $order = $this->createOrder();
        $courier = Courier::factory()->create();

        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
        ]);

        $mockService = Mockery::mock(CourierAssignmentService::class);
        $mockService->shouldReceive('assignCourier')
            ->once()
            ->andReturn($delivery);
        $this->app->instance(CourierAssignmentService::class, $mockService);

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson("/api/admin/orders/{$order->id}/couriers/auto-assign");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Livreur assigné automatiquement');
    }

    public function test_auto_assign_no_courier_available(): void
    {
        $admin = $this->createAdminUser();
        $order = $this->createOrder();

        $mockService = Mockery::mock(CourierAssignmentService::class);
        $mockService->shouldReceive('assignCourier')
            ->once()
            ->andReturn(null);
        $this->app->instance(CourierAssignmentService::class, $mockService);

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson("/api/admin/orders/{$order->id}/couriers/auto-assign");

        $response->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Aucun livreur disponible');
    }

    // ═══════════════════════════════════════════════════════════════
    //  manualAssign
    // ═══════════════════════════════════════════════════════════════

    public function test_manual_assign_success(): void
    {
        $admin = $this->createAdminUser();
        $order = $this->createOrder();
        $courier = Courier::factory()->create();

        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
        ]);

        $mockService = Mockery::mock(CourierAssignmentService::class);
        $mockService->shouldReceive('assignSpecificCourier')
            ->once()
            ->andReturn($delivery);
        $this->app->instance(CourierAssignmentService::class, $mockService);

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson("/api/admin/orders/{$order->id}/couriers/manual-assign", [
                'courier_id' => $courier->id,
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Livreur assigné manuellement');
    }

    public function test_manual_assign_validation_fails(): void
    {
        $admin = $this->createAdminUser();
        $order = $this->createOrder();

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson("/api/admin/orders/{$order->id}/couriers/manual-assign", []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['courier_id']);
    }

    public function test_manual_assign_courier_not_found(): void
    {
        $admin = $this->createAdminUser();
        $order = $this->createOrder();

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson("/api/admin/orders/{$order->id}/couriers/manual-assign", [
                'courier_id' => 99999,
            ]);

        $response->assertStatus(422);
    }

    public function test_manual_assign_fails_when_service_returns_null(): void
    {
        $admin = $this->createAdminUser();
        $order = $this->createOrder();
        $courier = Courier::factory()->create();

        $mockService = Mockery::mock(CourierAssignmentService::class);
        $mockService->shouldReceive('assignSpecificCourier')
            ->once()
            ->andReturn(null);
        $this->app->instance(CourierAssignmentService::class, $mockService);

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson("/api/admin/orders/{$order->id}/couriers/manual-assign", [
                'courier_id' => $courier->id,
            ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    // ═══════════════════════════════════════════════════════════════
    //  reassign
    // ═══════════════════════════════════════════════════════════════

    public function test_reassign_success(): void
    {
        $admin = $this->createAdminUser();
        $order = $this->createOrder();
        $courier = Courier::factory()->create();
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
        ]);

        $newCourier = Courier::factory()->create(['name' => 'New Courier', 'phone' => '2250700000000']);

        $mockService = Mockery::mock(CourierAssignmentService::class);
        $mockService->shouldReceive('reassignDelivery')
            ->once()
            ->andReturn($newCourier);
        $this->app->instance(CourierAssignmentService::class, $mockService);

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson("/api/admin/deliveries/{$delivery->id}/reassign");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Livraison réassignée');
    }

    public function test_reassign_no_courier_available(): void
    {
        $admin = $this->createAdminUser();
        $order = $this->createOrder();
        $courier = Courier::factory()->create();
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
        ]);

        $mockService = Mockery::mock(CourierAssignmentService::class);
        $mockService->shouldReceive('reassignDelivery')
            ->once()
            ->andReturn(null);
        $this->app->instance(CourierAssignmentService::class, $mockService);

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson("/api/admin/deliveries/{$delivery->id}/reassign");

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    // ═══════════════════════════════════════════════════════════════
    //  estimateDeliveryTime
    // ═══════════════════════════════════════════════════════════════

    public function test_estimate_delivery_time(): void
    {
        $admin = $this->createAdminUser();
        $order = $this->createOrder();

        $mockService = Mockery::mock(CourierAssignmentService::class);
        $mockService->shouldReceive('estimateDeliveryTime')
            ->once()
            ->andReturn(25);
        $this->app->instance(CourierAssignmentService::class, $mockService);

        $response = $this->actingAs($admin, 'sanctum')
            ->postJson("/api/admin/orders/{$order->id}/estimate-time");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['success', 'data']);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Auth / Authorization
    // ═══════════════════════════════════════════════════════════════

    public function test_unauthenticated_request_returns_401(): void
    {
        $order = $this->createOrder();

        $response = $this->getJson("/api/admin/orders/{$order->id}/couriers/available");

        $response->assertUnauthorized();
    }

    public function test_non_admin_request_returns_403(): void
    {
        /** @var User $user */
        $user = User::factory()->create(['role' => 'customer', 'must_change_password' => false]);
        $order = $this->createOrder();

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/admin/orders/{$order->id}/couriers/available");

        $response->assertForbidden();
    }
}
