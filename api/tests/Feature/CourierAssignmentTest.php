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

    public function test_near_location_scope_returns_couriers_within_radius()
    {
        // Créer un livreur proche (à ~2 km)
        $nearCourier = $this->createCourierWithWallet([
            'status' => 'available',
            'latitude' => 5.3620,
            'longitude' => -4.0100,
        ]);

        // Créer un livreur loin (à ~25 km)
        $farCourier = $this->createCourierWithWallet([
            'status' => 'available',
            'latitude' => 5.5500,
            'longitude' => -4.2500,
        ]);

        // Position de référence (Abidjan centre)
        $refLat = 5.3600;
        $refLng = -4.0083;

        // Utiliser le service qui filtre par distance
        $nearbyCouriers = $this->service->getAvailableCouriersInRadius($refLat, $refLng, 10);

        $this->assertTrue($nearbyCouriers->contains('id', $nearCourier->id));
        $this->assertFalse($nearbyCouriers->contains('id', $farCourier->id));
    }

    public function test_near_location_scope_calculates_distance_correctly()
    {
        $courier = $this->createCourierWithWallet([
            'status' => 'available',
            'latitude' => 5.3800,
            'longitude' => -4.0283,
        ]);

        // Utiliser le service qui calcule la distance
        $results = $this->service->getAvailableCouriersInRadius(5.3600, -4.0083, 20);

        $this->assertCount(1, $results);
        $result = $results->first();
        $this->assertNotNull($result->distance);
        // Distance devrait être d'environ 3 km
        $this->assertGreaterThan(1, $result->distance);
        $this->assertLessThan(10, $result->distance);
    }

    public function test_service_filters_couriers_without_gps()
    {
        // Livreur avec GPS
        $withGps = $this->createCourierWithWallet([
            'status' => 'available',
            'latitude' => 5.3610,
            'longitude' => -4.0090,
        ]);

        // Livreur sans GPS
        $withoutGps = $this->createCourierWithWallet([
            'status' => 'available',
            'latitude' => null,
            'longitude' => null,
        ]);

        $results = $this->service->getAvailableCouriersInRadius(5.3600, -4.0083, 20);

        $this->assertTrue($results->contains('id', $withGps->id));
        $this->assertFalse($results->contains('id', $withoutGps->id));
    }

    public function test_get_available_couriers_in_radius_returns_sorted_by_distance()
    {
        // Créer des livreurs à différentes distances
        $courier1 = $this->createCourierWithWallet([
            'status' => 'available',
            'latitude' => 5.3700, // Plus loin
            'longitude' => -4.0200,
        ]);

        $courier2 = $this->createCourierWithWallet([
            'status' => 'available',
            'latitude' => 5.3610, // Plus proche
            'longitude' => -4.0090,
        ]);

        $refLat = 5.3600;
        $refLng = -4.0083;

        $couriers = $this->service->getAvailableCouriersInRadius($refLat, $refLng, 20);

        $this->assertCount(2, $couriers);
        // Le premier devrait être le plus proche
        $this->assertEquals($courier2->id, $couriers->first()->id);
    }
}
