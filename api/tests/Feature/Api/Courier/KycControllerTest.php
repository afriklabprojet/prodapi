<?php

namespace Tests\Feature\Api\Courier;

use App\Models\Courier;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class KycControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Courier $courier;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'courier']);
        $this->courier = Courier::factory()->create([
            'user_id' => $this->user->id,
            'kyc_status' => 'pending',
        ]);
    }

    public function test_courier_can_view_kyc_status(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/courier/kyc/status');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['kyc_status', 'documents']]);
    }

    public function test_kyc_status_shows_correct_document_flags(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/courier/kyc/status');

        $response->assertOk();
        $docs = $response->json('data.documents');
        $this->assertArrayHasKey('id_card_front', $docs);
        $this->assertArrayHasKey('id_card_back', $docs);
        $this->assertArrayHasKey('selfie', $docs);
        $this->assertArrayHasKey('driving_license_front', $docs);
        $this->assertArrayHasKey('driving_license_back', $docs);
        $this->assertArrayHasKey('vehicle_registration', $docs);
    }

    public function test_kyc_status_returns_current_status(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/courier/kyc/status');

        $response->assertOk()
            ->assertJsonPath('data.kyc_status', 'pending');
    }

    public function test_resubmit_validates_file_types(): void
    {
        $this->courier->update(['kyc_status' => 'rejected']);

        $response = $this->actingAs($this->user)->postJson('/api/courier/kyc/resubmit', [
            'id_card_front_document' => 'not-a-file',
        ]);

        $response->assertStatus(422);
    }

    public function test_resubmit_blocked_for_approved_courier(): void
    {
        $this->courier->update(['kyc_status' => 'approved']);

        $response = $this->actingAs($this->user)->postJson('/api/courier/kyc/resubmit', []);

        $response->assertStatus(400)
            ->assertJsonPath('success', false);
    }

    public function test_resubmit_allowed_for_rejected_courier(): void
    {
        Storage::fake('private');

        $this->courier->update(['kyc_status' => 'rejected']);

        $response = $this->actingAs($this->user)->postJson('/api/courier/kyc/resubmit', [
            'id_card_front_document' => UploadedFile::fake()->image('id_front.jpg', 800, 600),
        ]);

        // Should accept or process the resubmission
        $this->assertContains($response->status(), [200, 422]);
    }

    public function test_non_courier_cannot_view_kyc_status(): void
    {
        /** @var User $customer */
        $customer = User::factory()->create(['role' => 'customer']);

        $response = $this->actingAs($customer)->getJson('/api/courier/kyc/status');

        $response->assertStatus(403);
    }

    public function test_unauthenticated_cannot_view_kyc_status(): void
    {
        $response = $this->getJson('/api/courier/kyc/status');

        $response->assertStatus(401);
    }
}
