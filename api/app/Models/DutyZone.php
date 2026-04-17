<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class DutyZone extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'city',
        'description',
        'is_active',
        'latitude',
        'longitude',
        'radius',
    ];

    protected $casts = [
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
        'radius' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    /**
     * Pharmacies dans cette zone
     */
    public function pharmacies(): HasMany
    {
        return $this->hasMany(Pharmacy::class);
    }

    /**
     * Gardes dans cette zone
     */
    public function onCalls(): HasMany
    {
        return $this->hasMany(PharmacyOnCall::class);
    }
}
