<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentIntent extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'provider',
        'reference',
        'provider_reference',
        'provider_transaction_id',
        'amount',
        'currency',
        'status',
        'provider_payment_url',
        'raw_response',
        'raw_webhook',
        'confirmed_at',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'raw_response' => 'array',
        'raw_webhook' => 'array',
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
