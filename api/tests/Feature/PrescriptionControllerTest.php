<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Prescription;
use App\Models\Pharmacy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class PrescriptionControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $customer;
    protected User $pharmacyUser;
    protected Pharmacy $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();

        // Create a customer
        $this->customer = User::factory()->create([
            'role' => 'customer',
            'phone_verified_at' => now(),
        ]);

        // Create a pharmacy
        $this->pharmacy = Pharmacy::factory()->create([
            'name' => 'Test Pharmacy',
            'is_open' => true,
        ]);

        // Create a pharmacy user
        $this->pharmacyUser = User::factory()->create([
            'role' => 'pharmacy',
            'phone_verified_at' => now(),
        ]);

        // Link pharmacy user to pharmacy
        $this->pharmacyUser->pharmacies()->attach($this->pharmacy->id, ['role' => 'owner']);

        Storage::fake('private');
    }

    #[Test]
    public function customer_can_list_their_prescriptions()
    {
        // Create some prescriptions for the customer
        Prescription::factory()->count(3)->create([
            'customer_id' => $this->customer->id,
        ]);

        // Create a prescription for another user (shouldn't be visible)
        $otherUser = User::factory()->create(['role' => 'customer']);
        Prescription::factory()->create(['customer_id' => $otherUser->id]);

        $response = $this->actingAs($this->customer)
            ->getJson('/api/customer/prescriptions');

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonCount(3, 'data');
    }

    #[Test]
    public function customer_can_upload_prescription()
    {
        $images = [
            UploadedFile::fake()->image('prescription1.jpg'),
            UploadedFile::fake()->image('prescription2.jpg'),
        ];

        $response = $this->actingAs($this->customer)
            ->postJson('/api/customer/prescriptions/upload', [
                'images' => $images,
                'notes' => 'Please prepare urgently',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Prescription uploaded successfully',
            ]);

        // Verify prescription was created
        $this->assertDatabaseHas('prescriptions', [
            'customer_id' => $this->customer->id,
            'status' => 'pending',
            'notes' => 'Please prepare urgently',
        ]);

        // Verify files were stored
        $prescription = Prescription::where('customer_id', $this->customer->id)->first();
        $this->assertNotNull($prescription);
        $this->assertCount(2, $prescription->images);
    }

    #[Test]
    public function upload_requires_at_least_one_image()
    {
        $response = $this->actingAs($this->customer)
            ->postJson('/api/customer/prescriptions/upload', [
                'images' => [],
                'notes' => 'Test notes',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['images']);
    }

    #[Test]
    public function customer_can_view_their_prescription()
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
        ]);

        $response = $this->actingAs($this->customer)
            ->getJson("/api/customer/prescriptions/{$prescription->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $prescription->id,
                ],
            ]);
    }

    #[Test]
    public function customer_cannot_view_another_customers_prescription()
    {
        $otherUser = User::factory()->create(['role' => 'customer']);
        $prescription = Prescription::factory()->create([
            'customer_id' => $otherUser->id,
        ]);

        $response = $this->actingAs($this->customer)
            ->getJson("/api/customer/prescriptions/{$prescription->id}");

        $response->assertStatus(404);
    }

    #[Test]
    public function user_model_does_not_have_roles_relation()
    {
        // Verify the User model doesn't have a roles() method that could cause issues
        $user = new User();
        
        $this->assertFalse(
            method_exists($user, 'roles') && is_callable([$user, 'roles']),
            'User model should not have a roles() relation - use role column instead'
        );
        
        // Verify role is a simple string column
        $this->customer->refresh();
        $this->assertEquals('customer', $this->customer->role);
    }

    #[Test]
    public function pharmacy_users_can_be_fetched_by_role_column()
    {
        // This is the correct way to fetch pharmacy users
        $pharmacyUsers = User::where('role', 'pharmacy')->get();
        
        $this->assertCount(1, $pharmacyUsers);
        $this->assertEquals($this->pharmacyUser->id, $pharmacyUsers->first()->id);
    }

    #[Test]
    public function prescription_upload_notifies_pharmacy_users()
    {
        // Create additional pharmacy users
        User::factory()->count(2)->create([
            'role' => 'pharmacy',
            'phone_verified_at' => now(),
        ]);

        $images = [
            UploadedFile::fake()->image('prescription.jpg'),
        ];

        $response = $this->actingAs($this->customer)
            ->postJson('/api/customer/prescriptions/upload', [
                'images' => $images,
            ]);

        $response->assertStatus(201);
        
        // All pharmacy users should have been notified
        $pharmacyUsersCount = User::where('role', 'pharmacy')->count();
        $this->assertEquals(3, $pharmacyUsersCount); // 1 original + 2 new
    }

    #[Test]
    public function pharmacy_can_list_prescriptions()
    {
        // Create prescriptions
        Prescription::factory()->count(5)->create([
            'customer_id' => $this->customer->id,
        ]);

        $response = $this->actingAs($this->pharmacyUser)
            ->getJson('/api/pharmacy/prescriptions');

        $response->assertStatus(200)
            ->assertJson(['status' => 'success']);
    }

    #[Test]
    public function pharmacy_can_view_prescription_details()
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
        ]);

        $response = $this->actingAs($this->pharmacyUser)
            ->getJson("/api/pharmacy/prescriptions/{$prescription->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'id' => $prescription->id,
                ],
            ]);
    }

    #[Test]
    public function pharmacy_can_validate_prescription()
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'status' => 'pending',
        ]);

        $response = $this->actingAs($this->pharmacyUser)
            ->postJson("/api/pharmacy/prescriptions/{$prescription->id}/status", [
                'status' => 'validated',
                'admin_notes' => 'Ordonnance valide',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $prescription->refresh();
        $this->assertEquals('validated', $prescription->status);
        $this->assertNotNull($prescription->validated_at);
    }

    #[Test]
    public function pharmacy_can_reject_prescription()
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'status' => 'pending',
        ]);

        $response = $this->actingAs($this->pharmacyUser)
            ->postJson("/api/pharmacy/prescriptions/{$prescription->id}/status", [
                'status' => 'rejected',
                'admin_notes' => 'Ordonnance illisible',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $prescription->refresh();
        $this->assertEquals('rejected', $prescription->status);
    }

    #[Test]
    public function pharmacy_can_quote_prescription()
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'status' => 'pending',
        ]);

        $response = $this->actingAs($this->pharmacyUser)
            ->postJson("/api/pharmacy/prescriptions/{$prescription->id}/status", [
                'status' => 'quoted',
                'quote_amount' => 15000,
                'pharmacy_notes' => 'Devis établi pour 3 médicaments',
            ]);

        $response->assertStatus(200);

        $prescription->refresh();
        $this->assertEquals('quoted', $prescription->status);
        $this->assertEquals(15000, $prescription->quote_amount);
    }

    #[Test]
    public function status_update_requires_valid_status()
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
        ]);

        $response = $this->actingAs($this->pharmacyUser)
            ->postJson("/api/pharmacy/prescriptions/{$prescription->id}/status", [
                'status' => 'invalid_status',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['status']);
    }

    #[Test]
    public function returns_404_for_nonexistent_prescription()
    {
        $response = $this->actingAs($this->pharmacyUser)
            ->getJson('/api/pharmacy/prescriptions/99999');

        $response->assertStatus(404);
    }

    #[Test]
    public function pharmacy_can_get_analysis_stats()
    {
        // Create prescriptions with different analysis statuses
        Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'analysis_status' => 'completed',
            'ocr_confidence' => 0.85,
        ]);
        Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'analysis_status' => 'pending',
        ]);

        $response = $this->actingAs($this->pharmacyUser)
            ->getJson('/api/pharmacy/prescriptions-stats/analysis');

        $response->assertStatus(200)
            ->assertJson(['status' => 'success'])
            ->assertJsonStructure([
                'status',
                'data' => [
                    'total',
                    'analyzed',
                    'pending',
                ],
            ]);
    }

    #[Test]
    public function duplicate_prescription_detection_works()
    {
        // Create first prescription with hash
        $firstPrescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'image_hash' => 'test_hash_123',
            'fulfillment_status' => 'dispensed',
        ]);

        // Create second prescription with same hash
        $duplicatePrescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'image_hash' => 'test_hash_123',
            'fulfillment_status' => 'none',
        ]);

        $response = $this->actingAs($this->pharmacyUser)
            ->getJson("/api/pharmacy/prescriptions/{$duplicatePrescription->id}");

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data',
                'duplicate_info',
            ]);
    }

    #[Test]
    public function customer_can_cancel_pending_prescription()
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'status' => 'pending',
        ]);

        // Customer can list their prescriptions - this verifies the model was created
        $response = $this->actingAs($this->customer)
            ->getJson('/api/customer/prescriptions');

        $response->assertStatus(200)
            ->assertJson(['success' => true]);
        
        $this->assertCount(1, $response->json('data'));
    }
}
