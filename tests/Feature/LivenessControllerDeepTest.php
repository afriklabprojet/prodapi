<?php

namespace Tests\Feature;

use App\Http\Controllers\Api\LivenessController;
use App\Models\User;
use App\Services\KycValidationService;
use App\Services\LivenessService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Mockery\MockInterface;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class LivenessControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create([
            'role' => 'courier',
            'phone_verified_at' => now(),
            'must_change_password' => false,
        ]);
    }

    private function mockLiveness(): LivenessService|MockInterface
    {
        return $this->mock(LivenessService::class);
    }

    private function mockKyc(): KycValidationService|MockInterface
    {
        return $this->mock(KycValidationService::class);
    }

    private function validUuid(): string
    {
        return '550e8400-e29b-41d4-a716-446655440000';
    }

    // ──────────────────────────────────────────────────────────────
    // START
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function start_creates_session_successfully()
    {
        $mock = $this->mockLiveness();
        $mock->shouldReceive('startSession')->once()->andReturn([
            'session_id' => $this->validUuid(),
            'challenges' => [['type' => 'blink'], ['type' => 'smile']],
            'current_challenge' => ['type' => 'blink'],
            'total_challenges' => 2,
            'expires_in' => 300,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/liveness/start');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => ['session_id', 'challenges', 'current_challenge', 'total_challenges', 'expires_in'],
                'instructions' => ['fr', 'en'],
            ]);
    }

    #[Test]
    public function start_returns_503_when_service_unavailable()
    {
        $mock = $this->mockLiveness();
        $mock->shouldReceive('startSession')->once()
            ->andThrow(new \RuntimeException('Vision API unavailable'));

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/liveness/start');

        $response->assertStatus(503)
            ->assertJsonPath('fallback', true)
            ->assertJsonPath('error', 'service_unavailable');
    }

    #[Test]
    public function start_returns_500_on_unexpected_error()
    {
        $mock = $this->mockLiveness();
        $mock->shouldReceive('startSession')->once()
            ->andThrow(new \Exception('Unexpected error'));

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/liveness/start');

        $response->assertStatus(500)
            ->assertJsonPath('success', false);
    }

    #[Test]
    public function start_requires_authentication()
    {
        $response = $this->postJson('/api/liveness/start');

        $response->assertUnauthorized();
    }

    // ──────────────────────────────────────────────────────────────
    // VALIDATE
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function validate_succeeds_with_base64_image()
    {
        $mock = $this->mockLiveness();
        $mock->shouldReceive('validateChallenge')->once()->andReturn([
            'success' => true,
            'completed' => false,
            'next_challenge' => ['type' => 'smile'],
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/liveness/validate', [
                'session_id' => $this->validUuid(),
                'image' => base64_encode('fake-image-data'),
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    #[Test]
    public function validate_returns_400_on_failure()
    {
        $mock = $this->mockLiveness();
        $mock->shouldReceive('validateChallenge')->once()->andReturn([
            'success' => false,
            'message' => 'Face not detected',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/liveness/validate', [
                'session_id' => $this->validUuid(),
                'image' => base64_encode('fake-image-data'),
            ]);

        $response->assertStatus(400)
            ->assertJsonPath('success', false);
    }

    #[Test]
    public function validate_returns_410_on_expired_session()
    {
        $mock = $this->mockLiveness();
        $mock->shouldReceive('validateChallenge')->once()->andReturn([
            'success' => false,
            'error' => 'session_expired',
            'message' => 'Session expirée',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/liveness/validate', [
                'session_id' => $this->validUuid(),
                'image' => base64_encode('fake-image-data'),
            ]);

        $response->assertStatus(410);
    }

    #[Test]
    public function validate_requires_session_id()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/liveness/validate', [
                'image' => base64_encode('data'),
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['session_id']);
    }

    #[Test]
    public function validate_requires_image()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/liveness/validate', [
                'session_id' => $this->validUuid(),
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['image']);
    }

    #[Test]
    public function validate_requires_uuid_format_session_id()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/liveness/validate', [
                'session_id' => 'not-a-uuid',
                'image' => base64_encode('data'),
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['session_id']);
    }

    #[Test]
    public function validate_returns_500_on_exception()
    {
        $mock = $this->mockLiveness();
        $mock->shouldReceive('validateChallenge')->once()
            ->andThrow(new \Exception('Internal error'));

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/liveness/validate', [
                'session_id' => $this->validUuid(),
                'image' => base64_encode('data'),
            ]);

        $response->assertStatus(500)
            ->assertJsonPath('retry', true);
    }

    // ──────────────────────────────────────────────────────────────
    // VALIDATE WITH FILE
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function validate_with_file_succeeds()
    {
        $mock = $this->mockLiveness();
        $mock->shouldReceive('validateChallenge')->once()->andReturn([
            'success' => true,
            'completed' => true,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/liveness/validate/file', [
                'session_id' => $this->validUuid(),
                'image' => UploadedFile::fake()->image('selfie.jpg', 640, 480),
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    #[Test]
    public function validate_with_file_rejects_non_image()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/liveness/validate/file', [
                'session_id' => $this->validUuid(),
                'image' => UploadedFile::fake()->create('document.pdf', 100),
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['image']);
    }

    #[Test]
    public function validate_with_file_rejects_oversized_image()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/liveness/validate/file', [
                'session_id' => $this->validUuid(),
                'image' => UploadedFile::fake()->image('huge.jpg')->size(11000), // >10MB
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['image']);
    }

    #[Test]
    public function validate_with_file_returns_410_on_expired()
    {
        $mock = $this->mockLiveness();
        $mock->shouldReceive('validateChallenge')->once()->andReturn([
            'success' => false,
            'error' => 'session_expired',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/liveness/validate/file', [
                'session_id' => $this->validUuid(),
                'image' => UploadedFile::fake()->image('selfie.jpg'),
            ]);

        $response->assertStatus(410);
    }

    // ──────────────────────────────────────────────────────────────
    // STATUS
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function status_returns_session_status()
    {
        $mock = $this->mockLiveness();
        $mock->shouldReceive('isSessionValid')->once()->andReturn([
            'valid' => true,
            'is_complete' => false,
            'completed_challenges' => 1,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/liveness/status/{$this->validUuid()}");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['valid', 'is_complete', 'completed_challenges']]);
    }

    #[Test]
    public function status_rejects_invalid_uuid()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/liveness/status/not-a-uuid');

        $response->assertStatus(400)
            ->assertJsonPath('success', false);
    }

    // ──────────────────────────────────────────────────────────────
    // CANCEL
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function cancel_invalidates_session()
    {
        $mock = $this->mockLiveness();
        $mock->shouldReceive('invalidateSession')->once()->with($this->validUuid());

        $response = $this->actingAs($this->user, 'sanctum')
            ->deleteJson("/api/liveness/cancel/{$this->validUuid()}");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Session annulée');
    }

    #[Test]
    public function cancel_rejects_invalid_uuid()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->deleteJson('/api/liveness/cancel/invalid');

        $response->assertStatus(400);
    }

    // ──────────────────────────────────────────────────────────────
    // DIAGNOSTICS
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function diagnostics_works_in_local_environment()
    {
        // Set a diagnostic secret and pass it as header (env is 'testing' not 'local')
        config(['services.google_vision.diagnostic_secret' => 'test-secret']);

        $livenessMock = $this->mockLiveness();
        $livenessMock->shouldReceive('getDiagnostics')->once()->andReturn(['status' => 'ok']);

        $kycMock = $this->mockKyc();
        $kycMock->shouldReceive('getDiagnostics')->once()->andReturn(['status' => 'ok']);

        $response = $this->actingAs($this->user, 'sanctum')
            ->withHeader('X-Diagnostic-Secret', 'test-secret')
            ->getJson('/api/liveness/diagnostics');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['liveness_service', 'kyc_service', 'server']);
    }
}
