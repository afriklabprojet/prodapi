<?php

namespace Tests\Unit\Models;

use App\Models\OrderItem;
use Tests\TestCase;

class OrderItemTest extends TestCase
{
    public function test_fillable_fields(): void
    {
        $model = new OrderItem();
        $fillable = $model->getFillable();
        $this->assertContains('order_id', $fillable);
        $this->assertContains('product_id', $fillable);
        $this->assertContains('product_name', $fillable);
        $this->assertContains('quantity', $fillable);
        $this->assertContains('unit_price', $fillable);
        $this->assertContains('total_price', $fillable);
    }

    public function test_casts(): void
    {
        $model = new OrderItem();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('quantity', $casts);
    }

    public function test_has_order_relationship(): void
    {
        $model = new OrderItem();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->order());
    }

    public function test_has_product_relationship(): void
    {
        $model = new OrderItem();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->product());
    }
}
