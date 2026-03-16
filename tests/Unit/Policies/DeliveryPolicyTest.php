<?php

namespace Tests\Unit\Policies;

use App\Models\Order;
use App\Models\User;
use App\Models\Pharmacy;
use App\Models\Courier;
use App\Models\Delivery;
use App\Policies\DeliveryPolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Tests unitaires pour DeliveryPolicy
 * 
 * Security Audit Week 3 - Tests de sécurité
 */
class DeliveryPolicyTest extends TestCase
{
    use RefreshDatabase;

    protected DeliveryPolicy $policy;
    protected User $admin;
    protected User $customer;
    protected User $courierUser;
    protected User $otherCourierUser;
    protected Pharmacy $pharmacy;
    protected Courier $courier;
    protected Courier $otherCourier;

    protected function setUp(): void
    {
        parent::setUp();

        $this->policy = new DeliveryPolicy();

        // Créer les utilisateurs de test
        $this->admin = User::factory()->create(['role' => 'admin']);
        $this->customer = User::factory()->create(['role' => 'customer']);
        $this->courierUser = User::factory()->create(['role' => 'courier']);
        $this->otherCourierUser = User::factory()->create(['role' => 'courier']);

        // Créer une pharmacie
        $this->pharmacy = Pharmacy::factory()->create();

        // Créer les coursiers
        $this->courier = Courier::factory()->create([
            'user_id' => $this->courierUser->id,
            'status' => 'available',
        ]);
        $this->otherCourier = Courier::factory()->create([
            'user_id' => $this->otherCourierUser->id,
            'status' => 'available',
        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Tests viewAny
    |--------------------------------------------------------------------------
    */

    public function test_admin_can_view_any_deliveries(): void
    {
        $this->assertTrue($this->policy->viewAny($this->admin));
    }

    public function test_courier_can_view_any_deliveries(): void
    {
        $this->assertTrue($this->policy->viewAny($this->courierUser));
    }

    public function test_customer_cannot_view_any_deliveries(): void
    {
        $this->assertFalse($this->policy->viewAny($this->customer));
    }

    /*
    |--------------------------------------------------------------------------
    | Tests view
    |--------------------------------------------------------------------------
    */

    public function test_admin_can_view_any_delivery(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
        ]);

        $this->assertTrue($this->policy->view($this->admin, $delivery));
    }

    public function test_customer_can_view_delivery_for_their_order(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
        ]);

        $this->assertTrue($this->policy->view($this->customer, $delivery));
    }

    public function test_customer_cannot_view_delivery_for_other_customer_order(): void
    {
        $otherCustomer = User::factory()->create(['role' => 'customer']);
        
        $order = Order::factory()->create([
            'customer_id' => $otherCustomer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
        ]);

        $this->assertFalse($this->policy->view($this->customer, $delivery));
    }

    public function test_courier_can_view_assigned_delivery(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
        ]);

        $this->assertTrue($this->policy->view($this->courierUser, $delivery));
    }

    public function test_courier_cannot_view_unassigned_delivery(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->otherCourier->id,
        ]);

        $this->assertFalse($this->policy->view($this->courierUser, $delivery));
    }

    /*
    |--------------------------------------------------------------------------
    | Tests updateStatus
    |--------------------------------------------------------------------------
    */

    public function test_admin_can_update_any_delivery_status(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
        ]);

        $this->assertTrue($this->policy->updateStatus($this->admin, $delivery));
    }

    public function test_assigned_courier_can_update_delivery_status(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
        ]);

        $this->assertTrue($this->policy->updateStatus($this->courierUser, $delivery));
    }

    public function test_other_courier_cannot_update_delivery_status(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
        ]);

        $this->assertFalse($this->policy->updateStatus($this->otherCourierUser, $delivery));
    }

    public function test_customer_cannot_update_delivery_status(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
        ]);

        $this->assertFalse($this->policy->updateStatus($this->customer, $delivery));
    }

    /*
    |--------------------------------------------------------------------------
    | Tests markArrived
    |--------------------------------------------------------------------------
    */

    public function test_assigned_courier_can_mark_in_transit_delivery_as_arrived(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
            'status' => 'in_transit',
        ]);

        $this->assertTrue($this->policy->markArrived($this->courierUser, $delivery));
    }

    public function test_courier_cannot_mark_pending_delivery_as_arrived(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
            'status' => 'pending',
        ]);

        $this->assertFalse($this->policy->markArrived($this->courierUser, $delivery));
    }

    public function test_other_courier_cannot_mark_delivery_as_arrived(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
            'status' => 'in_transit',
        ]);

        $this->assertFalse($this->policy->markArrived($this->otherCourierUser, $delivery));
    }

    /*
    |--------------------------------------------------------------------------
    | Tests complete
    |--------------------------------------------------------------------------
    */

    public function test_admin_can_complete_any_delivery(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
            'status' => 'in_transit',
        ]);

        $this->assertTrue($this->policy->complete($this->admin, $delivery));
    }

    public function test_assigned_courier_can_complete_in_transit_delivery(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
            'status' => 'in_transit',
        ]);

        $this->assertTrue($this->policy->complete($this->courierUser, $delivery));
    }

    public function test_courier_cannot_complete_pending_delivery(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
            'status' => 'pending',
        ]);

        $this->assertFalse($this->policy->complete($this->courierUser, $delivery));
    }

    public function test_customer_cannot_complete_delivery(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        
        $delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
            'status' => 'in_transit',
        ]);

        $this->assertFalse($this->policy->complete($this->customer, $delivery));
    }
}
