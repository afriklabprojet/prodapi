<?php

namespace Tests\Feature\Api;

use App\Models\Customer;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Pharmacy;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProductReviewControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Product $product;
    protected Order $order;

    protected function setUp(): void
    {
        parent::setUp();

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->product = Product::factory()->create(['pharmacy_id' => $pharmacy->id]);

        $this->user = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $this->user->id]);

        $this->order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $this->user->id,
            'status' => 'delivered',
        ]);

        OrderItem::factory()->create([
            'order_id' => $this->order->id,
            'product_id' => $this->product->id,
        ]);
    }

    public function test_anyone_can_list_product_reviews(): void
    {
        $response = $this->getJson("/api/products/{$this->product->id}/reviews");

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_customer_can_submit_review(): void
    {
        $response = $this->actingAs($this->user)->postJson("/api/customer/products/{$this->product->id}/reviews", [
            'rating' => 5,
            'comment' => 'Excellent produit',
            'order_id' => $this->order->id,
        ]);

        $response->assertSuccessful()->assertJsonPath('success', true);
    }

    public function test_review_requires_rating(): void
    {
        $response = $this->actingAs($this->user)->postJson("/api/customer/products/{$this->product->id}/reviews", [
            'comment' => 'Bon produit',
            'order_id' => $this->order->id,
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('rating');
    }

    public function test_review_validates_rating_range(): void
    {
        $response = $this->actingAs($this->user)->postJson("/api/customer/products/{$this->product->id}/reviews", [
            'rating' => 6,
            'order_id' => $this->order->id,
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('rating');
    }

    public function test_review_requires_order_id(): void
    {
        $response = $this->actingAs($this->user)->postJson("/api/customer/products/{$this->product->id}/reviews", [
            'rating' => 4,
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('order_id');
    }

    public function test_unauthenticated_cannot_submit_review(): void
    {
        $response = $this->postJson("/api/customer/products/{$this->product->id}/reviews", [
            'rating' => 4,
            'order_id' => $this->order->id,
        ]);

        $response->assertStatus(401);
    }
}
