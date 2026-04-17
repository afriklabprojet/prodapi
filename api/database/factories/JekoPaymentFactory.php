<?php

namespace Database\Factories;

use App\Enums\JekoPaymentMethod;
use App\Enums\JekoPaymentStatus;
use App\Models\JekoPayment;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class JekoPaymentFactory extends Factory
{
    protected $model = JekoPayment::class;

    public function definition(): array
    {
        return [
            'uuid' => (string) Str::uuid(),
            'reference' => 'JEKO-' . strtoupper(Str::random(10)),
            'payable_type' => 'App\Models\Order',
            'payable_id' => 1,
            'user_id' => null,
            'amount_cents' => $this->faker->numberBetween(10000, 1000000),
            'currency' => 'XOF',
            'payment_method' => JekoPaymentMethod::WAVE,
            'status' => JekoPaymentStatus::PENDING,
            'initiated_at' => now(),
        ];
    }
}
