<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PharmacyOnCall extends Model
{
    use HasFactory;

    protected $fillable = [
        'pharmacy_id',
        'duty_zone_id',
        'start_at',
        'end_at',
        'type',
        'is_active',
    ];

    protected $casts = [
        'start_at' => 'datetime',
        'end_at' => 'datetime',
        'is_active' => 'boolean',
    ];

    /**
     * Pharmacie de garde
     */
    public function pharmacy(): BelongsTo
    {
        return $this->belongsTo(Pharmacy::class);
    }

    /**
     * Zone de garde
     */
    public function dutyZone(): BelongsTo
    {
        return $this->belongsTo(DutyZone::class);
    }
}
