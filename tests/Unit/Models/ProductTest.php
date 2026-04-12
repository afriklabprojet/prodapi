<?php

namespace Tests\Unit\Models;

use App\Models\Product;
use App\Models\Pharmacy;
use App\Models\Category;
use App\Models\OrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class ProductTest extends TestCase
{
    use RefreshDatabase;

    protected Pharmacy $pharmacy;
    protected Product $product;

    protected function setUp(): void
    {
        parent::setUp();

        $this->pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'price' => 5000,
            'discount_price' => null,
            'stock_quantity' => 20,
            'low_stock_threshold' => 5,
            'is_available' => true,
            'expiry_date' => null,
        ]);
    }

    #[Test]
    public function it_belongs_to_a_pharmacy()
    {
        $this->assertInstanceOf(Pharmacy::class, $this->product->pharmacy);
        $this->assertEquals($this->pharmacy->id, $this->product->pharmacy->id);
    }

    #[Test]
    public function it_has_many_order_items()
    {
        OrderItem::factory()->count(3)->create(['product_id' => $this->product->id]);

        $this->assertCount(3, $this->product->orderItems);
        $this->assertInstanceOf(OrderItem::class, $this->product->orderItems->first());
    }

    #[Test]
    public function it_belongs_to_a_category()
    {
        $category = Category::factory()->create();
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'category_id' => $category->id,
        ]);

        $this->assertInstanceOf(Category::class, $product->category);
    }

    #[Test]
    public function final_price_returns_price_without_discount()
    {
        $this->assertEquals(5000, $this->product->final_price);
    }

    #[Test]
    public function final_price_returns_discount_price_when_set()
    {
        $this->product->update(['discount_price' => 3500]);
        $this->product->refresh();

        $this->assertEquals(3500, $this->product->final_price);
    }

    #[Test]
    public function discount_percentage_calculated_correctly()
    {
        $this->product->update(['discount_price' => 4000]);
        $this->product->refresh();

        $this->assertEquals(20, $this->product->discount_percentage);
    }

    #[Test]
    public function discount_percentage_null_without_discount()
    {
        $this->assertNull($this->product->discount_percentage);
    }

    #[Test]
    public function is_low_stock_when_below_threshold()
    {
        $this->product->update(['stock_quantity' => 3]);
        $this->product->refresh();

        $this->assertTrue($this->product->is_low_stock);
    }

    #[Test]
    public function is_not_low_stock_when_above_threshold()
    {
        $this->assertFalse($this->product->is_low_stock);
    }

    #[Test]
    public function is_out_of_stock_when_zero()
    {
        $this->product->update(['stock_quantity' => 0]);
        $this->product->refresh();

        $this->assertTrue($this->product->is_out_of_stock);
    }

    #[Test]
    public function is_not_out_of_stock_when_positive()
    {
        $this->assertFalse($this->product->is_out_of_stock);
    }

    #[Test]
    public function is_expired_when_past_date()
    {
        $this->product->update(['expiry_date' => now()->subDay()]);
        $this->product->refresh();

        $this->assertTrue($this->product->is_expired);
    }

    #[Test]
    public function is_not_expired_when_no_date()
    {
        $this->assertFalse($this->product->is_expired);
    }

    #[Test]
    public function is_not_expired_when_future_date()
    {
        $this->product->update(['expiry_date' => now()->addYear()]);
        $this->product->refresh();

        $this->assertFalse($this->product->is_expired);
    }

    #[Test]
    public function scope_available_filters_correctly()
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => false,
            'stock_quantity' => 10,
        ]);

        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
            'stock_quantity' => 0,
        ]);

        $available = Product::available()->get();

        $this->assertTrue($available->contains($this->product));
        $this->assertCount(1, $available);
    }

    #[Test]
    public function scope_featured_filters_correctly()
    {
        $featured = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_featured' => true,
        ]);

        $results = Product::featured()->get();

        $this->assertTrue($results->contains($featured));
    }

    #[Test]
    public function scope_for_pharmacy_filters_correctly()
    {
        $otherPharmacy = Pharmacy::factory()->create();
        Product::factory()->create(['pharmacy_id' => $otherPharmacy->id]);

        $results = Product::forPharmacy($this->pharmacy->id)->get();

        $this->assertTrue($results->every(fn ($p) => $p->pharmacy_id === $this->pharmacy->id));
    }

    #[Test]
    public function scope_search_filters_by_name()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Amoxicilline 250mg',
        ]);

        $results = Product::search('Amoxicilline')->get();

        $this->assertTrue($results->contains($product));
    }

    #[Test]
    public function slug_is_auto_generated()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Paracétamol 500mg',
            'slug' => null,
        ]);

        $this->assertNotNull($product->slug);
        $this->assertStringContainsString('paracetamol', $product->slug);
    }

    #[Test]
    public function uses_soft_deletes()
    {
        $product = Product::factory()->create(['pharmacy_id' => $this->pharmacy->id]);
        $product->delete();

        $this->assertSoftDeleted($product);
        $this->assertNotNull(Product::withTrashed()->find($product->id));
    }
}
