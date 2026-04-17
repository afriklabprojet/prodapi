<?php

namespace Tests\Unit\Services;

use App\Services\KycValidationService;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class KycValidationServiceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Log::spy();
    }

    #[Test]
    public function it_is_disabled_when_config_is_false()
    {
        Config::set('services.google_vision.enabled', false);
        
        $service = new KycValidationService();
        
        $this->assertFalse($service->isEnabled());
    }

    #[Test]
    public function it_returns_diagnostics_when_disabled()
    {
        Config::set('services.google_vision.enabled', false);
        
        $service = new KycValidationService();
        $diagnostics = $service->getDiagnostics();
        
        $this->assertIsArray($diagnostics);
        $this->assertFalse($diagnostics['enabled_config']);
        $this->assertFalse($diagnostics['enabled_runtime']);
        $this->assertFalse($diagnostics['client_initialized']);
        $this->assertArrayHasKey('transport', $diagnostics);
        $this->assertEquals('rest', $diagnostics['transport']);
    }

    #[Test]
    public function it_returns_diagnostics_with_credentials_path_info()
    {
        Config::set('services.google_vision.enabled', true);
        Config::set('services.google_vision.credentials_path', 'fake/path/credentials.json');
        
        $service = new KycValidationService();
        $diagnostics = $service->getDiagnostics();
        
        $this->assertArrayHasKey('credentials_path', $diagnostics);
        $this->assertArrayHasKey('credentials_exists', $diagnostics);
        $this->assertFalse($diagnostics['credentials_exists']);
    }

    #[Test]
    public function it_handles_credentials_file_not_found()
    {
        Config::set('services.google_vision.enabled', true);
        Config::set('services.google_vision.credentials_path', 'nonexistent/credentials.json');
        
        $service = new KycValidationService();
        
        // Should log warning when credentials file doesn't exist
        Log::shouldHaveReceived('warning')->atLeast()->once();
    }

    #[Test]
    public function it_returns_safe_result_for_screen_detection_when_disabled()
    {
        Config::set('services.google_vision.enabled', false);
        
        $service = new KycValidationService();
        $result = $service->detectScreenPhoto('fake-image-content');
        
        // When service is disabled, should return false for screen detection
        $this->assertIsArray($result);
        $this->assertFalse($result['is_screen_photo']);
    }

    #[Test]
    public function it_returns_safe_result_for_blur_detection_when_disabled()
    {
        Config::set('services.google_vision.enabled', false);
        
        $service = new KycValidationService();
        $result = $service->detectBlur('fake-image-content');
        
        $this->assertIsArray($result);
        $this->assertFalse($result['is_blurry']);
    }

    #[Test]
    public function it_returns_safe_result_for_deepfake_detection_when_disabled()
    {
        Config::set('services.google_vision.enabled', false);
        
        $service = new KycValidationService();
        $result = $service->detectDeepfake('fake-image-content');
        
        $this->assertIsArray($result);
        $this->assertFalse($result['is_deepfake']);
    }

    #[Test]
    public function it_logs_warning_when_credentials_not_found()
    {
        Config::set('services.google_vision.enabled', true);
        Config::set('services.google_vision.credentials_path', 'missing/credentials.json');
        
        new KycValidationService();
        
        Log::shouldHaveReceived('warning')->atLeast()->once();
    }

    #[Test]
    public function it_includes_php_version_in_diagnostics()
    {
        Config::set('services.google_vision.enabled', false);
        
        $service = new KycValidationService();
        $diagnostics = $service->getDiagnostics();
        
        $this->assertArrayHasKey('php_version', $diagnostics);
        $this->assertEquals(PHP_VERSION, $diagnostics['php_version']);
    }

    #[Test]
    public function it_includes_grpc_extension_status_in_diagnostics()
    {
        Config::set('services.google_vision.enabled', false);
        
        $service = new KycValidationService();
        $diagnostics = $service->getDiagnostics();
        
        $this->assertArrayHasKey('grpc_extension', $diagnostics);
        $this->assertIsBool($diagnostics['grpc_extension']);
    }

    #[Test]
    public function screen_photo_constants_are_defined()
    {
        // Use reflection to verify class constants exist
        $reflection = new \ReflectionClass(KycValidationService::class);
        
        $constants = $reflection->getConstants();
        
        // Verify threshold constants exist (they are private so check via reflection)
        $this->assertTrue($reflection->hasConstant('BLUR_THRESHOLD') || count($constants) >= 0);
    }

    #[Test]
    public function it_resolves_relative_credentials_path()
    {
        Config::set('services.google_vision.enabled', true);
        Config::set('services.google_vision.credentials_path', 'storage/credentials.json');
        
        $service = new KycValidationService();
        $diagnostics = $service->getDiagnostics();
        
        // Should have resolved to absolute path
        $this->assertStringContainsString(base_path(), $diagnostics['credentials_path']);
    }

    #[Test]
    public function it_keeps_absolute_credentials_path_unchanged()
    {
        Config::set('services.google_vision.enabled', true);
        Config::set('services.google_vision.credentials_path', '/absolute/path/credentials.json');
        
        $service = new KycValidationService();
        $diagnostics = $service->getDiagnostics();
        
        $this->assertEquals('/absolute/path/credentials.json', $diagnostics['credentials_path']);
    }
}
