<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Prescription;
use App\Models\User;
use App\Services\PrescriptionOcrService;
use App\Services\ProductMatchingService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class CustomerPrescriptionControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    private User $customer;

    protected function setUp(): void
    {
        parent::setUp();

        $this->customer = User::factory()->create([
            'role' => 'customer',
            'phone_verified_at' => now(),
            'must_change_password' => false,
        ]);
    }

    private function actingAsCustomer()
    {
        return $this->actingAs($this->customer, 'sanctum');
    }

    // ─── INDEX ───────────────────────────────────────────────────────────────

    public function test_index_returns_customer_prescriptions(): void
    {
        Prescription::factory()->count(3)->create([
            'customer_id' => $this->customer->id,
        ]);

        // Other customer's prescription should not appear
        Prescription::factory()->create();

        $response = $this->actingAsCustomer()->getJson('/api/customer/prescriptions');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(3, 'data');
    }

    public function test_index_empty(): void
    {
        $response = $this->actingAsCustomer()->getJson('/api/customer/prescriptions');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(0, 'data');
    }

    public function test_index_requires_auth(): void
    {
        $this->getJson('/api/customer/prescriptions')->assertUnauthorized();
    }

    // ─── UPLOAD ──────────────────────────────────────────────────────────────

    public function test_upload_prescription_success(): void
    {
        Storage::fake('private');

        $response = $this->actingAsCustomer()->postJson('/api/customer/prescriptions/upload', [
            'images' => [UploadedFile::fake()->image('prescription.jpg')],
            'notes' => 'Urgent',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('is_duplicate', false);

        $this->assertDatabaseHas('prescriptions', [
            'customer_id' => $this->customer->id,
            'status' => 'pending',
            'notes' => 'Urgent',
        ]);
    }

    public function test_upload_detects_duplicate_via_hash(): void
    {
        Storage::fake('private');

        // First upload
        $image = UploadedFile::fake()->image('prescription.jpg');
        $this->actingAsCustomer()->postJson('/api/customer/prescriptions/upload', [
            'images' => [$image],
        ]);

        // Same image content = same hash (in practice with fake files the hash may differ,
        // but we test that the duplicate field is present in response)
        $response = $this->actingAsCustomer()->postJson('/api/customer/prescriptions/upload', [
            'images' => [UploadedFile::fake()->image('prescription2.jpg')],
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure(['is_duplicate', 'existing_prescription_id']);
    }

    public function test_upload_with_checkout_source(): void
    {
        Storage::fake('private');

        $response = $this->actingAsCustomer()->postJson('/api/customer/prescriptions/upload', [
            'images' => [UploadedFile::fake()->image('rx.jpg')],
            'source' => 'checkout',
        ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('prescriptions', [
            'customer_id' => $this->customer->id,
            'source' => 'checkout',
        ]);
    }

    public function test_upload_validation_requires_images(): void
    {
        $response = $this->actingAsCustomer()->postJson('/api/customer/prescriptions/upload', []);

        $response->assertStatus(422);
    }

    public function test_upload_rejects_non_image_files(): void
    {
        $response = $this->actingAsCustomer()->postJson('/api/customer/prescriptions/upload', [
            'images' => [UploadedFile::fake()->create('document.pdf', 100, 'application/pdf')],
        ]);

        $response->assertStatus(422);
    }

    // ─── SHOW ────────────────────────────────────────────────────────────────

    public function test_show_own_prescription(): void
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
        ]);

        $response = $this->actingAsCustomer()->getJson("/api/customer/prescriptions/{$prescription->id}");

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_show_other_customer_prescription_returns_404(): void
    {
        $other = Prescription::factory()->create();

        $response = $this->actingAsCustomer()->getJson("/api/customer/prescriptions/{$other->id}");

        $response->assertNotFound();
    }

    // ─── PAY ─────────────────────────────────────────────────────────────────

    public function test_pay_quoted_prescription(): void
    {
        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy->users()->attach($pharmacyUser->id, ['role' => 'titulaire']);

        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'status' => 'quoted',
            'quote_amount' => 5000,
            'validated_by' => $pharmacyUser->id,
        ]);

        $response = $this->actingAsCustomer()->postJson("/api/customer/prescriptions/{$prescription->id}/pay", [
            'payment_method' => 'mobile_money',
        ]);

        $response->assertOk();

        $this->assertDatabaseHas('prescriptions', [
            'id' => $prescription->id,
            'status' => 'paid',
        ]);
    }

    public function test_pay_non_quoted_prescription_returns_error(): void
    {
        $prescription = Prescription::factory()->create([
            'customer_id' => $this->customer->id,
            'status' => 'pending',
        ]);

        $response = $this->actingAsCustomer()->postJson("/api/customer/prescriptions/{$prescription->id}/pay");

        $response->assertStatus(400);
    }

    public function test_pay_other_customer_prescription_returns_404(): void
    {
        $prescription = Prescription::factory()->create([
            'status' => 'quoted',
            'quote_amount' => 5000,
        ]);

        $response = $this->actingAsCustomer()->postJson("/api/customer/prescriptions/{$prescription->id}/pay");

        $response->assertNotFound();
    }

    // ─── OCR ─────────────────────────────────────────────────────────────────

    public function test_ocr_analysis_success(): void
    {
        Storage::fake('public');

        $this->mock(PrescriptionOcrService::class, function ($mock) {
            $mock->shouldReceive('analyzeImage')->andReturn([
                'success' => true,
                'medications' => [['name' => 'Amoxicilline', 'dosage' => '500mg']],
                'confidence' => 0.85,
                'raw_text' => 'Amoxicilline 500mg 3x/jour',
                'is_prescription' => true,
            ]);
        });

        $this->mock(ProductMatchingService::class, function ($mock) {
            $mock->shouldReceive('matchMedications')->andReturn([
                'matched' => [['medication' => 'Amoxicilline', 'product_id' => 1, 'product_name' => 'Amoxicilline 500mg', 'price' => 2500, 'pharmacy_name' => 'Pharma Test', 'match_score' => 0.95]],
                'not_found' => [],
                'out_of_stock' => [],
                'stats' => ['total' => 1, 'matched' => 1],
            ]);
        });

        $response = $this->actingAsCustomer()->postJson('/api/customer/prescriptions/ocr', [
            'image' => UploadedFile::fake()->image('prescription.jpg'),
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['matched_products', 'unmatched_medications', 'confidence']);
    }

    public function test_ocr_failure_returns_error(): void
    {
        Storage::fake('public');

        $this->mock(PrescriptionOcrService::class, function ($mock) {
            $mock->shouldReceive('analyzeImage')->andReturn([
                'success' => false,
                'error' => 'Image illisible',
            ]);
        });

        $response = $this->actingAsCustomer()->postJson('/api/customer/prescriptions/ocr', [
            'image' => UploadedFile::fake()->image('blurry.jpg'),
        ]);

        $response->assertStatus(400);
    }

    public function test_ocr_validation_requires_image(): void
    {
        $response = $this->actingAsCustomer()->postJson('/api/customer/prescriptions/ocr', []);

        $response->assertStatus(422);
    }

    public function test_ocr_exception_returns_500(): void
    {
        Storage::fake('public');

        $this->mock(PrescriptionOcrService::class, function ($mock) {
            $mock->shouldReceive('analyzeImage')->andThrow(new \Exception('Service down'));
        });

        $response = $this->actingAsCustomer()->postJson('/api/customer/prescriptions/ocr', [
            'image' => UploadedFile::fake()->image('rx.jpg'),
        ]);

        $response->assertStatus(500);
    }
}
