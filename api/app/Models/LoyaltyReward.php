<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class LoyaltyReward extends Model
{
    protected $fillable = [
        'name',
        'description',
        'type',
        'points_cost',
        'value',
        'value_type',
        'min_tier',
        'is_active',
        'max_redemptions',
        'redemptions_count',
        'expires_at',
    ];

    protected $casts = [
        'points_cost' => 'integer',
        'value' => 'integer',
        'is_active' => 'boolean',
        'max_redemptions' => 'integer',
        'redemptions_count' => 'integer',
        'expires_at' => 'datetime',
    ];

    public function redemptions(): HasMany
    {
        return $this->hasMany(LoyaltyRedemption::class);
    }

    // ── Scopes ───────────────────────────────────────────────────

    public function scopeActive($query)
    {
        return $query->where('is_active', true)
            ->where(function ($q) {
                $q->whereNull('expires_at')
                    ->orWhere('expires_at', '>', now());
            })
            ->where(function ($q) {
                $q->whereNull('max_redemptions')
                    ->orWhereColumn('redemptions_count', '<', 'max_redemptions');
            });
    }

    public function scopeForTier($query, string $tier)
    {
        $tiers = ['bronze', 'silver', 'gold', 'platinum'];
        $tierIndex = array_search($tier, $tiers);
        $eligibleTiers = array_slice($tiers, 0, $tierIndex + 1);

        return $query->whereIn('min_tier', $eligibleTiers);
    }
}
