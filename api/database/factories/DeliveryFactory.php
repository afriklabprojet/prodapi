<?php

namespace Database\Factories;

use App\Models\Delivery;
use App\Models\Order;
use App\Models\Courier;
use Illuminate\Database\Eloquent\Factories\Factory;

class DeliveryFactory extends Factory
{
    protected $model = Delivery::class;

    public function definition(): array
    {
        return [
            'order_id' => Order::factory(),
            'courier_id' => null,
            'status' => 'pending',
            'pickup_address' => fake()->address(),
            'delivery_address' => fake()->address(),
            'pickup_latitude' => fake()->latitude(5.0, 7.5),
            'pickup_longitude' => fake()->longitude(-8.0, -3.0),
            'delivery_latitude' => fake()->latitude(5.0, 7.5),
            'delivery_longitude' => fake()->longitude(-8.0, -3.0),
            'estimated_distance' => fake()->randomFloat(2, 1, 20),
            'estimated_duration' => fake()->numberBetween(10, 60),
            'delivery_fee' => fake()->randomFloat(2, 500, 3000),
        ];
    }

    public function assigned(): static
    {
        return $this->state(fn (array $attributes) => [
            'courier_id' => Courier::factory()->available(),
            'status' => 'assigned',
            'assigned_at' => now(),
        ]);
    }

    public function accepted(): static
    {
        return $this->state(fn (array $attributes) => [
            'courier_id' => Courier::factory()->busy(),
            'status' => 'accepted',
            'assigned_at' => now()->subMinutes(5),
            'accepted_at' => now(),
        ]);
    }

    public function pickedUp(): static
    {
        return $this->state(fn (array $attributes) => [
            'courier_id' => Courier::factory()->busy(),
            'status' => 'picked_up',
            'picked_up_at' => now(),
        ]);
    }

    public function inTransit(): static
    {
        return $this->state(fn (array $attributes) => [
            'courier_id' => Courier::factory()->busy(),
            'status' => 'in_transit',
        ]);
    }

    public function arrived(): static
    {
        return $this->state(fn (array $attributes) => [
            'courier_id' => Courier::factory()->busy(),
            'status' => 'arrived',
            'waiting_started_at' => now(),
        ]);
    }

    public function delivered(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'delivered',
            'delivered_at' => now(),
        ]);
    }

    public function failed(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'failed',
            'failure_reason' => fake()->sentence(),
        ]);
    }

    public function cancelled(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'cancelled',
            'cancellation_reason' => fake()->sentence(),
        ]);
    }

    public function withWaiting(): static
    {
        return $this->state(fn (array $attributes) => [
            'waiting_started_at' => now()->subMinutes(10),
            'waiting_fee' => 500,
        ]);
    }
}
