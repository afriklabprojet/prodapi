<?php

namespace Tests\Feature\Api;

use App\Models\Customer;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SecureDocumentControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $this->user->id]);
    }

    public function test_rejects_invalid_document_type(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/documents/invalid_type/test.pdf');

        $response->assertStatus(404)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Type de document invalide');
    }

    public function test_rejects_path_traversal_attempt(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/documents/kyc/..%2F..%2Fetc%2Fpasswd');

        // Path traversal characters stripped, then regex check or file not found
        $this->assertContains($response->status(), [400, 404]);
    }

    public function test_returns_404_for_nonexistent_file(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/documents/kyc/nonexistent-file.pdf');

        $response->assertStatus(404)
            ->assertJsonPath('success', false);
    }

    public function test_temporary_url_rejects_invalid_type(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/documents/invalid_type/test.pdf/url');

        $response->assertStatus(404)
            ->assertJsonPath('success', false);
    }

    public function test_temporary_url_returns_404_for_nonexistent_file(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/documents/kyc/nonexistent.pdf/url');

        $response->assertStatus(404)
            ->assertJsonPath('success', false);
    }

    public function test_unauthenticated_cannot_access_documents(): void
    {
        $response = $this->getJson('/api/documents/kyc/test.pdf');

        $response->assertStatus(401);
    }

    public function test_allowed_types_are_accessible(): void
    {
        // kyc, prescriptions, delivery-proofs, support-attachments are valid types
        $response = $this->actingAs($this->user)->getJson('/api/documents/prescriptions/test.pdf');

        // Should be 404 (file not found), NOT 403 (type invalid)
        $response->assertStatus(404)
            ->assertJsonPath('message', 'Document introuvable');
    }
}
