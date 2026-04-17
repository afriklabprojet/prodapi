<?php

namespace Tests\Unit\Policies;

use App\Models\Order;
use App\Models\User;
use App\Models\Pharmacy;
use App\Models\Courier;
use App\Models\Delivery;
use App\Policies\OrderPolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Tests unitaires pour OrderPolicy
 * 
 * Security Audit Week 3 - Tests de sécurité
 */
class OrderPolicyTest extends TestCase
{
    use RefreshDatabase;

    protected OrderPolicy $policy;
    protected User $admin;
    protected User $customer;
    protected User $pharmacyUser;
    protected User $courierUser;
    protected Pharmacy $pharmacy;
    protected Courier $courier;

    protected function setUp(): void
    {
        parent::setUp();

        $this->policy = new OrderPolicy();

        // Créer les utilisateurs de test
        $this->admin = User::factory()->create(['role' => 'admin']);
        $this->customer = User::factory()->create(['role' => 'customer']);
        $this->pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $this->courierUser = User::factory()->create(['role' => 'courier']);

        // Créer une pharmacie et l'associer
        $this->pharmacy = Pharmacy::factory()->create();
        $this->pharmacyUser->pharmacies()->attach($this->pharmacy->id);

        // Créer un coursier
        $this->courier = Courier::factory()->create(['user_id' => $this->courierUser->id]);
    }

    /*
    |--------------------------------------------------------------------------
    | Tests viewAny
    |--------------------------------------------------------------------------
    */

    public function test_admin_can_view_any_orders(): void
    {
        $this->assertTrue($this->policy->viewAny($this->admin));
    }

    public function test_customer_can_view_any_orders(): void
    {
        $this->assertTrue($this->policy->viewAny($this->customer));
    }

    /*
    |--------------------------------------------------------------------------
    | Tests view
    |--------------------------------------------------------------------------
    */

    public function test_admin_can_view_any_order(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $this->assertTrue($this->policy->view($this->admin, $order));
    }

    public function test_customer_can_view_own_order(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $this->assertTrue($this->policy->view($this->customer, $order));
    }

    public function test_customer_cannot_view_other_customer_order(): void
    {
        $otherCustomer = User::factory()->create(['role' => 'customer']);
        $order = Order::factory()->create([
            'customer_id' => $otherCustomer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $this->assertFalse($this->policy->view($this->customer, $order));
    }

    public function test_pharmacy_can_view_order_to_their_pharmacy(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $this->assertTrue($this->policy->view($this->pharmacyUser, $order));
    }

    public function test_pharmacy_cannot_view_order_to_other_pharmacy(): void
    {
        $otherPharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $otherPharmacy->id,
        ]);

        $this->assertFalse($this->policy->view($this->pharmacyUser, $order));
    }

    public function test_courier_can_view_order_assigned_to_them(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
        ]);

        // Recharger l'ordre pour avoir la relation delivery
        $order->refresh();

        $this->assertTrue($this->policy->view($this->courierUser, $order));
    }

    public function test_courier_cannot_view_order_not_assigned_to_them(): void
    {
        $otherCourier = Courier::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $otherCourier->id,
        ]);

        $order->refresh();

        $this->assertFalse($this->policy->view($this->courierUser, $order));
    }

    /*
    |--------------------------------------------------------------------------
    | Tests create
    |--------------------------------------------------------------------------
    */

    public function test_only_customer_can_create_orders(): void
    {
        $this->assertTrue($this->policy->create($this->customer));
        $this->assertFalse($this->policy->create($this->pharmacyUser));
        $this->assertFalse($this->policy->create($this->courierUser));
    }

    public function test_admin_cannot_create_orders(): void
    {
        // Selon l'implémentation, seuls les customers peuvent créer des commandes
        $this->assertFalse($this->policy->create($this->admin));
    }

    /*
    |--------------------------------------------------------------------------
    | Tests cancel
    |--------------------------------------------------------------------------
    */

    public function test_customer_can_cancel_own_pending_order(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'pending',
        ]);

        $this->assertTrue($this->policy->cancel($this->customer, $order));
    }

    public function test_customer_cannot_cancel_delivered_order(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'delivered',
        ]);

        $this->assertFalse($this->policy->cancel($this->customer, $order));
    }

    public function test_customer_cannot_cancel_other_customer_order(): void
    {
        $otherCustomer = User::factory()->create(['role' => 'customer']);
        $order = Order::factory()->create([
            'customer_id' => $otherCustomer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'pending',
        ]);

        $this->assertFalse($this->policy->cancel($this->customer, $order));
    }

    public function test_admin_can_cancel_any_order(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'confirmed',
        ]);

        $this->assertTrue($this->policy->cancel($this->admin, $order));
    }

    /*
    |--------------------------------------------------------------------------
    | Tests accept (pharmacy accepts order)
    |--------------------------------------------------------------------------
    */

    public function test_pharmacy_can_accept_pending_order_to_their_pharmacy(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'pending',
        ]);

        $this->assertTrue($this->policy->accept($this->pharmacyUser, $order));
    }

    public function test_pharmacy_cannot_accept_order_to_other_pharmacy(): void
    {
        $otherPharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $otherPharmacy->id,
            'status' => 'pending',
        ]);

        $this->assertFalse($this->policy->accept($this->pharmacyUser, $order));
    }

    public function test_pharmacy_cannot_accept_non_pending_order(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'confirmed',
        ]);

        $this->assertFalse($this->policy->accept($this->pharmacyUser, $order));
    }

    public function test_customer_cannot_accept_order(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'pending',
        ]);

        $this->assertFalse($this->policy->accept($this->customer, $order));
    }

    /*
    |--------------------------------------------------------------------------
    | Tests assignCourier
    |--------------------------------------------------------------------------
    */

    public function test_admin_can_assign_courier(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'ready',
        ]);

        $this->assertTrue($this->policy->assignCourier($this->admin, $order));
    }

    public function test_pharmacy_can_assign_courier_to_ready_order(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'ready',
        ]);

        $this->assertTrue($this->policy->assignCourier($this->pharmacyUser, $order));
    }

    public function test_customer_cannot_assign_courier(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'ready',
        ]);

        $this->assertFalse($this->policy->assignCourier($this->customer, $order));
    }

    public function test_pharmacy_cannot_assign_courier_to_pending_order(): void
    {
        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'pending',
        ]);

        $this->assertFalse($this->policy->assignCourier($this->pharmacyUser, $order));
    }
}
