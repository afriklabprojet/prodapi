<?php

namespace Tests\Unit\Policies;

use App\Models\Product;
use App\Models\Pharmacy;
use App\Models\User;
use App\Policies\ProductPolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProductPolicyTest extends TestCase
{
    use RefreshDatabase;

    protected ProductPolicy $policy;

    protected function setUp(): void
    {
        parent::setUp();
        $this->policy = new ProductPolicy();
    }

    /**
     * Test viewAny
     */
    public function test_anyone_can_view_products_list(): void
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = User::factory()->create(['role' => 'pharmacy']);
        $admin = User::factory()->create(['role' => 'admin']);

        $this->assertTrue($this->policy->viewAny($customer));
        $this->assertTrue($this->policy->viewAny($pharmacy));
        $this->assertTrue($this->policy->viewAny($admin));
    }

    /**
     * Test view
     */
    public function test_admin_can_view_any_product(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'is_available' => false,
        ]);

        $this->assertTrue($this->policy->view($admin, $product));
    }

    public function test_pharmacy_can_view_own_product(): void
    {
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::factory()->create();
        $pharmacy->users()->attach($pharmacyUser->id, ['role' => 'owner']);
        
        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'is_available' => false,
        ]);

        $this->assertTrue($this->policy->view($pharmacyUser, $product));
    }

    public function test_customer_can_only_view_available_products(): void
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        
        $availableProduct = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'is_available' => true,
        ]);
        
        $unavailableProduct = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'is_available' => false,
        ]);

        $this->assertTrue($this->policy->view($customer, $availableProduct));
        $this->assertFalse($this->policy->view($customer, $unavailableProduct));
    }

    /**
     * Test create
     */
    public function test_only_pharmacy_and_admin_can_create(): void
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $courier = User::factory()->create(['role' => 'courier']);
        $pharmacy = User::factory()->create(['role' => 'pharmacy']);
        $admin = User::factory()->create(['role' => 'admin']);

        $this->assertFalse($this->policy->create($customer));
        $this->assertFalse($this->policy->create($courier));
        $this->assertTrue($this->policy->create($pharmacy));
        $this->assertTrue($this->policy->create($admin));
    }

    /**
     * Test update
     */
    public function test_pharmacy_can_only_update_own_product(): void
    {
        $pharmacyUser1 = User::factory()->create(['role' => 'pharmacy']);
        $pharmacyUser2 = User::factory()->create(['role' => 'pharmacy']);
        
        $pharmacy1 = Pharmacy::factory()->create();
        $pharmacy2 = Pharmacy::factory()->create();
        
        $pharmacy1->users()->attach($pharmacyUser1->id, ['role' => 'owner']);
        $pharmacy2->users()->attach($pharmacyUser2->id, ['role' => 'owner']);
        
        $product = Product::factory()->create(['pharmacy_id' => $pharmacy1->id]);

        $this->assertTrue($this->policy->update($pharmacyUser1, $product));
        $this->assertFalse($this->policy->update($pharmacyUser2, $product));
    }

    /**
     * Test delete
     */
    public function test_customer_cannot_delete(): void
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create(['pharmacy_id' => $pharmacy->id]);

        $this->assertFalse($this->policy->delete($customer, $product));
    }

    public function test_admin_can_delete_any_product(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create(['pharmacy_id' => $pharmacy->id]);

        $this->assertTrue($this->policy->delete($admin, $product));
    }
}
