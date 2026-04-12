<?php

namespace Tests\Unit\Services;

use App\Services\PrescriptionOcrService;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class PrescriptionOcrServiceTest extends TestCase
{
    protected PrescriptionOcrService $service;

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.google_vision.api_key' => null]);
        $this->service = new PrescriptionOcrService();
    }

    public function test_service_instantiates_without_credentials(): void
    {
        $service = new PrescriptionOcrService();
        $this->assertInstanceOf(PrescriptionOcrService::class, $service);
    }

    public function test_analyze_image_returns_error_when_image_not_found(): void
    {
        Storage::fake('local');
        Storage::fake('private');
        Storage::fake('public');

        Log::shouldReceive('warning')->once()->withArgs(function ($msg) {
            return str_contains($msg, '[OCR] Image not found') || str_contains($msg, 'not found');
        });
        Log::shouldReceive('error')->zeroOrMoreTimes();

        $result = $this->service->analyzeImage('non_existent_image.jpg');

        $this->assertIsArray($result);
        $this->assertArrayHasKey('success', $result);
        $this->assertFalse($result['success']);
    }

    public function test_analyze_image_with_api_key_calls_vision_api(): void
    {
        config(['services.google_vision.api_key' => 'test-api-key']);
        $service = new PrescriptionOcrService();

        Storage::fake('private');
        Storage::disk('private')->put('test_prescription.jpg', base64_decode('/9j/4AAQSkZJRg=='));

        Http::fake([
            'vision.googleapis.com/*' => Http::response([
                'responses' => [
                    [
                        'textAnnotations' => [
                            ['description' => 'Doliprane 500mg comprimé'],
                        ],
                        'fullTextAnnotation' => [
                            'text' => 'Doliprane 500mg comprimé',
                        ],
                    ],
                ],
            ], 200),
        ]);

        Log::shouldReceive('info')->zeroOrMoreTimes();
        Log::shouldReceive('debug')->zeroOrMoreTimes();
        Log::shouldReceive('warning')->zeroOrMoreTimes();
        Log::shouldReceive('error')->zeroOrMoreTimes();

        $result = $service->analyzeImage('test_prescription.jpg');

        $this->assertIsArray($result);
        $this->assertArrayHasKey('success', $result);
    }

    public function test_analyze_image_returns_error_when_api_fails(): void
    {
        config(['services.google_vision.api_key' => 'test-api-key']);
        $service = new PrescriptionOcrService();

        Storage::fake('private');
        Storage::disk('private')->put('test_prescription.jpg', base64_decode('/9j/4AAQSkZJRg=='));

        Http::fake([
            'vision.googleapis.com/*' => Http::response(['error' => 'Unauthorized'], 401),
        ]);

        Log::shouldReceive('error')->zeroOrMoreTimes();
        Log::shouldReceive('info')->zeroOrMoreTimes();
        Log::shouldReceive('debug')->zeroOrMoreTimes();
        Log::shouldReceive('warning')->zeroOrMoreTimes();

        $result = $service->analyzeImage('test_prescription.jpg');

        $this->assertIsArray($result);
        $this->assertFalse($result['success']);
        $this->assertStringContainsString('401', $result['error'] ?? '');
    }

    public function test_analyze_image_handles_empty_api_response(): void
    {
        config(['services.google_vision.api_key' => 'test-api-key']);
        $service = new PrescriptionOcrService();

        Storage::fake('private');
        Storage::disk('private')->put('test_prescription.jpg', base64_decode('/9j/4AAQSkZJRg=='));

        Http::fake([
            'vision.googleapis.com/*' => Http::response([
                'responses' => [],
            ], 200),
        ]);

        Log::shouldReceive('debug')->zeroOrMoreTimes();
        Log::shouldReceive('info')->zeroOrMoreTimes();
        Log::shouldReceive('warning')->zeroOrMoreTimes();
        Log::shouldReceive('error')->zeroOrMoreTimes();

        $result = $service->analyzeImage('test_prescription.jpg');

        $this->assertIsArray($result);
        $this->assertFalse($result['success']);
    }

    public function test_analyze_image_handles_vision_api_error_response(): void
    {
        config(['services.google_vision.api_key' => 'test-api-key']);
        $service = new PrescriptionOcrService();

        Storage::fake('private');
        Storage::disk('private')->put('test_prescription.jpg', base64_decode('/9j/4AAQSkZJRg=='));

        Http::fake([
            'vision.googleapis.com/*' => Http::response([
                'responses' => [
                    [
                        'error' => [
                            'code' => 400,
                            'message' => 'Image is too large',
                        ],
                    ],
                ],
            ], 200),
        ]);

        Log::shouldReceive('debug')->zeroOrMoreTimes();
        Log::shouldReceive('info')->zeroOrMoreTimes();
        Log::shouldReceive('warning')->zeroOrMoreTimes();
        Log::shouldReceive('error')->zeroOrMoreTimes();

        $result = $service->analyzeImage('test_prescription.jpg');

        $this->assertIsArray($result);
        $this->assertFalse($result['success']);
        $this->assertStringContainsString('Image is too large', $result['error'] ?? '');
    }

    public function test_analyze_image_returns_success_with_no_text(): void
    {
        config(['services.google_vision.api_key' => 'test-api-key']);
        $service = new PrescriptionOcrService();

        Storage::fake('private');
        Storage::disk('private')->put('test_prescription.jpg', base64_decode('/9j/4AAQSkZJRg=='));

        Http::fake([
            'vision.googleapis.com/*' => Http::response([
                'responses' => [
                    [
                        'textAnnotations' => [],
                        'fullTextAnnotation' => ['text' => ''],
                    ],
                ],
            ], 200),
        ]);

        Log::shouldReceive('debug')->zeroOrMoreTimes();
        Log::shouldReceive('info')->zeroOrMoreTimes();
        Log::shouldReceive('warning')->zeroOrMoreTimes();
        Log::shouldReceive('error')->zeroOrMoreTimes();

        $result = $service->analyzeImage('test_prescription.jpg');

        $this->assertIsArray($result);
        $this->assertTrue($result['success']);
        $this->assertEmpty($result['medications']);
    }

    public function test_analyze_image_extracts_medications_from_text(): void
    {
        config(['services.google_vision.api_key' => 'test-api-key']);
        $service = new PrescriptionOcrService();

        Storage::fake('private');
        Storage::disk('private')->put('prescription.jpg', base64_decode('/9j/4AAQSkZJRg=='));

        Http::fake([
            'vision.googleapis.com/*' => Http::response([
                'responses' => [
                    [
                        'textAnnotations' => [
                            ['description' => "Doliprane 500mg\n3 comprimés par jour\nAmoxicilline 1g\n2 gélules matin et soir"],
                        ],
                        'fullTextAnnotation' => [
                            'text' => "Doliprane 500mg\n3 comprimés par jour\nAmoxicilline 1g\n2 gélules matin et soir",
                        ],
                    ],
                ],
            ], 200),
        ]);

        Log::shouldReceive('info')->zeroOrMoreTimes();
        Log::shouldReceive('debug')->zeroOrMoreTimes();
        Log::shouldReceive('warning')->zeroOrMoreTimes();
        Log::shouldReceive('error')->zeroOrMoreTimes();

        $result = $service->analyzeImage('prescription.jpg');

        $this->assertIsArray($result);
        $this->assertTrue($result['success']);
        $this->assertNotEmpty($result['medications']);
    }

    public function test_analyze_image_returns_raw_text(): void
    {
        config(['services.google_vision.api_key' => 'test-api-key']);
        $service = new PrescriptionOcrService();

        Storage::fake('private');
        Storage::disk('private')->put('prescription.jpg', base64_decode('/9j/4AAQSkZJRg=='));

        $rawText = 'Doliprane 500mg comprimé';

        Http::fake([
            'vision.googleapis.com/*' => Http::response([
                'responses' => [
                    [
                        'textAnnotations' => [
                            ['description' => $rawText],
                        ],
                        'fullTextAnnotation' => ['text' => $rawText],
                    ],
                ],
            ], 200),
        ]);

        Log::shouldReceive('info')->zeroOrMoreTimes();
        Log::shouldReceive('debug')->zeroOrMoreTimes();
        Log::shouldReceive('warning')->zeroOrMoreTimes();
        Log::shouldReceive('error')->zeroOrMoreTimes();

        $result = $service->analyzeImage('prescription.jpg');

        $this->assertArrayHasKey('raw_text', $result);
        $this->assertStringContainsString('Doliprane', $result['raw_text']);
    }

    public function test_analyzes_image_from_absolute_path(): void
    {
        config(['services.google_vision.api_key' => 'test-api-key']);
        $service = new PrescriptionOcrService();

        $tmpFile = tempnam(sys_get_temp_dir(), 'ocr_test_') . '.jpg';
        file_put_contents($tmpFile, base64_decode('/9j/4AAQSkZJRg=='));

        Http::fake([
            'vision.googleapis.com/*' => Http::response([
                'responses' => [
                    [
                        'fullTextAnnotation' => ['text' => 'Paracétamol 1g comprimé'],
                        'textAnnotations' => [
                            ['description' => 'Paracétamol 1g comprimé'],
                        ],
                    ],
                ],
            ], 200),
        ]);

        Log::shouldReceive('info')->zeroOrMoreTimes();
        Log::shouldReceive('debug')->zeroOrMoreTimes();
        Log::shouldReceive('warning')->zeroOrMoreTimes();
        Log::shouldReceive('error')->zeroOrMoreTimes();

        $result = $service->analyzeImage($tmpFile);

        $this->assertIsArray($result);

        if (file_exists($tmpFile)) {
            unlink($tmpFile);
        }
    }

    public function test_analyze_image_without_credentials_returns_error(): void
    {
        config(['services.google_vision.api_key' => null]);
        $service = new PrescriptionOcrService();

        Storage::fake('private');
        Storage::disk('private')->put('prescription.jpg', base64_decode('/9j/4AAQSkZJRg=='));

        Log::shouldReceive('warning')->zeroOrMoreTimes();
        Log::shouldReceive('error')->zeroOrMoreTimes();

        $result = $service->analyzeImage('prescription.jpg');

        $this->assertIsArray($result);
        $this->assertArrayHasKey('success', $result);
        $this->assertFalse($result['success']);
    }
}
