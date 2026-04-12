<?php

namespace Database\Factories;

use App\Models\DutyZone;
use Illuminate\Database\Eloquent\Factories\Factory;

class DutyZoneFactory extends Factory
{
    protected $model = DutyZone::class;

    public function definition(): array
    {
        return [
            'name' => $this->faker->word() . ' Zone',
            'city' => $this->faker->city(),
            'description' => $this->faker->sentence(),
            'is_active' => true,
            'latitude' => $this->faker->latitude(5.0, 7.0),
            'longitude' => $this->faker->longitude(-6.0, -3.0),
            'radius' => $this->faker->randomFloat(2, 1, 50),
        ];
    }
}
