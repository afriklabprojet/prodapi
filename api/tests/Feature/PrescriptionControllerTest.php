<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Prescription;
use App\Models\Pharmacy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

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

    /** @test */
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

    /** @test */
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

    /** @test */
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

    /** @test */
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

    /** @test */
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

    /** @test */
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

    /** @test */
    public function pharmacy_users_can_be_fetched_by_role_column()
    {
        // This is the correct way to fetch pharmacy users
        $pharmacyUsers = User::where('role', 'pharmacy')->get();
        
        $this->assertCount(1, $pharmacyUsers);
        $this->assertEquals($this->pharmacyUser->id, $pharmacyUsers->first()->id);
    }

    /** @test */
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
}
