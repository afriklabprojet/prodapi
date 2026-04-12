<?php

namespace Tests\Feature;

use App\Models\Pharmacy;
use App\Models\Prescription;
use App\Models\PrescriptionDispensing;
use App\Models\Product;
use App\Models\User;
use App\Services\PrescriptionOcrService;
use App\Services\ProductMatchingService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PharmacyPrescriptionControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    private User $pharmacyUser;
    private Pharmacy $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();

        $this->pharmacyUser = User::factory()->create([
            'role' => 'pharmacy',
            'phone_verified_at' => now(),
            'must_change_password' => false,
        ]);

        $this->pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->pharmacy->users()->attach($this->pharmacyUser->id, ['role' => 'titulaire']);
    }

    private function actingAsPharmacy()
    {
        return $this->actingAs($this->pharmacyUser, 'sanctum');
    }

    // ─── INDEX ───────────────────────────────────────────────────────────────

    public function test_index_returns_all_prescriptions(): void
    {
        Prescription::factory()->count(3)->create();

        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/prescriptions');

        $response->assertOk()
            ->assertJsonPath('status', 'success');
    }

    public function test_index_flags_duplicates(): void
    {
        // Two prescriptions with the same hash, one already dispensed
        $hash = hash('sha256', 'test_image_content');
        Prescription::factory()->create([
            'image_hash' => $hash,
            'fulfillment_status' => 'full',
        ]);
        Prescription::factory()->create([
            'image_hash' => $hash,
            'fulfillment_status' => 'none',
        ]);

        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/prescriptions');

        $response->assertOk();
        // The second (unfulfilled) prescription should be flagged as duplicate
        $data = $response->json('data');
        $duplicates = collect($data)->where('is_duplicate', true);
        $this->assertGreaterThanOrEqual(1, $duplicates->count());
    }

    // ─── SHOW ────────────────────────────────────────────────────────────────

    public function test_show_existing_prescription(): void
    {
        $prescription = Prescription::factory()->create();

        $response = $this->actingAsPharmacy()->getJson("/api/pharmacy/prescriptions/{$prescription->id}");

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_show_nonexistent_prescription_returns_404(): void
    {
        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/prescriptions/99999');

        $response->assertNotFound();
    }

    public function test_show_detects_duplicate_info(): void
    {
        $hash = hash('sha256', 'same_image');
        $original = Prescription::factory()->create([
            'image_hash' => $hash,
            'fulfillment_status' => 'full',
        ]);
        $duplicate = Prescription::factory()->create([
            'image_hash' => $hash,
            'fulfillment_status' => 'none',
        ]);

        $response = $this->actingAsPharmacy()->getJson("/api/pharmacy/prescriptions/{$duplicate->id}");

        $response->assertOk()
            ->assertJsonStructure(['duplicate_info']);
    }

    // ─── UPDATE STATUS ───────────────────────────────────────────────────────

    public function test_update_status_to_validated(): void
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $prescription = Prescription::factory()->create([
            'customer_id' => $customer->id,
            'status' => 'pending',
        ]);

        $response = $this->actingAsPharmacy()->postJson("/api/pharmacy/prescriptions/{$prescription->id}/status", [
            'status' => 'validated',
            'admin_notes' => 'Ordonnance valide',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('prescriptions', [
            'id' => $prescription->id,
            'status' => 'validated',
            'validated_by' => $this->pharmacyUser->id,
        ]);
    }

    public function test_update_status_to_quoted_with_amount(): void
    {
        $prescription = Prescription::factory()->create(['status' => 'pending']);

        $response = $this->actingAsPharmacy()->postJson("/api/pharmacy/prescriptions/{$prescription->id}/status", [
            'status' => 'quoted',
            'quote_amount' => 15000,
            'pharmacy_notes' => 'Devis établi',
        ]);

        $response->assertOk();

        $this->assertDatabaseHas('prescriptions', [
            'id' => $prescription->id,
            'status' => 'quoted',
            'quote_amount' => 15000,
        ]);
    }

    public function test_update_status_to_rejected(): void
    {
        $prescription = Prescription::factory()->create(['status' => 'pending']);

        $response = $this->actingAsPharmacy()->postJson("/api/pharmacy/prescriptions/{$prescription->id}/status", [
            'status' => 'rejected',
            'admin_notes' => 'Ordonnance illisible',
        ]);

        $response->assertOk();
    }

    public function test_update_status_nonexistent_returns_404(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/prescriptions/99999/status', [
            'status' => 'validated',
        ]);

        $response->assertNotFound();
    }

    public function test_update_status_validation(): void
    {
        $prescription = Prescription::factory()->create();

        $response = $this->actingAsPharmacy()->postJson("/api/pharmacy/prescriptions/{$prescription->id}/status", [
            'status' => 'invalid_status',
        ]);

        $response->assertUnprocessable();
    }

    // ─── ANALYZE ─────────────────────────────────────────────────────────────

    public function test_analyze_prescription_already_completed(): void
    {
        $prescription = Prescription::factory()->create([
            'analysis_status' => 'completed',
            'extracted_medications' => [['name' => 'Paracetamol']],
            'ocr_confidence' => 0.9,
        ]);

        $response = $this->actingAsPharmacy()->postJson("/api/pharmacy/prescriptions/{$prescription->id}/analyze");

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_analyze_nonexistent_returns_404(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/prescriptions/99999/analyze');

        $response->assertNotFound();
    }

    public function test_analyze_returns_422_when_no_images_are_available(): void
    {
        $prescription = Prescription::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'images' => [],
            'analysis_status' => 'pending',
        ]);

        $response = $this->actingAsPharmacy()->postJson("/api/pharmacy/prescriptions/{$prescription->id}/analyze");

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
        $this->assertEquals('failed', $prescription->fresh()->analysis_status);
    }

    public function test_analyze_handles_ocr_failure(): void
    {
        $prescription = Prescription::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'images' => ['prescriptions/test-ocr-failure.jpg'],
            'analysis_status' => 'pending',
        ]);

        $mock = $this->createMock(PrescriptionOcrService::class);
        $mock->method('analyzeImage')->willReturn([
            'success' => false,
            'error' => 'OCR service unavailable',
        ]);
        $this->app->instance(PrescriptionOcrService::class, $mock);

        $response = $this->actingAsPharmacy()->postJson("/api/pharmacy/prescriptions/{$prescription->id}/analyze");

        $response->assertStatus(502)
            ->assertJsonPath('success', false);
        $this->assertEquals('failed', $prescription->fresh()->analysis_status);
    }

    public function test_analyze_successfully_extracts_and_matches_medications(): void
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Paracetamol 500mg',
            'price' => 2500,
            'stock_quantity' => 30,
            'is_available' => true,
        ]);

        $prescription = Prescription::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'images' => ['prescriptions/test-success.jpg'],
            'analysis_status' => 'pending',
        ]);

        $ocrMock = $this->createMock(PrescriptionOcrService::class);
        $ocrMock->method('analyzeImage')->willReturn([
            'success' => true,
            'raw_text' => 'Paracetamol 500mg',
            'confidence' => 0.92,
            'medications' => [
                ['name' => 'Paracetamol 500mg', 'dosage' => '500mg'],
            ],
        ]);
        $this->app->instance(PrescriptionOcrService::class, $ocrMock);

        $matchMock = $this->createMock(ProductMatchingService::class);
        $matchMock->method('matchMedications')->willReturn([
            'matched' => [[
                'product_id' => $product->id,
                'product_name' => $product->name,
                'price' => $product->price,
            ]],
            'not_found' => [],
            'out_of_stock' => [],
            'alternatives' => [],
            'stats' => ['matched_count' => 1],
            'total_estimated_price' => 2500,
        ]);
        $this->app->instance(ProductMatchingService::class, $matchMock);

        $response = $this->actingAsPharmacy()->postJson("/api/pharmacy/prescriptions/{$prescription->id}/analyze");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.estimated_total', 2500)
            ->assertJsonPath('data.confidence', 0.92);

        $prescription->refresh();
        $this->assertEquals('completed', $prescription->analysis_status);
    }

    public function test_analyze_handles_unexpected_exception(): void
    {
        $prescription = Prescription::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'images' => ['prescriptions/test-exception.jpg'],
            'analysis_status' => 'pending',
        ]);

        $mock = $this->createMock(PrescriptionOcrService::class);
        $mock->method('analyzeImage')->willThrowException(new \Exception('Unexpected OCR crash'));
        $this->app->instance(PrescriptionOcrService::class, $mock);

        $response = $this->actingAsPharmacy()->postJson("/api/pharmacy/prescriptions/{$prescription->id}/analyze");

        $response->assertStatus(500)
            ->assertJsonPath('success', false);
        $this->assertEquals('failed', $prescription->fresh()->analysis_status);
    }

    // ─── ANALYSIS STATS ──────────────────────────────────────────────────────

    public function test_analysis_stats_returns_data(): void
    {
        Prescription::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'analysis_status' => 'completed',
        ]);
        Prescription::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'analysis_status' => 'pending',
        ]);

        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/prescriptions-stats/analysis');

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure(['data' => ['total', 'analyzed', 'pending']]);
    }

    // ─── DISPENSE ────────────────────────────────────────────────────────────

    public function test_dispense_medications(): void
    {
        $prescription = Prescription::factory()->create([
            'fulfillment_status' => 'none',
        ]);

        $response = $this->actingAsPharmacy()->postJson("/api/pharmacy/prescriptions/{$prescription->id}/dispense", [
            'medications' => [
                [
                    'medication_name' => 'Amoxicilline 500mg',
                    'quantity_prescribed' => 3,
                    'quantity_dispensed' => 3,
                ],
            ],
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('prescription_dispensings', [
            'prescription_id' => $prescription->id,
            'medication_name' => 'Amoxicilline 500mg',
        ]);
    }

    public function test_dispense_fully_dispensed_prescription_returns_conflict(): void
    {
        $prescription = Prescription::factory()->create([
            'fulfillment_status' => 'full',
        ]);

        $response = $this->actingAsPharmacy()->postJson("/api/pharmacy/prescriptions/{$prescription->id}/dispense", [
            'medications' => [
                ['medication_name' => 'Test', 'quantity_prescribed' => 1, 'quantity_dispensed' => 1],
            ],
        ]);

        $response->assertStatus(409);
    }

    public function test_dispense_nonexistent_returns_404(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/prescriptions/99999/dispense', [
            'medications' => [
                ['medication_name' => 'Test', 'quantity_prescribed' => 1, 'quantity_dispensed' => 1],
            ],
        ]);

        $response->assertNotFound();
    }

    public function test_dispense_validation(): void
    {
        $prescription = Prescription::factory()->create();

        $response = $this->actingAsPharmacy()->postJson("/api/pharmacy/prescriptions/{$prescription->id}/dispense", []);

        $response->assertUnprocessable();
    }

    public function test_dispense_partial_quantity_sets_partial_fulfillment(): void
    {
        $prescription = Prescription::factory()->create([
            'fulfillment_status' => 'none',
        ]);

        $response = $this->actingAsPharmacy()->postJson("/api/pharmacy/prescriptions/{$prescription->id}/dispense", [
            'medications' => [
                [
                    'medication_name' => 'Paracetamol',
                    'quantity_prescribed' => 3,
                    'quantity_dispensed' => 1,
                ],
            ],
        ]);

        $response->assertOk()
            ->assertJsonPath('fulfillment_status', 'partial');
    }

    public function test_dispense_second_pass_completes_remaining_medications(): void
    {
        $prescription = Prescription::factory()->create([
            'fulfillment_status' => 'none',
            'extracted_medications' => [
                ['name' => 'Amoxicilline'],
                ['name' => 'Vitamine C'],
            ],
        ]);

        PrescriptionDispensing::create([
            'prescription_id' => $prescription->id,
            'pharmacy_id' => $this->pharmacy->id,
            'medication_name' => 'Amoxicilline',
            'quantity_prescribed' => 3,
            'quantity_dispensed' => 1,
            'dispensed_at' => now(),
            'dispensed_by' => $this->pharmacyUser->id,
        ]);

        $response = $this->actingAsPharmacy()->postJson("/api/pharmacy/prescriptions/{$prescription->id}/dispense", [
            'medications' => [
                [
                    'medication_name' => 'Vitamine C',
                    'quantity_prescribed' => 1,
                    'quantity_dispensed' => 1,
                ],
            ],
        ]);

        $response->assertOk()
            ->assertJsonPath('fulfillment_status', 'full');
    }

    // ─── DISPENSING HISTORY ──────────────────────────────────────────────────

    public function test_dispensing_history_returns_data(): void
    {
        $prescription = Prescription::factory()->create([
            'fulfillment_status' => 'partial',
        ]);

        PrescriptionDispensing::create([
            'prescription_id' => $prescription->id,
            'pharmacy_id' => $this->pharmacy->id,
            'medication_name' => 'Paracetamol',
            'quantity_prescribed' => 3,
            'quantity_dispensed' => 2,
            'dispensed_at' => now(),
            'dispensed_by' => $this->pharmacyUser->id,
        ]);

        $response = $this->actingAsPharmacy()->getJson("/api/pharmacy/prescriptions/{$prescription->id}/dispensing-history");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['fulfillment_status', 'summary', 'history']]);
    }

    public function test_dispensing_history_nonexistent_returns_404(): void
    {
        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/prescriptions/99999/dispensing-history');

        $response->assertNotFound();
    }

    // ─── AUTH ────────────────────────────────────────────────────────────────

    public function test_requires_auth(): void
    {
        $this->getJson('/api/pharmacy/prescriptions')->assertUnauthorized();
    }
}
