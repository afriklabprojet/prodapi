<?php

namespace Tests\Unit\Policies;

use App\Models\User;
use App\Models\Pharmacy;
use App\Models\Prescription;
use App\Policies\PrescriptionPolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Tests unitaires pour PrescriptionPolicy
 * 
 * Security Audit Week 3 - Tests de sécurité
 */
class PrescriptionPolicyTest extends TestCase
{
    use RefreshDatabase;

    protected PrescriptionPolicy $policy;
    protected User $admin;
    protected User $customer;
    protected User $otherCustomer;
    protected User $pharmacyUser;
    protected Pharmacy $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();

        $this->policy = new PrescriptionPolicy();

        // Créer les utilisateurs de test
        $this->admin = User::factory()->create(['role' => 'admin']);
        $this->customer = User::factory()->create(['role' => 'customer']);
        $this->otherCustomer = User::factory()->create(['role' => 'customer']);
        $this->pharmacyUser = User::factory()->create(['role' => 'pharmacy']);

        // Créer une pharmacie et l'associer
        $this->pharmacy = Pharmacy::factory()->create();
        $this->pharmacyUser->pharmacies()->attach($this->pharmacy->id);
    }

    /*
    |--------------------------------------------------------------------------
    | Tests viewAny
    |--------------------------------------------------------------------------
    */

    public function test_admin_can_view_any_prescriptions(): void
    {
        $this->assertTrue($this->policy->viewAny($this->admin));
    }

    public function test_customer_can_view_any_prescriptions(): void
    {
        $this->assertTrue($this->policy->viewAny($this->customer));
    }

    public function test_pharmacy_can_view_any_prescriptions(): void
    {
        $this->assertTrue($this->policy->viewAny($this->pharmacyUser));
    }

    /*
    |--------------------------------------------------------------------------
    | Tests view
    |--------------------------------------------------------------------------
    */

    public function test_admin_can_view_any_prescription(): void
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
        ]);

        $this->assertTrue($this->policy->view($this->admin, $prescription));
    }

    public function test_customer_can_view_own_prescription(): void
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
        ]);

        $this->assertTrue($this->policy->view($this->customer, $prescription));
    }

    public function test_customer_cannot_view_other_customer_prescription(): void
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
        ]);

        $this->assertFalse($this->policy->view($this->otherCustomer, $prescription));
    }

    public function test_pharmacy_can_view_pending_prescription(): void
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'status' => 'pending',
        ]);

        // Les pharmacies peuvent voir les prescriptions pending pour faire des devis
        $this->assertTrue($this->policy->view($this->pharmacyUser, $prescription));
    }

    /*
    |--------------------------------------------------------------------------
    | Tests create
    |--------------------------------------------------------------------------
    */

    public function test_customer_can_create_prescription(): void
    {
        $this->assertTrue($this->policy->create($this->customer));
    }

    public function test_pharmacy_cannot_create_prescription(): void
    {
        $this->assertFalse($this->policy->create($this->pharmacyUser));
    }

    public function test_admin_cannot_create_prescription(): void
    {
        // Seuls les customers peuvent créer des prescriptions
        $this->assertFalse($this->policy->create($this->admin));
    }

    /*
    |--------------------------------------------------------------------------
    | Tests updateStatus
    |--------------------------------------------------------------------------
    */

    public function test_admin_can_update_status_of_any_prescription(): void
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
        ]);

        $this->assertTrue($this->policy->updateStatus($this->admin, $prescription));
    }

    public function test_pharmacy_can_update_status_of_pending_prescription(): void
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'status' => 'pending',
        ]);

        // Les pharmacies peuvent traiter les prescriptions pending
        $this->assertTrue($this->policy->updateStatus($this->pharmacyUser, $prescription));
    }

    public function test_customer_cannot_update_status_of_prescription(): void
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'status' => 'pending',
        ]);

        $this->assertFalse($this->policy->updateStatus($this->customer, $prescription));
    }

    /*
    |--------------------------------------------------------------------------
    | Tests delete
    |--------------------------------------------------------------------------
    */

    public function test_customer_can_delete_own_pending_prescription(): void
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'status' => 'pending',
        ]);

        $this->assertTrue($this->policy->delete($this->customer, $prescription));
    }

    public function test_customer_cannot_delete_validated_prescription(): void
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'status' => 'validated',
        ]);

        $this->assertFalse($this->policy->delete($this->customer, $prescription));
    }

    public function test_customer_cannot_delete_other_customer_prescription(): void
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'status' => 'pending',
        ]);

        $this->assertFalse($this->policy->delete($this->otherCustomer, $prescription));
    }

    public function test_admin_can_delete_any_prescription(): void
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'status' => 'validated',
        ]);

        $this->assertTrue($this->policy->delete($this->admin, $prescription));
    }

    public function test_pharmacy_cannot_delete_prescription(): void
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'status' => 'pending',
        ]);

        $this->assertFalse($this->policy->delete($this->pharmacyUser, $prescription));
    }
}
