<?php

namespace Tests\Unit\Http\Controllers\Admin;

use App\Http\Controllers\Admin\PrivateDocumentController;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class PrivateDocumentControllerTest extends TestCase
{
    use RefreshDatabase;

    // ═══════════════════════════════════════════════════════════════
    //  Authentication / Authorization
    // ═══════════════════════════════════════════════════════════════

    public function test_unauthenticated_user_is_redirected(): void
    {
        $response = $this->get('/admin/documents/view/test/file.jpg');

        // web guard redirects guests to login
        $response->assertRedirect();
    }

    public function test_non_admin_user_gets_403(): void
    {
        /** @var User $user */
        $user = User::factory()->create(['role' => 'customer']);

        $response = $this->actingAs($user)
            ->get('/admin/documents/view/test/file.jpg');

        $response->assertForbidden();
    }

    public function test_admin_can_access_document(): void
    {
        Storage::fake('private');
        Storage::disk('private')->put('kyc/document.jpg', 'fake-image-content');

        /** @var User $admin */
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin)
            ->get('/admin/documents/view/kyc/document.jpg');

        $response->assertOk();
    }

    public function test_pharmacy_user_cannot_access_document(): void
    {
        /** @var User $user */
        $user = User::factory()->create(['role' => 'pharmacy']);

        $response = $this->actingAs($user)
            ->get('/admin/documents/view/kyc/document.jpg');

        $response->assertForbidden();
    }

    // ═══════════════════════════════════════════════════════════════
    //  Path Traversal Prevention
    // ═══════════════════════════════════════════════════════════════

    public function test_path_traversal_blocked_with_double_dots(): void
    {
        /** @var User $admin */
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin)
            ->get('/admin/documents/view/../../etc/passwd');

        // After sanitization of "..", the path becomes "etc/passwd" which doesn't exist
        $this->assertTrue(in_array($response->getStatusCode(), [400, 404]));
    }

    public function test_invalid_path_characters_blocked(): void
    {
        /** @var User $admin */
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin)
            ->get('/admin/documents/view/file%3Cwith%3Etags.jpg');

        // Special chars in filename should fail regex validation
        $response->assertStatus(400);
    }

    // ═══════════════════════════════════════════════════════════════
    //  File Not Found
    // ═══════════════════════════════════════════════════════════════

    public function test_nonexistent_file_returns_404(): void
    {
        Storage::fake('private');

        /** @var User $admin */
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin)
            ->get('/admin/documents/view/nonexistent/file.jpg');

        $response->assertNotFound();
    }

    // ═══════════════════════════════════════════════════════════════
    //  Download endpoint
    // ═══════════════════════════════════════════════════════════════

    public function test_download_works_for_admin(): void
    {
        Storage::fake('private');
        Storage::disk('private')->put('reports/report.pdf', 'pdf-content');

        /** @var User $admin */
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin)
            ->get('/admin/documents/download/reports/report.pdf');

        $response->assertOk();
    }

    public function test_download_non_admin_gets_403(): void
    {
        /** @var User $user */
        $user = User::factory()->create(['role' => 'pharmacy']);

        $response = $this->actingAs($user)
            ->get('/admin/documents/download/reports/report.pdf');

        $response->assertForbidden();
    }

    public function test_download_nonexistent_file_returns_404(): void
    {
        Storage::fake('private');

        /** @var User $admin */
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin)
            ->get('/admin/documents/download/missing/file.pdf');

        $response->assertNotFound();
    }

    // ═══════════════════════════════════════════════════════════════
    //  Valid paths
    // ═══════════════════════════════════════════════════════════════

    public function test_valid_path_with_subdirectories(): void
    {
        Storage::fake('private');
        Storage::disk('private')->put('couriers/123/kyc/id_front.jpg', 'image-data');

        /** @var User $admin */
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin)
            ->get('/admin/documents/view/couriers/123/kyc/id_front.jpg');

        $response->assertOk();
    }

    public function test_path_with_hyphens_and_underscores(): void
    {
        Storage::fake('private');
        Storage::disk('private')->put('docs/my-file_v2.pdf', 'pdf-data');

        /** @var User $admin */
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin)
            ->get('/admin/documents/view/docs/my-file_v2.pdf');

        $response->assertOk();
    }
}
