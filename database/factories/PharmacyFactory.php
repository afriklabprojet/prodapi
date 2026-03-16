<?php

namespace Database\Factories;

use App\Models\Pharmacy;
use App\Models\DutyZone;
use Illuminate\Database\Eloquent\Factories\Factory;

class PharmacyFactory extends Factory
{
    protected $model = Pharmacy::class;

    public function definition(): array
    {
        return [
            'name' => 'Pharmacie ' . fake()->company(),
            'phone' => fake()->unique()->numerify('+225##########'),
            'email' => fake()->unique()->companyEmail(),
            'address' => fake()->address(),
            'city' => fake()->randomElement(['Abidjan', 'Bouaké', 'Yamoussoukro', 'San-Pédro', 'Daloa']),
            'region' => fake()->randomElement(['Lagunes', 'Vallée du Bandama', 'Sassandra-Marahoué', 'Savanes', 'Montagnes']),
            'latitude' => fake()->latitude(5.0, 7.5),
            'longitude' => fake()->longitude(-8.0, -3.0),
            'status' => 'approved',
            'is_active' => true,
            'commission_rate_platform' => 0.10,
            'commission_rate_pharmacy' => 0.85,
            'commission_rate_courier' => 0.05,
            'license_number' => fake()->numerify('PHARM-####-####'),
            'owner_name' => fake()->name(),
            'is_featured' => fake()->boolean(20),
            'withdrawal_threshold' => 50000,
            'auto_withdraw_enabled' => false,
        ];
    }

    public function pending(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'pending',
        ]);
    }

    public function approved(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'approved',
            'is_active' => true,
            'approved_at' => now(),
        ]);
    }

    public function rejected(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'rejected',
            'is_active' => false,
            'rejection_reason' => 'Documents incomplets',
        ]);
    }

    public function inactive(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_active' => false,
        ]);
    }

    public function featured(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_featured' => true,
        ]);
    }

    public function withDutyZone(): static
    {
        return $this->state(fn (array $attributes) => [
            'duty_zone_id' => DutyZone::factory(),
        ]);
    }
}
