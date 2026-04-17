<?php

namespace Database\Factories;

use App\Models\PaymentIntent;
use App\Models\Order;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class PaymentIntentFactory extends Factory
{
    protected $model = PaymentIntent::class;

    public function definition(): array
    {
        return [
            'order_id' => Order::factory(),
            'provider' => 'jeko',
            'reference' => 'PAY-' . strtoupper(Str::random(10)),
            'provider_reference' => fake()->optional()->uuid(),
            'provider_transaction_id' => fake()->optional()->uuid(),
            'amount' => fake()->randomFloat(2, 1000, 50000),
            'currency' => 'XOF',
            'status' => 'PENDING',
            'provider_payment_url' => fake()->optional()->url(),
            'raw_response' => null,
            'raw_webhook' => null,
            'confirmed_at' => null,
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
}
