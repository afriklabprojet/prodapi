<?php

namespace Tests\Feature;

use App\Models\Courier;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use App\Models\Wallet;
use App\Services\CourierAssignmentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CourierAssignmentTest extends TestCase
{
    use RefreshDatabase;

    protected CourierAssignmentService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = app(CourierAssignmentService::class);
    }
    
    /**
     * Helper to create a courier with wallet
     */
    protected function createCourierWithWallet(array $attributes = []): Courier
    {
        $courier = Courier::factory()->create($attributes);
        Wallet::create([
            'walletable_type' => Courier::class,
            'walletable_id' => $courier->id,
            'balance' => 1000,
            'currency' => 'XOF',
        ]);
        return $courier;
    }

    public function test_can_find_nearest_available_courier()
    {
        // Créer des livreurs à différentes distances
        $nearCourier = $this->createCourierWithWallet([
            'status' => 'available',
            'latitude' => 5.3600,
            'longitude' => -4.0083,
        ]);

        $farCourier = $this->createCourierWithWallet([
            'status' => 'available',
            'latitude' => 5.5000,
            'longitude' => -4.2000,
        ]);

        // Position de test (proche du premier livreur)
        $courier = $this->service->findNearestAvailableCourier(5.3600, -4.0083);

        $this->assertNotNull($courier);
        $this->assertEquals($nearCourier->id, $courier->id);
    }

    public function test_only_returns_available_couriers()
    {
        $this->createCourierWithWallet([
            'status' => 'busy',
            'latitude' => 5.3600,
            'longitude' => -4.0083,
        ]);

        $courier = $this->service->findNearestAvailableCourier(5.3600, -4.0083);

        $this->assertNull($courier);
    }

    public function test_can_assign_courier_to_order()
    {
        $pharmacy = Pharmacy::factory()->create([
            'latitude' => 5.3600,
            'longitude' => -4.0083,
            'status' => 'approved',
        ]);

        $courier = $this->createCourierWithWallet([
            'status' => 'available',
            'latitude' => 5.3610,
            'longitude' => -4.0090,
        ]);

        $order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'status' => 'ready',
            'delivery_latitude' => 5.3700,
            'delivery_longitude' => -4.0200,
        ]);

        $delivery = $this->service->assignCourier($order);

        $this->assertNotNull($delivery);
        $this->assertEquals($courier->id, $delivery->courier_id);
        $this->assertEquals($order->id, $delivery->order_id);
        $this->assertEquals('pending', $delivery->status);
    }

    public function test_calculates_distance_correctly()
    {
        // Distance entre Abidjan et Yamoussoukro ~ 228 km
        $distance = $this->service->calculateDistance(
            5.3600, -4.0083,  // Abidjan
            6.8205, -5.2764   // Yamoussoukro
        );

        $this->assertGreaterThan(200, $distance);
        $this->assertLessThan(250, $distance);
    }

    public function test_estimates_delivery_time_for_motorcycle()
    {
        // 10 km à 30 km/h = 20 min + 10 min préparation = 30 min
        $time = $this->service->estimateDeliveryTime(
            5.3600, -4.0083,
            5.3700, -4.0900,
            'motorcycle'
        );

        $this->assertGreaterThan(10, $time);
        $this->assertLessThan(60, $time);
    }

    public function test_can_reassign_delivery()
    {
        $pharmacy = Pharmacy::factory()->create([
            'latitude' => 5.3600,
            'longitude' => -4.0083,
        ]);

        $oldCourier = $this->createCourierWithWallet([
            'status' => 'available',
            'latitude' => 5.3610,
            'longitude' => -4.0090,
        ]);

        $newCourier = $this->createCourierWithWallet([
            'status' => 'available',
            'latitude' => 5.3620,
            'longitude' => -4.0095,
        ]);

        $order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
        ]);

        $delivery = $this->service->assignSpecificCourier($order, $oldCourier);
        $this->assertEquals($oldCourier->id, $delivery->courier_id);

        $newAssignedCourier = $this->service->reassignDelivery($delivery);
        $this->assertNotNull($newAssignedCourier);
        $this->assertEquals($newCourier->id, $newAssignedCourier->id);
    }

    public function test_auto_assignment_when_order_marked_ready()
    {
        $pharmacy = Pharmacy::factory()->create([
            'latitude' => 5.3600,
            'longitude' => -4.0083,
            'status' => 'approved',
        ]);

        $courier = $this->createCourierWithWallet([
            'status' => 'available',
            'latitude' => 5.3610,
            'longitude' => -4.0090,
        ]);

        $order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'status' => 'confirmed',
            'delivery_latitude' => 5.3700,
            'delivery_longitude' => -4.0200,
        ]);

        // Marquer comme ready (déclenche l'Observer)
        $order->update(['status' => 'ready']);

        $order->refresh();
        $this->assertTrue($order->delivery()->exists());
        $this->assertEquals($courier->id, $order->delivery->courier_id);
    }
}
