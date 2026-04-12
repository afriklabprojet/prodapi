<?php

namespace Tests\Unit\Models;

use App\Models\Category;
use Tests\TestCase;

class CategoryTest extends TestCase
{
    public function test_fillable_fields(): void
    {
        $model = new Category();
        $fillable = $model->getFillable();
        $this->assertContains('name', $fillable);
        $this->assertContains('slug', $fillable);
        $this->assertContains('description', $fillable);
        $this->assertContains('is_active', $fillable);
        $this->assertContains('order', $fillable);
    }

    public function test_casts(): void
    {
        $model = new Category();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('is_active', $casts);
        $this->assertArrayHasKey('order', $casts);
    }

    public function test_has_products_relationship(): void
    {
        $model = new Category();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\HasMany::class, $model->products());
    }
}
