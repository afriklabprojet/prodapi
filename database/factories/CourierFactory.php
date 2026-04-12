<?php

namespace Database\Factories;

use App\Models\Courier;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class CourierFactory extends Factory
{
    protected $model = Courier::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory()->courier(),
            'name' => fake()->name(),
            'phone' => fake()->unique()->numerify('+225##########'),
            'vehicle_type' => fake()->randomElement(['motorcycle', 'bicycle', 'car']),
            'vehicle_number' => strtoupper(fake()->bothify('??-####-??')),
            'license_number' => strtoupper(fake()->bothify('CI########')),
            'status' => 'available',
            'latitude' => fake()->latitude(5.2, 5.5),
            'longitude' => fake()->longitude(-4.2, -3.8),
            'kyc_status' => 'approved',
        ];
    }

    /**
     * Configure the courier as pending KYC.
     */
    public function pendingKyc(): static
    {
        return $this->state(fn (array $attributes) => [
            'kyc_status' => 'pending',
        ]);
    }

    /**
     * Configure the courier as unavailable.
     */
    public function unavailable(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'unavailable',
        ]);
    }

    /**
     * Configure the courier as on delivery.
     */
    public function onDelivery(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'on_delivery',
        ]);
    }
}
