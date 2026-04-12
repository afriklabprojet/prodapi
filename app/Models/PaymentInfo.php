<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentInfo extends Model
{
    protected $fillable = [
        'pharmacy_id',
        'type',
        'bank_name',
        'holder_name',
        'account_number',
        'iban',
        'operator',
        'phone_number',
        'is_primary',
        'is_verified',
        'verified_at',
    ];

    protected $casts = [
        'is_primary' => 'boolean',
        'is_verified' => 'boolean',
        'verified_at' => 'datetime',
    ];

    /**
     * Pharmacie propriétaire
     */
    public function pharmacy(): BelongsTo
    {
        return $this->belongsTo(Pharmacy::class);
    }
}
