<?php

namespace Database\Factories;

use App\Models\BonusMultiplier;
use Illuminate\Database\Eloquent\Factories\Factory;

class BonusMultiplierFactory extends Factory
{
    protected $model = BonusMultiplier::class;

    public function definition(): array
    {
        return [
            'name' => fake()->words(3, true),
            'description' => fake()->sentence(),
            'type' => fake()->randomElement(['time_bonus', 'zone_bonus', 'streak_bonus', 'weather_bonus']),
            'multiplier' => fake()->randomFloat(2, 1.1, 2.0),
            'flat_bonus' => fake()->numberBetween(0, 500),
            'conditions' => [],
            'is_active' => true,
            'starts_at' => null,
            'ends_at' => null,
        ];
    }

    public function inactive(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_active' => false,
        ]);
    }

    public function expired(): static
    {
        return $this->state(fn (array $attributes) => [
            'starts_at' => now()->subDays(5),
            'ends_at' => now()->subHours(1),
        ]);
    }
}
