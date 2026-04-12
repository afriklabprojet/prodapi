<?php

namespace Tests\Feature\Api\Pharmacy;

use App\Models\Category;
use App\Models\Pharmacy;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * @group deep
 */
class InventoryControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    protected User $pharmacyUser;
    protected Pharmacy $pharmacy;
    protected Category $category;
    protected string $token;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');

        $this->pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->pharmacyUser->pharmacies()->attach($this->pharmacy->id, ['role' => 'owner']);
        
        $this->category = Category::factory()->create(['is_active' => true]);
        $this->token = $this->pharmacyUser->createToken('test')->plainTextToken;
    }

    protected function authHeader(): array
    {
        return ['Authorization' => "Bearer {$this->token}"];
    }

    // ==================== INDEX TESTS ====================

    public function test_index_returns_paginated_products(): void
    {
        Product::factory()->count(25)->create(['pharmacy_id' => $this->pharmacy->id]);

        $response = $this->withHeaders($this->authHeader())
            ->getJson('/api/pharmacy/inventory?per_page=10');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(10, 'data')
            ->assertJsonPath('meta.per_page', 10)
            ->assertJsonPath('meta.total', 25);
    }

    public function test_index_respects_max_per_page(): void
    {
        Product::factory()->count(150)->create(['pharmacy_id' => $this->pharmacy->id]);

        $response = $this->withHeaders($this->authHeader())
            ->getJson('/api/pharmacy/inventory?per_page=500');

        $response->assertOk()
            ->assertJsonPath('meta.per_page', 100); // Capped at 100
    }

    public function test_index_filters_by_search(): void
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Paracetamol 500mg',
        ]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Ibuprofène 400mg',
        ]);

        $response = $this->withHeaders($this->authHeader())
            ->getJson('/api/pharmacy/inventory?search=Paracetamol');

        $response->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_index_only_shows_own_pharmacy_products(): void
    {
        $otherPharmacy = Pharmacy::factory()->create();
        Product::factory()->count(5)->create(['pharmacy_id' => $otherPharmacy->id]);
        Product::factory()->count(3)->create(['pharmacy_id' => $this->pharmacy->id]);

        $response = $this->withHeaders($this->authHeader())
            ->getJson('/api/pharmacy/inventory');

        $response->assertOk()
            ->assertJsonPath('meta.total', 3);
    }

    public function test_index_includes_category_relation(): void
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'category_id' => $this->category->id,
        ]);

        $response = $this->withHeaders($this->authHeader())
            ->getJson('/api/pharmacy/inventory');

        $response->assertOk();
        $product = $response->json('data.0');
        $this->assertArrayHasKey('category', $product);
    }

    // ==================== STORE TESTS ====================

    public function test_store_creates_product(): void
    {
        $response = $this->withHeaders($this->authHeader())
            ->postJson('/api/pharmacy/inventory', [
                'name' => 'Doliprane 1000mg',
                'description' => 'Antidouleur puissant',
                'price' => 3500,
                'stock_quantity' => 50,
                'category_id' => $this->category->id,
                'requires_prescription' => true,
                'is_available' => true,
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('products', [
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Doliprane 1000mg',
            'requires_prescription' => true,
        ]);
    }

    public function test_store_with_image(): void
    {
        $image = UploadedFile::fake()->image('medicine.jpg', 200, 200);

        $response = $this->withHeaders($this->authHeader())
            ->postJson('/api/pharmacy/inventory', [
                'name' => 'Aspirine',
                'description' => 'Anti-inflammatoire',
                'price' => 1500,
                'stock_quantity' => 100,
                'category_id' => $this->category->id,
                'image' => $image,
            ]);

        $response->assertStatus(201);
        $this->assertTrue(Storage::disk('public')->exists('products/' . $image->hashName()));
    }

    public function test_store_with_all_optional_fields(): void
    {
        $response = $this->withHeaders($this->authHeader())
            ->postJson('/api/pharmacy/inventory', [
                'name' => 'Amoxicilline 500mg',
                'description' => 'Antibiotique',
                'price' => 5000,
                'stock_quantity' => 30,
                'category_id' => $this->category->id,
                'barcode' => '1234567890123',
                'brand' => 'Biogaran',
                'manufacturer' => 'Sanofi',
                'active_ingredient' => 'Amoxicilline',
                'unit' => 'boîte de 12',
                'expiry_date' => now()->addYear()->toDateString(),
                'usage_instructions' => '1 comprimé 3 fois par jour',
                'side_effects' => 'Troubles digestifs possibles',
            ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('products', [
            'name' => 'Amoxicilline 500mg',
            'brand' => 'Biogaran',
        ]);
    }

    public function test_store_validation_errors(): void
    {
        $response = $this->withHeaders($this->authHeader())
            ->postJson('/api/pharmacy/inventory', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['name', 'description', 'price', 'stock_quantity', 'category_id']);
    }

    public function test_store_validates_category_exists(): void
    {
        $response = $this->withHeaders($this->authHeader())
            ->postJson('/api/pharmacy/inventory', [
                'name' => 'Test Product',
                'description' => 'Test',
                'price' => 1000,
                'stock_quantity' => 10,
                'category_id' => 99999,
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('category_id');
    }

    public function test_store_generates_slug(): void
    {
        $response = $this->withHeaders($this->authHeader())
            ->postJson('/api/pharmacy/inventory', [
                'name' => 'Vitamine C Effervescent',
                'description' => 'Complément alimentaire',
                'price' => 2000,
                'stock_quantity' => 50,
                'category_id' => $this->category->id,
            ]);

        $response->assertStatus(201);
        $product = Product::latest()->first();
        $this->assertStringContainsString('vitamine-c-effervescent', $product->slug);
    }

    // ==================== UPDATE STOCK TESTS ====================

    public function test_update_stock(): void
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'stock_quantity' => 50,
        ]);

        $response = $this->withHeaders($this->authHeader())
            ->postJson("/api/pharmacy/inventory/{$product->id}/stock", [
                'quantity' => 75,
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertEquals(75, $product->fresh()->stock_quantity);
    }

    public function test_update_stock_to_zero(): void
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'stock_quantity' => 50,
        ]);

        $response = $this->withHeaders($this->authHeader())
            ->postJson("/api/pharmacy/inventory/{$product->id}/stock", [
                'quantity' => 0,
            ]);

        $response->assertOk();
        $this->assertEquals(0, $product->fresh()->stock_quantity);
    }

    public function test_update_stock_validates_quantity(): void
    {
        $product = Product::factory()->create(['pharmacy_id' => $this->pharmacy->id]);

        $response = $this->withHeaders($this->authHeader())
            ->postJson("/api/pharmacy/inventory/{$product->id}/stock", [
                'quantity' => -5,
            ]);

        $response->assertStatus(422);
    }

    public function test_update_stock_not_found(): void
    {
        $response = $this->withHeaders($this->authHeader())
            ->postJson('/api/pharmacy/inventory/99999/stock', [
                'quantity' => 10,
            ]);

        $response->assertStatus(404);
    }

    // ==================== UPDATE PRICE TESTS ====================

    public function test_update_price(): void
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'price' => 1000,
        ]);

        $response = $this->withHeaders($this->authHeader())
            ->postJson("/api/pharmacy/inventory/{$product->id}/price", [
                'price' => 1500,
            ]);

        $response->assertOk();
        $this->assertEquals(1500, $product->fresh()->price);
    }

    public function test_update_price_to_zero(): void
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'price' => 1000,
        ]);

        $response = $this->withHeaders($this->authHeader())
            ->postJson("/api/pharmacy/inventory/{$product->id}/price", [
                'price' => 0,
            ]);

        $response->assertOk();
        $this->assertEquals(0, $product->fresh()->price);
    }

    public function test_update_price_validates(): void
    {
        $product = Product::factory()->create(['pharmacy_id' => $this->pharmacy->id]);

        $response = $this->withHeaders($this->authHeader())
            ->postJson("/api/pharmacy/inventory/{$product->id}/price", [
                'price' => -100,
            ]);

        $response->assertStatus(422);
    }

    // ==================== TOGGLE STATUS TESTS ====================

    public function test_toggle_availability(): void
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
        ]);

        $response = $this->withHeaders($this->authHeader())
            ->postJson("/api/pharmacy/inventory/{$product->id}/toggle-status");

        $response->assertOk();
        $this->assertFalse($product->fresh()->is_available);

        // Toggle again
        $this->withHeaders($this->authHeader())
            ->postJson("/api/pharmacy/inventory/{$product->id}/toggle-status");

        $this->assertTrue($product->fresh()->is_available);
    }

    // ==================== UPDATE TESTS ====================

    public function test_update_product(): void
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Original Name',
        ]);

        $response = $this->withHeaders($this->authHeader())
            ->postJson("/api/pharmacy/inventory/{$product->id}/update", [
                'name' => 'Updated Name',
                'price' => 2500,
            ]);

        $response->assertOk();
        $this->assertEquals('Updated Name', $product->fresh()->name);
        $this->assertEquals(2500, $product->fresh()->price);
    }

    public function test_update_replaces_image(): void
    {
        $oldImage = UploadedFile::fake()->image('old.jpg');
        $oldPath = $oldImage->store('products', 'public');
        
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'image' => $oldPath,
        ]);

        $newImage = UploadedFile::fake()->image('new.jpg');

        $response = $this->withHeaders($this->authHeader())
            ->postJson("/api/pharmacy/inventory/{$product->id}/update", [
                'image' => $newImage,
            ]);

        $response->assertOk();
        $this->assertTrue(Storage::disk('public')->exists('products/' . $newImage->hashName()));
    }

    // ==================== DELETE TESTS ====================

    public function test_delete_product(): void
    {
        $product = Product::factory()->create(['pharmacy_id' => $this->pharmacy->id]);

        $response = $this->withHeaders($this->authHeader())
            ->deleteJson("/api/pharmacy/inventory/{$product->id}");

        $response->assertOk();
        $this->assertSoftDeleted('products', ['id' => $product->id]);
    }

    public function test_delete_other_pharmacy_product_fails(): void
    {
        $otherPharmacy = Pharmacy::factory()->create();
        $product = Product::factory()->create(['pharmacy_id' => $otherPharmacy->id]);

        $response = $this->withHeaders($this->authHeader())
            ->deleteJson("/api/pharmacy/inventory/{$product->id}");

        $response->assertStatus(404);
    }

    // ==================== CATEGORY TESTS ====================

    public function test_list_categories(): void
    {
        Category::factory()->count(5)->create(['is_active' => true]);
        Category::factory()->create(['is_active' => false]);

        $response = $this->withHeaders($this->authHeader())
            ->getJson('/api/pharmacy/inventory/categories');

        $response->assertOk()
            ->assertJsonPath('success', true);
        
        // Should only return active categories
        $this->assertCount(6, $response->json('data')); // 5 + 1 from setUp
    }

    public function test_store_category(): void
    {
        $response = $this->withHeaders($this->authHeader())
            ->postJson('/api/pharmacy/inventory/categories', [
                'name' => 'Vitamines',
                'description' => 'Compléments vitaminiques',
            ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('categories', [
            'name' => 'Vitamines',
            'slug' => 'vitamines',
        ]);
    }

    public function test_store_category_unique_name(): void
    {
        Category::factory()->create(['name' => 'Antibiotiques']);

        $response = $this->withHeaders($this->authHeader())
            ->postJson('/api/pharmacy/inventory/categories', [
                'name' => 'Antibiotiques',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors('name');
    }

    public function test_update_category(): void
    {
        $category = Category::factory()->create(['name' => 'Old Name']);

        $response = $this->withHeaders($this->authHeader())
            ->putJson("/api/pharmacy/inventory/categories/{$category->id}", [
                'name' => 'New Name',
            ]);

        $response->assertOk();
        $this->assertEquals('New Name', $category->fresh()->name);
    }

    public function test_delete_category(): void
    {
        $category = Category::factory()->create();

        $response = $this->withHeaders($this->authHeader())
            ->deleteJson("/api/pharmacy/inventory/categories/{$category->id}");

        $response->assertOk();
        // Category uses soft deletes - check it's soft deleted
        $this->assertSoftDeleted('categories', ['id' => $category->id]);
    }

    public function test_delete_category_with_products_fails(): void
    {
        $category = Category::factory()->create();
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'category_id' => $category->id,
        ]);

        $response = $this->withHeaders($this->authHeader())
            ->deleteJson("/api/pharmacy/inventory/categories/{$category->id}");

        $response->assertStatus(422);
        $this->assertDatabaseHas('categories', ['id' => $category->id]);
    }

    // ==================== PROMOTION & LOSS TESTS ====================

    public function test_apply_promotion_updates_discount_price_and_end_date(): void
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'price' => 10000,
        ]);

        $response = $this->withHeaders($this->authHeader())
            ->postJson("/api/pharmacy/inventory/{$product->id}/promotion", [
                'discount_percentage' => 20,
                'end_date' => now()->addDays(7)->toDateString(),
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true);

        $product->refresh();
        $this->assertEquals(8000.0, (float) $product->discount_price);
        $this->assertNotNull($product->promotion_end_date);
    }

    public function test_apply_promotion_validates_discount_percentage(): void
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'price' => 10000,
        ]);

        $response = $this->withHeaders($this->authHeader())
            ->postJson("/api/pharmacy/inventory/{$product->id}/promotion", [
                'discount_percentage' => 0,
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['discount_percentage']);
    }

    public function test_remove_promotion_clears_discount_fields(): void
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'price' => 10000,
            'discount_price' => 8000,
            'promotion_end_date' => now()->addDays(5),
        ]);

        $response = $this->withHeaders($this->authHeader())
            ->deleteJson("/api/pharmacy/inventory/{$product->id}/promotion");

        $response->assertOk()
            ->assertJsonPath('success', true);

        $product->refresh();
        $this->assertNull($product->discount_price);
        $this->assertNull($product->promotion_end_date);
    }

    public function test_mark_as_loss_reduces_stock(): void
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'stock_quantity' => 25,
        ]);

        $response = $this->withHeaders($this->authHeader())
            ->postJson("/api/pharmacy/inventory/{$product->id}/loss", [
                'quantity' => 5,
                'reason' => 'Produit expiré',
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertEquals(20, $product->fresh()->stock_quantity);
    }

    public function test_mark_as_loss_rejects_quantity_above_stock(): void
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'stock_quantity' => 3,
        ]);

        $response = $this->withHeaders($this->authHeader())
            ->postJson("/api/pharmacy/inventory/{$product->id}/loss", [
                'quantity' => 5,
                'reason' => 'Casse',
            ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    // ==================== AUTHORIZATION TESTS ====================

    public function test_unapproved_pharmacy_forbidden(): void
    {
        $this->pharmacy->update(['status' => 'pending']);

        $response = $this->withHeaders($this->authHeader())
            ->getJson('/api/pharmacy/inventory');

        $response->assertStatus(403);
    }

    public function test_unauthenticated_forbidden(): void
    {
        $this->getJson('/api/pharmacy/inventory')->assertStatus(401);
    }

    public function test_non_pharmacy_user_cannot_access(): void
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $token = $customer->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->getJson('/api/pharmacy/inventory');

        $response->assertStatus(403);
    }
}
