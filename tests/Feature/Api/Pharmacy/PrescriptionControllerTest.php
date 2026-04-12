<?php

namespace Tests\Feature\Api\Pharmacy;

use App\Models\User;
use App\Models\Pharmacy;
use App\Models\Prescription;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class PrescriptionControllerTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $pharmacy;
    protected $customerUser;
    protected $prescription;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
        ]);
        $this->pharmacy->users()->attach($this->user->id);

        $this->customerUser = User::factory()->create(['role' => 'customer']);
        $this->prescription = Prescription::factory()->create([
            'customer_id' => $this->customerUser->id,
            'status' => 'pending',
        ]);
    }

    #[Test]
    public function pharmacy_can_list_prescriptions()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/pharmacy/prescriptions');

        $response->assertOk()
            ->assertJsonStructure([
                'status',
                'data' => [
                    '*' => [
                        'id',
                        'status',
                        'customer',
                    ],
                ],
            ]);
    }

    #[Test]
    public function pharmacy_can_view_prescription_details()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/pharmacy/prescriptions/{$this->prescription->id}");

        $response->assertOk()
            ->assertJsonStructure([
                'status',
                'data' => [
                    'id',
                    'status',
                    'customer',
                ],
            ]);
    }

    #[Test]
    public function returns_404_for_non_existent_prescription()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/pharmacy/prescriptions/999999');

        $response->assertNotFound()
            ->assertJsonPath('status', 'error')
            ->assertJsonPath('message', 'Prescription not found');
    }

    #[Test]
    public function pharmacy_can_validate_prescription()
    {
        Notification::fake();

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/pharmacy/prescriptions/{$this->prescription->id}/status", [
                'status' => 'validated',
                'admin_notes' => 'Prescription approuvée',
            ]);

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('message', 'Prescription status updated successfully');

        $this->assertDatabaseHas('prescriptions', [
            'id' => $this->prescription->id,
            'status' => 'validated',
        ]);
    }

    #[Test]
    public function pharmacy_can_reject_prescription()
    {
        Notification::fake();

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/pharmacy/prescriptions/{$this->prescription->id}/status", [
                'status' => 'rejected',
                'admin_notes' => 'Ordonnance illisible',
            ]);

        $response->assertOk()
            ->assertJsonPath('status', 'success');

        $this->assertDatabaseHas('prescriptions', [
            'id' => $this->prescription->id,
            'status' => 'rejected',
        ]);
    }

    #[Test]
    public function pharmacy_can_quote_prescription()
    {
        Notification::fake();

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/pharmacy/prescriptions/{$this->prescription->id}/status", [
                'status' => 'quoted',
                'quote_amount' => 15000,
                'pharmacy_notes' => 'Tous les produits sont disponibles',
            ]);

        $response->assertOk()
            ->assertJsonPath('status', 'success');

        $this->assertDatabaseHas('prescriptions', [
            'id' => $this->prescription->id,
            'status' => 'quoted',
            'quote_amount' => 15000,
        ]);
    }

    #[Test]
    public function status_update_validates_required_fields()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/pharmacy/prescriptions/{$this->prescription->id}/status", []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['status']);
    }

    #[Test]
    public function status_update_validates_status_values()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/pharmacy/prescriptions/{$this->prescription->id}/status", [
                'status' => 'invalid_status',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['status']);
    }

    #[Test]
    public function status_update_validates_quote_amount()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/pharmacy/prescriptions/{$this->prescription->id}/status", [
                'status' => 'quoted',
                'quote_amount' => -100, // Negative amount
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['quote_amount']);
    }

    #[Test]
    public function validation_sets_validated_at_timestamp()
    {
        Notification::fake();

        $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/pharmacy/prescriptions/{$this->prescription->id}/status", [
                'status' => 'validated',
            ]);

        $this->prescription->refresh();
        $this->assertNotNull($this->prescription->validated_at);
    }

    #[Test]
    public function validation_sets_validated_by_user()
    {
        Notification::fake();

        $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/pharmacy/prescriptions/{$this->prescription->id}/status", [
                'status' => 'validated',
            ]);

        $this->prescription->refresh();
        $this->assertEquals($this->user->id, $this->prescription->validated_by);
    }

    #[Test]
    public function customer_is_notified_on_status_change()
    {
        Notification::fake();

        $this->actingAs($this->user, 'sanctum')
            ->postJson("/api/pharmacy/prescriptions/{$this->prescription->id}/status", [
                'status' => 'validated',
            ]);

        Notification::assertSentTo(
            $this->customerUser,
            \App\Notifications\PrescriptionStatusNotification::class
        );
    }

    #[Test]
    public function unauthenticated_user_cannot_access_prescriptions()
    {
        $response = $this->getJson('/api/pharmacy/prescriptions');

        $response->assertUnauthorized();
    }
}
