<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Challenge extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'type',
        'metric',
        'target_value',
        'reward_amount',
        'icon',
        'color',
        'is_active',
        'starts_at',
        'ends_at',
    ];

    protected $casts = [
        'target_value' => 'integer',
        'reward_amount' => 'integer',
        'is_active' => 'boolean',
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
    ];

    /**
     * Livreurs participant à ce challenge
     */
    public function couriers(): BelongsToMany
    {
        return $this->belongsToMany(Courier::class, 'courier_challenges')
            ->withPivot('current_progress', 'status', 'started_at', 'completed_at', 'rewarded_at')
            ->withTimestamps();
    }
}
