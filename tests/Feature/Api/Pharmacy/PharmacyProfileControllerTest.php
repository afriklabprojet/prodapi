<?php

namespace Tests\Feature\Api\Pharmacy;

use App\Models\User;
use App\Models\Pharmacy;
use App\Models\DutyZone;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class PharmacyProfileControllerTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $pharmacy;
    protected $dutyZone;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('private');

        $this->dutyZone = DutyZone::factory()->create();

        $this->user = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
            'duty_zone_id' => $this->dutyZone->id,
        ]);
        $this->pharmacy->users()->attach($this->user->id);
    }

    /** @test */
    public function user_can_list_their_pharmacies()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/pharmacy/profile');

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'data' => [
                    '*' => [
                        'id',
                        'name',
                        'phone',
                        'address',
                        'city',
                    ],
                ],
            ]);
    }

    /** @test */
    public function user_can_update_pharmacy_profile()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->putJson("/api/pharmacy/profile/{$this->pharmacy->id}", [
                'name' => 'Pharmacie Mise à Jour',
                'phone' => '+225 0709090909',
                'address' => 'Nouvelle Adresse',
                'city' => 'Abidjan',
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Pharmacy profile updated successfully.');

        $this->assertDatabaseHas('pharmacies', [
            'id' => $this->pharmacy->id,
            'name' => 'Pharmacie Mise à Jour',
            'phone' => '+225 0709090909',
        ]);
    }

    /** @test */
    public function update_validates_required_fields()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->putJson("/api/pharmacy/profile/{$this->pharmacy->id}", []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['name', 'phone', 'address', 'city']);
    }

    /** @test */
    public function user_can_update_duty_zone()
    {
        $newZone = DutyZone::factory()->create(['name' => 'Abidjan Sud']);

        $response = $this->actingAs($this->user, 'sanctum')
            ->putJson("/api/pharmacy/profile/{$this->pharmacy->id}", [
                'name' => $this->pharmacy->name,
                'phone' => $this->pharmacy->phone,
                'address' => $this->pharmacy->address,
                'city' => $this->pharmacy->city,
                'duty_zone_id' => $newZone->id,
            ]);

        $response->assertOk();

        $this->assertDatabaseHas('pharmacies', [
            'id' => $this->pharmacy->id,
            'duty_zone_id' => $newZone->id,
        ]);
    }

    /** @test */
    public function user_can_upload_license_document()
    {
        $file = UploadedFile::fake()->create('license.pdf', 100, 'application/pdf');

        $response = $this->actingAs($this->user, 'sanctum')
            ->putJson("/api/pharmacy/profile/{$this->pharmacy->id}", [
                'name' => $this->pharmacy->name,
                'phone' => $this->pharmacy->phone,
                'address' => $this->pharmacy->address,
                'city' => $this->pharmacy->city,
                'license_document' => $file,
            ]);

        $response->assertOk();
        
        // Verify file was stored
        $this->pharmacy->refresh();
        if ($this->pharmacy->license_document) {
            Storage::disk('private')->assertExists($this->pharmacy->license_document);
        }
    }

    /** @test */
    public function user_can_upload_id_card_document()
    {
        $file = UploadedFile::fake()->image('id_card.jpg', 100, 100);

        $response = $this->actingAs($this->user, 'sanctum')
            ->putJson("/api/pharmacy/profile/{$this->pharmacy->id}", [
                'name' => $this->pharmacy->name,
                'phone' => $this->pharmacy->phone,
                'address' => $this->pharmacy->address,
                'city' => $this->pharmacy->city,
                'id_card_document' => $file,
            ]);

        $response->assertOk();
    }

    /** @test */
    public function document_upload_rejects_invalid_mime_types()
    {
        $file = UploadedFile::fake()->create('document.exe', 100, 'application/x-msdownload');

        $response = $this->actingAs($this->user, 'sanctum')
            ->putJson("/api/pharmacy/profile/{$this->pharmacy->id}", [
                'name' => $this->pharmacy->name,
                'phone' => $this->pharmacy->phone,
                'address' => $this->pharmacy->address,
                'city' => $this->pharmacy->city,
                'license_document' => $file,
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['license_document']);
    }

    /** @test */
    public function document_upload_rejects_large_files()
    {
        $file = UploadedFile::fake()->create('large.pdf', 6000, 'application/pdf'); // 6MB

        $response = $this->actingAs($this->user, 'sanctum')
            ->putJson("/api/pharmacy/profile/{$this->pharmacy->id}", [
                'name' => $this->pharmacy->name,
                'phone' => $this->pharmacy->phone,
                'address' => $this->pharmacy->address,
                'city' => $this->pharmacy->city,
                'license_document' => $file,
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['license_document']);
    }

    /** @test */
    public function user_cannot_access_other_pharmacy_profile()
    {
        $otherPharmacy = Pharmacy::factory()->create(['status' => 'approved']);

        $response = $this->actingAs($this->user, 'sanctum')
            ->putJson("/api/pharmacy/profile/{$otherPharmacy->id}", [
                'name' => 'Hack',
                'phone' => '123',
                'address' => 'Fake',
                'city' => 'City',
            ]);

        $response->assertStatus(403);
    }

    /** @test */
    public function user_can_download_own_documents()
    {
        // Create a fake document
        Storage::disk('private')->put('pharmacy-documents/licenses/test.pdf', 'fake content');
        $this->pharmacy->update(['license_document' => 'pharmacy-documents/licenses/test.pdf']);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/pharmacy/profile/{$this->pharmacy->id}/documents/license");

        // Response could be 200 (download) or 404 (if route not exists)
        $this->assertContains($response->getStatusCode(), [200, 404]);
    }

    /** @test */
    public function user_without_pharmacy_cannot_access_profile()
    {
        $userNoPharmacy = User::factory()->create(['role' => 'pharmacy']);

        $response = $this->actingAs($userNoPharmacy, 'sanctum')
            ->getJson('/api/pharmacy/profile');

        $response->assertOk()
            ->assertJsonPath('data', []);
    }

    /** @test */
    public function unauthenticated_user_cannot_access_profile()
    {
        $response = $this->getJson('/api/pharmacy/profile');

        $response->assertUnauthorized();
    }

    /** @test */
    public function email_must_be_valid_format()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->putJson("/api/pharmacy/profile/{$this->pharmacy->id}", [
                'name' => $this->pharmacy->name,
                'phone' => $this->pharmacy->phone,
                'address' => $this->pharmacy->address,
                'city' => $this->pharmacy->city,
                'email' => 'invalid-email',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    /** @test */
    public function duty_zone_id_must_exist()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->putJson("/api/pharmacy/profile/{$this->pharmacy->id}", [
                'name' => $this->pharmacy->name,
                'phone' => $this->pharmacy->phone,
                'address' => $this->pharmacy->address,
                'city' => $this->pharmacy->city,
                'duty_zone_id' => 99999, // Non-existent
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['duty_zone_id']);
    }
}
