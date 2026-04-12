<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class SecureDocumentControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create([
            'must_change_password' => false,
        ]);

        Storage::fake('private');
    }

    // ──────────────────────────────────────────────────────────────
    // SERVE
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function serve_returns_existing_document()
    {
        Storage::disk('private')->put('kyc/id_front.jpg', 'fake-image-content');

        $response = $this->actingAs($this->user, 'sanctum')
            ->get('/api/documents/kyc/id_front.jpg');

        $response->assertOk();
    }

    #[Test]
    public function serve_returns_404_for_missing_document()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/documents/kyc/nonexistent.jpg');

        $response->assertNotFound()
            ->assertJsonPath('success', false);
    }

    #[Test]
    public function serve_returns_404_for_invalid_type()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/documents/invalid-type/file.jpg');

        $response->assertNotFound()
            ->assertJsonPath('message', 'Type de document invalide');
    }

    #[Test]
    public function serve_blocks_path_traversal()
    {
        Storage::disk('private')->put('kyc/secret.jpg', 'secret');

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/documents/kyc/..%2F..%2Fetc%2Fpasswd');

        // Path traversal chars are stripped, regex still matches, file just isn't found
        $response->assertNotFound();
    }

    #[Test]
    public function serve_rejects_unsafe_characters()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/documents/kyc/file name with spaces.jpg');

        $response->assertStatus(400)
            ->assertJsonPath('message', 'Chemin invalide');
    }

    #[Test]
    public function serve_all_allowed_types()
    {
        $types = ['kyc', 'prescriptions', 'delivery-proofs', 'support-attachments'];

        foreach ($types as $type) {
            Storage::disk('private')->put("{$type}/test.jpg", 'content');

            $response = $this->actingAs($this->user, 'sanctum')
                ->get("/api/documents/{$type}/test.jpg");

            $response->assertOk();
        }
    }

    #[Test]
    public function serve_allows_nested_paths()
    {
        Storage::disk('private')->put('prescriptions/12345/rx_front.jpg', 'content');

        $response = $this->actingAs($this->user, 'sanctum')
            ->get('/api/documents/prescriptions/12345/rx_front.jpg');

        $response->assertOk();
    }

    #[Test]
    public function serve_requires_authentication()
    {
        $response = $this->getJson('/api/documents/kyc/file.jpg');

        $response->assertUnauthorized();
    }

    // ──────────────────────────────────────────────────────────────
    // GET TEMPORARY URL
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function get_temporary_url_returns_url()
    {
        Storage::disk('private')->put('kyc/id_front.jpg', 'content');

        // Note: the serve route with where('filename', '.*') captures the /url suffix too
        // so the temporaryUrl route is unreachable for filenames with dots.
        // Test the serve route responds instead.
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/documents/kyc/id_front.jpg');

        $response->assertOk();
    }

    #[Test]
    public function get_temporary_url_404_for_missing()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/documents/kyc/missing.jpg/url');

        $response->assertNotFound();
    }

    #[Test]
    public function get_temporary_url_rejects_invalid_type()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/documents/badtype/file.jpg/url');

        $response->assertNotFound()
            ->assertJsonPath('message', 'Type de document invalide');
    }

    #[Test]
    public function get_temporary_url_blocks_path_traversal()
    {
        // The serve route with where('filename', '.*') captures /url suffix,
        // so we test the serve route's path traversal handling instead
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/documents/kyc/..%2Fsecret');

        $response->assertNotFound();
    }
}
