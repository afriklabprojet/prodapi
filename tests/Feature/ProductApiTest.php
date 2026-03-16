<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Product;
use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

class ProductApiTest extends TestCase
{
    use RefreshDatabase;

    protected $pharmacy;
    protected $user;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->user = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
        ]);
        $this->pharmacy->users()->attach($this->user->id, ['role' => 'owner']);
    }

    /** @test */
    public function can_list_products_without_authentication()
    {
        Product::factory()->count(5)->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
        ]);

        $response = $this->getJson('/api/products');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    'products' => [
                        '*' => [
                            'id',
                            'name',
                            'slug',
                            'price',
                            'final_price',
                            'discount_percentage',
                            'stock_quantity',
                            'pharmacy' => ['id', 'name'],
                        ],
                    ],
                    'pagination',
                ],
            ]);
    }

    /** @test */
    public function can_search_products()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Paracetamol 500mg',
            'is_available' => true,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Ibuprofene 400mg',
            'is_available' => true,
        ]);

        $response = $this->getJson('/api/products/search?q=para');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data.products')
            ->assertJsonFragment(['name' => 'Paracetamol 500mg']);
    }

    /** @test */
    public function can_filter_by_category()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'category' => 'analgesics',
            'is_available' => true,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'category' => 'antibiotics',
            'is_available' => true,
        ]);

        $response = $this->getJson('/api/products/category/analgesics');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data.products')
            ->assertJsonFragment(['category' => 'analgesics']);
    }

    /** @test */
    public function can_get_all_categories()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'category' => 'analgesics',
        ]);

        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'category' => 'antibiotics',
        ]);

        $response = $this->getJson('/api/products/categories');

        $response->assertStatus(200)
            ->assertJsonCount(2);
    }

    /** @test */
    public function can_get_featured_products()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_featured' => true,
            'is_available' => true,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_featured' => false,
            'is_available' => true,
        ]);

        $response = $this->getJson('/api/products/featured');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data');
    }

    /** @test */
    public function can_get_product_by_id()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
        ]);

        $response = $this->getJson("/api/products/{$product->id}");

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'product' => [
                        'id' => $product->id,
                        'name' => $product->name,
                    ]
                ]
            ]);

        // Verify views are incremented
        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'views_count' => 1,
        ]);
    }

    /** @test */
    public function can_get_product_by_slug()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'slug' => 'test-product',
            'is_available' => true,
        ]);

        $response = $this->getJson("/api/products/slug/test-product");

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'product' => [
                        'slug' => 'test-product',
                    ]
                ]
            ]);
    }

    /** @test */
    public function product_not_found_returns_404()
    {
        $response = $this->getJson('/api/products/99999');

        $response->assertStatus(404);
    }

    /** @test */
    public function can_filter_by_pharmacy()
    {
        $otherPharmacy = Pharmacy::factory()->create();

        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'stock_quantity' => 10,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $otherPharmacy->id,
            'is_available' => true,
            'stock_quantity' => 10,
        ]);

        $response = $this->getJson("/api/products?pharmacy_id={$this->pharmacy->id}");

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data.products');
    }

    /** @test */
    public function can_filter_by_price_range()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'price' => 5000,
            'is_available' => true,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'price' => 15000,
            'is_available' => true,
        ]);

        $response = $this->getJson('/api/products?min_price=4000&max_price=10000');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data.products');
    }

    /** @test */
    public function can_filter_by_prescription_requirement()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'requires_prescription' => true,
            'is_available' => true,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'requires_prescription' => false,
            'is_available' => true,
        ]);

        $response = $this->getJson('/api/products?requires_prescription=false');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data.products');
    }

    /** @test */
    public function unavailable_products_are_not_listed()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => false,
        ]);

        $response = $this->getJson('/api/products');

        $response->assertStatus(200)
            ->assertJsonCount(0, 'data.products');
    }

    /** @test */
    public function out_of_stock_products_show_correct_status()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'stock_quantity' => 0,
            'is_available' => true,
        ]);

        $response = $this->getJson("/api/products/{$product->id}");

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'product' => [
                        'is_out_of_stock' => true,
                    ]
                ]
            ]);
    }

    /** @test */
    public function products_can_be_sorted()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Product A',
            'price' => 10000,
            'is_available' => true,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Product B',
            'price' => 5000,
            'is_available' => true,
        ]);

        $response = $this->getJson('/api/products?sort_by=price&sort_order=asc&pharmacy_id=' . $this->pharmacy->id);

        $response->assertStatus(200);
        
        $data = $response->json('data.products');
        $this->assertGreaterThanOrEqual(2, count($data));
        
        // Verify prices are in ascending order
        for ($i = 1; $i < count($data); $i++) {
            $this->assertGreaterThanOrEqual($data[$i - 1]['price'], $data[$i]['price']);
        }
    }

    /** @test */
    public function discount_price_is_correctly_calculated()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'price' => 10000,
            'discount_price' => 8000,
            'is_available' => true,
        ]);

        $response = $this->getJson("/api/products/{$product->id}");

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'product' => [
                        'price' => 10000,
                        'discount_price' => 8000,
                        'final_price' => 8000,
                        'discount_percentage' => 20,
                    ]
                ]
            ]);
    }

    /** @test */
    public function expired_products_show_warning()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'expiry_date' => now()->subDays(1)->format('Y-m-d'),
            'is_available' => true,
        ]);

        $response = $this->getJson("/api/products/{$product->id}");

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'product' => [
                        'is_expired' => true,
                    ]
                ]
            ]);
    }
}
