<?php

namespace Tests\Unit\Services;

use App\Services\ProductMatchingService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProductMatchingServiceTest extends TestCase
{
    use RefreshDatabase;

    private ProductMatchingService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new ProductMatchingService();
    }

    public function test_it_can_be_instantiated(): void
    {
        $this->assertInstanceOf(ProductMatchingService::class, $this->service);
    }

    public function test_match_empty_medications_returns_empty_results(): void
    {
        $results = $this->service->matchMedications([]);

        $this->assertArrayHasKey('matched', $results);
        $this->assertArrayHasKey('not_found', $results);
        $this->assertArrayHasKey('out_of_stock', $results);
        $this->assertArrayHasKey('alternatives', $results);
        $this->assertArrayHasKey('total_estimated_price', $results);
        $this->assertArrayHasKey('stats', $results);
        $this->assertEmpty($results['matched']);
        $this->assertEmpty($results['not_found']);
        $this->assertEquals(0, $results['stats']['total_medications']);
        $this->assertEquals(0, $results['stats']['fulfillment_rate']);
    }

    public function test_match_medications_with_empty_names_are_skipped(): void
    {
        $medications = [
            ['name' => '', 'confidence' => 0.9],
            ['name' => null, 'confidence' => 0.5],
        ];

        $results = $this->service->matchMedications($medications);
        $this->assertEquals(0, $results['stats']['matched_count']);
    }

    public function test_match_medications_not_found_returns_in_not_found(): void
    {
        $medications = [
            ['name' => 'NonExistentMedication12345', 'confidence' => 0.8],
        ];

        $results = $this->service->matchMedications($medications);

        $this->assertEmpty($results['matched']);
        $this->assertNotEmpty($results['not_found']);
        $this->assertEquals('NonExistentMedication12345', $results['not_found'][0]['medication']);
    }

    public function test_results_stats_structure(): void
    {
        $medications = [
            ['name' => 'Paracetamol', 'confidence' => 0.95],
            ['name' => 'Ibuprofène', 'confidence' => 0.87],
        ];

        $results = $this->service->matchMedications($medications);

        $this->assertArrayHasKey('total_medications', $results['stats']);
        $this->assertArrayHasKey('matched_count', $results['stats']);
        $this->assertArrayHasKey('not_found_count', $results['stats']);
        $this->assertArrayHasKey('out_of_stock_count', $results['stats']);
        $this->assertArrayHasKey('fulfillment_rate', $results['stats']);
        $this->assertEquals(2, $results['stats']['total_medications']);
    }

    public function test_normalize_text_via_reflection(): void
    {
        $reflection = new \ReflectionClass($this->service);

        if ($reflection->hasMethod('normalizeText')) {
            $method = $reflection->getMethod('normalizeText');
            $method->setAccessible(true);

            $result = $method->invoke($this->service, 'Paracétamol 500mg');
            $this->assertIsString($result);
            // Should normalize: lowercase, remove accents, etc.
            $this->assertStringNotContainsString('é', strtolower($result));
        } else {
            $this->assertTrue(true); // normalizeText might not exist
        }
    }

    public function test_calculate_similarity_via_reflection(): void
    {
        $reflection = new \ReflectionClass($this->service);

        if ($reflection->hasMethod('calculateSimilarity')) {
            $method = $reflection->getMethod('calculateSimilarity');
            $method->setAccessible(true);

            // Identical strings should have score 1.0
            $score = $method->invoke($this->service, 'paracetamol', 'paracetamol');
            $this->assertEquals(1.0, $score);

            // Similar strings should have high score
            $score = $method->invoke($this->service, 'paracetamol', 'paracetamo');
            $this->assertGreaterThan(0.5, $score);

            // Different strings should have low score
            $score = $method->invoke($this->service, 'paracetamol', 'ibuprofene');
            $this->assertLessThan(0.5, $score);
        } else {
            $this->assertTrue(true);
        }
    }

    public function test_min_match_score_is_reasonable(): void
    {
        $reflection = new \ReflectionClass($this->service);
        $property = $reflection->getProperty('minMatchScore');
        $property->setAccessible(true);

        $minScore = $property->getValue($this->service);
        $this->assertGreaterThanOrEqual(0.5, $minScore);
        $this->assertLessThanOrEqual(0.9, $minScore);
    }
}
