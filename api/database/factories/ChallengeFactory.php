<?php

namespace Database\Factories;

use App\Models\Challenge;
use Illuminate\Database\Eloquent\Factories\Factory;

class ChallengeFactory extends Factory
{
    protected $model = Challenge::class;

    public function definition(): array
    {
        return [
            'title' => fake()->sentence(3),
            'description' => fake()->paragraph(),
            'type' => fake()->randomElement(['daily', 'weekly', 'monthly', 'one_time']),
            'metric' => fake()->randomElement(['deliveries', 'distance', 'rating', 'earnings']),
            'target_value' => fake()->numberBetween(5, 50),
            'reward_amount' => fake()->numberBetween(1000, 10000),
            'icon' => fake()->randomElement(['🎯', '🏆', '⭐', '🚀']),
            'color' => fake()->randomElement(['blue', 'green', 'yellow', 'red']),
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

    public function future(): static
    {
        return $this->state(fn (array $attributes) => [
            'starts_at' => now()->addDays(5),
        ]);
    }

    public function expired(): static
    {
        return $this->state(fn (array $attributes) => [
            'starts_at' => now()->subDays(10),
            'ends_at' => now()->subDays(1),
        ]);
    }
}
