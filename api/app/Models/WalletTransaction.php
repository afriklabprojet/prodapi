<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WalletTransaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'wallet_id',
        'type',
        'amount',
        'balance_after',
        'reference',
        'description',
        'metadata',
        'category',
        'delivery_id',
        'status',
        'payment_method',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'balance_after' => 'decimal:2',
        'metadata' => 'array',
    ];

    /**
     * Wallet associé
     */
    public function wallet(): BelongsTo
    {
        return $this->belongsTo(Wallet::class);
    }

    /**
     * Scope: Seulement les crédits
     */
    public function scopeCredits(Builder $query): Builder
    {
        return $query->where('type', 'CREDIT');
    }

    /**
     * Scope: Seulement les débits
     */
    public function scopeDebits(Builder $query): Builder
    {
        return $query->where('type', 'DEBIT');
    }
}

