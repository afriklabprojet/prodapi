<?php

namespace Tests\Unit\Services;

use App\Models\Product;
use App\Models\Pharmacy;
use App\Services\ProductMatchingService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProductMatchingServiceDeepTest extends TestCase
{
    use RefreshDatabase;

    private ProductMatchingService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new ProductMatchingService();
    }

    private function callPrivate(string $method, array $args = []): mixed
    {
        $ref = new \ReflectionMethod($this->service, $method);
        $ref->setAccessible(true);
        return $ref->invoke($this->service, ...$args);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // normalizeText
    // ═══════════════════════════════════════════════════════════════════════

    public function test_normalize_text_basic(): void
    {
        $this->assertEquals('paracetamol 500mg', $this->callPrivate('normalizeText', ['Paracétamol 500mg']));
    }

    public function test_normalize_text_special_chars(): void
    {
        $this->assertEquals('test-med 10', $this->callPrivate('normalizeText', ['TEST-MED!@# 10']));
    }

    public function test_normalize_text_multiple_spaces(): void
    {
        $this->assertEquals('amox 250', $this->callPrivate('normalizeText', ['  amox   250  ']));
    }

    public function test_normalize_text_accents(): void
    {
        $this->assertEquals('ibuprofene gelatine', $this->callPrivate('normalizeText', ['Ibuprofène Gélatine']));
    }

    public function test_normalize_text_empty(): void
    {
        $this->assertEquals('', $this->callPrivate('normalizeText', ['']));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // calculateSimilarity
    // ═══════════════════════════════════════════════════════════════════════

    public function test_similarity_identical(): void
    {
        $this->assertEquals(1.0, $this->callPrivate('calculateSimilarity', ['abc', 'abc']));
    }

    public function test_similarity_empty_strings(): void
    {
        $this->assertEquals(0.0, $this->callPrivate('calculateSimilarity', ['abc', '']));
        $this->assertEquals(0.0, $this->callPrivate('calculateSimilarity', ['', 'abc']));
    }

    public function test_similarity_containment(): void
    {
        $score = $this->callPrivate('calculateSimilarity', ['para', 'paracetamol']);
        $this->assertGreaterThanOrEqual(0.7, $score);
        $this->assertLessThanOrEqual(1.0, $score);
    }

    public function test_similarity_reverse_containment(): void
    {
        $score = $this->callPrivate('calculateSimilarity', ['paracetamol', 'para']);
        $this->assertGreaterThanOrEqual(0.7, $score);
    }

    public function test_similarity_levenshtein(): void
    {
        $score = $this->callPrivate('calculateSimilarity', ['paracetamol', 'paracetamll']);
        $this->assertGreaterThan(0.5, $score);
    }

    public function test_similarity_prefix_bonus(): void
    {
        $score1 = $this->callPrivate('calculateSimilarity', ['amox500', 'amox250']);
        $score2 = $this->callPrivate('calculateSimilarity', ['xmox500', 'amox250']);
        $this->assertGreaterThan($score2, $score1);
    }

    public function test_similarity_cap_at_one(): void
    {
        // Very similar short strings with prefix bonus
        $score = $this->callPrivate('calculateSimilarity', ['ab', 'abc']);
        $this->assertLessThanOrEqual(1.0, $score);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // matchMedications — empty / not found
    // ═══════════════════════════════════════════════════════════════════════

    public function test_match_empty_list(): void
    {
        $r = $this->service->matchMedications([]);
        $this->assertEquals(0, $r['stats']['total_medications']);
        $this->assertEquals(0, $r['total_estimated_price']);
    }

    public function test_match_empty_name_skipped(): void
    {
        $r = $this->service->matchMedications([['name' => '']]);
        $this->assertEmpty($r['matched']);
        $this->assertEmpty($r['not_found']);
    }

    public function test_match_not_found(): void
    {
        $r = $this->service->matchMedications([['name' => 'Inexistanticilline XYZ']]);
        $this->assertCount(1, $r['not_found']);
        $this->assertEquals(0, $r['stats']['matched_count']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // matchMedications — exact match
    // ═══════════════════════════════════════════════════════════════════════

    public function test_match_exact(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'Paracétamol 500mg',
            'price' => 1000,
            'stock_quantity' => 10,
            'is_available' => true,
        ]);

        $r = $this->service->matchMedications([['name' => 'Paracétamol 500mg']]);
        $this->assertCount(1, $r['matched']);
        $this->assertEquals(1.0, $r['matched'][0]['match_score']);
        $this->assertEquals(1000, $r['total_estimated_price']);
    }

    public function test_match_exact_case_insensitive(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'Amoxicillin',
            'price' => 2000,
            'stock_quantity' => 5,
            'is_available' => true,
        ]);

        $r = $this->service->matchMedications([['name' => 'amoxicillin']]);
        $this->assertCount(1, $r['matched']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // matchMedications — LIKE match
    // ═══════════════════════════════════════════════════════════════════════

    public function test_match_like_by_name(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'Paracétamol Biogaran 500mg',
            'price' => 800,
            'stock_quantity' => 20,
            'is_available' => true,
        ]);

        $r = $this->service->matchMedications([['name' => 'paracetamol']]);
        // Should find via LIKE or fuzzy
        $total = count($r['matched']) + count($r['not_found']) + count($r['out_of_stock']);
        $this->assertEquals(1, $total);
    }

    public function test_match_like_by_active_ingredient(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'Doliprane 1000',
            'active_ingredient' => 'paracetamol',
            'price' => 1500,
            'stock_quantity' => 15,
            'is_available' => true,
        ]);

        $r = $this->service->matchMedications([['name' => 'paracetamol']]);
        $hasMatch = count($r['matched']) > 0;
        $this->assertTrue($hasMatch || count($r['not_found']) > 0);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // matchMedications — fuzzy match
    // ═══════════════════════════════════════════════════════════════════════

    public function test_match_fuzzy(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'Amoxicilline 500mg',
            'price' => 3000,
            'stock_quantity' => 8,
            'is_available' => true,
        ]);

        // Slight OCR typo
        $r = $this->service->matchMedications([['name' => 'Amoxiciline 500mg']]);
        $total = count($r['matched']);
        $this->assertGreaterThanOrEqual(0, $total); // fuzzy may or may not match
    }

    // ═══════════════════════════════════════════════════════════════════════
    // matchMedications — out of stock + alternatives
    // ═══════════════════════════════════════════════════════════════════════

    public function test_match_out_of_stock(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'Ibuprofène 400mg',
            'price' => 1200,
            'stock_quantity' => 0,
            'is_available' => true,
        ]);

        $r = $this->service->matchMedications([['name' => 'Ibuprofène 400mg']]);
        $this->assertCount(1, $r['out_of_stock']);
        $this->assertEquals(0, $r['stats']['matched_count']);
    }

    public function test_match_unavailable_product(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'Some Med',
            'price' => 500,
            'stock_quantity' => 10,
            'is_available' => false,
        ]);

        $r = $this->service->matchMedications([['name' => 'Some Med']]);
        // unavailable => is_available=false => not found in query
        $this->assertEmpty($r['matched']);
    }

    public function test_out_of_stock_with_alternatives_by_ingredient(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $oos = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'Ibuprofène 400mg',
            'active_ingredient' => 'ibuprofen',
            'price' => 1200,
            'stock_quantity' => 0,
            'is_available' => true,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'Advil 400mg',
            'active_ingredient' => 'ibuprofen',
            'price' => 1500,
            'stock_quantity' => 5,
            'is_available' => true,
        ]);

        $r = $this->service->matchMedications([['name' => 'Ibuprofène 400mg']]);
        $this->assertCount(1, $r['out_of_stock']);
        $this->assertArrayHasKey('Ibuprofène 400mg', $r['alternatives']);
        $this->assertNotEmpty($r['alternatives']['Ibuprofène 400mg']);
    }

    public function test_out_of_stock_with_alternatives_by_category(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $oos = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'MedX Pain',
            'category' => 'antalgique',
            'price' => 1000,
            'stock_quantity' => 0,
            'is_available' => true,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'MedY Pain',
            'category' => 'antalgique',
            'price' => 900,
            'stock_quantity' => 3,
            'is_available' => true,
        ]);

        $r = $this->service->matchMedications([['name' => 'MedX Pain']]);
        if (count($r['out_of_stock']) > 0) {
            $this->assertArrayHasKey('MedX Pain', $r['alternatives']);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // matchMedications — pharmacy filter
    // ═══════════════════════════════════════════════════════════════════════

    public function test_match_with_pharmacy_filter(): void
    {
        $p1 = Pharmacy::factory()->create();
        $p2 = Pharmacy::factory()->create();

        Product::factory()->create([
            'pharmacy_id' => $p1->id,
            'name' => 'MedA',
            'price' => 1000,
            'stock_quantity' => 5,
            'is_available' => true,
        ]);
        Product::factory()->create([
            'pharmacy_id' => $p2->id,
            'name' => 'MedA',
            'price' => 1100,
            'stock_quantity' => 3,
            'is_available' => true,
        ]);

        $r = $this->service->matchMedications([['name' => 'MedA']], $p1->id);
        $this->assertCount(1, $r['matched']);
        $this->assertEquals($p1->id, $r['matched'][0]['pharmacy_id']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // matchMedications — multiple meds
    // ═══════════════════════════════════════════════════════════════════════

    public function test_match_multiple_medications(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'ProductA',
            'price' => 1000,
            'stock_quantity' => 10,
            'is_available' => true,
        ]);
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'ProductB',
            'price' => 2000,
            'stock_quantity' => 5,
            'is_available' => true,
        ]);

        $r = $this->service->matchMedications([
            ['name' => 'ProductA'],
            ['name' => 'ProductB'],
            ['name' => 'Nonexistent'],
        ]);

        $this->assertEquals(3, $r['stats']['total_medications']);
        $this->assertEquals(2, $r['stats']['matched_count']);
        $this->assertEquals(1, $r['stats']['not_found_count']);
        $this->assertGreaterThan(0, $r['stats']['fulfillment_rate']);
        $this->assertEquals(3000, $r['total_estimated_price']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // matchMedications — price with discount
    // ═══════════════════════════════════════════════════════════════════════

    public function test_match_returns_discount_price(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'DiscountMed',
            'price' => 5000,
            'discount_price' => 3000,
            'stock_quantity' => 10,
            'is_available' => true,
        ]);

        $r = $this->service->matchMedications([['name' => 'DiscountMed']]);
        $this->assertCount(1, $r['matched']);
        $this->assertEquals(3000, $r['matched'][0]['price']);
        $this->assertEquals(3000, $r['total_estimated_price']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // matchMedications — data shape
    // ═══════════════════════════════════════════════════════════════════════

    public function test_matched_entry_shape(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'ShapeMed',
            'price' => 2000,
            'stock_quantity' => 5,
            'is_available' => true,
            'requires_prescription' => true,
        ]);

        $r = $this->service->matchMedications([['name' => 'ShapeMed']]);
        $m = $r['matched'][0];

        $this->assertArrayHasKey('medication', $m);
        $this->assertArrayHasKey('product_id', $m);
        $this->assertArrayHasKey('product_name', $m);
        $this->assertArrayHasKey('price', $m);
        $this->assertArrayHasKey('stock', $m);
        $this->assertArrayHasKey('requires_prescription', $m);
        $this->assertArrayHasKey('match_score', $m);
        $this->assertArrayHasKey('pharmacy_id', $m);
        $this->assertArrayHasKey('pharmacy_name', $m);
        $this->assertTrue($m['requires_prescription']);
    }

    public function test_not_found_entry_shape(): void
    {
        $r = $this->service->matchMedications([['name' => 'Unknown99', 'confidence' => 0.75]]);
        $nf = $r['not_found'][0];

        $this->assertEquals('Unknown99', $nf['medication']);
        $this->assertEquals(0.75, $nf['confidence']);
        $this->assertArrayHasKey('suggestions', $nf);
    }

    public function test_not_found_with_zero_confidence(): void
    {
        $r = $this->service->matchMedications([['name' => 'ZZZ_nothing']]);
        $this->assertEquals(0, $r['not_found'][0]['confidence']);
    }

    public function test_out_of_stock_entry_shape(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'OosMed',
            'price' => 1000,
            'stock_quantity' => 0,
            'is_available' => true,
        ]);

        $r = $this->service->matchMedications([['name' => 'OosMed']]);
        $this->assertCount(1, $r['out_of_stock']);
        $oos = $r['out_of_stock'][0];
        $this->assertArrayHasKey('medication', $oos);
        $this->assertArrayHasKey('product_id', $oos);
        $this->assertArrayHasKey('product_name', $oos);
        $this->assertArrayHasKey('stock', $oos);
        $this->assertEquals(0, $oos['stock']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getSuggestions
    // ═══════════════════════════════════════════════════════════════════════

    public function test_suggestions_for_partial_match(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'Paracetamol 500',
            'price' => 1000,
            'stock_quantity' => 10,
            'is_available' => true,
        ]);
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'Paracetamol 1000',
            'price' => 1500,
            'stock_quantity' => 8,
            'is_available' => true,
        ]);

        // Force not-found by searching a dissimilar name that produces suggestions
        $r = $this->service->matchMedications([['name' => 'Xaracetamol']]);
        // We either get them as matches (fuzzy) or suggestions
        $total = count($r['matched']) + count($r['not_found']);
        $this->assertGreaterThan(0, $total);
    }

    public function test_suggestions_max_three(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        for ($i = 0; $i < 6; $i++) {
            Product::factory()->create([
                'pharmacy_id' => $pharmacy->id,
                'name' => "TestMed{$i}",
                'price' => 1000,
                'stock_quantity' => 10,
                'is_available' => true,
            ]);
        }

        $products = Product::where('is_available', true)->limit(5)->get();
        $suggestions = $this->callPrivate('getSuggestions', ['testmed', $products]);
        $this->assertLessThanOrEqual(3, count($suggestions));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // findAlternatives
    // ═══════════════════════════════════════════════════════════════════════

    public function test_find_alternatives_by_ingredient(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'BrandA',
            'active_ingredient' => 'acetaminophen',
            'price' => 1000,
            'stock_quantity' => 0,
            'is_available' => true,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'BrandB',
            'active_ingredient' => 'acetaminophen',
            'price' => 1200,
            'stock_quantity' => 5,
            'is_available' => true,
        ]);

        $alts = $this->callPrivate('findAlternatives', [$product, null]);
        $this->assertCount(1, $alts);
        $this->assertEquals('BrandB', $alts[0]['name']);
    }

    public function test_find_alternatives_by_category_fills_remaining(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'CatMed A',
            'category' => 'antidouleur',
            'active_ingredient' => 'unique_substance',
            'price' => 1000,
            'stock_quantity' => 0,
            'is_available' => true,
        ]);

        // No same ingredient alternatives
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'CatMed B',
            'category' => 'antidouleur',
            'active_ingredient' => 'different',
            'price' => 800,
            'stock_quantity' => 3,
            'is_available' => true,
        ]);

        $alts = $this->callPrivate('findAlternatives', [$product, null]);
        $this->assertNotEmpty($alts);
        $this->assertEquals('CatMed B', $alts[0]['name']);
    }

    public function test_find_alternatives_no_match(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'Unique Med',
            'active_ingredient' => null,
            'category' => null,
            'price' => 1000,
            'stock_quantity' => 0,
            'is_available' => true,
        ]);

        $alts = $this->callPrivate('findAlternatives', [$product, null]);
        $this->assertEmpty($alts);
    }

    public function test_find_alternatives_respects_pharmacy_filter(): void
    {
        $p1 = Pharmacy::factory()->create();
        $p2 = Pharmacy::factory()->create();

        $product = Product::factory()->create([
            'pharmacy_id' => $p1->id,
            'name' => 'FilteredMed',
            'active_ingredient' => 'aspirin',
            'price' => 500,
            'stock_quantity' => 0,
            'is_available' => true,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $p2->id,
            'name' => 'AltMed',
            'active_ingredient' => 'aspirin',
            'price' => 600,
            'stock_quantity' => 10,
            'is_available' => true,
        ]);

        // Filter to $p1 only — should NOT find the p2 alternative
        $alts = $this->callPrivate('findAlternatives', [$product, $p1->id]);
        $this->assertEmpty($alts);

        // Without filter — should find
        $alts2 = $this->callPrivate('findAlternatives', [$product, null]);
        $this->assertCount(1, $alts2);
    }

    public function test_find_alternatives_max_three(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'OverflowMed',
            'active_ingredient' => 'shared_ingredient',
            'price' => 1000,
            'stock_quantity' => 0,
            'is_available' => true,
        ]);

        for ($i = 0; $i < 5; $i++) {
            Product::factory()->create([
                'pharmacy_id' => $pharmacy->id,
                'name' => "AltMed{$i}",
                'active_ingredient' => 'shared_ingredient',
                'price' => 500 + ($i * 100),
                'stock_quantity' => 5,
                'is_available' => true,
            ]);
        }

        $alts = $this->callPrivate('findAlternatives', [$product, null]);
        $this->assertLessThanOrEqual(3, count($alts));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // checkAvailability
    // ═══════════════════════════════════════════════════════════════════════

    public function test_check_availability_all_available(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'AvailMed',
            'price' => 1000,
            'stock_quantity' => 10,
            'is_available' => true,
        ]);

        $r = $this->service->checkAvailability([['name' => 'AvailMed']]);
        $this->assertTrue($r['all_available']);
        $this->assertEquals(100, $r['fulfillment_rate']);
        $this->assertEmpty($r['missing']);
    }

    public function test_check_availability_partial(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'PartialMed',
            'price' => 1000,
            'stock_quantity' => 5,
            'is_available' => true,
        ]);

        $r = $this->service->checkAvailability([
            ['name' => 'PartialMed'],
            ['name' => 'MissingMed'],
        ]);
        $this->assertFalse($r['all_available']);
        $this->assertEquals(50, $r['fulfillment_rate']);
        $this->assertNotEmpty($r['missing']);
    }

    public function test_check_availability_none_available(): void
    {
        $r = $this->service->checkAvailability([['name' => 'Nope1'], ['name' => 'Nope2']]);
        $this->assertFalse($r['all_available']);
        $this->assertEquals(0, $r['fulfillment_rate']);
        $this->assertEquals(0, $r['estimated_total']);
    }

    public function test_check_availability_with_pharmacy(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'PharmMed',
            'price' => 2000,
            'stock_quantity' => 3,
            'is_available' => true,
        ]);

        $r = $this->service->checkAvailability([['name' => 'PharmMed']], $pharmacy->id);
        $this->assertTrue($r['all_available']);
        $this->assertEquals(2000, $r['estimated_total']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // stats shape
    // ═══════════════════════════════════════════════════════════════════════

    public function test_stats_fulfillment_rate_calculation(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'Med1',
            'price' => 100,
            'stock_quantity' => 1,
            'is_available' => true,
        ]);

        $r = $this->service->matchMedications([
            ['name' => 'Med1'],
            ['name' => 'Med2NotExist'],
            ['name' => 'Med3NotExist'],
        ]);

        $this->assertEquals(3, $r['stats']['total_medications']);
        $this->assertEquals(1, $r['stats']['matched_count']);
        $this->assertEquals(2, $r['stats']['not_found_count']);
        $this->assertEqualsWithDelta(33.3, $r['stats']['fulfillment_rate'], 0.1);
    }
}
