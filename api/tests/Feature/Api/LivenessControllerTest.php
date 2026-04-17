<?php

namespace Tests\Feature\Api;

use App\Models\Courier;
use App\Models\User;
use App\Services\LivenessService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery;
use Tests\TestCase;

class LivenessControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'courier']);
        Courier::factory()->create(['user_id' => $this->user->id]);
    }

    public function test_authenticated_user_can_start_liveness_session(): void
    {
        $mockService = Mockery::mock(LivenessService::class);
        $mockService->shouldReceive('startSession')
            ->once()
            ->andReturn([
                'session_id' => 'test-uuid',
                'challenge' => 'blink',
                'expires_at' => now()->addMinutes(5)->toIso8601String(),
            ]);
        $this->app->instance(LivenessService::class, $mockService);

        $response = $this->actingAs($this->user)->postJson('/api/liveness/start');

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_validate_requires_session_id_and_image(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/liveness/validate', []);

        $response->assertStatus(422);
    }

    public function test_validate_requires_uuid_session_id(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/liveness/validate', [
            'session_id' => 'not-a-uuid',
            'image' => 'base64data',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('session_id');
    }

    public function test_status_requires_valid_uuid(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/liveness/status/not-a-uuid');

        $response->assertStatus(400);
    }

    public function test_cancel_requires_valid_uuid(): void
    {
        $response = $this->actingAs($this->user)->deleteJson('/api/liveness/cancel/not-a-uuid');

        $response->assertStatus(400);
    }

    public function test_unauthenticated_cannot_start_session(): void
    {
        $response = $this->postJson('/api/liveness/start');

        $response->assertStatus(401);
    }
}
