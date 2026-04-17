<?php

namespace Database\Factories;

use App\Models\Payment;
use App\Models\Order;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class PaymentFactory extends Factory
{
    protected $model = Payment::class;

    public function definition(): array
    {
        return [
            'order_id' => Order::factory(),
            'provider' => fake()->randomElement(['jeko', 'cash']),
            'reference' => 'PAY-' . strtoupper(Str::random(10)),
            'provider_transaction_id' => Str::random(20),
            'amount' => fake()->randomFloat(2, 1000, 50000),
            'currency' => 'XOF',
            'status' => 'SUCCESS',
            'payment_method' => fake()->randomElement(['wave', 'orange', 'mtn', 'cash']),
            'confirmed_at' => now(),
        ];
    }

    public function success(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'SUCCESS',
            'confirmed_at' => now(),
        ]);
    }

    public function failed(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'FAILED',
        ]);
    }

    public function cash(): static
    {
        return $this->state(fn (array $attributes) => [
            'provider' => 'cash',
            'payment_method' => 'cash',
        ]);
    }

    public function jeko(): static
    {
        return $this->state(fn (array $attributes) => [
            'provider' => 'jeko',
        ]);
    }
}
