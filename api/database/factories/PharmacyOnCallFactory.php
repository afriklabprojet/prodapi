<?php

namespace Database\Factories;

use App\Models\PharmacyOnCall;
use App\Models\Pharmacy;
use App\Models\DutyZone;
use Illuminate\Database\Eloquent\Factories\Factory;

class PharmacyOnCallFactory extends Factory
{
    protected $model = PharmacyOnCall::class;

    public function definition(): array
    {
        $startDate = fake()->dateTimeBetween('now', '+1 week');
        $endDate = fake()->dateTimeBetween($startDate, '+2 weeks');

        return [
            'pharmacy_id' => Pharmacy::factory(),
            'duty_zone_id' => DutyZone::factory(),
            'start_at' => $startDate,
            'end_at' => $endDate,
            'is_active' => true,
        ];
    }

    public function active(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_active' => true,
            'start_at' => now()->subDay(),
            'end_at' => now()->addWeek(),
        ]);
    }

    public function past(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_active' => false,
            'start_at' => now()->subMonth(),
            'end_at' => now()->subWeek(),
        ]);
    }

    public function future(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_active' => true,
            'start_at' => now()->addWeek(),
            'end_at' => now()->addMonth(),
        ]);
    }
}
