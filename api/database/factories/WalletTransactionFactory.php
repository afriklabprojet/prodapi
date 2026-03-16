<?php

namespace Database\Factories;

use App\Models\WalletTransaction;
use App\Models\Wallet;
use Illuminate\Database\Eloquent\Factories\Factory;

class WalletTransactionFactory extends Factory
{
    protected $model = WalletTransaction::class;

    public function definition(): array
    {
        $type = fake()->randomElement(['credit', 'debit']);
        
        return [
            'wallet_id' => Wallet::factory(),
            'type' => $type,
            'amount' => fake()->randomFloat(2, 500, 10000),
            'balance_after' => fake()->randomFloat(2, 0, 60000),
            'description' => fake()->randomElement([
                'Paiement livraison',
                'Commission pharmacie',
                'Retrait wallet',
                'Bonus challenge',
                'Remboursement'
            ]),
            'reference' => 'TXN-' . fake()->unique()->randomNumber(8),
            'metadata' => null,
        ];
    }

    public function credit(): static
    {
        return $this->state(fn (array $attributes) => [
            'type' => 'credit',
            'description' => 'Crédit wallet',
        ]);
    }

    public function debit(): static
    {
        return $this->state(fn (array $attributes) => [
            'type' => 'debit',
            'description' => 'Débit wallet',
        ]);
    }

    public function delivery(): static
    {
        return $this->state(fn (array $attributes) => [
            'type' => 'credit',
            'description' => 'Paiement livraison',
        ]);
    }

    public function withdrawal(): static
    {
        return $this->state(fn (array $attributes) => [
            'type' => 'debit',
            'description' => 'Retrait wallet',
        ]);
    }
}
