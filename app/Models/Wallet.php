<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Support\Facades\DB;

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
     * Créditer le wallet (thread-safe avec lock + idempotent)
     */
    public function credit(float $amount, string $reference, string $description, ?array $metadata = null): WalletTransaction
    {
        if ($amount <= 0) {
            throw new \InvalidArgumentException('Le montant du crédit doit être positif');
        }

        return DB::transaction(function () use ($amount, $reference, $description, $metadata) {
            $wallet = self::where('id', $this->id)->lockForUpdate()->first();

            if (!$wallet) {
                throw new \RuntimeException('Wallet introuvable');
            }

            // Idempotency: vérifier si cette référence existe déjà
            $existing = $wallet->transactions()->where('reference', $reference)->first();
            if ($existing) {
                \Illuminate\Support\Facades\Log::info('Wallet credit: duplicate reference (idempotent)', [
                    'wallet_id' => $wallet->id,
                    'reference' => $reference,
                ]);
                return $existing;
            }

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
     * Débiter le wallet (thread-safe avec lock + protection solde négatif)
     */
    public function debit(float $amount, string $reference, string $description, ?array $metadata = null): WalletTransaction
    {
        if ($amount <= 0) {
            throw new \InvalidArgumentException('Le montant du débit doit être positif');
        }

        return DB::transaction(function () use ($amount, $reference, $description, $metadata) {
            $wallet = self::where('id', $this->id)->lockForUpdate()->first();

            if (!$wallet) {
                throw new \RuntimeException('Wallet introuvable');
            }

            if ($wallet->balance < $amount) {
                throw new \App\Exceptions\InsufficientBalanceException(
                    "Solde insuffisant: {$wallet->balance} < {$amount}"
                );
            }

            // Idempotency: vérifier si cette référence existe déjà
            $existing = $wallet->transactions()->where('reference', $reference)->first();
            if ($existing) {
                \Illuminate\Support\Facades\Log::info('Wallet debit: duplicate reference (idempotent)', [
                    'wallet_id' => $wallet->id,
                    'reference' => $reference,
                ]);
                return $existing;
            }

            $newBalance = $wallet->balance - $amount;

            $transaction = $wallet->transactions()->create([
                'type' => 'DEBIT',
                'amount' => $amount,
                'balance_after' => $newBalance,
                'reference' => $reference,
                'description' => $description,
                'metadata' => $metadata,
            ]);

            // Utiliser WHERE balance >= amount pour empêcher physiquement le négatif
            // SECURITY H-4: Eloquent decrement génère un binding paramétré (pas d'interpolation SQL)
            $affected = self::where('id', $wallet->id)
                ->where('balance', '>=', $amount)
                ->decrement('balance', abs($amount));

            if ($affected === 0) {
                throw new \App\Exceptions\InsufficientBalanceException(
                    'Race condition détectée: solde insuffisant au moment du débit'
                );
            }

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

