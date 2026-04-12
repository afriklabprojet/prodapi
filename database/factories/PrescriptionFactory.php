<?php

namespace Database\Factories;

use App\Models\Prescription;
use App\Models\User;
use App\Models\Pharmacy;
use App\Models\Order;
use Illuminate\Database\Eloquent\Factories\Factory;

class PrescriptionFactory extends Factory
{
    protected $model = Prescription::class;

    public function definition(): array
    {
        return [
            'customer_id' => User::factory(),
            'pharmacy_id' => Pharmacy::factory(),
            'images' => [fake()->imageUrl()],
            'status' => 'pending',
            'source' => 'upload',
        ];
    }

    public function validated(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'validated',
            'validated_at' => now(),
            'validated_by' => User::factory(),
        ]);
    }

    public function rejected(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'rejected',
            'admin_notes' => 'Ordonnance illisible',
        ]);
    }

    public function withOrder(): static
    {
        return $this->state(fn (array $attributes) => [
            'order_id' => Order::factory(),
        ]);
    }
}
