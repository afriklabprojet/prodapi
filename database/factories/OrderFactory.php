<?php

namespace Database\Factories;

use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class OrderFactory extends Factory
{
    protected $model = Order::class;

    public function definition(): array
    {
        $subtotal = fake()->randomFloat(2, 1000, 50000);
        $deliveryFee = fake()->randomElement([500, 1000, 1500, 2000]);
        $serviceFee = round($subtotal * 0.05, 2);
        $paymentFee = 0;
        $total = $subtotal + $deliveryFee + $serviceFee + $paymentFee;

        return [
            'reference' => 'DR-' . strtoupper(uniqid()),
            'pharmacy_id' => Pharmacy::factory(),
            'customer_id' => User::factory(),
            'status' => 'pending',
            'payment_status' => 'pending',
            'delivery_code' => fake()->numerify('####'),
            'payment_mode' => 'mobile_money',
            'subtotal' => $subtotal,
            'delivery_fee' => $deliveryFee,
            'service_fee' => $serviceFee,
            'payment_fee' => $paymentFee,
            'total_amount' => $total,
            'currency' => 'XOF',
            'delivery_address' => fake()->address(),
            'delivery_city' => fake()->randomElement(['Abidjan', 'Bouaké', 'Yamoussoukro', 'San-Pédro', 'Daloa']),
            'delivery_latitude' => fake()->latitude(5.0, 7.5),
            'delivery_longitude' => fake()->longitude(-8.0, -3.0),
            'customer_phone' => fake()->numerify('+225##########'),
        ];
    }

    public function confirmed(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'confirmed',
            'confirmed_at' => now(),
        ]);
    }

    public function paid(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'confirmed',
            'payment_status' => 'paid',
            'confirmed_at' => now(),
            'paid_at' => now(),
        ]);
    }

    public function delivered(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'delivered',
            'payment_status' => 'paid',
            'confirmed_at' => now(),
            'paid_at' => now(),
            'delivered_at' => now(),
        ]);
    }

    public function cancelled(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'cancelled',
            'cancelled_at' => now(),
            'cancellation_reason' => 'Annulé par le client',
        ]);
    }
}
