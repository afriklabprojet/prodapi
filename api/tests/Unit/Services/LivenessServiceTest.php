<?php

namespace Tests\Unit\Services;

use App\Services\LivenessService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class LivenessServiceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        // Ensure Vision API is disabled for unit tests (set in phpunit.xml as GOOGLE_VISION_ENABLED=false)
        config(['services.google_vision.enabled' => false]);
    }

    public function test_service_instantiates_when_disabled(): void
    {
        Log::shouldReceive('warning')->once()->withArgs(function ($msg) {
            return str_contains($msg, 'LivenessService') && str_contains($msg, 'DISABLED');
        });

        $service = new LivenessService();

        $this->assertInstanceOf(LivenessService::class, $service);
    }

    public function test_is_enabled_returns_false_when_disabled(): void
    {
        Log::shouldReceive('warning')->once();

        $service = new LivenessService();

        $this->assertFalse($service->isEnabled());
    }

    public function test_challenge_constants_are_defined(): void
    {
        $this->assertSame('blink', LivenessService::CHALLENGE_BLINK);
        $this->assertSame('turn_left', LivenessService::CHALLENGE_TURN_LEFT);
        $this->assertSame('turn_right', LivenessService::CHALLENGE_TURN_RIGHT);
        $this->assertSame('smile', LivenessService::CHALLENGE_SMILE);
    }

    public function test_session_ttl_constant_is_300_seconds(): void
    {
        $reflection = new \ReflectionClass(LivenessService::class);
        $constants = $reflection->getConstants();

        $this->assertArrayHasKey('SESSION_TTL', $constants);
        $this->assertSame(300, $constants['SESSION_TTL']);
    }

    public function test_blink_detection_threshold_constant(): void
    {
        $reflection = new \ReflectionClass(LivenessService::class);
        $constants = $reflection->getConstants();

        $this->assertArrayHasKey('BLINK_DETECTION_THRESHOLD', $constants);
        $this->assertIsFloat($constants['BLINK_DETECTION_THRESHOLD']);
    }

    public function test_smile_likelihood_threshold_constant(): void
    {
        $reflection = new \ReflectionClass(LivenessService::class);
        $constants = $reflection->getConstants();

        $this->assertArrayHasKey('SMILE_LIKELIHOOD_THRESHOLD', $constants);
        $this->assertIsInt($constants['SMILE_LIKELIHOOD_THRESHOLD']);
    }

    public function test_head_turn_angle_threshold_constant(): void
    {
        $reflection = new \ReflectionClass(LivenessService::class);
        $constants = $reflection->getConstants();

        $this->assertArrayHasKey('HEAD_TURN_ANGLE_THRESHOLD', $constants);
        $this->assertIsInt($constants['HEAD_TURN_ANGLE_THRESHOLD']);
    }

    public function test_start_session_throws_when_disabled(): void
    {
        Log::shouldReceive('warning')->twice(); // constructor + startSession

        $service = new LivenessService();

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessageMatches('/indisponible|unavailable/i');

        $service->startSession('user_42');
    }

    public function test_get_diagnostics_returns_array(): void
    {
        Log::shouldReceive('warning')->once();

        $service = new LivenessService();

        $diagnostics = $service->getDiagnostics();

        $this->assertIsArray($diagnostics);
        $this->assertArrayHasKey('enabled_config', $diagnostics);
        $this->assertArrayHasKey('enabled_runtime', $diagnostics);
        $this->assertArrayHasKey('client_initialized', $diagnostics);
        $this->assertArrayHasKey('credentials_path', $diagnostics);
        $this->assertArrayHasKey('credentials_exists', $diagnostics);
        $this->assertArrayHasKey('grpc_extension', $diagnostics);
        $this->assertArrayHasKey('transport', $diagnostics);
        $this->assertArrayHasKey('php_version', $diagnostics);
    }

    public function test_get_diagnostics_reports_disabled_state(): void
    {
        Log::shouldReceive('warning')->once();

        $service = new LivenessService();

        $diagnostics = $service->getDiagnostics();

        $this->assertFalse($diagnostics['enabled_config']);
        $this->assertFalse($diagnostics['enabled_runtime']);
        $this->assertFalse($diagnostics['client_initialized']);
    }

    public function test_get_diagnostics_returns_rest_transport(): void
    {
        Log::shouldReceive('warning')->once();

        $service = new LivenessService();

        $diagnostics = $service->getDiagnostics();

        $this->assertSame('rest', $diagnostics['transport']);
    }

    public function test_four_distinct_challenge_types_exist(): void
    {
        $challenges = [
            LivenessService::CHALLENGE_BLINK,
            LivenessService::CHALLENGE_TURN_LEFT,
            LivenessService::CHALLENGE_TURN_RIGHT,
            LivenessService::CHALLENGE_SMILE,
        ];

        $this->assertCount(4, array_unique($challenges));
    }
}
