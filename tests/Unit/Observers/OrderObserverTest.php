<?php

namespace Tests\Unit\Observers;

use App\Models\Order;
use App\Observers\OrderObserver;
use App\Services\CommissionService;
use App\Services\CourierAssignmentService;
use App\Services\FirestoreService;
use App\Services\LoyaltyService;
use Mockery;
use Tests\TestCase;

class OrderObserverTest extends TestCase
{
    private OrderObserver $observer;
    private $assignmentService;
    private $commissionService;
    private $firestoreService;
    private $loyaltyService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->assignmentService = Mockery::mock(CourierAssignmentService::class);
        $this->commissionService = Mockery::mock(CommissionService::class);
        $this->firestoreService = Mockery::mock(FirestoreService::class);
        $this->loyaltyService = Mockery::mock(LoyaltyService::class);

        $this->observer = new OrderObserver(
            $this->assignmentService,
            $this->commissionService,
            $this->firestoreService,
            $this->loyaltyService,
        );
    }

    public function test_it_can_be_instantiated(): void
    {
        $this->assertInstanceOf(OrderObserver::class, $this->observer);
    }

    public function test_deleted_does_nothing(): void
    {
        $order = new Order();
        // Should not throw
        $this->observer->deleted($order);
        $this->assertTrue(true);
    }

    public function test_restored_does_nothing(): void
    {
        $order = new Order();
        $this->observer->restored($order);
        $this->assertTrue(true);
    }

    public function test_force_deleted_does_nothing(): void
    {
        $order = new Order();
        $this->observer->forceDeleted($order);
        $this->assertTrue(true);
    }
}
