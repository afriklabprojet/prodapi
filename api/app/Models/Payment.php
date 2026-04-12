<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Payment extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'provider',
        'reference',
        'provider_transaction_id',
        'amount',
        'currency',
        'status',
        'payment_method',
        'confirmed_at',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'confirmed_at' => 'datetime',
    ];

    /**
     * Commande associée
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }
}
