<?php

namespace Tests\Unit\Services;

use App\Services\CourierAssignmentService;
use Tests\TestCase;

class CourierAssignmentServiceTest extends TestCase
{
    private CourierAssignmentService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new CourierAssignmentService();
    }

    public function test_it_can_be_instantiated(): void
    {
        $this->assertInstanceOf(CourierAssignmentService::class, $this->service);
    }

    public function test_calculate_distance_same_point_is_zero(): void
    {
        $distance = $this->service->calculateDistance(5.360, -4.008, 5.360, -4.008);
        $this->assertEquals(0.0, $distance);
    }

    public function test_calculate_distance_known_points(): void
    {
        // Abidjan to Yamoussoukro is approximately 240 km
        $distance = $this->service->calculateDistance(5.3600, -4.0083, 6.8276, -5.2893);
        $this->assertGreaterThan(180, $distance);
        $this->assertLessThan(300, $distance);
    }

    public function test_calculate_distance_short_distance(): void
    {
        // Two points ~5km apart
        $distance = $this->service->calculateDistance(5.3600, -4.0083, 5.3800, -4.0283);
        $this->assertGreaterThan(1, $distance);
        $this->assertLessThan(10, $distance);
    }

    public function test_calculate_distance_is_symmetric(): void
    {
        $d1 = $this->service->calculateDistance(5.360, -4.008, 6.827, -5.289);
        $d2 = $this->service->calculateDistance(6.827, -5.289, 5.360, -4.008);
        $this->assertEqualsWithDelta($d1, $d2, 0.001);
    }

    public function test_estimate_delivery_time_motorcycle(): void
    {
        $time = $this->service->estimateDeliveryTime(5.360, -4.008, 5.380, -4.028, 'motorcycle');
        // Should include 10 min preparation + travel time
        $this->assertGreaterThan(10, $time);
    }

    public function test_estimate_delivery_time_bicycle(): void
    {
        $time = $this->service->estimateDeliveryTime(5.360, -4.008, 5.380, -4.028, 'bicycle');
        // Bicycle is slower, so time should be longer
        $motorcycleTime = $this->service->estimateDeliveryTime(5.360, -4.008, 5.380, -4.028, 'motorcycle');
        $this->assertGreaterThan($motorcycleTime, $time);
    }

    public function test_estimate_delivery_time_car(): void
    {
        $time = $this->service->estimateDeliveryTime(5.360, -4.008, 5.380, -4.028, 'car');
        $this->assertGreaterThan(10, $time);
        $this->assertIsInt($time);
    }

    public function test_estimate_delivery_time_unknown_vehicle_defaults(): void
    {
        $time = $this->service->estimateDeliveryTime(5.360, -4.008, 5.380, -4.028, 'unknown');
        // Should fallback to default speed of 25
        $this->assertGreaterThan(10, $time);
        $this->assertIsInt($time);
    }

    public function test_estimate_delivery_time_includes_preparation(): void
    {
        // Same point => 0 distance => just preparation time (10 min)
        $time = $this->service->estimateDeliveryTime(5.360, -4.008, 5.360, -4.008, 'motorcycle');
        $this->assertEquals(10, $time);
    }
}
