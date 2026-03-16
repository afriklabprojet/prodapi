<?php

namespace Database\Factories;

use App\Models\Commission;
use App\Models\Order;
use Illuminate\Database\Eloquent\Factories\Factory;

class CommissionFactory extends Factory
{
    protected $model = Commission::class;

    public function definition(): array
    {
        return [
            'order_id' => Order::factory(),
            'total_amount' => fake()->randomFloat(2, 5000, 50000),
            'calculated_at' => now(),
        ];
    }
}
