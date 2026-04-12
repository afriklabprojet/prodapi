<?php

namespace Tests\Unit\Models;

use App\Models\Product;
use App\Models\Pharmacy;
use App\Models\Category;
use App\Models\OrderItem;
use App\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProductModelTest extends TestCase
{
    use RefreshDatabase;

    public function test_fillable_attributes(): void
    {
        $product = new Product();
        $fillable = $product->getFillable();
        $this->assertContains('pharmacy_id', $fillable);
        $this->assertContains('name', $fillable);
        $this->assertContains('slug', $fillable);
        $this->assertContains('description', $fillable);
        $this->assertContains('price', $fillable);
        $this->assertContains('discount_price', $fillable);
        $this->assertContains('stock_quantity', $fillable);
        $this->assertContains('requires_prescription', $fillable);
        $this->assertContains('is_available', $fillable);
        $this->assertContains('is_featured', $fillable);
        $this->assertContains('average_rating', $fillable);
        $this->assertContains('reviews_count', $fillable);
    }

    public function test_casts(): void
    {
        $product = new Product();
        $casts = $product->getCasts();
        $this->assertSame('float', $casts['price']);
        $this->assertSame('float', $casts['discount_price']);
        $this->assertSame('boolean', $casts['requires_prescription']);
        $this->assertSame('boolean', $casts['is_available']);
        $this->assertSame('boolean', $casts['is_featured']);
        $this->assertSame('date', $casts['expiry_date']);
        $this->assertSame('array', $casts['images']);
        $this->assertSame('array', $casts['tags']);
        $this->assertSame('float', $casts['average_rating']);
    }

    public function test_appends(): void
    {
        $product = new Product();
        $appends = $product->getAppends();
        $this->assertContains('final_price', $appends);
        $this->assertContains('discount_percentage', $appends);
        $this->assertContains('is_low_stock', $appends);
        $this->assertContains('is_out_of_stock', $appends);
        $this->assertContains('is_expired', $appends);
    }

    public function test_image_attribute_returns_null_for_null(): void
    {
        $product = new Product();
        $this->assertNull($product->image);
    }

    public function test_image_attribute_returns_url_as_is(): void
    {
        $product = new Product();
        $product->setRawAttributes(['image' => 'https://example.com/image.jpg']);
        $this->assertSame('https://example.com/image.jpg', $product->image);
    }

    public function test_uses_soft_deletes(): void
    {
        $product = new Product();
        $this->assertContains('Illuminate\Database\Eloquent\SoftDeletes', class_uses_recursive($product));
    }

    public function test_pharmacy_relationship(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create(['pharmacy_id' => $pharmacy->id]);

        $this->assertInstanceOf(Pharmacy::class, $product->pharmacy);
        $this->assertEquals($pharmacy->id, $product->pharmacy->id);
    }

    public function test_order_items_relationship(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create(['pharmacy_id' => $pharmacy->id]);
        $order = Order::factory()->create(['pharmacy_id' => $pharmacy->id]);
        
        OrderItem::create([
            'order_id' => $order->id,
            'product_id' => $product->id,
            'product_name' => $product->name,
            'quantity' => 2,
            'unit_price' => $product->price,
            'total_price' => $product->price * 2,
        ]);

        $this->assertCount(1, $product->orderItems);
    }

    public function test_category_relationship(): void
    {
        $category = Category::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'category_id' => $category->id,
        ]);

        $this->assertInstanceOf(Category::class, $product->category);
        $this->assertEquals($category->id, $product->category->id);
    }

    public function test_category_name_attribute_returns_category_name(): void
    {
        $category = Category::factory()->create(['name' => 'Vitamins']);
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'category_id' => $category->id,
        ]);
        
        // Force refresh to clear any cached relations
        $product->refresh();

        $this->assertEquals('Vitamins', $product->category_name);
    }

    public function test_category_name_attribute_returns_default_when_no_category(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'category_id' => null,
        ]);
        
        // Set an empty relation so getRelation doesn't throw
        $product->setRelation('category', null);

        $this->assertEquals('Non classé', $product->category_name);
    }

    public function test_final_price_returns_discount_price_when_set(): void
    {
        $product = new Product();
        $product->price = 1000;
        $product->discount_price = 800;

        $this->assertEquals(800, $product->final_price);
    }

    public function test_final_price_returns_regular_price_when_no_discount(): void
    {
        $product = new Product();
        $product->price = 1000;
        $product->discount_price = null;

        $this->assertEquals(1000, $product->final_price);
    }

    public function test_discount_percentage_returns_correct_value(): void
    {
        $product = new Product();
        $product->price = 1000;
        $product->discount_price = 800;

        $this->assertEquals(20, $product->discount_percentage);
    }

    public function test_discount_percentage_returns_null_when_no_discount(): void
    {
        $product = new Product();
        $product->price = 1000;
        $product->discount_price = null;

        $this->assertNull($product->discount_percentage);
    }

    public function test_discount_percentage_returns_null_when_discount_greater_than_price(): void
    {
        $product = new Product();
        $product->price = 1000;
        $product->discount_price = 1200;

        $this->assertNull($product->discount_percentage);
    }

    public function test_is_low_stock_returns_true_when_at_threshold(): void
    {
        $product = new Product();
        $product->stock_quantity = 5;
        $product->low_stock_threshold = 10;

        $this->assertTrue($product->is_low_stock);
    }

    public function test_is_low_stock_returns_false_when_above_threshold(): void
    {
        $product = new Product();
        $product->stock_quantity = 20;
        $product->low_stock_threshold = 10;

        $this->assertFalse($product->is_low_stock);
    }

    public function test_is_low_stock_returns_false_when_out_of_stock(): void
    {
        $product = new Product();
        $product->stock_quantity = 0;
        $product->low_stock_threshold = 10;

        $this->assertFalse($product->is_low_stock);
    }

    public function test_is_out_of_stock_returns_true_when_quantity_is_zero(): void
    {
        $product = new Product();
        $product->stock_quantity = 0;

        $this->assertTrue($product->is_out_of_stock);
    }

    public function test_is_out_of_stock_returns_false_when_quantity_positive(): void
    {
        $product = new Product();
        $product->stock_quantity = 5;

        $this->assertFalse($product->is_out_of_stock);
    }

    public function test_is_expired_returns_true_when_past_expiry(): void
    {
        $product = new Product();
        $product->expiry_date = now()->subDays(1);

        $this->assertTrue($product->is_expired);
    }

    public function test_is_expired_returns_false_when_not_expired(): void
    {
        $product = new Product();
        $product->expiry_date = now()->addDays(30);

        $this->assertFalse($product->is_expired);
    }

    public function test_is_expired_returns_false_when_no_expiry_date(): void
    {
        $product = new Product();
        $product->expiry_date = null;

        $this->assertFalse($product->is_expired);
    }

    public function test_scope_available(): void
    {
        $pharmacy = Pharmacy::factory()->create();

        $available = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'is_available' => true,
            'stock_quantity' => 10,
            'expiry_date' => now()->addMonth(),
        ]);

        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'is_available' => false,
            'stock_quantity' => 10,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'is_available' => true,
            'stock_quantity' => 0,
        ]);

        $results = Product::available()->get();

        $this->assertTrue($results->contains('id', $available->id));
        $this->assertCount(1, $results);
    }

    public function test_scope_featured(): void
    {
        $pharmacy = Pharmacy::factory()->create();

        $featured = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'is_featured' => true,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'is_featured' => false,
        ]);

        $results = Product::featured()->get();

        $this->assertTrue($results->contains('id', $featured->id));
        $this->assertCount(1, $results);
    }

    public function test_scope_for_pharmacy(): void
    {
        $pharmacy1 = Pharmacy::factory()->create();
        $pharmacy2 = Pharmacy::factory()->create();

        $product1 = Product::factory()->create(['pharmacy_id' => $pharmacy1->id]);
        Product::factory()->create(['pharmacy_id' => $pharmacy2->id]);

        $results = Product::forPharmacy($pharmacy1->id)->get();

        $this->assertCount(1, $results);
        $this->assertEquals($product1->id, $results->first()->id);
    }

    public function test_scope_in_category(): void
    {
        $pharmacy = Pharmacy::factory()->create();

        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'category' => 'vitamins',
        ]);

        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'category' => 'painkillers',
        ]);

        $results = Product::inCategory('vitamins')->get();

        $this->assertCount(1, $results);
        $this->assertEquals($product->id, $results->first()->id);
    }

    public function test_scope_search(): void
    {
        $pharmacy = Pharmacy::factory()->create();

        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'Vitamin C 1000mg',
            'description' => 'Immune support',
        ]);

        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'Aspirin',
            'description' => 'Pain relief',
        ]);

        $results = Product::search('Vitamin')->get();

        $this->assertCount(1, $results);
        $this->assertEquals($product->id, $results->first()->id);
    }

    public function test_scope_low_stock(): void
    {
        $pharmacy = Pharmacy::factory()->create();

        $lowStock = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'stock_quantity' => 3,
            'low_stock_threshold' => 10,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'stock_quantity' => 20,
            'low_stock_threshold' => 10,
        ]);

        $results = Product::lowStock()->get();

        $this->assertTrue($results->contains('id', $lowStock->id));
    }

    public function test_scope_out_of_stock(): void
    {
        $pharmacy = Pharmacy::factory()->create();

        $outOfStock = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'stock_quantity' => 0,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'stock_quantity' => 10,
        ]);

        $results = Product::outOfStock()->get();

        $this->assertCount(1, $results);
        $this->assertEquals($outOfStock->id, $results->first()->id);
    }

    public function test_increment_views(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'views_count' => 0,
        ]);

        $product->incrementViews();

        $this->assertEquals(1, $product->refresh()->views_count);
    }

    public function test_increment_sales(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'sales_count' => 0,
        ]);

        $product->incrementSales(3);

        $this->assertEquals(3, $product->refresh()->sales_count);
    }

    public function test_decrease_stock_returns_true_when_sufficient(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'stock_quantity' => 10,
        ]);

        $result = $product->decreaseStock(5);

        $this->assertTrue($result);
        $this->assertEquals(5, $product->refresh()->stock_quantity);
    }

    public function test_decrease_stock_returns_false_when_insufficient(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'stock_quantity' => 2,
        ]);

        $result = $product->decreaseStock(5);

        $this->assertFalse($result);
        $this->assertEquals(2, $product->refresh()->stock_quantity);
    }

    public function test_increase_stock(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'stock_quantity' => 10,
        ]);

        $product->increaseStock(5);

        $this->assertEquals(15, $product->refresh()->stock_quantity);
    }

    public function test_slug_generated_on_creation(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        
        $product = Product::create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'Test Product Name',
            'price' => 1000,
            'stock_quantity' => 10,
            'is_available' => true,
        ]);

        $this->assertStringContainsString('test-product-name', $product->slug);
        $this->assertStringContainsString((string) $pharmacy->id, $product->slug);
    }

    public function test_slug_updated_when_name_changes(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'name' => 'Original Name',
        ]);

        $product->update(['name' => 'New Product Name']);

        $this->assertStringContainsString('new-product-name', $product->refresh()->slug);
    }

    public function test_image_attribute_converts_local_storage_path(): void
    {
        $product = new Product();
        $product->setRawAttributes(['image' => 'storage/products/image.jpg']);

        $this->assertStringContainsString('/img-proxy/', $product->image);
    }
}
