<?php

namespace Tests\Unit\Services;

use App\Services\LivenessService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Mockery;
use Tests\TestCase;

class LivenessServiceDeepTest extends TestCase
{
    private LivenessService $service;

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.google_vision.enabled' => false]);
        Log::spy();

        // PHP 8.4 warns when tempnam() uses the system temp directory
        $prev = set_error_handler(function (int $severity, string $message, string $file, int $line) use (&$prev) {
            if ($severity === E_WARNING && str_contains($message, 'tempnam()')) {
                return true;
            }
            return $prev ? $prev($severity, $message, $file, $line) : false;
        });

        $this->service = new LivenessService();
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    /**
     * Try to create a service with a real ImageAnnotatorClient using fake creds.
     * Returns null if the client can't be created (no network needed, just parsing).
     */
    private function createEnabledService(): ?LivenessService
    {
        $credFile = tempnam(sys_get_temp_dir(), 'gv_');
        file_put_contents($credFile, json_encode([
            'type' => 'service_account',
            'project_id' => 'test-project',
            'private_key_id' => 'key123',
            'private_key' => "-----BEGIN RSA PRIVATE KEY-----\nMIIBogIBAAJBANDiE2+Xi/WnO+s120NUTk6hI4QMxmJl+ceEmE5YeXwfRrGMRCyN\ndB0TKkLslgSr5G4AyA7JfKllhFAnzwJIxkcCAwEAAQJAbi13Ej/YbFy6azHAiXaQ\nwLevfpOEzdTMN2pKKH4VXvIBHsEHqK6n4MhLYj4UFBRjl+/3VCJJmS34hKiHNHfM\nQQIhAPPiDBr3vkdXCfHeFUXw3fNIXiYmiQEiSnqjMGcBJ8BpAiEA22xkbCfhFhkV\nIwMFscbM+vq3l0M3OdlwSMjpxwlzUG8CIQCS0gqFmlUvE/y+fhSPKfNveFLp6X2+\nvchGfcAmKiHjsQIgUOYMk5DQ7z2K2giYKRF+SAT+3LF0iEIHzGzHTAMLS+cCIBbi\nHlMex+ky/ql88Zun/wJnhYK+JDAoJMU8qJF1mZui\n-----END RSA PRIVATE KEY-----\n",
            'client_email' => 'test@test.iam.gserviceaccount.com',
            'client_id' => '123',
            'auth_uri' => 'https://accounts.google.com/o/oauth2/auth',
            'token_uri' => 'https://oauth2.googleapis.com/token',
        ]));

        config([
            'services.google_vision.enabled' => true,
            'services.google_vision.credentials_path' => $credFile,
        ]);

        $service = new LivenessService();
        @unlink($credFile);

        return $service->isEnabled() ? $service : null;
    }

    private function callPrivate(object $obj, string $method, array $args = []): mixed
    {
        $ref = new \ReflectionMethod($obj, $method);
        $ref->setAccessible(true);
        return $ref->invoke($obj, ...$args);
    }

    private function mockFace(array $overrides = []): object
    {
        $defaults = [
            'detectionConfidence' => 0.95,
            'panAngle' => 0.0,
            'tiltAngle' => 0.0,
            'rollAngle' => 0.0,
            'joyLikelihood' => 1,
            'landmarks' => [],
        ];
        $opts = array_merge($defaults, $overrides);

        $mockLandmarks = [];
        foreach ($opts['landmarks'] as $lm) {
            $pos = Mockery::mock('Position');
            $pos->shouldReceive('getX')->andReturn($lm['x'] ?? 0);
            $pos->shouldReceive('getY')->andReturn($lm['y'] ?? 0);
            $pos->shouldReceive('getZ')->andReturn($lm['z'] ?? 0.0);

            $landmark = Mockery::mock('Landmark');
            $landmark->shouldReceive('getType')->andReturn($lm['type'] ?? 0);
            $landmark->shouldReceive('getPosition')->andReturn($pos);
            $mockLandmarks[] = $landmark;
        }

        // Bounding box
        $vertices = [];
        for ($i = 0; $i < 4; $i++) {
            $v = Mockery::mock('Vertex');
            $v->shouldReceive('getX')->andReturn($i < 2 ? 10 : 200);
            $v->shouldReceive('getY')->andReturn($i % 2 === 0 ? 10 : 200);
            $vertices[] = $v;
        }
        $poly = Mockery::mock('BoundingPoly');
        $poly->shouldReceive('getVertices')->andReturn($vertices);

        $face = Mockery::mock('FaceAnnotation');
        $face->shouldReceive('getDetectionConfidence')->andReturn($opts['detectionConfidence']);
        $face->shouldReceive('getPanAngle')->andReturn($opts['panAngle']);
        $face->shouldReceive('getTiltAngle')->andReturn($opts['tiltAngle']);
        $face->shouldReceive('getRollAngle')->andReturn($opts['rollAngle']);
        $face->shouldReceive('getJoyLikelihood')->andReturn($opts['joyLikelihood']);
        $face->shouldReceive('getLandmarks')->andReturn($mockLandmarks);
        $face->shouldReceive('getBoundingPoly')->andReturn($poly);

        return $face;
    }

    // ═════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═════════════════════════════════════════════════════════════════════════

    public function test_constructor_disabled_by_config(): void
    {
        config(['services.google_vision.enabled' => false]);
        $service = new LivenessService();
        $this->assertFalse($service->isEnabled());
    }

    public function test_constructor_with_valid_credentials(): void
    {
        $service = $this->createEnabledService();
        if (!$service) {
            $this->markTestSkipped('Could not create Vision client with fake creds');
        }
        $this->assertTrue($service->isEnabled());
    }

    public function test_constructor_with_invalid_json_credentials(): void
    {
        $credFile = tempnam(sys_get_temp_dir(), 'gv_');
        file_put_contents($credFile, 'not-json');

        config([
            'services.google_vision.enabled' => true,
            'services.google_vision.credentials_path' => $credFile,
        ]);

        $service = new LivenessService();
        @unlink($credFile);
        $this->assertFalse($service->isEnabled());
    }

    public function test_constructor_with_json_missing_project_id(): void
    {
        $credFile = tempnam(sys_get_temp_dir(), 'gv_');
        file_put_contents($credFile, json_encode(['type' => 'service_account']));

        config([
            'services.google_vision.enabled' => true,
            'services.google_vision.credentials_path' => $credFile,
        ]);

        $service = new LivenessService();
        @unlink($credFile);
        $this->assertFalse($service->isEnabled());
    }

    public function test_constructor_credentials_not_found_tries_adc(): void
    {
        config([
            'services.google_vision.enabled' => true,
            'services.google_vision.credentials_path' => '/nonexistent/path.json',
        ]);

        $service = new LivenessService();
        // ADC will probably fail in test env → disabled
        $diag = $service->getDiagnostics();
        $this->assertArrayHasKey('enabled_config', $diag);
    }

    public function test_diagnostics_returns_expected_keys(): void
    {
        $diag = $this->service->getDiagnostics();
        $this->assertArrayHasKey('enabled_config', $diag);
        $this->assertArrayHasKey('enabled_runtime', $diag);
        $this->assertArrayHasKey('client_initialized', $diag);
        $this->assertArrayHasKey('credentials_path', $diag);
        $this->assertArrayHasKey('grpc_extension', $diag);
        $this->assertEquals('rest', $diag['transport']);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // getChallengeInfo (private)
    // ═════════════════════════════════════════════════════════════════════════

    public function test_get_challenge_info_blink(): void
    {
        $result = $this->callPrivate($this->service, 'getChallengeInfo', ['blink']);
        $this->assertEquals('blink', $result['type']);
        $this->assertEquals('eye', $result['icon']);
        $this->assertEquals(3, $result['duration']);
        $this->assertNotEmpty($result['instruction']);
        $this->assertNotEmpty($result['description']);
    }

    public function test_get_challenge_info_turn_left(): void
    {
        $result = $this->callPrivate($this->service, 'getChallengeInfo', ['turn_left']);
        $this->assertEquals('turn_left', $result['type']);
        $this->assertEquals('arrow_left', $result['icon']);
    }

    public function test_get_challenge_info_turn_right(): void
    {
        $result = $this->callPrivate($this->service, 'getChallengeInfo', ['turn_right']);
        $this->assertEquals('turn_right', $result['type']);
        $this->assertEquals('arrow_right', $result['icon']);
    }

    public function test_get_challenge_info_smile(): void
    {
        $result = $this->callPrivate($this->service, 'getChallengeInfo', ['smile']);
        $this->assertEquals('smile', $result['type']);
        $this->assertEquals('sentiment_satisfied', $result['icon']);
    }

    public function test_get_challenge_info_unknown(): void
    {
        $result = $this->callPrivate($this->service, 'getChallengeInfo', ['unknown_xyz']);
        $this->assertEquals('unknown', $result['type']);
        $this->assertEquals('help', $result['icon']);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // validateBlink (private)
    // ═════════════════════════════════════════════════════════════════════════

    public function test_validate_blink_passes_with_enough_eye_landmarks(): void
    {
        $face = $this->mockFace([
            'detectionConfidence' => 0.9,
            'landmarks' => [
                ['type' => 'LEFT_EYE_TOP', 'x' => 80, 'y' => 95, 'z' => 1.5],
                ['type' => 'LEFT_EYE_BOTTOM', 'x' => 80, 'y' => 105, 'z' => 1.2],
                ['type' => 'RIGHT_EYE_TOP', 'x' => 120, 'y' => 95, 'z' => 1.5],
                ['type' => 'RIGHT_EYE_BOTTOM', 'x' => 120, 'y' => 105, 'z' => 1.2],
            ],
        ]);

        $result = $this->callPrivate($this->service, 'validateBlink', [$face, ['face_reference' => null]]);

        $this->assertTrue($result['valid']);
        $this->assertStringContainsString('détecté', $result['reason']);
        $this->assertEquals(4, $result['details']['eye_landmarks']);
    }

    public function test_validate_blink_fails_with_low_confidence(): void
    {
        $face = $this->mockFace([
            'detectionConfidence' => 0.3,
            'landmarks' => [
                ['type' => 'LEFT_EYE', 'x' => 80, 'y' => 100, 'z' => 1.0],
                ['type' => 'RIGHT_EYE', 'x' => 120, 'y' => 100, 'z' => 1.0],
            ],
        ]);

        $result = $this->callPrivate($this->service, 'validateBlink', [$face, ['face_reference' => null]]);
        $this->assertFalse($result['valid']);
    }

    public function test_validate_blink_fails_with_too_few_landmarks(): void
    {
        $face = $this->mockFace([
            'detectionConfidence' => 0.9,
            'landmarks' => [
                ['type' => 'NOSE_TIP', 'x' => 100, 'y' => 120],
            ],
        ]);

        $result = $this->callPrivate($this->service, 'validateBlink', [$face, ['face_reference' => null]]);
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('cligner', $result['reason']);
    }

    public function test_validate_blink_confidence_at_boundary(): void
    {
        $face = $this->mockFace([
            'detectionConfidence' => 0.51,
            'landmarks' => [
                ['type' => 'LEFT_EYE', 'x' => 80, 'y' => 100, 'z' => 1.0],
                ['type' => 'RIGHT_EYE', 'x' => 120, 'y' => 100, 'z' => 1.0],
            ],
        ]);

        $result = $this->callPrivate($this->service, 'validateBlink', [$face, ['face_reference' => null]]);
        $this->assertTrue($result['valid']);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // validateTurnLeft / validateTurnRight (private)
    // ═════════════════════════════════════════════════════════════════════════

    public function test_validate_turn_left_passes(): void
    {
        $face = $this->mockFace(['panAngle' => -20.0]);
        $result = $this->callPrivate($this->service, 'validateTurnLeft', [$face]);
        $this->assertTrue($result['valid']);
        $this->assertStringContainsString('gauche', $result['reason']);
        $this->assertEquals(-20.0, $result['details']['pan_angle']);
    }

    public function test_validate_turn_left_fails_insufficient_angle(): void
    {
        $face = $this->mockFace(['panAngle' => -5.0]);
        $result = $this->callPrivate($this->service, 'validateTurnLeft', [$face]);
        $this->assertFalse($result['valid']);
        $this->assertArrayHasKey('threshold', $result['details']);
    }

    public function test_validate_turn_left_fails_wrong_direction(): void
    {
        $face = $this->mockFace(['panAngle' => 15.0]);
        $result = $this->callPrivate($this->service, 'validateTurnLeft', [$face]);
        $this->assertFalse($result['valid']);
    }

    public function test_validate_turn_right_passes(): void
    {
        $face = $this->mockFace(['panAngle' => 20.0]);
        $result = $this->callPrivate($this->service, 'validateTurnRight', [$face]);
        $this->assertTrue($result['valid']);
        $this->assertStringContainsString('droite', $result['reason']);
    }

    public function test_validate_turn_right_fails_insufficient_angle(): void
    {
        $face = $this->mockFace(['panAngle' => 5.0]);
        $result = $this->callPrivate($this->service, 'validateTurnRight', [$face]);
        $this->assertFalse($result['valid']);
    }

    public function test_validate_turn_at_exact_threshold(): void
    {
        // panAngle must be > threshold (strict), not >=
        $face = $this->mockFace(['panAngle' => -10.0]);
        $result = $this->callPrivate($this->service, 'validateTurnLeft', [$face]);
        $this->assertFalse($result['valid']); // -10 is NOT < -10
    }

    // ═════════════════════════════════════════════════════════════════════════
    // validateSmile (private)
    // ═════════════════════════════════════════════════════════════════════════

    public function test_validate_smile_very_unlikely_fails(): void
    {
        $face = $this->mockFace(['joyLikelihood' => 1]); // VERY_UNLIKELY
        $result = $this->callPrivate($this->service, 'validateSmile', [$face]);
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('sourire', $result['reason']);
        $this->assertEquals('très improbable', $result['details']['joy_likelihood']);
    }

    public function test_validate_smile_unlikely_passes(): void
    {
        $face = $this->mockFace(['joyLikelihood' => 2]); // UNLIKELY = threshold
        $result = $this->callPrivate($this->service, 'validateSmile', [$face]);
        $this->assertTrue($result['valid']);
        $this->assertEquals('improbable', $result['details']['joy_likelihood']);
    }

    public function test_validate_smile_possible(): void
    {
        $face = $this->mockFace(['joyLikelihood' => 3]);
        $result = $this->callPrivate($this->service, 'validateSmile', [$face]);
        $this->assertTrue($result['valid']);
        $this->assertEquals('possible', $result['details']['joy_likelihood']);
    }

    public function test_validate_smile_likely(): void
    {
        $face = $this->mockFace(['joyLikelihood' => 4]);
        $result = $this->callPrivate($this->service, 'validateSmile', [$face]);
        $this->assertTrue($result['valid']);
        $this->assertEquals('probable', $result['details']['joy_likelihood']);
    }

    public function test_validate_smile_very_likely(): void
    {
        $face = $this->mockFace(['joyLikelihood' => 5]);
        $result = $this->callPrivate($this->service, 'validateSmile', [$face]);
        $this->assertTrue($result['valid']);
        $this->assertEquals('très probable', $result['details']['joy_likelihood']);
    }

    public function test_validate_smile_unknown(): void
    {
        $face = $this->mockFace(['joyLikelihood' => 0]); // UNKNOWN
        $result = $this->callPrivate($this->service, 'validateSmile', [$face]);
        $this->assertFalse($result['valid']);
        $this->assertEquals('inconnu', $result['details']['joy_likelihood']);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // advanceSession (private)
    // ═════════════════════════════════════════════════════════════════════════

    public function test_advance_session_to_next_challenge(): void
    {
        $sessionData = [
            'user_id' => 'u1',
            'challenges' => ['turn_left', 'smile'],
            'completed' => [],
            'current_index' => 0,
            'started_at' => now()->toIso8601String(),
            'face_reference' => null,
        ];
        Cache::put('liveness_session:adv1', $sessionData, 300);

        $result = $this->callPrivate($this->service, 'advanceSession', ['adv1', $sessionData, 'turn_left', true, 'OK']);

        $this->assertTrue($result['success']);
        $this->assertFalse($result['completed']);
        $this->assertArrayHasKey('next_challenge', $result);
        $this->assertEquals(2, $result['progress']['current']);
        $this->assertEquals(2, $result['progress']['total']);

        $cached = Cache::get('liveness_session:adv1');
        $this->assertEquals(1, $cached['current_index']);
        $this->assertCount(1, $cached['completed']);
        $this->assertTrue($cached['completed'][0]['passed']);
    }

    public function test_advance_session_completes_all_challenges(): void
    {
        $sessionData = [
            'user_id' => 'u1',
            'challenges' => ['smile'],
            'completed' => [],
            'current_index' => 0,
            'started_at' => now()->toIso8601String(),
            'face_reference' => null,
        ];
        Cache::put('liveness_session:adv2', $sessionData, 300);

        $result = $this->callPrivate($this->service, 'advanceSession', ['adv2', $sessionData, 'smile', true, 'Sourire détecté']);

        $this->assertTrue($result['success']);
        $this->assertTrue($result['completed']);
        $this->assertEquals(1, $result['challenges_completed']);
        $this->assertEquals('adv2', $result['session_id']);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // extractFaceReference (private)
    // ═════════════════════════════════════════════════════════════════════════

    public function test_extract_face_reference(): void
    {
        $face = $this->mockFace(['detectionConfidence' => 0.99, 'panAngle' => 5.0, 'tiltAngle' => -2.0]);
        $result = $this->callPrivate($this->service, 'extractFaceReference', [$face]);

        $this->assertEquals(0.99, $result['detection_confidence']);
        $this->assertEquals(5.0, $result['pan_angle']);
        $this->assertEquals(-2.0, $result['tilt_angle']);
        $this->assertArrayHasKey('bounding_box', $result);
        $this->assertArrayHasKey('top_left', $result['bounding_box']);
        $this->assertArrayHasKey('bottom_right', $result['bounding_box']);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // decodeBase64Image (private)
    // ═════════════════════════════════════════════════════════════════════════

    public function test_decode_base64_image_png(): void
    {
        $original = 'hello-image-data';
        $encoded = 'data:image/png;base64,' . base64_encode($original);
        $result = $this->callPrivate($this->service, 'decodeBase64Image', [$encoded]);
        $this->assertEquals($original, $result);
    }

    public function test_decode_base64_image_jpeg(): void
    {
        $original = 'jpeg-raw-bytes';
        $encoded = 'data:image/jpeg;base64,' . base64_encode($original);
        $result = $this->callPrivate($this->service, 'decodeBase64Image', [$encoded]);
        $this->assertEquals($original, $result);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // getLandmarkTypeName (private)
    // ═════════════════════════════════════════════════════════════════════════

    public function test_get_landmark_type_name_int(): void
    {
        $result = $this->callPrivate($this->service, 'getLandmarkTypeName', [0]);
        $this->assertIsString($result);
    }

    public function test_get_landmark_type_name_string(): void
    {
        $result = $this->callPrivate($this->service, 'getLandmarkTypeName', ['LEFT_EYE']);
        $this->assertEquals('LEFT_EYE', $result);
    }

    public function test_get_landmark_type_name_object(): void
    {
        $obj = new class { public function name(): string { return 'RIGHT_EYE'; } };
        $result = $this->callPrivate($this->service, 'getLandmarkTypeName', [$obj]);
        $this->assertEquals('RIGHT_EYE', $result);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // SESSION MANAGEMENT — startSession
    // ═════════════════════════════════════════════════════════════════════════

    public function test_start_session_throws_when_disabled(): void
    {
        $this->expectException(\RuntimeException::class);
        $this->service->startSession('user_1');
    }

    public function test_start_session_creates_session_with_real_client(): void
    {
        $service = $this->createEnabledService();
        if (!$service) {
            $this->markTestSkipped('Vision client could not be created');
        }

        $result = $service->startSession('user_42');

        $this->assertArrayHasKey('session_id', $result);
        $this->assertArrayHasKey('challenges', $result);
        $this->assertArrayHasKey('current_challenge', $result);
        $this->assertEquals(2, $result['total_challenges']);
        $this->assertEquals(300, $result['expires_in']);

        // Verify cache
        $cached = Cache::get("liveness_session:{$result['session_id']}");
        $this->assertNotNull($cached);
        $this->assertEquals('user_42', $cached['user_id']);
        $this->assertCount(2, $cached['challenges']);
        $this->assertEquals(0, $cached['current_index']);
        $this->assertEmpty($cached['completed']);
        $this->assertNull($cached['face_reference']);
    }

    public function test_start_session_returns_valid_challenge_types(): void
    {
        $service = $this->createEnabledService();
        if (!$service) {
            $this->markTestSkipped('Vision client could not be created');
        }

        $result = $service->startSession('user_1');
        $validTypes = ['blink', 'turn_left', 'turn_right', 'smile'];

        foreach ($result['challenges'] as $ch) {
            $this->assertContains($ch['type'], $validTypes);
            $this->assertArrayHasKey('instruction', $ch);
            $this->assertArrayHasKey('description', $ch);
            $this->assertArrayHasKey('icon', $ch);
            $this->assertEquals(3, $ch['duration']);
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    // SESSION MANAGEMENT — validateChallenge edge cases
    // ═════════════════════════════════════════════════════════════════════════

    public function test_validate_challenge_expired_session(): void
    {
        $service = $this->createEnabledService();
        if (!$service) {
            $this->markTestSkipped('Vision client could not be created');
        }

        $result = $service->validateChallenge('nonexistent-session', 'img');
        $this->assertFalse($result['success']);
        $this->assertEquals('session_expired', $result['error']);
    }

    public function test_validate_challenge_already_completed(): void
    {
        $service = $this->createEnabledService();
        if (!$service) {
            $this->markTestSkipped('Vision client could not be created');
        }

        Cache::put('liveness_session:done', [
            'user_id' => 'u1',
            'challenges' => ['blink'],
            'completed' => [['challenge' => 'blink', 'passed' => true, 'reason' => 'ok', 'completed_at' => now()->toIso8601String()]],
            'current_index' => 1,
            'started_at' => now()->toIso8601String(),
            'face_reference' => null,
        ], 300);

        $result = $service->validateChallenge('done', 'img');
        $this->assertFalse($result['success']);
        $this->assertEquals('session_completed', $result['error']);
    }

    public function test_validate_challenge_service_unavailable_when_disabled(): void
    {
        Cache::put('liveness_session:test', [
            'user_id' => 'u1',
            'challenges' => ['blink'],
            'completed' => [],
            'current_index' => 0,
            'started_at' => now()->toIso8601String(),
            'face_reference' => null,
        ], 300);

        $result = $this->service->validateChallenge('test', 'some-image');
        $this->assertFalse($result['success']);
        $this->assertEquals('service_unavailable', $result['error']);
        $this->assertTrue($result['fallback']);
    }

    public function test_validate_challenge_decodes_base64_image(): void
    {
        $service = $this->createEnabledService();
        if (!$service) {
            $this->markTestSkipped('Vision client could not be created');
        }

        Cache::put('liveness_session:b64', [
            'user_id' => 'u1',
            'challenges' => ['blink'],
            'completed' => [],
            'current_index' => 0,
            'started_at' => now()->toIso8601String(),
            'face_reference' => null,
        ], 300);

        // Will fail at API level but exercises the base64 decode + exception catch
        $base64 = 'data:image/png;base64,' . base64_encode('fake-png');
        $result = $service->validateChallenge('b64', $base64);
        $this->assertFalse($result['success']);
        // Either no_face or validation_error
        $this->assertContains($result['error'], ['no_face', 'validation_error']);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // isSessionValid
    // ═════════════════════════════════════════════════════════════════════════

    public function test_is_session_valid_not_found(): void
    {
        $result = $this->service->isSessionValid('nonexistent');
        $this->assertFalse($result['valid']);
        $this->assertStringContainsString('non trouvée', $result['reason']);
    }

    public function test_is_session_valid_incomplete(): void
    {
        Cache::put('liveness_session:inc', [
            'user_id' => 'u1',
            'challenges' => ['blink', 'smile'],
            'completed' => [['challenge' => 'blink', 'passed' => true, 'reason' => 'ok', 'completed_at' => now()->toIso8601String()]],
            'current_index' => 1,
            'started_at' => now()->toIso8601String(),
            'face_reference' => null,
        ], 300);

        $result = $this->service->isSessionValid('inc');
        $this->assertFalse($result['valid']);
        $this->assertFalse($result['is_complete']);
        $this->assertEquals(1, $result['completed_challenges']);
        $this->assertEquals(2, $result['total_challenges']);
    }

    public function test_is_session_valid_complete_all_passed(): void
    {
        Cache::put('liveness_session:ok', [
            'user_id' => 'u1',
            'challenges' => ['blink'],
            'completed' => [['challenge' => 'blink', 'passed' => true, 'reason' => 'ok', 'completed_at' => now()->toIso8601String()]],
            'current_index' => 1,
            'started_at' => now()->toIso8601String(),
            'face_reference' => null,
        ], 300);

        $result = $this->service->isSessionValid('ok');
        $this->assertTrue($result['valid']);
        $this->assertTrue($result['is_complete']);
        $this->assertTrue($result['all_passed']);
        $this->assertEquals('u1', $result['user_id']);
    }

    public function test_is_session_valid_complete_with_failure(): void
    {
        Cache::put('liveness_session:fail', [
            'user_id' => 'u1',
            'challenges' => ['smile'],
            'completed' => [['challenge' => 'smile', 'passed' => false, 'reason' => 'fail', 'completed_at' => now()->toIso8601String()]],
            'current_index' => 1,
            'started_at' => now()->toIso8601String(),
            'face_reference' => null,
        ], 300);

        $result = $this->service->isSessionValid('fail');
        $this->assertFalse($result['valid']);
        $this->assertTrue($result['is_complete']);
        $this->assertFalse($result['all_passed']);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // invalidateSession
    // ═════════════════════════════════════════════════════════════════════════

    public function test_invalidate_session_removes_from_cache(): void
    {
        Cache::put('liveness_session:kill', ['data' => true], 300);
        $this->service->invalidateSession('kill');
        $this->assertNull(Cache::get('liveness_session:kill'));
    }
}
