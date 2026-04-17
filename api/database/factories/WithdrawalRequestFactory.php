<?php

namespace Database\Factories;

use App\Models\Courier;
use App\Models\Pharmacy;
use App\Models\Wallet;
use App\Models\WithdrawalRequest;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class WithdrawalRequestFactory extends Factory
{
    protected $model = WithdrawalRequest::class;

    public function definition(): array
    {
        $requestableType = $this->faker->randomElement([Pharmacy::class, Courier::class]);
        
        return [
            'wallet_id' => Wallet::factory(),
            'requestable_type' => $requestableType,
            'requestable_id' => $requestableType === Pharmacy::class 
                ? Pharmacy::factory() 
                : Courier::factory(),
            'amount' => $this->faker->numberBetween(1000, 50000),
            'payment_method' => $this->faker->randomElement(['orange', 'mtn', 'moov', 'wave', 'djamo']),
            'phone' => '+225' . $this->faker->numerify('##########'),
            'reference' => 'WD-' . strtoupper(Str::random(8)),
            'status' => 'pending',
        ];
    }

    /**
     * Retrait d'une pharmacie
     */
    public function fromPharmacy(): static
    {
        return $this->state(fn (array $attributes) => [
            'requestable_type' => Pharmacy::class,
            'requestable_id' => Pharmacy::factory(),
        ]);
    }

    /**
     * Retrait d'un livreur
     */
    public function fromCourier(): static
    {
        return $this->state(fn (array $attributes) => [
            'requestable_type' => Courier::class,
            'requestable_id' => Courier::factory(),
        ]);
    }

    /**
     * Statut en attente
     */
    public function pending(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'pending',
        ]);
    }

    /**
     * Statut en cours de traitement
     */
    public function processing(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'processing',
            'processed_at' => now(),
            'jeko_reference' => 'JEKO-' . strtoupper(Str::random(10)),
        ]);
    }

    /**
     * Statut complété
     */
    public function completed(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'completed',
            'processed_at' => now()->subHours(2),
            'completed_at' => now(),
            'jeko_reference' => 'JEKO-' . strtoupper(Str::random(10)),
        ]);
    }

    /**
     * Statut échoué
     */
    public function failed(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'failed',
            'error_message' => 'Transaction échouée',
        ]);
    }
}
