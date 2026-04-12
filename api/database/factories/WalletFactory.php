<?php

namespace Database\Factories;

use App\Models\Courier;
use App\Models\Wallet;
use Illuminate\Database\Eloquent\Factories\Factory;

class WalletFactory extends Factory
{
    protected $model = Wallet::class;

    public function definition(): array
    {
        $courier = Courier::factory()->create();
        
        return [
            'walletable_type' => Courier::class,
            'walletable_id' => $courier->id,
            'balance' => fake()->numberBetween(0, 100000),
            'currency' => 'XOF',
        ];
    }

    /**
     * Create a wallet for a specific owner.
     */
    public function forOwner($owner): static
    {
        return $this->state(fn (array $attributes) => [
            'walletable_type' => get_class($owner),
            'walletable_id' => $owner->id,
        ]);
    }

    /**
     * Create a wallet with zero balance.
     */
    public function empty(): static
    {
        return $this->state(fn (array $attributes) => [
            'balance' => 0,
        ]);
    }

    /**
     * Create a wallet with a specific balance.
     */
    public function withBalance(float $balance): static
    {
        return $this->state(fn (array $attributes) => [
            'balance' => $balance,
        ]);
    }
}
