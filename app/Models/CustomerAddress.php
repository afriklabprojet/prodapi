<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CustomerAddress extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'label',
        'address',
        'city',
        'district',
        'phone',
        'instructions',
        'latitude',
        'longitude',
        'is_default',
    ];

    protected $casts = [
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
        'is_default' => 'boolean',
    ];

    protected $appends = ['full_address', 'has_coordinates'];

    public function getFullAddressAttribute(): string
    {
        $parts = array_filter([
            $this->address,
            $this->district,
            $this->city,
        ]);
        return implode(', ', $parts);
    }

    public function getHasCoordinatesAttribute(): bool
    {
        return $this->latitude !== null && $this->longitude !== null;
    }

    /**
     * Client propriétaire
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
