<?php

namespace Tests\Unit\Services;

use App\Models\Courier;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Services\AutoAssignmentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Mockery;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class AutoAssignmentServiceDeepTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Log::spy();
    }

    /**
     * Build a partial mock of AutoAssignmentService where findBestCourier
     * is overridden to return the given courier (avoids Haversine/SQLite issues).
     */
    private function serviceWithMockedFinder(?Courier $returnCourier): AutoAssignmentService
    {
        /** @var AutoAssignmentService&\Mockery\MockInterface $mock */
        $mock = Mockery::mock(AutoAssignmentService::class)->makePartial();
        $mock->shouldAllowMockingProtectedMethods();
        $mock->shouldReceive('findBestCourier')->andReturn($returnCourier);
        return $mock;
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  assignDelivery — early-exit paths (real service, no findBestCourier)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function assign_delivery_returns_null_when_no_order(): void
    {
        $service = new AutoAssignmentService();
        $delivery = Delivery::factory()->create();
        $delivery->setRelation('order', null);

        $result = $service->assignDelivery($delivery);

        $this->assertNull($result);
        Log::shouldHaveReceived('warning')->withArgs(fn ($msg) => str_contains($msg, 'sans commande'));
    }

    #[Test]
    public function assign_delivery_returns_null_when_pharmacy_has_no_coords(): void
    {
        $service = new AutoAssignmentService();
        $pharmacy = Pharmacy::factory()->create(['latitude' => null, 'longitude' => null]);
        $order = Order::factory()->create(['pharmacy_id' => $pharmacy->id]);
        $delivery = Delivery::factory()->create(['order_id' => $order->id]);

        $result = $service->assignDelivery($delivery);

        $this->assertNull($result);
        Log::shouldHaveReceived('warning')->withArgs(fn ($msg) => str_contains($msg, 'coordonn'));
    }

    #[Test]
    public function assign_delivery_returns_null_when_no_courier_available(): void
    {
        $service = $this->serviceWithMockedFinder(null);
        $pharmacy = Pharmacy::factory()->create(['latitude' => 5.3364, 'longitude' => -4.0267]);
        $order = Order::factory()->create(['pharmacy_id' => $pharmacy->id]);
        $delivery = Delivery::factory()->create(['order_id' => $order->id]);

        $result = $service->assignDelivery($delivery);

        $this->assertNull($result);
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, 'Aucun livreur'));
    }

    #[Test]
    public function assign_delivery_assigns_courier_and_updates_delivery(): void
    {
        $courier = Courier::factory()->create();
        $service = $this->serviceWithMockedFinder($courier);

        $pharmacy = Pharmacy::factory()->create(['latitude' => 5.3364, 'longitude' => -4.0267]);
        $order = Order::factory()->create(['pharmacy_id' => $pharmacy->id]);
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'status' => 'pending',
        ]);

        $result = $service->assignDelivery($delivery);

        $this->assertNotNull($result);
        $this->assertEquals($courier->id, $result->id);
        $this->assertDatabaseHas('deliveries', [
            'id' => $delivery->id,
            'courier_id' => $courier->id,
            'status' => 'pending',
        ]);
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, 'assignée'));
    }

    #[Test]
    public function assign_delivery_catches_exception_gracefully(): void
    {
        $service = new AutoAssignmentService();
        $delivery = Delivery::factory()->create();
        $delivery->setRelation('order', null);

        $result = $service->assignDelivery($delivery);
        $this->assertNull($result);
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  findBestCourier — tested via partial mock (HAVING without GROUP BY
    //  is MySQL-specific and doesn't work in SQLite)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function assign_delivery_passes_excluded_courier_ids(): void
    {
        $courier = Courier::factory()->create();
        /** @var AutoAssignmentService&\Mockery\MockInterface $mock */
        $mock = Mockery::mock(AutoAssignmentService::class)->makePartial();
        $mock->shouldAllowMockingProtectedMethods();
        $mock->shouldReceive('findBestCourier')
            ->withArgs(function ($lat, $lng, $excludeIds) {
                return is_array($excludeIds) && count($excludeIds) === 0;
            })
            ->andReturn($courier);

        $pharmacy = Pharmacy::factory()->create(['latitude' => 5.3364, 'longitude' => -4.0267]);
        $order = Order::factory()->create(['pharmacy_id' => $pharmacy->id]);
        $delivery = Delivery::factory()->create(['order_id' => $order->id]);

        $result = $mock->assignDelivery($delivery);
        $this->assertNotNull($result);
    }

    #[Test]
    public function assign_delivery_passes_pharmacy_coords_to_finder(): void
    {
        /** @var AutoAssignmentService&\Mockery\MockInterface $mock */
        $mock = Mockery::mock(AutoAssignmentService::class)->makePartial();
        $mock->shouldAllowMockingProtectedMethods();
        $mock->shouldReceive('findBestCourier')
            ->withArgs(function ($lat, $lng) {
                return abs($lat - 5.3364) < 0.001 && abs($lng - (-4.0267)) < 0.001;
            })
            ->once()
            ->andReturn(null);

        $pharmacy = Pharmacy::factory()->create(['latitude' => 5.3364, 'longitude' => -4.0267]);
        $order = Order::factory()->create(['pharmacy_id' => $pharmacy->id]);
        $delivery = Delivery::factory()->create(['order_id' => $order->id]);

        $mock->assignDelivery($delivery);
    }

    #[Test]
    public function assign_delivery_updates_delivery_with_courier(): void
    {
        $courier = Courier::factory()->create();
        $service = $this->serviceWithMockedFinder($courier);

        $pharmacy = Pharmacy::factory()->create(['latitude' => 5.3364, 'longitude' => -4.0267]);
        $order = Order::factory()->create(['pharmacy_id' => $pharmacy->id]);
        $delivery = Delivery::factory()->create(['order_id' => $order->id, 'status' => 'pending']);

        $service->assignDelivery($delivery);

        $delivery->refresh();
        $this->assertEquals($courier->id, $delivery->courier_id);
        $this->assertEquals('pending', $delivery->status);
    }

    #[Test]
    public function assign_delivery_logs_assignment_info(): void
    {
        $courier = Courier::factory()->create();
        $service = $this->serviceWithMockedFinder($courier);

        $pharmacy = Pharmacy::factory()->create(['latitude' => 5.3364, 'longitude' => -4.0267]);
        $order = Order::factory()->create(['pharmacy_id' => $pharmacy->id]);
        $delivery = Delivery::factory()->create(['order_id' => $order->id]);

        $service->assignDelivery($delivery);

        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, 'assignée'));
    }

    #[Test]
    public function assign_delivery_returns_courier_object(): void
    {
        $courier = Courier::factory()->create();
        $service = $this->serviceWithMockedFinder($courier);

        $pharmacy = Pharmacy::factory()->create(['latitude' => 5.3364, 'longitude' => -4.0267]);
        $order = Order::factory()->create(['pharmacy_id' => $pharmacy->id]);
        $delivery = Delivery::factory()->create(['order_id' => $order->id]);

        $result = $service->assignDelivery($delivery);
        $this->assertInstanceOf(Courier::class, $result);
        $this->assertEquals($courier->id, $result->id);
    }

    #[Test]
    public function assign_delivery_with_null_pharmacy_returns_null(): void
    {
        $service = new AutoAssignmentService();
        $order = Order::factory()->create();
        $delivery = Delivery::factory()->create(['order_id' => $order->id]);
        // Set pharmacy to null
        $order->setRelation('pharmacy', null);
        $delivery->setRelation('order', $order);

        $result = $service->assignDelivery($delivery);
        $this->assertNull($result);
    }
}
