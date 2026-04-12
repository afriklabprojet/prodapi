<?php

namespace Tests\Unit\Policies;

use App\Models\Pharmacy;
use App\Models\User;
use App\Policies\PharmacyPolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class PharmacyPolicyTest extends TestCase
{
    use RefreshDatabase;

    private PharmacyPolicy $policy;

    protected function setUp(): void
    {
        parent::setUp();
        $this->policy = new PharmacyPolicy();
    }

    #[Test]
    public function anyone_can_view_any_pharmacies(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $customer = User::factory()->create(['role' => 'customer']);

        $this->assertTrue($this->policy->viewAny($admin));
        $this->assertTrue($this->policy->viewAny($customer));
    }

    #[Test]
    public function admin_can_view_any_pharmacy(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $pharmacy = Pharmacy::factory()->create(['status' => 'pending']);

        $this->assertTrue($this->policy->view($admin, $pharmacy));
    }

    #[Test]
    public function pharmacy_owner_can_view_own_pharmacy(): void
    {
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::factory()->create();
        $pharmacyUser->pharmacies()->attach($pharmacy->id, ['role' => 'owner']);

        $this->assertTrue($this->policy->view($pharmacyUser, $pharmacy));
    }

    #[Test]
    public function customer_can_view_approved_pharmacy(): void
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
            'is_active' => true,
        ]);

        $this->assertTrue($this->policy->view($customer, $pharmacy));
    }

    #[Test]
    public function customer_cannot_view_pending_pharmacy(): void
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create([
            'status' => 'pending',
            'is_active' => true,
        ]);

        $this->assertFalse($this->policy->view($customer, $pharmacy));
    }

    #[Test]
    public function admin_can_create_pharmacies(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $this->assertTrue($this->policy->create($admin));
    }

    #[Test]
    public function non_admin_cannot_create_pharmacies(): void
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = User::factory()->create(['role' => 'pharmacy']);

        $this->assertFalse($this->policy->create($customer));
        $this->assertFalse($this->policy->create($pharmacy));
    }

    #[Test]
    public function admin_can_update_any_pharmacy(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $pharmacy = Pharmacy::factory()->create();

        $this->assertTrue($this->policy->update($admin, $pharmacy));
    }

    #[Test]
    public function pharmacy_owner_can_update_own_pharmacy(): void
    {
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::factory()->create();
        $pharmacyUser->pharmacies()->attach($pharmacy->id, ['role' => 'owner']);

        $this->assertTrue($this->policy->update($pharmacyUser, $pharmacy));
    }

    #[Test]
    public function pharmacy_owner_cannot_update_other_pharmacy(): void
    {
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $ownPharmacy = Pharmacy::factory()->create();
        $pharmacyUser->pharmacies()->attach($ownPharmacy->id, ['role' => 'owner']);

        $otherPharmacy = Pharmacy::factory()->create();

        $this->assertFalse($this->policy->update($pharmacyUser, $otherPharmacy));
    }

    #[Test]
    public function admin_can_delete_pharmacy(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $pharmacy = Pharmacy::factory()->create();

        $this->assertTrue($this->policy->delete($admin, $pharmacy));
    }

    #[Test]
    public function non_admin_cannot_delete_pharmacy(): void
    {
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::factory()->create();
        $pharmacyUser->pharmacies()->attach($pharmacy->id, ['role' => 'owner']);

        $this->assertFalse($this->policy->delete($pharmacyUser, $pharmacy));
    }

    #[Test]
    public function admin_can_approve_pending_pharmacy(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $pharmacy = Pharmacy::factory()->create(['status' => 'pending']);

        $this->assertTrue($this->policy->approve($admin, $pharmacy));
    }

    #[Test]
    public function admin_cannot_approve_already_approved_pharmacy(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);

        $this->assertFalse($this->policy->approve($admin, $pharmacy));
    }

    #[Test]
    public function admin_can_suspend_active_pharmacy(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);

        $this->assertTrue($this->policy->suspend($admin, $pharmacy));
    }

    #[Test]
    public function admin_cannot_suspend_already_suspended_pharmacy(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $pharmacy = Pharmacy::factory()->create(['status' => 'suspended']);

        $this->assertFalse($this->policy->suspend($admin, $pharmacy));
    }

    #[Test]
    public function pharmacy_owner_can_manage_on_calls(): void
    {
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::factory()->create();
        $pharmacyUser->pharmacies()->attach($pharmacy->id, ['role' => 'owner']);

        $this->assertTrue($this->policy->manageOnCalls($pharmacyUser, $pharmacy));
    }

    #[Test]
    public function admin_can_view_pharmacy_inventory(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $pharmacy = Pharmacy::factory()->create();

        $this->assertTrue($this->policy->viewInventory($admin, $pharmacy));
    }

    #[Test]
    public function pharmacy_owner_can_view_own_inventory(): void
    {
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::factory()->create();
        $pharmacyUser->pharmacies()->attach($pharmacy->id, ['role' => 'owner']);

        $this->assertTrue($this->policy->viewInventory($pharmacyUser, $pharmacy));
    }

    #[Test]
    public function customer_cannot_view_pharmacy_inventory(): void
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();

        $this->assertFalse($this->policy->viewInventory($customer, $pharmacy));
    }

    #[Test]
    public function pharmacy_owner_can_manage_inventory(): void
    {
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::factory()->create();
        $pharmacyUser->pharmacies()->attach($pharmacy->id, ['role' => 'owner']);

        $this->assertTrue($this->policy->manageInventory($pharmacyUser, $pharmacy));
    }

    #[Test]
    public function pharmacy_owner_can_view_reports(): void
    {
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::factory()->create();
        $pharmacyUser->pharmacies()->attach($pharmacy->id, ['role' => 'owner']);

        $this->assertTrue($this->policy->viewReports($pharmacyUser, $pharmacy));
    }
}
