<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class Wallet extends Model
{
    use HasFactory;

    protected $fillable = [
        'walletable_type',
        'walletable_id',
        'balance',
        'currency',
    ];

    protected $casts = [
        'balance' => 'decimal:2',
    ];

    /**
     * Propriétaire du wallet (Pharmacy, Courier, ou Platform)
     */
    public function walletable(): MorphTo
    {
        return $this->morphTo();
    }

    /**
     * Transactions du wallet
     */
    public function transactions(): HasMany
    {
        return $this->hasMany(WalletTransaction::class);
    }

    /**
     * Wallet de la plateforme (singleton via ID fixe)
     */
    public static function platform(): self
    {
        return self::firstOrCreate([
            'walletable_type' => 'platform',
            'walletable_id' => 0,
        ], [
            'balance' => 0,
            'currency' => 'XOF',
        ]);
    }

    /**
     * Vérifier si le solde est suffisant
     */
    public function hasSufficientBalance(float $amount): bool
    {
        return $this->balance >= $amount;
    }

    /**
     * Créditer le wallet (thread-safe avec lock)
     */
    public function credit(float $amount, string $reference, string $description, ?array $metadata = null): WalletTransaction
    {
        return \DB::transaction(function () use ($amount, $reference, $description, $metadata) {
            $wallet = self::where('id', $this->id)->lockForUpdate()->first();

            $transaction = $wallet->transactions()->create([
                'type' => 'CREDIT',
                'amount' => $amount,
                'balance_after' => $wallet->balance + $amount,
                'reference' => $reference,
                'description' => $description,
                'metadata' => $metadata,
            ]);

            $wallet->increment('balance', $amount);
            $this->refresh();

            return $transaction;
        });
    }

    /**
     * Débiter le wallet (thread-safe avec lock)
     */
    public function debit(float $amount, string $reference, string $description, ?array $metadata = null): WalletTransaction
    {
        return \DB::transaction(function () use ($amount, $reference, $description, $metadata) {
            $wallet = self::where('id', $this->id)->lockForUpdate()->first();

            if ($wallet->balance < $amount) {
                throw new \Exception('Insufficient balance');
            }

            $transaction = $wallet->transactions()->create([
                'type' => 'DEBIT',
                'amount' => $amount,
                'balance_after' => $wallet->balance - $amount,
                'reference' => $reference,
                'description' => $description,
                'metadata' => $metadata,
            ]);

            $wallet->decrement('balance', $amount);
            $this->refresh();

            return $transaction;
        });
    }

    /**
     * Demandes de retrait
     */
    public function payoutRequests(): HasMany
    {
        return $this->hasMany(PayoutRequest::class);
    }
}

