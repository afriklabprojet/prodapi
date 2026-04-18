<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InventoryBatch extends Model
{
    protected $fillable = [
        'product_id',
        'pharmacy_id',
        'batch_number',
        'lot_number',
        'expiry_date',
        'quantity',
        'received_at',
        'supplier',
    ];

    protected $casts = [
        'expiry_date' => 'date',
        'received_at' => 'date',
        'quantity'    => 'integer',
    ];

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function pharmacy(): BelongsTo
    {
        return $this->belongsTo(Pharmacy::class);
    }

    public function isExpired(): bool
    {
        return $this->expiry_date->isPast();
    }

    public function isExpiringSoon(int $daysThreshold = 30): bool
    {
        return !$this->isExpired() && $this->expiry_date->diffInDays(now()) <= $daysThreshold;
    }
}
