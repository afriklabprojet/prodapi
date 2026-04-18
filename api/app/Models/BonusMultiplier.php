<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BonusMultiplier extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'type',
        'multiplier',
        'flat_bonus',
        'conditions',
        'is_active',
        'starts_at',
        'ends_at',
    ];

    protected $casts = [
        'multiplier' => 'decimal:2',
        'flat_bonus' => 'integer',
        'conditions' => 'array',
        'is_active' => 'boolean',
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
    ];
}
