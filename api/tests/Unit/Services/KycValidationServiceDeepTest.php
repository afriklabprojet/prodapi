<?php

namespace Tests\Unit\Services;

use App\Services\KycValidationService;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Mockery;
use Tests\TestCase;

class KycValidationServiceDeepTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Config::set('services.google_vision.enabled', false);
        Log::spy();

        // PHP 8.4 warns when tempnam() uses the system temp directory
        $prev = set_error_handler(function (int $severity, string $message, string $file, int $line) use (&$prev) {
            if ($severity === E_WARNING && str_contains($message, 'tempnam()')) {
                return true;
            }
            return $prev ? $prev($severity, $message, $file, $line) : false;
        });
    }

    // ═══════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════

    private function callPrivate(object $obj, string $method, array $args = []): mixed
    {
        $ref = new \ReflectionMethod($obj, $method);
        $ref->setAccessible(true);
        return $ref->invoke($obj, ...$args);
    }

    /**
     * Create a service with enabled=true and a mock client injected via reflection.
     */
    private function enableWithMock(object $mockClient): KycValidationService
    {
        $service = new KycValidationService();
        $ref = new \ReflectionClass($service);

        $prop = $ref->getProperty('enabled');
        $prop->setAccessible(true);
        $prop->setValue($service, true);

        $prop = $ref->getProperty('client');
        $prop->setAccessible(true);
        $prop->setValue($service, $mockClient);

        return $service;
    }

    /**
     * Create a mock Vision client that returns annotate responses in sequence.
     * Each call to batchAnnotateImages returns the next response wrapped in a batch.
     */
    private function mockClient(array $annotateResponses): object
    {
        $batchResponses = [];
        foreach ($annotateResponses as $i => $resp) {
            $batch = Mockery::mock();
            $batch->shouldReceive('getResponses')->andReturn([$resp]);
            $batchResponses[] = $batch;
        }

        $client = Mockery::mock();
        $client->shouldReceive('batchAnnotateImages')
            ->andReturn(...$batchResponses);

        return $client;
    }

    private function annotateResp(array $cfg = []): object
    {
        $resp = Mockery::mock();
        $resp->shouldReceive('getFaceAnnotations')->andReturn(new \ArrayIterator($cfg['faces'] ?? []));
        $resp->shouldReceive('getLabelAnnotations')->andReturn(new \ArrayIterator($cfg['labels'] ?? []));
        $resp->shouldReceive('getImagePropertiesAnnotation')->andReturn($cfg['properties'] ?? null);
        $resp->shouldReceive('getWebDetection')->andReturn($cfg['web'] ?? null);
        $resp->shouldReceive('getTextAnnotations')->andReturn(new \ArrayIterator($cfg['texts'] ?? []));
        $resp->shouldReceive('getFullTextAnnotation')->andReturn($cfg['document'] ?? null);
        return $resp;
    }

    private function mockFace(array $opts = []): object
    {
        $face = Mockery::mock();
        $face->shouldReceive('getDetectionConfidence')->andReturn($opts['confidence'] ?? 0.95);
        $face->shouldReceive('getBlurredLikelihood')->andReturn($opts['blurred'] ?? 1);
        $face->shouldReceive('getUnderExposedLikelihood')->andReturn($opts['underExposed'] ?? 1);
        $face->shouldReceive('getPanAngle')->andReturn($opts['pan'] ?? 0.0);
        $face->shouldReceive('getTiltAngle')->andReturn($opts['tilt'] ?? 0.0);
        $face->shouldReceive('getRollAngle')->andReturn($opts['roll'] ?? 0.0);
        $face->shouldReceive('getJoyLikelihood')->andReturn($opts['joy'] ?? 3);
        $face->shouldReceive('getSorrowLikelihood')->andReturn($opts['sorrow'] ?? 1);
        $face->shouldReceive('getAngerLikelihood')->andReturn($opts['anger'] ?? 1);
        $face->shouldReceive('getSurpriseLikelihood')->andReturn($opts['surprise'] ?? 1);
        $face->shouldReceive('getHeadwearLikelihood')->andReturn($opts['headwear'] ?? 1);
        $face->shouldReceive('getLandmarks')->andReturn($opts['landmarks'] ?? $this->defaultLandmarks());
        $face->shouldReceive('getBoundingPoly')->andReturn($this->mockBoundingPoly());
        return $face;
    }

    private function defaultLandmarks(): array
    {
        return [
            $this->mockLandmark('LEFT_EYE', 80, 100),
            $this->mockLandmark('RIGHT_EYE', 120, 100),
            $this->mockLandmark('LEFT_PUPIL', 82, 100),
            $this->mockLandmark('RIGHT_PUPIL', 118, 100),
            $this->mockLandmark('NOSE_TIP', 100, 120),
        ];
    }

    private function mockLandmark(string $type, float $x, float $y): object
    {
        $pos = Mockery::mock();
        $pos->shouldReceive('getX')->andReturn($x);
        $pos->shouldReceive('getY')->andReturn($y);

        $lm = Mockery::mock();
        $lm->shouldReceive('getType')->andReturn($type);
        $lm->shouldReceive('getPosition')->andReturn($pos);
        return $lm;
    }

    private function mockBoundingPoly(): object
    {
        $vertices = [];
        for ($i = 0; $i < 4; $i++) {
            $v = Mockery::mock();
            $v->shouldReceive('getX')->andReturn($i < 2 ? 10 : 200);
            $v->shouldReceive('getY')->andReturn($i % 2 === 0 ? 10 : 200);
            $vertices[] = $v;
        }
        $poly = Mockery::mock();
        $poly->shouldReceive('getVertices')->andReturn($vertices);
        return $poly;
    }

    private function mockLabel(string $desc, float $score): object
    {
        $label = Mockery::mock();
        $label->shouldReceive('getDescription')->andReturn($desc);
        $label->shouldReceive('getScore')->andReturn($score);
        return $label;
    }

    private function mockColor(int $r, int $g, int $b, float $score = 0.1): object
    {
        $colorObj = Mockery::mock();
        $colorObj->shouldReceive('getRed')->andReturn($r);
        $colorObj->shouldReceive('getGreen')->andReturn($g);
        $colorObj->shouldReceive('getBlue')->andReturn($b);

        $info = Mockery::mock();
        $info->shouldReceive('getColor')->andReturn($colorObj);
        $info->shouldReceive('getScore')->andReturn($score);
        return $info;
    }

    private function mockProperties(array $colors): object
    {
        $domColors = Mockery::mock();
        $domColors->shouldReceive('getColors')->andReturn($colors);

        $props = Mockery::mock();
        $props->shouldReceive('getDominantColors')->andReturn($domColors);
        return $props;
    }

    private function mockWeb(int $fullMatches = 0, int $partialMatches = 0): object
    {
        $full = array_fill(0, $fullMatches, Mockery::mock());
        $partial = array_fill(0, $partialMatches, Mockery::mock());

        $web = Mockery::mock();
        $web->shouldReceive('getFullMatchingImages')->andReturn($full);
        $web->shouldReceive('getPartialMatchingImages')->andReturn($partial);
        return $web;
    }

    private function mockText(string $description): object
    {
        $text = Mockery::mock();
        $text->shouldReceive('getDescription')->andReturn($description);
        return $text;
    }

    /** Normal colors (no moire, no artifacts) */
    private function normalColors(): array
    {
        return [
            $this->mockColor(128, 128, 128, 0.3),
            $this->mockColor(200, 180, 160, 0.2),
            $this->mockColor(100, 120, 90, 0.15),
            $this->mockColor(80, 70, 60, 0.12),
        ];
    }

    /** A normal good face suitable for passing all checks */
    private function goodFace(): object
    {
        return $this->mockFace([
            'confidence' => 0.95,
            'blurred' => 1,
            'underExposed' => 1,
            'pan' => 5.0,
            'tilt' => 3.0,
            'roll' => 2.0,
            'joy' => 3,
            'sorrow' => 1,
            'anger' => 1,
            'surprise' => 2,
            'headwear' => 1,
        ]);
    }

    /**
     * 2 responses for a clean detectScreenPhoto:
     * 1. labels (no screen keywords)
     * 2. image properties (normal colors)
     */
    private function cleanScreenResponses(): array
    {
        return [
            $this->annotateResp(['labels' => [$this->mockLabel('person', 0.9)]]),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
        ];
    }

    /** Create a temp file with content */
    private function tmpImage(string $content = 'fake-image-bytes'): string
    {
        $f = tempnam(sys_get_temp_dir(), 'kyc_');
        file_put_contents($f, $content);
        return $f;
    }

    private function createEnabledService(): ?KycValidationService
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

        Config::set('services.google_vision.enabled', true);
        Config::set('services.google_vision.credentials_path', $credFile);
        $service = new KycValidationService();
        @unlink($credFile);
        return $service->isEnabled() ? $service : null;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR & DIAGNOSTICS
    // ═══════════════════════════════════════════════════════════════════════

    public function test_disabled_by_config(): void
    {
        $service = new KycValidationService();
        $this->assertFalse($service->isEnabled());
    }

    public function test_valid_credentials(): void
    {
        $service = $this->createEnabledService();
        if (!$service) {
            $this->markTestSkipped('Vision client could not be created');
        }
        $this->assertTrue($service->isEnabled());
    }

    public function test_invalid_json_credentials(): void
    {
        $f = tempnam(sys_get_temp_dir(), 'gv_');
        file_put_contents($f, 'not-json');
        Config::set('services.google_vision.enabled', true);
        Config::set('services.google_vision.credentials_path', $f);
        $service = new KycValidationService();
        @unlink($f);
        $this->assertFalse($service->isEnabled());
    }

    public function test_json_missing_project_id(): void
    {
        $f = tempnam(sys_get_temp_dir(), 'gv_');
        file_put_contents($f, json_encode(['type' => 'service_account']));
        Config::set('services.google_vision.enabled', true);
        Config::set('services.google_vision.credentials_path', $f);
        $service = new KycValidationService();
        @unlink($f);
        $this->assertFalse($service->isEnabled());
    }

    public function test_credentials_not_found_tries_adc(): void
    {
        Config::set('services.google_vision.enabled', true);
        Config::set('services.google_vision.credentials_path', '/nonexistent/path.json');
        $service = new KycValidationService();
        $this->assertArrayHasKey('enabled_config', $service->getDiagnostics());
    }

    public function test_diagnostics(): void
    {
        $d = (new KycValidationService())->getDiagnostics();
        $this->assertArrayHasKey('enabled_config', $d);
        $this->assertArrayHasKey('enabled_runtime', $d);
        $this->assertArrayHasKey('client_initialized', $d);
        $this->assertArrayHasKey('credentials_path', $d);
        $this->assertArrayHasKey('grpc_extension', $d);
        $this->assertEquals('rest', $d['transport']);
    }

    public function test_relative_credentials_path(): void
    {
        Config::set('services.google_vision.enabled', true);
        Config::set('services.google_vision.credentials_path', 'relative/path.json');
        $service = new KycValidationService();
        $diag = $service->getDiagnostics();
        $this->assertStringContainsString('relative/path.json', $diag['credentials_path'] ?? '');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PRIVATE UTILITY METHODS (no API needed)
    // ═══════════════════════════════════════════════════════════════════════

    // --- detectIdKeywords ---

    public function test_detect_id_keywords_cni(): void
    {
        $text = "REPUBLIQUE DE CÔTE D'IVOIRE\nCARTE NATIONALE D'IDENTITE\nNOM: KONAN\nPRENOMS: JEAN";
        $r = $this->callPrivate(new KycValidationService(), 'detectIdKeywords', [$text]);
        $this->assertGreaterThanOrEqual(2, $r['score']);
        $this->assertContains('CARTE NATIONALE', $r['found']);
    }

    public function test_detect_id_keywords_passport(): void
    {
        $text = "PASSEPORT P<CIV MRZ 123456";
        $r = $this->callPrivate(new KycValidationService(), 'detectIdKeywords', [$text]);
        $this->assertGreaterThanOrEqual(4, $r['score']);
        $this->assertContains('PASSEPORT', $r['found']);
    }

    public function test_detect_id_keywords_driving_license(): void
    {
        $text = "PERMIS DE CONDUIRE CATEGORIE B REPUBLIQUE";
        $r = $this->callPrivate(new KycValidationService(), 'detectIdKeywords', [$text]);
        $this->assertGreaterThanOrEqual(2, $r['score']);
    }

    public function test_detect_id_keywords_unknown(): void
    {
        $r = $this->callPrivate(new KycValidationService(), 'detectIdKeywords', ['12345 67890']);
        $this->assertEquals(0, $r['score']);
        $this->assertEmpty($r['found']);
    }

    // --- detectMoirePattern ---

    public function test_moire_too_few_colors(): void
    {
        $colors = [$this->mockColor(100, 100, 100), $this->mockColor(200, 200, 200)];
        $this->assertFalse($this->callPrivate(new KycValidationService(), 'detectMoirePattern', [$colors]));
    }

    public function test_moire_pure_rgb(): void
    {
        $colors = [$this->mockColor(255, 0, 0), $this->mockColor(0, 255, 0), $this->mockColor(0, 0, 255)];
        $this->assertTrue($this->callPrivate(new KycValidationService(), 'detectMoirePattern', [$colors]));
    }

    public function test_moire_mixed_colors(): void
    {
        $colors = [$this->mockColor(128, 128, 128), $this->mockColor(200, 180, 160), $this->mockColor(100, 120, 90)];
        $this->assertFalse($this->callPrivate(new KycValidationService(), 'detectMoirePattern', [$colors]));
    }

    // --- calculateFaceSymmetry ---

    public function test_symmetry_no_landmarks(): void
    {
        $this->assertEquals(0.5, $this->callPrivate(new KycValidationService(), 'calculateFaceSymmetry', [[]]));
    }

    public function test_symmetry_perfectly_symmetric(): void
    {
        $lm = [
            $this->mockLandmark('LEFT_EYE', 80, 100),
            $this->mockLandmark('RIGHT_EYE', 120, 100),
        ];
        $r = $this->callPrivate(new KycValidationService(), 'calculateFaceSymmetry', [$lm]);
        $this->assertGreaterThan(0.9, $r);
    }

    public function test_symmetry_asymmetric(): void
    {
        $lm = [
            $this->mockLandmark('LEFT_EYE', 80, 100),
            $this->mockLandmark('RIGHT_EYE', 120, 160),
        ];
        $r = $this->callPrivate(new KycValidationService(), 'calculateFaceSymmetry', [$lm]);
        $this->assertLessThan(0.95, $r);
    }

    // --- checkEyeInconsistencies ---

    public function test_eye_inconsistencies_too_few_points(): void
    {
        $lm = [$this->mockLandmark('LEFT_EYE', 80, 100), $this->mockLandmark('RIGHT_EYE', 120, 100)];
        $this->assertFalse($this->callPrivate(new KycValidationService(), 'checkEyeInconsistencies', [$lm]));
    }

    public function test_eye_inconsistencies_similar(): void
    {
        $lm = [
            $this->mockLandmark('LEFT_EYE', 80, 100),
            $this->mockLandmark('LEFT_EYE_TOP', 80, 95),
            $this->mockLandmark('LEFT_EYE_BOTTOM', 80, 105),
            $this->mockLandmark('RIGHT_EYE', 120, 100),
            $this->mockLandmark('RIGHT_EYE_TOP', 120, 95),
            $this->mockLandmark('RIGHT_EYE_BOTTOM', 120, 105),
        ];
        $this->assertFalse($this->callPrivate(new KycValidationService(), 'checkEyeInconsistencies', [$lm]));
    }

    public function test_eye_inconsistencies_different(): void
    {
        $lm = [
            $this->mockLandmark('LEFT_EYE', 80, 100),
            $this->mockLandmark('LEFT_EYE_TOP', 80, 90),
            $this->mockLandmark('LEFT_EYE_BOTTOM', 100, 120),
            $this->mockLandmark('RIGHT_EYE', 120, 100),
            $this->mockLandmark('RIGHT_EYE_TOP', 120, 99),
            $this->mockLandmark('RIGHT_EYE_BOTTOM', 121, 101),
        ];
        $this->assertTrue($this->callPrivate(new KycValidationService(), 'checkEyeInconsistencies', [$lm]));
    }

    // --- calculateBoundingBox ---

    public function test_bounding_box_empty(): void
    {
        $this->assertEquals(0, $this->callPrivate(new KycValidationService(), 'calculateBoundingBox', [[]]));
    }

    public function test_bounding_box_with_points(): void
    {
        $this->assertEquals(200, $this->callPrivate(new KycValidationService(), 'calculateBoundingBox', [[['x' => 0, 'y' => 0], ['x' => 10, 'y' => 20]]]));
    }

    // --- detectGenerationArtifacts ---

    public function test_artifacts_null_properties(): void
    {
        $this->assertFalse($this->callPrivate(new KycValidationService(), 'detectGenerationArtifacts', [null]));
    }

    public function test_artifacts_no_dominant_colors(): void
    {
        $p = Mockery::mock();
        $p->shouldReceive('getDominantColors')->andReturn(null);
        $this->assertFalse($this->callPrivate(new KycValidationService(), 'detectGenerationArtifacts', [$p]));
    }

    public function test_artifacts_low_variance_many_colors(): void
    {
        $colors = [];
        for ($i = 0; $i < 6; $i++) {
            $colors[] = $this->mockColor(100 + $i, 100, 100, 0.10 + $i * 0.001);
        }
        $this->assertTrue($this->callPrivate(new KycValidationService(), 'detectGenerationArtifacts', [$this->mockProperties($colors)]));
    }

    public function test_artifacts_few_colors(): void
    {
        $colors = [$this->mockColor(100, 100, 100, 0.5), $this->mockColor(200, 200, 200, 0.3)];
        $this->assertFalse($this->callPrivate(new KycValidationService(), 'detectGenerationArtifacts', [$this->mockProperties($colors)]));
    }

    // --- checkEyeReflections ---

    public function test_eye_reflections_insufficient(): void
    {
        $lm = [$this->mockLandmark('LEFT_EYE', 80, 100), $this->mockLandmark('NOSE_TIP', 100, 120)];
        $this->assertFalse($this->callPrivate(new KycValidationService(), 'checkEyeReflections', [$lm]));
    }

    public function test_eye_reflections_enough(): void
    {
        $lm = [
            $this->mockLandmark('LEFT_EYE', 80, 100),
            $this->mockLandmark('RIGHT_EYE', 120, 100),
            $this->mockLandmark('LEFT_PUPIL', 82, 100),
            $this->mockLandmark('RIGHT_PUPIL', 118, 100),
        ];
        $this->assertTrue($this->callPrivate(new KycValidationService(), 'checkEyeReflections', [$lm]));
    }

    // --- getLandmarkTypeName ---

    public function test_landmark_type_name_int(): void
    {
        $this->assertIsString($this->callPrivate(new KycValidationService(), 'getLandmarkTypeName', [0]));
    }

    public function test_landmark_type_name_string(): void
    {
        $this->assertEquals('LEFT_EYE', $this->callPrivate(new KycValidationService(), 'getLandmarkTypeName', ['LEFT_EYE']));
    }

    public function test_landmark_type_name_object(): void
    {
        $obj = new class { public function name(): string { return 'RIGHT_EYE'; } };
        $this->assertEquals('RIGHT_EYE', $this->callPrivate(new KycValidationService(), 'getLandmarkTypeName', [$obj]));
    }

    // --- getImageContent ---

    public function test_image_content_from_storage(): void
    {
        Storage::fake('private');
        Storage::disk('private')->put('kyc/selfie.jpg', 'image-bytes');
        $r = $this->callPrivate(new KycValidationService(), 'getImageContent', ['kyc/selfie.jpg']);
        $this->assertEquals('image-bytes', $r);
    }

    public function test_image_content_from_file(): void
    {
        $f = $this->tmpImage('raw-img');
        $r = $this->callPrivate(new KycValidationService(), 'getImageContent', [$f]);
        @unlink($f);
        $this->assertEquals('raw-img', $r);
    }

    public function test_image_content_not_found(): void
    {
        Storage::fake('private');
        $this->assertNull($this->callPrivate(new KycValidationService(), 'getImageContent', ['/no/file.jpg']));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // detectScreenPhoto (2 API calls: labels + properties)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_screen_photo_detected_by_keywords(): void
    {
        $client = $this->mockClient([
            $this->annotateResp(['labels' => [
                $this->mockLabel('computer screen', 0.85),
                $this->mockLabel('display', 0.70),
            ]]),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectScreenPhoto('image');
        $this->assertTrue($r['is_screen_photo']);
        $this->assertGreaterThanOrEqual(0.6, $r['screen_score']);
        $this->assertNotNull($r['reason']);
        $this->assertContains('computer screen', $r['detected_labels']);
    }

    public function test_screen_photo_clean(): void
    {
        $client = $this->mockClient($this->cleanScreenResponses());
        $service = $this->enableWithMock($client);

        $r = $service->detectScreenPhoto('image');
        $this->assertFalse($r['is_screen_photo']);
        $this->assertEquals(0, $r['screen_score']);
        $this->assertNull($r['reason']);
    }

    public function test_screen_photo_moire_adds_score(): void
    {
        $moireColors = [$this->mockColor(255, 0, 0), $this->mockColor(0, 255, 0), $this->mockColor(0, 0, 255)];
        $client = $this->mockClient([
            $this->annotateResp(['labels' => [$this->mockLabel('electronic device', 0.4)]]),
            $this->annotateResp(['properties' => $this->mockProperties($moireColors)]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectScreenPhoto('image');
        $this->assertTrue($r['has_moire']);
        // 0.4 (label) + 0.3 (moiré) = 0.7 >= 0.6
        $this->assertTrue($r['is_screen_photo']);
    }

    public function test_screen_photo_exception(): void
    {
        $client = Mockery::mock();
        $client->shouldReceive('batchAnnotateImages')->andThrow(new \Exception('API fail'));
        $service = $this->enableWithMock($client);

        $r = $service->detectScreenPhoto('image');
        $this->assertFalse($r['is_screen_photo']);
        $this->assertArrayHasKey('error', $r);
    }

    public function test_screen_photo_properties_null(): void
    {
        $client = $this->mockClient([
            $this->annotateResp(['labels' => [$this->mockLabel('photo', 0.9)]]),
            $this->annotateResp(), // no properties
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectScreenPhoto('image');
        $this->assertFalse($r['is_screen_photo']);
        $this->assertFalse($r['has_moire']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // detectBlur (1 API call: faces)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_blur_no_face(): void
    {
        $client = $this->mockClient([$this->annotateResp()]);
        $service = $this->enableWithMock($client);

        $r = $service->detectBlur('image');
        $this->assertFalse($r['is_blurry']);
        $this->assertTrue($r['no_face']);
    }

    public function test_blur_very_unlikely(): void
    {
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$this->mockFace(['blurred' => 1, 'underExposed' => 1])]]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectBlur('image');
        $this->assertFalse($r['is_blurry']);
        $this->assertEquals(0.0, $r['blur_score']);
    }

    public function test_blur_likely(): void
    {
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$this->mockFace(['blurred' => 4])]]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectBlur('image');
        $this->assertTrue($r['is_blurry']);
        $this->assertEquals(0.7, $r['blur_score']);
    }

    public function test_blur_very_likely(): void
    {
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$this->mockFace(['blurred' => 5])]]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectBlur('image');
        $this->assertTrue($r['is_blurry']);
        $this->assertEquals(1.0, $r['blur_score']);
    }

    public function test_blur_possible(): void
    {
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$this->mockFace(['blurred' => 3])]]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectBlur('image');
        $this->assertTrue($r['is_blurry']); // 0.5 >= 0.3
    }

    public function test_blur_unlikely(): void
    {
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$this->mockFace(['blurred' => 2])]]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectBlur('image');
        $this->assertFalse($r['is_blurry']); // 0.2 < 0.3
    }

    public function test_blur_under_exposed_adds_score(): void
    {
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$this->mockFace(['blurred' => 1, 'underExposed' => 4])]]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectBlur('image');
        $this->assertTrue($r['is_blurry']); // 0.0 + 0.3 = 0.3 >= 0.3
        $this->assertTrue($r['under_exposed']);
    }

    public function test_blur_unknown_defaults(): void
    {
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$this->mockFace(['blurred' => 0])]]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectBlur('image');
        $this->assertTrue($r['is_blurry']); // 0.3 (default) >= 0.3
    }

    public function test_blur_exception(): void
    {
        $client = Mockery::mock();
        $client->shouldReceive('batchAnnotateImages')->andThrow(new \Exception('fail'));
        $service = $this->enableWithMock($client);

        $r = $service->detectBlur('image');
        $this->assertFalse($r['is_blurry']);
        $this->assertArrayHasKey('error', $r);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // detectDeepfake (3 API calls: faces, web, properties)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_deepfake_no_face(): void
    {
        $client = $this->mockClient([$this->annotateResp()]);
        $service = $this->enableWithMock($client);

        $r = $service->detectDeepfake('image');
        $this->assertFalse($r['is_deepfake']);
        $this->assertTrue($r['no_face']);
    }

    public function test_deepfake_found_online(): void
    {
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$this->goodFace()]]),
            $this->annotateResp(['web' => $this->mockWeb(2, 0)]),  // 2 full matches → +0.5
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectDeepfake('image');
        $this->assertTrue($r['is_deepfake']);
        $this->assertTrue($r['found_online']);
        $this->assertGreaterThanOrEqual(0.5, $r['suspicion_score']);
    }

    public function test_deepfake_partial_matches(): void
    {
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$this->goodFace()]]),
            $this->annotateResp(['web' => $this->mockWeb(0, 5)]),  // 5 partial → +0.2
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectDeepfake('image');
        $this->assertContains('Image similaire trouvée en ligne', $r['reasons']);
    }

    public function test_deepfake_high_symmetry(): void
    {
        // Perfectly symmetric landmarks
        $lm = [
            $this->mockLandmark('LEFT_EYE', 80, 100),
            $this->mockLandmark('RIGHT_EYE', 120, 100),
            $this->mockLandmark('LEFT_EAR', 50, 110),
            $this->mockLandmark('RIGHT_EAR', 150, 110),
            $this->mockLandmark('LEFT_CHEEK', 70, 130),
            $this->mockLandmark('RIGHT_CHEEK', 130, 130),
        ];
        $face = $this->mockFace(['landmarks' => $lm]);

        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face]]),
            $this->annotateResp(['web' => $this->mockWeb(0, 0)]),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectDeepfake('image');
        $this->assertContains('Symétrie faciale anormalement élevée', $r['reasons']);
    }

    public function test_deepfake_generation_artifacts(): void
    {
        $artifactColors = [];
        for ($i = 0; $i < 6; $i++) {
            $artifactColors[] = $this->mockColor(100 + $i, 100, 100, 0.10 + $i * 0.001);
        }

        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$this->goodFace()]]),
            $this->annotateResp(['web' => $this->mockWeb(0, 0)]),
            $this->annotateResp(['properties' => $this->mockProperties($artifactColors)]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectDeepfake('image');
        $this->assertContains('Artefacts de génération détectés', $r['reasons']);
    }

    public function test_deepfake_clean(): void
    {
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$this->goodFace()]]),
            $this->annotateResp(['web' => $this->mockWeb(0, 0)]),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectDeepfake('image');
        $this->assertFalse($r['is_deepfake']);
        $this->assertNull($r['reason']);
    }

    public function test_deepfake_eye_inconsistencies(): void
    {
        $lm = [
            $this->mockLandmark('LEFT_EYE', 80, 100),
            $this->mockLandmark('LEFT_EYE_TOP', 80, 90),
            $this->mockLandmark('LEFT_EYE_BOTTOM', 100, 120),
            $this->mockLandmark('RIGHT_EYE', 120, 100),
            $this->mockLandmark('RIGHT_EYE_TOP', 120, 99),
            $this->mockLandmark('RIGHT_EYE_BOTTOM', 121, 101),
        ];
        $face = $this->mockFace(['landmarks' => $lm]);

        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face]]),
            $this->annotateResp(['web' => $this->mockWeb(0, 0)]),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectDeepfake('image');
        $this->assertContains('Incohérence dans la région des yeux', $r['reasons']);
    }

    public function test_deepfake_no_web_detection(): void
    {
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$this->goodFace()]]),
            $this->annotateResp(), // web=null
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectDeepfake('image');
        $this->assertFalse($r['found_online']);
    }

    public function test_deepfake_exception(): void
    {
        $client = Mockery::mock();
        $client->shouldReceive('batchAnnotateImages')->andThrow(new \Exception('fail'));
        $service = $this->enableWithMock($client);

        $r = $service->detectDeepfake('image');
        $this->assertFalse($r['is_deepfake']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // detectLiveness (3 API calls: faces + labels + properties via screenCheck)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_liveness_no_face(): void
    {
        $client = $this->mockClient([$this->annotateResp()]);
        $service = $this->enableWithMock($client);

        $r = $service->detectLiveness('image');
        $this->assertFalse($r['is_live']);
        $this->assertEquals(0, $r['liveness_score']);
    }

    public function test_liveness_good_face(): void
    {
        $face = $this->goodFace();
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face]]),
            ...$this->cleanScreenResponses(), // screen check: labels + properties
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectLiveness('image');
        $this->assertTrue($r['is_live']);
        $this->assertGreaterThanOrEqual(0.7, $r['liveness_score']);
    }

    public function test_liveness_extreme_roll_angle(): void
    {
        $face = $this->mockFace(['roll' => 35.0, 'joy' => 3, 'surprise' => 2]);
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face]]),
            ...$this->cleanScreenResponses(),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectLiveness('image');
        $this->assertContains('Visage incliné de manière suspecte', $r['issues']);
    }

    public function test_liveness_extreme_pan_angle(): void
    {
        $face = $this->mockFace(['pan' => 50.0, 'joy' => 3, 'surprise' => 2]);
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face]]),
            ...$this->cleanScreenResponses(),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectLiveness('image');
        $this->assertContains('Visage tourné latéralement', $r['issues']);
    }

    public function test_liveness_extreme_tilt_angle(): void
    {
        $face = $this->mockFace(['tilt' => -35.0, 'joy' => 3, 'surprise' => 2]);
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face]]),
            ...$this->cleanScreenResponses(),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectLiveness('image');
        $this->assertContains('Visage incliné vers le haut/bas', $r['issues']);
    }

    public function test_liveness_low_confidence(): void
    {
        $face = $this->mockFace(['confidence' => 0.5, 'joy' => 3, 'surprise' => 2]);
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face]]),
            ...$this->cleanScreenResponses(),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectLiveness('image');
        $this->assertContains('Qualité de détection faible', $r['issues']);
    }

    public function test_liveness_no_expression(): void
    {
        $face = $this->mockFace(['joy' => 1, 'sorrow' => 1, 'anger' => 1, 'surprise' => 1]);
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face]]),
            ...$this->cleanScreenResponses(),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectLiveness('image');
        $this->assertContains('Absence d\'expression détectable', $r['issues']);
    }

    public function test_liveness_headwear(): void
    {
        $face = $this->mockFace(['headwear' => 5, 'joy' => 3, 'surprise' => 2]);
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face]]),
            ...$this->cleanScreenResponses(),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectLiveness('image');
        $this->assertContains('Chapeau ou accessoire détecté', $r['issues']);
    }

    public function test_liveness_no_eye_reflections(): void
    {
        $face = $this->mockFace([
            'joy' => 3,
            'surprise' => 2,
            'landmarks' => [$this->mockLandmark('NOSE_TIP', 100, 120)],
        ]);
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face]]),
            ...$this->cleanScreenResponses(),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectLiveness('image');
        $this->assertContains('Pas de reflet détecté dans les yeux', $r['issues']);
    }

    public function test_liveness_screen_photo_detected(): void
    {
        $face = $this->goodFace();
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face]]),
            // Screen check detects screen
            $this->annotateResp(['labels' => [$this->mockLabel('monitor', 0.85)]]),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectLiveness('image');
        $this->assertContains('Photo d\'écran détectée', $r['issues']);
    }

    public function test_liveness_many_issues_below_threshold(): void
    {
        // all angles extreme, no expression, headwear, no reflections, screen
        $face = $this->mockFace([
            'roll' => 35.0,
            'pan' => 50.0,
            'tilt' => -35.0,
            'confidence' => 0.5,
            'joy' => 1,
            'sorrow' => 1,
            'anger' => 1,
            'surprise' => 1,
            'headwear' => 5,
            'landmarks' => [$this->mockLandmark('NOSE_TIP', 100, 120)],
        ]);
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face]]),
            $this->annotateResp(['labels' => [$this->mockLabel('screen', 0.88)]]),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->detectLiveness('image');
        $this->assertFalse($r['is_live']);
        $this->assertEquals(0, $r['liveness_score']); // max(0, ...) clamped
        $this->assertNotNull($r['reason']);
    }

    public function test_liveness_exception(): void
    {
        $client = Mockery::mock();
        $client->shouldReceive('batchAnnotateImages')->andThrow(new \Exception('fail'));
        $service = $this->enableWithMock($client);

        $r = $service->detectLiveness('image');
        $this->assertTrue($r['is_live']); // catch returns is_live=true
    }

    // ═══════════════════════════════════════════════════════════════════════
    // validateSelfie (10 API calls if all pass)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_selfie_disabled(): void
    {
        $r = (new KycValidationService())->validateSelfie('path.jpg');
        $this->assertTrue($r['valid']);
        $this->assertTrue($r['skipped']);
    }

    public function test_selfie_image_not_found(): void
    {
        $client = $this->mockClient([]); // no calls needed
        $service = $this->enableWithMock($client);

        $r = $service->validateSelfie('/nonexistent.jpg');
        $this->assertFalse($r['valid']);
        $this->assertStringContainsString('lire', $r['reason']);
    }

    public function test_selfie_no_face(): void
    {
        $f = $this->tmpImage();
        $client = $this->mockClient([$this->annotateResp()]); // no faces
        $service = $this->enableWithMock($client);

        $r = $service->validateSelfie($f);
        @unlink($f);
        $this->assertFalse($r['valid']);
        $this->assertEquals('no_face', $r['fraud_type']);
    }

    public function test_selfie_multiple_faces(): void
    {
        $f = $this->tmpImage();
        $face1 = $this->goodFace();
        $face2 = $this->goodFace();
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face1, $face2]]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateSelfie($f);
        @unlink($f);
        $this->assertFalse($r['valid']);
        $this->assertEquals('multiple_faces', $r['fraud_type']);
    }

    public function test_selfie_low_confidence(): void
    {
        $f = $this->tmpImage();
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$this->mockFace(['confidence' => 0.5])]]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateSelfie($f);
        @unlink($f);
        $this->assertFalse($r['valid']);
        $this->assertEquals('low_quality', $r['fraud_type']);
    }

    public function test_selfie_blurry(): void
    {
        $f = $this->tmpImage();
        $face = $this->goodFace();
        $blurryFace = $this->mockFace(['blurred' => 5]); // very likely blurred
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face]]),        // Call 1: face check passes
            $this->annotateResp(['faces' => [$blurryFace]]),  // Call 2: blur check → blurry
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateSelfie($f);
        @unlink($f);
        $this->assertFalse($r['valid']);
        $this->assertEquals('blurry_image', $r['fraud_type']);
    }

    public function test_selfie_screen_photo(): void
    {
        $f = $this->tmpImage();
        $face = $this->goodFace();
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face]]),       // Call 1: face OK
            $this->annotateResp(['faces' => [$face]]),       // Call 2: blur check → OK
            // Call 3+4: screen check → screen detected
            $this->annotateResp(['labels' => [$this->mockLabel('monitor', 0.85)]]),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateSelfie($f);
        @unlink($f);
        $this->assertFalse($r['valid']);
        $this->assertEquals('screen_photo', $r['fraud_type']);
    }

    public function test_selfie_deepfake(): void
    {
        $f = $this->tmpImage();
        $face = $this->goodFace();
        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face]]),       // Call 1: face OK
            $this->annotateResp(['faces' => [$face]]),       // Call 2: blur → OK
            ...$this->cleanScreenResponses(),                // Call 3-4: screen → clean
            // Call 5-7: deepfake → found online
            $this->annotateResp(['faces' => [$face]]),
            $this->annotateResp(['web' => $this->mockWeb(3, 0)]),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateSelfie($f);
        @unlink($f);
        $this->assertFalse($r['valid']);
        $this->assertEquals('deepfake', $r['fraud_type']);
    }

    public function test_selfie_not_live(): void
    {
        $f = $this->tmpImage();
        $face = $this->goodFace();
        // Not-live face: extreme angles + no expression
        $deadFace = $this->mockFace([
            'roll' => 35.0, 'pan' => 50.0, 'tilt' => -35.0,
            'confidence' => 0.5, 'joy' => 1, 'sorrow' => 1, 'anger' => 1, 'surprise' => 1,
            'headwear' => 5,
            'landmarks' => [$this->mockLandmark('NOSE_TIP', 100, 120)],
        ]);

        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face]]),       // Call 1: face OK
            $this->annotateResp(['faces' => [$face]]),       // Call 2: blur → OK
            ...$this->cleanScreenResponses(),                // Call 3-4: screen → clean
            // Call 5-7: deepfake → clean
            $this->annotateResp(['faces' => [$face]]),
            $this->annotateResp(['web' => $this->mockWeb(0, 0)]),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
            // Call 8-10: liveness → NOT live
            $this->annotateResp(['faces' => [$deadFace]]),
            ...$this->cleanScreenResponses(),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateSelfie($f);
        @unlink($f);
        $this->assertFalse($r['valid']);
        $this->assertEquals('not_live', $r['fraud_type']);
    }

    public function test_selfie_all_passes(): void
    {
        $f = $this->tmpImage();
        $face = $this->goodFace();

        $client = $this->mockClient([
            $this->annotateResp(['faces' => [$face]]),       // Call 1: face OK
            $this->annotateResp(['faces' => [$face]]),       // Call 2: blur → OK
            ...$this->cleanScreenResponses(),                // Call 3-4: screen → clean
            // Call 5-7: deepfake → clean
            $this->annotateResp(['faces' => [$face]]),
            $this->annotateResp(['web' => $this->mockWeb(0, 0)]),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
            // Call 8-10: liveness → live
            $this->annotateResp(['faces' => [$face]]),
            ...$this->cleanScreenResponses(),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateSelfie($f);
        @unlink($f);
        $this->assertTrue($r['valid']);
        $this->assertEquals(1, $r['face_count']);
        $this->assertGreaterThanOrEqual(0.7, $r['confidence']);
        $this->assertArrayHasKey('fraud_checks', $r);
    }

    public function test_selfie_exception(): void
    {
        $f = $this->tmpImage();
        $client = Mockery::mock();
        $client->shouldReceive('batchAnnotateImages')->andThrow(new \Exception('fail'));
        $service = $this->enableWithMock($client);

        $r = $service->validateSelfie($f);
        @unlink($f);
        $this->assertTrue($r['valid']);
        $this->assertTrue($r['skipped']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // validateIdCard (6 API calls if all pass)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_id_card_disabled(): void
    {
        $r = (new KycValidationService())->validateIdCard('path.jpg');
        $this->assertTrue($r['valid']);
        $this->assertTrue($r['skipped']);
    }

    public function test_id_card_image_not_found(): void
    {
        $client = $this->mockClient([]);
        $service = $this->enableWithMock($client);

        $r = $service->validateIdCard('/nonexistent.jpg');
        $this->assertFalse($r['valid']);
    }

    public function test_id_card_screen_detected(): void
    {
        $f = $this->tmpImage();
        $client = $this->mockClient([
            $this->annotateResp(['labels' => [$this->mockLabel('computer monitor', 0.9)]]),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateIdCard($f);
        @unlink($f);
        $this->assertFalse($r['valid']);
        $this->assertEquals('screen_photo', $r['fraud_type']);
    }

    public function test_id_card_document_blurry(): void
    {
        $f = $this->tmpImage();
        // 2 colors → blurry document
        $fewColors = [$this->mockColor(128, 128, 128), $this->mockColor(200, 200, 200)];
        $client = $this->mockClient([
            ...$this->cleanScreenResponses(),             // Calls 1-2: screen OK
            $this->annotateResp(['properties' => $this->mockProperties($fewColors)]), // Call 3: doc blur
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateIdCard($f);
        @unlink($f);
        $this->assertFalse($r['valid']);
        $this->assertEquals('blurry_document', $r['fraud_type']);
    }

    public function test_id_card_no_text(): void
    {
        $f = $this->tmpImage();
        $client = $this->mockClient([
            ...$this->cleanScreenResponses(),                                          // Calls 1-2
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]), // Call 3: blur OK
            $this->annotateResp(),                                                     // Call 4: no text
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateIdCard($f);
        @unlink($f);
        $this->assertFalse($r['valid']);
        $this->assertFalse($r['has_text']);
    }

    public function test_id_card_short_text(): void
    {
        $f = $this->tmpImage();
        $client = $this->mockClient([
            ...$this->cleanScreenResponses(),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
            $this->annotateResp(['texts' => [$this->mockText('Short')]]), // < 50 chars
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateIdCard($f);
        @unlink($f);
        $this->assertFalse($r['valid']);
        $this->assertStringContainsString('incomplet', strtolower($r['reason']));
    }

    public function test_id_card_low_keywords(): void
    {
        $f = $this->tmpImage();
        // Long text but no ID keywords - avoid single letters B,C,D,E that match license categories
        $longText = str_repeat('0123456789 XXXXX YYYYY ZZZZZ ', 5);
        $client = $this->mockClient([
            ...$this->cleanScreenResponses(),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
            $this->annotateResp(['texts' => [$this->mockText($longText)]]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateIdCard($f);
        @unlink($f);
        $this->assertFalse($r['valid']);
        $this->assertStringContainsString('non reconnu', strtolower($r['reason']));
    }

    public function test_id_card_found_online(): void
    {
        $f = $this->tmpImage();
        $cniText = "REPUBLIQUE DE CÔTE D'IVOIRE\nCARTE NATIONALE D'IDENTITE\nNOM: KONAN JEAN\nPRENOMS: JEAN PAUL\nDATE DE NAISSANCE: 01/01/1990\nLIEU DE NAISSANCE: ABIDJAN";
        $client = $this->mockClient([
            ...$this->cleanScreenResponses(),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
            $this->annotateResp(['texts' => [$this->mockText($cniText)]]),
            $this->annotateResp(['faces' => [$this->goodFace()]]),
            $this->annotateResp(['web' => $this->mockWeb(5, 0)]), // found online
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateIdCard($f);
        @unlink($f);
        $this->assertFalse($r['valid']);
        $this->assertEquals('image_from_web', $r['fraud_type']);
    }

    public function test_id_card_valid_cni(): void
    {
        $f = $this->tmpImage();
        $cniText = "REPUBLIQUE DE CÔTE D'IVOIRE\nCARTE NATIONALE D'IDENTITE\nNOM: KONAN JEAN\nPRENOMS: JEAN PAUL\nDATE DE NAISSANCE: 01/01/1990\nLIEU DE NAISSANCE: ABIDJAN\nSEXE: M\nNATIONALITE: IVOIRIENNE";
        $client = $this->mockClient([
            ...$this->cleanScreenResponses(),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
            $this->annotateResp(['texts' => [$this->mockText($cniText)]]),
            $this->annotateResp(['faces' => [$this->goodFace()]]),
            $this->annotateResp(['web' => $this->mockWeb(0, 0)]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateIdCard($f);
        @unlink($f);
        $this->assertTrue($r['valid']);
        $this->assertTrue($r['has_text']);
        $this->assertTrue($r['has_face']);
        $this->assertNotEmpty($r['keywords_found']);
    }

    public function test_id_card_valid_no_face_on_recto(): void
    {
        $f = $this->tmpImage();
        $cniText = "REPUBLIQUE DE CÔTE D'IVOIRE\nCARTE NATIONALE D'IDENTITE\nNOM: KONAN JEAN\nPRENOMS: JEAN PAUL\nDATE DE NAISSANCE: 01/01/1990\nLIEU DE NAISSANCE: ABIDJAN";
        $client = $this->mockClient([
            ...$this->cleanScreenResponses(),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
            $this->annotateResp(['texts' => [$this->mockText($cniText)]]),
            $this->annotateResp(),  // no face — still valid
            $this->annotateResp(['web' => $this->mockWeb(0, 0)]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateIdCard($f);
        @unlink($f);
        $this->assertTrue($r['valid']);
        $this->assertFalse($r['has_face']);
    }

    public function test_id_card_exception(): void
    {
        $f = $this->tmpImage();
        $client = Mockery::mock();
        $client->shouldReceive('batchAnnotateImages')->andThrow(new \Exception('fail'));
        $service = $this->enableWithMock($client);

        $r = $service->validateIdCard($f);
        @unlink($f);
        $this->assertTrue($r['valid']);
        $this->assertTrue($r['skipped']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // validateIdCardBack (3 API calls if pass)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_id_card_back_disabled(): void
    {
        $r = (new KycValidationService())->validateIdCardBack('path.jpg');
        $this->assertTrue($r['valid']);
        $this->assertTrue($r['skipped']);
    }

    public function test_id_card_back_image_not_found(): void
    {
        $client = $this->mockClient([]);
        $service = $this->enableWithMock($client);

        $r = $service->validateIdCardBack('/nonexistent.jpg');
        $this->assertFalse($r['valid']);
    }

    public function test_id_card_back_screen(): void
    {
        $f = $this->tmpImage();
        $client = $this->mockClient([
            $this->annotateResp(['labels' => [$this->mockLabel('lcd screen', 0.9)]]),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateIdCardBack($f);
        @unlink($f);
        $this->assertFalse($r['valid']);
        $this->assertEquals('screen_photo', $r['fraud_type']);
    }

    public function test_id_card_back_no_text(): void
    {
        $f = $this->tmpImage();
        $client = $this->mockClient([
            ...$this->cleanScreenResponses(),
            $this->annotateResp(), // no text
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateIdCardBack($f);
        @unlink($f);
        $this->assertFalse($r['valid']);
        $this->assertFalse($r['has_text']);
    }

    public function test_id_card_back_short_text(): void
    {
        $f = $this->tmpImage();
        $client = $this->mockClient([
            ...$this->cleanScreenResponses(),
            $this->annotateResp(['texts' => [$this->mockText('Short')]]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateIdCardBack($f);
        @unlink($f);
        $this->assertFalse($r['valid']);
    }

    public function test_id_card_back_valid(): void
    {
        $f = $this->tmpImage();
        $backText = "MRZ LIGNE 1 ABCDEF1234567890\nMRZ LIGNE 2 ABCDEF1234567890\nNuméro: CI-123456789";
        $client = $this->mockClient([
            ...$this->cleanScreenResponses(),
            $this->annotateResp(['texts' => [$this->mockText($backText)]]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateIdCardBack($f);
        @unlink($f);
        $this->assertTrue($r['valid']);
        $this->assertTrue($r['has_text']);
    }

    public function test_id_card_back_exception(): void
    {
        $f = $this->tmpImage();
        $client = Mockery::mock();
        $client->shouldReceive('batchAnnotateImages')->andThrow(new \Exception('fail'));
        $service = $this->enableWithMock($client);

        $r = $service->validateIdCardBack($f);
        @unlink($f);
        $this->assertTrue($r['valid']);
        $this->assertTrue($r['skipped']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // validateKycDocuments orchestrator
    // ═══════════════════════════════════════════════════════════════════════

    public function test_kyc_docs_all_disabled(): void
    {
        $r = (new KycValidationService())->validateKycDocuments([
            'selfie' => 'a.jpg', 'id_card_front' => 'b.jpg', 'id_card_back' => 'c.jpg',
        ]);
        $this->assertTrue($r['overall_valid']);
        $this->assertFalse($r['fraud_detected']);
        $this->assertArrayHasKey('selfie', $r['documents']);
        $this->assertArrayHasKey('id_card_front', $r['documents']);
        $this->assertArrayHasKey('id_card_back', $r['documents']);
    }

    public function test_kyc_docs_empty(): void
    {
        $r = (new KycValidationService())->validateKycDocuments([]);
        $this->assertTrue($r['overall_valid']);
        $this->assertEmpty($r['documents']);
    }

    public function test_kyc_docs_selfie_fraud(): void
    {
        $f = $this->tmpImage();
        $client = $this->mockClient([$this->annotateResp()]); // no face
        $service = $this->enableWithMock($client);

        $r = $service->validateKycDocuments(['selfie' => $f]);
        @unlink($f);
        $this->assertFalse($r['overall_valid']);
        $this->assertTrue($r['fraud_detected']);
        $this->assertContains('no_face', $r['fraud_types']);
    }

    public function test_kyc_docs_id_front_fraud(): void
    {
        $f = $this->tmpImage();
        // Screen photo detected on ID
        $client = $this->mockClient([
            $this->annotateResp(['labels' => [$this->mockLabel('monitor screen', 0.9)]]),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateKycDocuments(['id_card_front' => $f]);
        @unlink($f);
        $this->assertFalse($r['overall_valid']);
        $this->assertTrue($r['fraud_detected']);
        $this->assertContains('screen_photo', $r['fraud_types']);
    }

    public function test_kyc_docs_id_back_fraud(): void
    {
        $f = $this->tmpImage();
        $client = $this->mockClient([
            $this->annotateResp(['labels' => [$this->mockLabel('lcd display', 0.9)]]),
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $service->validateKycDocuments(['id_card_back' => $f]);
        @unlink($f);
        $this->assertFalse($r['overall_valid']);
        $this->assertTrue($r['fraud_detected']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // detectDocumentBlur (private, 1 API call: properties)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_doc_blur_few_colors(): void
    {
        $fewColors = [$this->mockColor(100, 100, 100), $this->mockColor(200, 200, 200)];
        $client = $this->mockClient([
            $this->annotateResp(['properties' => $this->mockProperties($fewColors)]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $this->callPrivate($service, 'detectDocumentBlur', ['image']);
        $this->assertTrue($r['is_blurry']);
        $this->assertEquals(0.7, $r['blur_score']);
    }

    public function test_doc_blur_enough_colors(): void
    {
        $client = $this->mockClient([
            $this->annotateResp(['properties' => $this->mockProperties($this->normalColors())]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $this->callPrivate($service, 'detectDocumentBlur', ['image']);
        $this->assertFalse($r['is_blurry']);
    }

    public function test_doc_blur_no_properties(): void
    {
        $client = $this->mockClient([$this->annotateResp()]);
        $service = $this->enableWithMock($client);

        $r = $this->callPrivate($service, 'detectDocumentBlur', ['image']);
        $this->assertFalse($r['is_blurry']);
    }

    public function test_doc_blur_properties_no_dominant_colors(): void
    {
        $props = Mockery::mock();
        $props->shouldReceive('getDominantColors')->andReturn(null);
        $client = $this->mockClient([
            $this->annotateResp(['properties' => $props]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $this->callPrivate($service, 'detectDocumentBlur', ['image']);
        $this->assertFalse($r['is_blurry']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // checkImageOnline (private, 1 API call: web detection)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_check_image_online_not_found(): void
    {
        $client = $this->mockClient([$this->annotateResp(['web' => $this->mockWeb(0, 0)])]);
        $service = $this->enableWithMock($client);

        $r = $this->callPrivate($service, 'checkImageOnline', ['image']);
        $this->assertFalse($r['found_online']);
    }

    public function test_check_image_online_exact_match(): void
    {
        $client = $this->mockClient([$this->annotateResp(['web' => $this->mockWeb(3, 0)])]);
        $service = $this->enableWithMock($client);

        $r = $this->callPrivate($service, 'checkImageOnline', ['image']);
        $this->assertTrue($r['found_online']);
        $this->assertEquals(3, $r['exact_matches']);
    }

    public function test_check_image_online_many_partials(): void
    {
        $client = $this->mockClient([$this->annotateResp(['web' => $this->mockWeb(0, 5)])]);
        $service = $this->enableWithMock($client);

        $r = $this->callPrivate($service, 'checkImageOnline', ['image']);
        $this->assertTrue($r['found_online']); // > 3 partials
    }

    public function test_check_image_online_few_partials(): void
    {
        $client = $this->mockClient([$this->annotateResp(['web' => $this->mockWeb(0, 2)])]);
        $service = $this->enableWithMock($client);

        $r = $this->callPrivate($service, 'checkImageOnline', ['image']);
        $this->assertFalse($r['found_online']); // <= 3 partials
    }

    public function test_check_image_online_no_web(): void
    {
        $client = $this->mockClient([$this->annotateResp()]); // web=null
        $service = $this->enableWithMock($client);

        $r = $this->callPrivate($service, 'checkImageOnline', ['image']);
        $this->assertFalse($r['found_online']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // annotateImage (private, core method)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_annotate_image_no_client(): void
    {
        $service = new KycValidationService();
        $ref = new \ReflectionClass($service);
        $prop = $ref->getProperty('enabled');
        $prop->setAccessible(true);
        $prop->setValue($service, true);
        // client stays null

        $r = $this->callPrivate($service, 'annotateImage', ['image', [1]]);
        $this->assertNull($r);
    }

    public function test_annotate_image_empty_responses(): void
    {
        $batch = Mockery::mock();
        $batch->shouldReceive('getResponses')->andReturn([]);

        $client = Mockery::mock();
        $client->shouldReceive('batchAnnotateImages')->andReturn($batch);
        $service = $this->enableWithMock($client);

        $r = $this->callPrivate($service, 'annotateImage', ['image', [1]]);
        $this->assertNull($r);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // detectDocument (private, not used by public methods but exists)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_detect_document_returns_text(): void
    {
        $docMock = Mockery::mock();
        $client = $this->mockClient([
            $this->annotateResp(['document' => $docMock]),
        ]);
        $service = $this->enableWithMock($client);

        $r = $this->callPrivate($service, 'detectDocument', ['image']);
        $this->assertSame($docMock, $r);
    }

    public function test_detect_document_null_response(): void
    {
        $batch = Mockery::mock();
        $batch->shouldReceive('getResponses')->andReturn([]);
        $client = Mockery::mock();
        $client->shouldReceive('batchAnnotateImages')->andReturn($batch);
        $service = $this->enableWithMock($client);

        $r = $this->callPrivate($service, 'detectDocument', ['image']);
        $this->assertNull($r);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Error catch paths
    // ═══════════════════════════════════════════════════════════════════════

    public function test_check_image_online_exception(): void
    {
        $client = Mockery::mock();
        $client->shouldReceive('batchAnnotateImages')->andThrow(new \Exception('web error'));
        $service = $this->enableWithMock($client);

        $r = $this->callPrivate($service, 'checkImageOnline', ['image']);
        $this->assertFalse($r['found_online']);
        $this->assertArrayHasKey('error', $r);
    }

    public function test_doc_blur_exception(): void
    {
        $client = Mockery::mock();
        $client->shouldReceive('batchAnnotateImages')->andThrow(new \Exception('blur error'));
        $service = $this->enableWithMock($client);

        $r = $this->callPrivate($service, 'detectDocumentBlur', ['image']);
        $this->assertFalse($r['is_blurry']);
        $this->assertArrayHasKey('error', $r);
    }

    public function test_get_image_content_exception(): void
    {
        Storage::shouldReceive('disk')->with('private')->andThrow(new \Exception('storage error'));
        $r = $this->callPrivate(new KycValidationService(), 'getImageContent', ['some/path']);
        $this->assertNull($r);
    }
}
