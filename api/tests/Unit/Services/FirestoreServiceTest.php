<?php

namespace Tests\Unit\Services;

use App\Services\FirestoreService;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class FirestoreServiceTest extends TestCase
{
    public function test_service_instantiates_when_firestore_unavailable(): void
    {
        Log::shouldReceive('warning')->once()->withArgs(function ($msg) {
            return str_contains($msg, 'Firestore not available');
        });

        $service = new FirestoreService();

        $this->assertInstanceOf(FirestoreService::class, $service);
    }

    public function test_update_delivery_status_returns_silently_when_firestore_null(): void
    {
        Log::shouldReceive('warning')->once();

        $service = new FirestoreService();

        // Should not throw, should return void silently
        $service->updateDeliveryStatus(1, 'pending');

        $this->addToAssertionCount(1); // no exception = pass
    }

    public function test_update_delivery_status_with_optional_params_when_firestore_null(): void
    {
        Log::shouldReceive('warning')->once();

        $service = new FirestoreService();

        $service->updateDeliveryStatus(
            orderId: 42,
            status: 'delivered',
            courierId: 5,
            deliveryId: 10,
            extraData: ['latitude' => 36.7, 'longitude' => 3.1]
        );

        $this->addToAssertionCount(1);
    }

    public function test_update_courier_online_status_returns_silently_when_firestore_null(): void
    {
        Log::shouldReceive('warning')->once();

        $service = new FirestoreService();

        $service->updateCourierOnlineStatus(1, true);

        $this->addToAssertionCount(1);
    }

    public function test_update_courier_offline_status_returns_silently_when_firestore_null(): void
    {
        Log::shouldReceive('warning')->once();

        $service = new FirestoreService();

        $service->updateCourierOnlineStatus(99, false);

        $this->addToAssertionCount(1);
    }

    public function test_clear_delivery_tracking_returns_silently_when_firestore_null(): void
    {
        Log::shouldReceive('warning')->once();

        $service = new FirestoreService();

        $service->clearDeliveryTracking(123);

        $this->addToAssertionCount(1);
    }

    public function test_service_does_not_throw_on_construction(): void
    {
        Log::shouldReceive('warning')->zeroOrMoreTimes();

        $service = new FirestoreService();
        $this->assertInstanceOf(FirestoreService::class, $service);
    }
}
