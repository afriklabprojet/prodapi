<?php

namespace Tests\Unit\Services;

use App\Services\FirestoreService;
use Illuminate\Support\Facades\Log;
use Mockery;
use Tests\TestCase;

class FirestoreServiceDeepTest extends TestCase
{
    private function makeService(mixed $client = null): FirestoreService
    {
        $service = new FirestoreService();
        $ref = new \ReflectionProperty($service, 'firestore');
        $ref->setAccessible(true);
        $ref->setValue($service, $client);
        return $service;
    }

    private function mockFirestoreChain(): array
    {
        $docRef = Mockery::mock();
        $colRef = Mockery::mock();
        $colRef->shouldReceive('document')->andReturn($docRef);
        $client = Mockery::mock();
        $client->shouldReceive('collection')->andReturn($colRef);
        return [$client, $colRef, $docRef];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // null firestore → silent return
    // ═══════════════════════════════════════════════════════════════════════

    public function test_update_delivery_status_no_firestore(): void
    {
        Log::spy();
        $service = $this->makeService(null);
        $service->updateDeliveryStatus(1, 'pending');
        Log::shouldNotHaveReceived('debug');
    }

    public function test_update_courier_status_no_firestore(): void
    {
        Log::spy();
        $service = $this->makeService(null);
        $service->updateCourierOnlineStatus(1, true);
        Log::shouldNotHaveReceived('debug');
    }

    public function test_clear_delivery_tracking_no_firestore(): void
    {
        Log::spy();
        $service = $this->makeService(null);
        $service->clearDeliveryTracking(1);
        Log::shouldNotHaveReceived('debug');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // updateDeliveryStatus
    // ═══════════════════════════════════════════════════════════════════════

    public function test_update_delivery_status_basic(): void
    {
        Log::spy();
        [$client, $colRef, $docRef] = $this->mockFirestoreChain();

        $docRef->shouldReceive('set')->once()->withArgs(function (array $data, array $opts) {
            return $data['status'] === 'in_transit'
                && $opts === ['merge' => true]
                && !isset($data['courierId'])
                && !isset($data['deliveryId']);
        });

        $service = $this->makeService($client);
        $service->updateDeliveryStatus(42, 'in_transit');

        Log::shouldHaveReceived('debug')->once();
    }

    public function test_update_delivery_status_with_courier(): void
    {
        Log::spy();
        [$client, $colRef, $docRef] = $this->mockFirestoreChain();

        $docRef->shouldReceive('set')->once()->withArgs(function (array $data) {
            return $data['courierId'] === 7 && $data['status'] === 'assigned';
        });

        $service = $this->makeService($client);
        $service->updateDeliveryStatus(1, 'assigned', 7);
    }

    public function test_update_delivery_status_with_delivery_id(): void
    {
        Log::spy();
        [$client, $colRef, $docRef] = $this->mockFirestoreChain();

        $docRef->shouldReceive('set')->once()->withArgs(function (array $data) {
            return $data['deliveryId'] === 99;
        });

        $service = $this->makeService($client);
        $service->updateDeliveryStatus(1, 'picked_up', null, 99);
    }

    public function test_update_delivery_status_with_extra_data(): void
    {
        Log::spy();
        [$client, $colRef, $docRef] = $this->mockFirestoreChain();

        $docRef->shouldReceive('set')->once()->withArgs(function (array $data) {
            return $data['latitude'] === 5.3 && $data['longitude'] === -3.9;
        });

        $service = $this->makeService($client);
        $service->updateDeliveryStatus(1, 'in_transit', 7, 99, ['latitude' => 5.3, 'longitude' => -3.9]);
    }

    public function test_update_delivery_status_all_params(): void
    {
        Log::spy();
        [$client, $colRef, $docRef] = $this->mockFirestoreChain();

        $docRef->shouldReceive('set')->once()->withArgs(function (array $data) {
            return $data['status'] === 'delivered'
                && $data['courierId'] === 5
                && $data['deliveryId'] === 33
                && $data['note'] === 'ok';
        });

        $service = $this->makeService($client);
        $service->updateDeliveryStatus(10, 'delivered', 5, 33, ['note' => 'ok']);
    }

    public function test_update_delivery_status_exception(): void
    {
        Log::spy();
        [$client, $colRef, $docRef] = $this->mockFirestoreChain();

        $docRef->shouldReceive('set')->andThrow(new \Exception('Firestore down'));

        $service = $this->makeService($client);
        $service->updateDeliveryStatus(1, 'pending');

        Log::shouldHaveReceived('error')->once();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // updateCourierOnlineStatus
    // ═══════════════════════════════════════════════════════════════════════

    public function test_update_courier_online(): void
    {
        Log::spy();
        [$client, $colRef, $docRef] = $this->mockFirestoreChain();

        $docRef->shouldReceive('set')->once()->withArgs(function (array $data, array $opts) {
            return $data['isOnline'] === true && $opts === ['merge' => true];
        });

        $service = $this->makeService($client);
        $service->updateCourierOnlineStatus(15, true);

        Log::shouldHaveReceived('debug')->once();
    }

    public function test_update_courier_offline(): void
    {
        Log::spy();
        [$client, $colRef, $docRef] = $this->mockFirestoreChain();

        $docRef->shouldReceive('set')->once()->withArgs(function (array $data) {
            return $data['isOnline'] === false;
        });

        $service = $this->makeService($client);
        $service->updateCourierOnlineStatus(3, false);
    }

    public function test_update_courier_status_exception(): void
    {
        Log::spy();
        [$client, $colRef, $docRef] = $this->mockFirestoreChain();

        $docRef->shouldReceive('set')->andThrow(new \Exception('timeout'));

        $service = $this->makeService($client);
        $service->updateCourierOnlineStatus(1, true);

        Log::shouldHaveReceived('error')->once();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // clearDeliveryTracking
    // ═══════════════════════════════════════════════════════════════════════

    public function test_clear_delivery_tracking_success(): void
    {
        Log::spy();
        [$client, $colRef, $docRef] = $this->mockFirestoreChain();

        $docRef->shouldReceive('delete')->once();

        $service = $this->makeService($client);
        $service->clearDeliveryTracking(50);

        Log::shouldHaveReceived('debug')->once();
    }

    public function test_clear_delivery_tracking_exception(): void
    {
        Log::spy();
        [$client, $colRef, $docRef] = $this->mockFirestoreChain();

        $docRef->shouldReceive('delete')->andThrow(new \Exception('not found'));

        $service = $this->makeService($client);
        $service->clearDeliveryTracking(1);

        Log::shouldHaveReceived('error')->once();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // constructor coverage (Firestore not bound)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_constructor_firestore_unavailable(): void
    {
        Log::spy();
        // Ensure Firestore is not resolvable
        $this->app->bind(\Kreait\Firebase\Contract\Firestore::class, function () {
            throw new \Exception('Firestore not configured');
        });

        $service = new FirestoreService();

        $ref = new \ReflectionProperty($service, 'firestore');
        $ref->setAccessible(true);
        $this->assertNull($ref->getValue($service));
    }
}
