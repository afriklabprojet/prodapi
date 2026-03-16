<?php

namespace Tests\Feature\Api\Pharmacy;

use App\Models\User;
use App\Models\Pharmacy;
use App\Models\Product;
use App\Models\Category;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class InventoryControllerTest extends TestCase
{
    use RefreshDatabase;

    private User $pharmacyUser;
    private Pharmacy $pharmacy;
    private string $token;

    protected function setUp(): void
    {
        parent::setUp();
        
        Storage::fake('public');
        
        $this->pharmacyUser = User::factory()->create([
            'role' => 'pharmacy',
        ]);
        
        $this->pharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
        ]);
        
        // Link pharmacy to user via pivot table
        $this->pharmacyUser->pharmacies()->attach($this->pharmacy->id, ['role' => 'owner']);
        
        $this->token = $this->pharmacyUser->createToken('test-token')->plainTextToken;
    }

    /** @test */
    public function pharmacy_can_list_products()
    {
        Product::factory()->count(5)->create([
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->getJson('/api/pharmacy/inventory');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data',
            ]);
    }

    /** @test */
    public function pharmacy_can_create_product()
    {
        $category = Category::factory()->create();

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->postJson('/api/pharmacy/inventory', [
                'name' => 'Paracetamol 500mg',
                'description' => 'Antidouleur et antipyrétique',
                'price' => 2500,
                'stock_quantity' => 100,
                'category_id' => $category->id,
                'requires_prescription' => false,
                'is_available' => true,
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertDatabaseHas('products', [
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Paracetamol 500mg',
        ]);
    }

    /** @test */
    public function pharmacy_can_update_product()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Old Name',
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->postJson("/api/pharmacy/inventory/{$product->id}/update", [
                'name' => 'New Name',
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'name' => 'New Name',
        ]);
    }

    /** @test */
    public function pharmacy_can_delete_product()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->deleteJson("/api/pharmacy/inventory/{$product->id}");

        $response->assertStatus(200);

        $this->assertSoftDeleted('products', [
            'id' => $product->id,
        ]);
    }

    /** @test */
    public function pharmacy_cannot_access_other_pharmacy_products()
    {
        $otherPharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create([
            'pharmacy_id' => $otherPharmacy->id,
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->postJson("/api/pharmacy/inventory/{$product->id}/update", [
                'name' => 'Hacked Name',
            ]);

        $response->assertStatus(404);
    }

    /** @test */
    public function unapproved_pharmacy_cannot_access_inventory()
    {
        $this->pharmacy->update(['status' => 'pending']);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->getJson('/api/pharmacy/inventory');

        $response->assertStatus(403);
    }

    /** @test */
    public function product_requires_name()
    {
        $category = Category::factory()->create();

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->postJson('/api/pharmacy/inventory', [
                'description' => 'Test',
                'price' => 1000,
                'stock_quantity' => 10,
                'category_id' => $category->id,
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['name']);
    }

    /** @test */
    public function product_requires_valid_category()
    {
        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->postJson('/api/pharmacy/inventory', [
                'name' => 'Test Product',
                'description' => 'Test',
                'price' => 1000,
                'stock_quantity' => 10,
                'category_id' => 99999,
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['category_id']);
    }

    /** @test */
    public function product_price_must_be_positive()
    {
        $category = Category::factory()->create();

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->postJson('/api/pharmacy/inventory', [
                'name' => 'Test Product',
                'description' => 'Test',
                'price' => -100,
                'stock_quantity' => 10,
                'category_id' => $category->id,
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['price']);
    }

    /** @test */
    public function can_upload_product_image()
    {
        $category = Category::factory()->create();
        $file = UploadedFile::fake()->image('product.jpg');

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->postJson('/api/pharmacy/inventory', [
                'name' => 'Test Product',
                'description' => 'Test',
                'price' => 1000,
                'stock_quantity' => 10,
                'category_id' => $category->id,
                'image' => $file,
            ]);

        $response->assertStatus(201);
    }

    /** @test */
    public function can_update_stock_quantity()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'stock_quantity' => 50,
        ]);

        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
            ->postJson("/api/pharmacy/inventory/{$product->id}/stock", [
                'quantity' => 100,
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'stock_quantity' => 100,
        ]);
    }
}
