<?php

namespace Tests\Feature;

use App\Models\Pharmacy;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PharmacyInventoryApiTest extends TestCase
{
    use RefreshDatabase;

    protected User $pharmacyUser;
    protected Pharmacy $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();

        // Create pharmacy user
        $this->pharmacyUser = User::factory()->create([
            'role' => 'pharmacy',
        ]);

        // Create pharmacy
        $this->pharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
        ]);

        // Attach user to pharmacy
        $this->pharmacy->users()->attach($this->pharmacyUser->id, ['role' => 'owner']);
    }

    /** @test */
    public function pharmacy_can_list_products()
    {
        // Create products for this pharmacy
        Product::factory()->count(5)->create([
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        Sanctum::actingAs($this->pharmacyUser);

        $response = $this->getJson('/api/pharmacy/inventory');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    '*' => ['id', 'name', 'price', 'stock_quantity'],
                ],
            ]);

        $this->assertCount(5, $response->json('data'));
    }

    /** @test */
    public function pharmacy_can_add_product()
    {
        Sanctum::actingAs($this->pharmacyUser);

        // Create a category first
        $category = \App\Models\Category::factory()->create();

        $productData = [
            'name' => 'Paracetamol 500mg',
            'description' => 'Pain reliever and fever reducer',
            'price' => 1500,
            'stock_quantity' => 100,
            'category_id' => $category->id,
            'requires_prescription' => false,
        ];

        $response = $this->postJson('/api/pharmacy/inventory', $productData);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => ['id', 'name', 'price', 'stock_quantity'],
            ]);

        $this->assertDatabaseHas('products', [
            'name' => 'Paracetamol 500mg',
            'pharmacy_id' => $this->pharmacy->id,
        ]);
    }

    /** @test */
    public function pharmacy_can_update_stock()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'stock_quantity' => 50,
        ]);

        Sanctum::actingAs($this->pharmacyUser);

        $response = $this->postJson("/api/pharmacy/inventory/{$product->id}/stock", [
            'quantity' => 75,
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'stock_quantity' => 75,
        ]);
    }

    /** @test */
    public function pharmacy_can_update_price()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'price' => 1000,
        ]);

        Sanctum::actingAs($this->pharmacyUser);

        $response = $this->postJson("/api/pharmacy/inventory/{$product->id}/price", [
            'price' => 1200,
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'price' => 1200,
        ]);
    }

    /** @test */
    public function pharmacy_can_toggle_product_availability()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'is_available' => true,
        ]);

        Sanctum::actingAs($this->pharmacyUser);

        $response = $this->postJson("/api/pharmacy/inventory/{$product->id}/toggle-status");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertDatabaseHas('products', [
            'id' => $product->id,
            'is_available' => false,
        ]);
    }

    /** @test */
    public function pharmacy_cannot_access_other_pharmacy_products()
    {
        // Create another pharmacy
        $otherPharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $otherProduct = Product::factory()->create([
            'pharmacy_id' => $otherPharmacy->id,
        ]);

        Sanctum::actingAs($this->pharmacyUser);

        $response = $this->postJson("/api/pharmacy/inventory/{$otherProduct->id}/stock", [
            'quantity' => 999,
        ]);

        $response->assertStatus(404);
    }

    /** @test */
    public function unapproved_pharmacy_cannot_access_inventory()
    {
        // Update pharmacy status to pending
        $this->pharmacy->update(['status' => 'pending']);

        Sanctum::actingAs($this->pharmacyUser);

        $response = $this->getJson('/api/pharmacy/inventory');

        $response->assertStatus(403);
    }

    /** @test */
    public function non_pharmacy_user_cannot_access_inventory()
    {
        $customerUser = User::factory()->create(['role' => 'customer']);

        Sanctum::actingAs($customerUser);

        $response = $this->getJson('/api/pharmacy/inventory');

        $response->assertStatus(403);
    }
}
