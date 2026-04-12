<?php

namespace Database\Factories;

use App\Models\Product;
use App\Models\Pharmacy;
use App\Models\Category;
use Illuminate\Database\Eloquent\Factories\Factory;

class ProductFactory extends Factory
{
    protected $model = Product::class;

    public function definition(): array
    {
        return [
            'pharmacy_id' => Pharmacy::factory(),
            'category_id' => Category::factory(),
            'name' => fake()->words(3, true),
            'slug' => fake()->unique()->slug(),
            'description' => fake()->sentence(),
            'brand' => fake()->company(),
            'price' => fake()->randomFloat(2, 500, 50000),
            'stock_quantity' => fake()->numberBetween(0, 200),
            'low_stock_threshold' => 10,
            'sku' => fake()->unique()->numerify('SKU-####'),
            'requires_prescription' => false,
            'is_available' => true,
            'is_featured' => false,
            'unit' => fake()->randomElement(['boîte', 'plaquette', 'flacon', 'tube']),
            'units_per_pack' => fake()->randomElement([1, 10, 20, 30]),
            'views_count' => 0,
            'sales_count' => 0,
        ];
    }

    public function unavailable(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_available' => false,
        ]);
    }

    public function requiresPrescription(): static
    {
        return $this->state(fn (array $attributes) => [
            'requires_prescription' => true,
        ]);
    }

    public function featured(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_featured' => true,
        ]);
    }
}
