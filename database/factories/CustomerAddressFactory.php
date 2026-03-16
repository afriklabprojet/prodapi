<?php

namespace Database\Factories;

use App\Models\CustomerAddress;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class CustomerAddressFactory extends Factory
{
    protected $model = CustomerAddress::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'label' => fake()->randomElement(['Domicile', 'Bureau', 'Autre']),
            'address' => fake()->streetAddress(),
            'city' => fake()->randomElement(['Abidjan', 'Bouaké', 'Yamoussoukro']),
            'district' => fake()->randomElement(['Cocody', 'Plateau', 'Yopougon', 'Marcory', 'Treichville']),
            'latitude' => fake()->latitude(5.2, 5.5),
            'longitude' => fake()->longitude(-4.1, -3.8),
            'is_default' => false,
            'instructions' => fake()->optional()->sentence(),
        ];
    }

    public function default(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_default' => true,
        ]);
    }

    public function home(): static
    {
        return $this->state(fn (array $attributes) => [
            'label' => 'Domicile',
        ]);
    }

    public function work(): static
    {
        return $this->state(fn (array $attributes) => [
            'label' => 'Bureau',
        ]);
    }
}
