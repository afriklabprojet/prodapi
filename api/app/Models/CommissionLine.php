<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class CommissionLine extends Model
{
    protected $fillable = [
        'commission_id',
        'actor_type',
        'actor_id',
        'rate',
        'amount',
    ];

    protected $casts = [
        'rate' => 'decimal:2',
        'amount' => 'decimal:2',
    ];

    public function commission(): BelongsTo
    {
        return $this->belongsTo(Commission::class);
    }

    public function actor(): MorphTo
    {
        return $this->morphTo();
    }
}
