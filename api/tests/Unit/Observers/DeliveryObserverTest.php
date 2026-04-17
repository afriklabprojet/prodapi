<?php

namespace Tests\Unit\Observers;

use App\Models\Delivery;
use App\Observers\DeliveryObserver;
use App\Services\AutoAssignmentService;
use Illuminate\Support\Facades\Log;
use Mockery;
use Tests\TestCase;

class DeliveryObserverTest extends TestCase
{
    public function test_created_triggers_auto_assign_for_pending_unassigned(): void
    {
        $delivery = Mockery::mock(Delivery::class)->makePartial();
        $delivery->status = 'pending';
        $delivery->courier_id = null;
        $delivery->id = 1;

        $autoAssignService = Mockery::mock(AutoAssignmentService::class);
        $autoAssignService->shouldReceive('assignDelivery')
            ->once()
            ->with($delivery)
            ->andReturn(null);

        $this->app->instance(AutoAssignmentService::class, $autoAssignService);

        Log::shouldReceive('warning')->once();

        $observer = new DeliveryObserver();
        $observer->created($delivery);
    }

    public function test_created_skips_when_already_assigned(): void
    {
        $delivery = new Delivery();
        $delivery->status = 'pending';
        $delivery->courier_id = 5;

        // Should not attempt auto-assignment
        $autoAssignService = Mockery::mock(AutoAssignmentService::class);
        $autoAssignService->shouldNotReceive('assignDelivery');
        $this->app->instance(AutoAssignmentService::class, $autoAssignService);

        $observer = new DeliveryObserver();
        $observer->created($delivery);
    }

    public function test_created_skips_when_not_pending(): void
    {
        $delivery = new Delivery();
        $delivery->status = 'in_transit';
        $delivery->courier_id = null;

        $autoAssignService = Mockery::mock(AutoAssignmentService::class);
        $autoAssignService->shouldNotReceive('assignDelivery');
        $this->app->instance(AutoAssignmentService::class, $autoAssignService);

        $observer = new DeliveryObserver();
        $observer->created($delivery);
    }

    public function test_auto_assign_failure_is_caught(): void
    {
        $delivery = Mockery::mock(Delivery::class)->makePartial();
        $delivery->status = 'pending';
        $delivery->courier_id = null;
        $delivery->id = 99;

        $autoAssignService = Mockery::mock(AutoAssignmentService::class);
        $autoAssignService->shouldReceive('assignDelivery')
            ->once()
            ->andThrow(new \RuntimeException('Service unavailable'));

        $this->app->instance(AutoAssignmentService::class, $autoAssignService);

        Log::shouldReceive('error')
            ->once()
            ->withArgs(fn($msg) => str_contains($msg, 'Erreur'));

        $observer = new DeliveryObserver();
        $observer->created($delivery);
    }
}
