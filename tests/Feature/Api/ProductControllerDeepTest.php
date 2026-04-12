<?php

namespace Tests\Feature\Api;

use App\Models\Category;
use App\Models\Pharmacy;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

/**
 * Deep tests for ProductController
 * @group deep
 */
class ProductControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    protected Pharmacy $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();

        $this->pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
    }

    // ==================== INDEX ====================

    #[Test]
    public function index_respects_per_page_parameter()
    {
        Product::factory()->count(15)->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
        ]);

        $response = $this->getJson('/api/products?per_page=5');

        $response->assertOk();
        $this->assertEquals(5, $response->json('data.pagination.per_page'));
        $this->assertCount(5, $response->json('data.products'));
    }

    #[Test]
    public function index_sorts_by_price_ascending()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'price' => 5000,
        ]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'price' => 1000,
        ]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'price' => 3000,
        ]);

        $response = $this->getJson('/api/products?sort_by=price&sort_order=asc');

        $response->assertOk();
        $prices = array_column($response->json('data.products'), 'price');
        $this->assertEquals($prices, array_values(array_map('floatval', $prices)));
        // Check sorting
        $this->assertTrue($prices[0] <= $prices[1]);
    }

    #[Test]
    public function index_sorts_by_price_descending()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'price' => 1000,
        ]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'price' => 5000,
        ]);

        $response = $this->getJson('/api/products?sort_by=price&sort_order=desc');

        $response->assertOk();
        $prices = array_column($response->json('data.products'), 'price');
        $this->assertTrue($prices[0] >= $prices[1]);
    }

    #[Test]
    public function index_sorts_by_name()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'name' => 'Zinc Supplement',
        ]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'name' => 'Aspirin',
        ]);

        $response = $this->getJson('/api/products?sort_by=name&sort_order=asc');

        $response->assertOk();
        $names = array_column($response->json('data.products'), 'name');
        $this->assertEquals('Aspirin', $names[0]);
    }

    #[Test]
    public function index_ignores_invalid_sort_field()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
        ]);

        // Invalid sort field should fall back to created_at DESC
        $response = $this->getJson('/api/products?sort_by=invalid_field');

        $response->assertOk();
    }

    #[Test]
    public function index_filters_by_min_price()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'price' => 500,
        ]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'price' => 2000,
        ]);

        $response = $this->getJson('/api/products?min_price=1000');

        $response->assertOk();
        $this->assertCount(1, $response->json('data.products'));
    }

    #[Test]
    public function index_filters_by_max_price()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'price' => 500,
        ]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'price' => 2000,
        ]);

        $response = $this->getJson('/api/products?max_price=1000');

        $response->assertOk();
        $this->assertCount(1, $response->json('data.products'));
    }

    #[Test]
    public function index_filters_by_price_range()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'price' => 500,
        ]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'price' => 1500,
        ]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'price' => 3000,
        ]);

        $response = $this->getJson('/api/products?min_price=1000&max_price=2000');

        $response->assertOk();
        $this->assertCount(1, $response->json('data.products'));
    }

    #[Test]
    public function index_filters_requires_prescription_true()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'requires_prescription' => true,
        ]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'requires_prescription' => false,
        ]);

        $response = $this->getJson('/api/products?requires_prescription=true');

        $response->assertOk();
        foreach ($response->json('data.products') as $product) {
            $this->assertTrue((bool) $product['requires_prescription']);
        }
    }

    #[Test]
    public function index_filters_requires_prescription_false()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'requires_prescription' => true,
        ]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'requires_prescription' => false,
        ]);

        $response = $this->getJson('/api/products?requires_prescription=false');

        $response->assertOk();
        foreach ($response->json('data.products') as $product) {
            $this->assertFalse((bool) $product['requires_prescription']);
        }
    }

    #[Test]
    public function index_only_returns_available_products()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
        ]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => false,
        ]);

        $response = $this->getJson('/api/products');

        $response->assertOk();
        $this->assertCount(1, $response->json('data.products'));
    }

    #[Test]
    public function index_includes_category_relation()
    {
        $category = Category::factory()->create(['is_active' => true]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'category_id' => $category->id,
            'is_available' => true,
        ]);

        $response = $this->getJson('/api/products');

        $response->assertOk();
        $this->assertNotNull($response->json('data.products.0.category'));
    }

    #[Test]
    public function index_includes_pharmacy_relation()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
        ]);

        $response = $this->getJson('/api/products');

        $response->assertOk();
        $this->assertNotNull($response->json('data.products.0.pharmacy'));
    }

    // ==================== FEATURED ====================

    #[Test]
    public function featured_respects_limit_parameter()
    {
        Product::factory()->count(10)->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'is_featured' => true,
        ]);

        $response = $this->getJson('/api/products/featured?limit=3');

        $response->assertOk();
        $this->assertCount(3, $response->json('data'));
    }

    #[Test]
    public function featured_only_returns_featured_products()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'is_featured' => true,
        ]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'is_featured' => false,
        ]);

        $response = $this->getJson('/api/products/featured');

        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
    }

    #[Test]
    public function featured_only_returns_available_products()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'is_featured' => true,
        ]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => false,
            'is_featured' => true,
        ]);

        $response = $this->getJson('/api/products/featured');

        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
    }

    // ==================== CATEGORIES ====================

    #[Test]
    public function categories_returns_active_categories()
    {
        Category::factory()->create(['is_active' => true, 'name' => 'Active']);
        Category::factory()->create(['is_active' => false, 'name' => 'Inactive']);

        $response = $this->getJson('/api/products/categories');

        $response->assertOk();
        $names = array_column($response->json('data'), 'name');
        $this->assertContains('Active', $names);
        $this->assertNotContains('Inactive', $names);
    }

    #[Test]
    public function categories_orders_by_order_field()
    {
        Category::factory()->create(['is_active' => true, 'name' => 'C', 'order' => 3]);
        Category::factory()->create(['is_active' => true, 'name' => 'A', 'order' => 1]);
        Category::factory()->create(['is_active' => true, 'name' => 'B', 'order' => 2]);

        $response = $this->getJson('/api/products/categories');

        $response->assertOk();
        $names = array_column($response->json('data'), 'name');
        $this->assertEquals(['A', 'B', 'C'], $names);
    }

    // ==================== BY CATEGORY ====================

    #[Test]
    public function by_category_finds_by_slug()
    {
        $category = Category::factory()->create(['slug' => 'vitamins', 'is_active' => true]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'category_id' => $category->id,
            'is_available' => true,
        ]);

        $response = $this->getJson('/api/products/category/vitamins');

        $response->assertOk();
        $this->assertCount(1, $response->json('data.products'));
    }

    #[Test]
    public function by_category_finds_by_id()
    {
        $category = Category::factory()->create(['is_active' => true]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'category_id' => $category->id,
            'is_available' => true,
        ]);

        $response = $this->getJson("/api/products/category/{$category->id}");

        $response->assertOk();
        $this->assertCount(1, $response->json('data.products'));
    }

    #[Test]
    public function by_category_returns_paginated_results()
    {
        $category = Category::factory()->create(['slug' => 'medication', 'is_active' => true]);
        Product::factory()->count(25)->create([
            'pharmacy_id' => $this->pharmacy->id,
            'category_id' => $category->id,
            'is_available' => true,
        ]);

        $response = $this->getJson('/api/products/category/medication');

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'products',
                    'pagination' => ['current_page', 'last_page', 'per_page', 'total'],
                ],
            ]);
    }

    // ==================== SEARCH ====================

    #[Test]
    public function search_finds_by_description()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Generic Product',
            'description' => 'Contains aspirin for pain relief',
            'is_available' => true,
        ]);

        $response = $this->getJson('/api/products/search?q=aspirin');

        $response->assertOk();
        $this->assertGreaterThan(0, count($response->json('data.products')));
    }

    #[Test]
    public function search_finds_by_manufacturer()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Test Product',
            'manufacturer' => 'Sanofi Laboratories',
            'is_available' => true,
        ]);

        $response = $this->getJson('/api/products/search?q=sanofi');

        $response->assertOk();
        $this->assertGreaterThan(0, count($response->json('data.products')));
    }

    #[Test]
    public function search_finds_by_active_ingredient()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Generic Drug',
            'active_ingredient' => 'paracetamol',
            'is_available' => true,
        ]);

        $response = $this->getJson('/api/products/search?q=paracetamol');

        $response->assertOk();
        $this->assertGreaterThan(0, count($response->json('data.products')));
    }

    #[Test]
    public function search_validates_minimum_query_length()
    {
        $response = $this->getJson('/api/products/search?q=a');

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['q']);
    }

    #[Test]
    public function search_validates_maximum_query_length()
    {
        $response = $this->getJson('/api/products/search?q=' . str_repeat('a', 101));

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['q']);
    }

    #[Test]
    public function search_prioritizes_featured_products()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Test Medicine A',
            'is_available' => true,
            'is_featured' => false,
            'sales_count' => 100,
        ]);
        $featured = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Test Medicine B',
            'is_available' => true,
            'is_featured' => true,
            'sales_count' => 1,
        ]);

        $response = $this->getJson('/api/products/search?q=test medicine');

        $response->assertOk();
        $products = $response->json('data.products');
        if (count($products) >= 2) {
            $this->assertEquals($featured->id, $products[0]['id']);
        }
    }

    // ==================== SHOW ====================

    #[Test]
    public function show_increments_view_count()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'views_count' => 5,
        ]);

        $response = $this->getJson("/api/products/{$product->id}");

        $response->assertOk();
        $this->assertEquals(6, $response->json('data.product.views_count'));
    }

    #[Test]
    public function show_returns_404_for_unavailable_product()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => false,
        ]);

        $response = $this->getJson("/api/products/{$product->id}");

        $response->assertNotFound();
    }

    #[Test]
    public function show_includes_pharmacy_info()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
        ]);

        $response = $this->getJson("/api/products/{$product->id}");

        $response->assertOk();
        $this->assertNotNull($response->json('data.product.pharmacy'));
    }

    // ==================== SHOW BY SLUG ====================

    #[Test]
    public function show_by_slug_works()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'slug' => 'unique-product-slug',
            'is_available' => true,
        ]);

        $response = $this->getJson('/api/products/slug/unique-product-slug');

        $response->assertOk()
            ->assertJsonPath('data.product.id', $product->id);
    }

    #[Test]
    public function show_by_slug_increments_views()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'slug' => 'view-test-slug',
            'is_available' => true,
            'views_count' => 0,
        ]);

        $response = $this->getJson('/api/products/slug/view-test-slug');

        $response->assertOk();
        $this->assertEquals(1, $response->json('data.product.views_count'));
    }

    #[Test]
    public function show_by_slug_returns_404_for_nonexistent()
    {
        $response = $this->getJson('/api/products/slug/nonexistent-slug');

        $response->assertNotFound();
    }

    // ==================== COMPARE PRICES ====================

    #[Test]
    public function compare_prices_returns_alternatives()
    {
        $pharmacy2 = Pharmacy::factory()->create(['status' => 'approved']);

        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Doliprane 500mg',
            'price' => 2000,
            'is_available' => true,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $pharmacy2->id,
            'name' => 'Doliprane 500mg', // Same name
            'price' => 1500,
            'is_available' => true,
            'stock_quantity' => 10,
        ]);

        $response = $this->getJson("/api/products/{$product->id}/compare-prices");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'current' => ['id', 'name', 'price', 'pharmacy'],
                    'alternatives',
                    'has_alternatives',
                ],
            ]);
    }

    #[Test]
    public function compare_prices_finds_by_active_ingredient()
    {
        $pharmacy2 = Pharmacy::factory()->create(['status' => 'approved']);

        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Brand Paracetamol',
            'active_ingredient' => 'paracetamol',
            'price' => 2500,
            'is_available' => true,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $pharmacy2->id,
            'name' => 'Generic Paracetamol',
            'active_ingredient' => 'paracetamol', // Same ingredient
            'price' => 1000,
            'is_available' => true,
            'stock_quantity' => 10,
        ]);

        $response = $this->getJson("/api/products/{$product->id}/compare-prices");

        $response->assertOk();
        $this->assertTrue($response->json('data.has_alternatives'));
    }

    #[Test]
    public function compare_prices_excludes_out_of_stock()
    {
        $pharmacy2 = Pharmacy::factory()->create(['status' => 'approved']);

        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Test Product',
            'is_available' => true,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $pharmacy2->id,
            'name' => 'Test Product',
            'is_available' => true,
            'stock_quantity' => 0, // Out of stock
        ]);

        $response = $this->getJson("/api/products/{$product->id}/compare-prices");

        $response->assertOk();
        $this->assertFalse($response->json('data.has_alternatives'));
    }

    #[Test]
    public function compare_prices_excludes_unavailable()
    {
        $pharmacy2 = Pharmacy::factory()->create(['status' => 'approved']);

        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Test Product',
            'is_available' => true,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $pharmacy2->id,
            'name' => 'Test Product',
            'is_available' => false, // Not available
            'stock_quantity' => 10,
        ]);

        $response = $this->getJson("/api/products/{$product->id}/compare-prices");

        $response->assertOk();
        $this->assertFalse($response->json('data.has_alternatives'));
    }

    #[Test]
    public function compare_prices_excludes_same_pharmacy()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Test Product',
            'is_available' => true,
        ]);

        // Same pharmacy, different product
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id, // Same pharmacy
            'name' => 'Test Product',
            'is_available' => true,
            'stock_quantity' => 10,
        ]);

        $response = $this->getJson("/api/products/{$product->id}/compare-prices");

        $response->assertOk();
        $this->assertFalse($response->json('data.has_alternatives'));
    }

    #[Test]
    public function compare_prices_orders_by_price()
    {
        $pharmacy2 = Pharmacy::factory()->create(['status' => 'approved']);
        $pharmacy3 = Pharmacy::factory()->create(['status' => 'approved']);

        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Test Product',
            'price' => 3000,
            'is_available' => true,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $pharmacy2->id,
            'name' => 'Test Product',
            'price' => 2500,
            'is_available' => true,
            'stock_quantity' => 10,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $pharmacy3->id,
            'name' => 'Test Product',
            'price' => 1500,
            'is_available' => true,
            'stock_quantity' => 10,
        ]);

        $response = $this->getJson("/api/products/{$product->id}/compare-prices");

        $response->assertOk();
        $alternatives = $response->json('data.alternatives');
        if (count($alternatives) >= 2) {
            $this->assertTrue($alternatives[0]['price'] <= $alternatives[1]['price']);
        }
    }

    #[Test]
    public function compare_prices_limits_to_5_results()
    {
        // Create 7 different pharmacies with same product
        for ($i = 0; $i < 7; $i++) {
            $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
            Product::factory()->create([
                'pharmacy_id' => $pharmacy->id,
                'name' => 'Popular Drug',
                'price' => 1000 + ($i * 100),
                'is_available' => true,
                'stock_quantity' => 10,
            ]);
        }

        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Popular Drug',
            'price' => 5000,
            'is_available' => true,
        ]);

        $response = $this->getJson("/api/products/{$product->id}/compare-prices");

        $response->assertOk();
        $this->assertLessThanOrEqual(5, count($response->json('data.alternatives')));
    }

    #[Test]
    public function compare_prices_returns_404_for_nonexistent_product()
    {
        $response = $this->getJson('/api/products/99999/compare-prices');

        $response->assertNotFound();
    }

    // ==================== EDGE CASES ====================

    #[Test]
    public function index_handles_empty_products()
    {
        $response = $this->getJson('/api/products');

        $response->assertOk()
            ->assertJsonPath('success', true);
        $this->assertEmpty($response->json('data.products'));
    }

    #[Test]
    public function featured_handles_empty()
    {
        $response = $this->getJson('/api/products/featured');

        $response->assertOk();
        $this->assertEmpty($response->json('data'));
    }

    #[Test]
    public function categories_handles_empty()
    {
        $response = $this->getJson('/api/products/categories');

        $response->assertOk();
        $this->assertEmpty($response->json('data'));
    }

    #[Test]
    public function search_handles_no_results()
    {
        $response = $this->getJson('/api/products/search?q=nonexistenttermxyz');

        $response->assertOk();
        $this->assertEmpty($response->json('data.products'));
    }

    #[Test]
    public function compare_prices_handles_no_alternatives()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Unique Product No Match',
            'is_available' => true,
        ]);

        $response = $this->getJson("/api/products/{$product->id}/compare-prices");

        $response->assertOk()
            ->assertJsonPath('data.has_alternatives', false);
        $this->assertEmpty($response->json('data.alternatives'));
    }
}
