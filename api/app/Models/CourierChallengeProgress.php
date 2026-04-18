<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CourierChallengeProgress extends Model
{
    use HasFactory;

    protected $table = 'courier_challenge_progress';

    protected $fillable = [
        'courier_id',
        'challenge_type',
        'period_date',
        'current_progress',
        'tier_reached',
        'rewards_earned',
    ];

    protected $casts = [
        'period_date' => 'date',
        'current_progress' => 'integer',
        'tier_reached' => 'integer',
        'rewards_earned' => 'integer',
    ];

    // ──────────────────────────────────────────
    // CONSTANTES - Types de challenges
    // ──────────────────────────────────────────

    const CHALLENGE_DAILY_STREAK = 'daily_streak';
    const CHALLENGE_PEAK_HOUR_HERO = 'peak_hour_hero';
    const CHALLENGE_PERFECT_RATING = 'perfect_rating';
    const CHALLENGE_SPEED_DEMON = 'speed_demon';
    const CHALLENGE_ZONE_EXPLORER = 'zone_explorer';

    /**
     * Configuration des challenges et leurs niveaux
     */
    const CHALLENGE_CONFIGS = [
        self::CHALLENGE_DAILY_STREAK => [
            'description' => 'Faire X livraisons aujourd\'hui',
            'tiers' => [
                ['target' => 5, 'reward' => 250, 'xp' => 50],
                ['target' => 10, 'reward' => 600, 'xp' => 100],
                ['target' => 15, 'reward' => 1200, 'xp' => 200],
                ['target' => 20, 'reward' => 2000, 'xp' => 350],
            ],
        ],
        self::CHALLENGE_PEAK_HOUR_HERO => [
            'description' => 'Livrer pendant les heures de pointe',
            'tiers' => [
                ['target' => 3, 'reward' => 300, 'xp' => 60],
                ['target' => 7, 'reward' => 800, 'xp' => 150],
            ],
        ],
        self::CHALLENGE_PERFECT_RATING => [
            'description' => 'Maintenir 5 étoiles sur X livraisons',
            'tiers' => [
                ['target' => 10, 'reward' => 500, 'xp' => 100],
                ['target' => 25, 'reward' => 1500, 'xp' => 300],
            ],
        ],
        self::CHALLENGE_SPEED_DEMON => [
            'description' => 'Livrer X commandes avant l\'ETA',
            'tiers' => [
                ['target' => 5, 'reward' => 400, 'xp' => 80],
                ['target' => 15, 'reward' => 1000, 'xp' => 200],
            ],
        ],
        self::CHALLENGE_ZONE_EXPLORER => [
            'description' => 'Livrer dans X zones différentes cette semaine',
            'tiers' => [
                ['target' => 3, 'reward' => 300, 'xp' => 60],
                ['target' => 5, 'reward' => 700, 'xp' => 140],
            ],
        ],
    ];

    // ──────────────────────────────────────────
    // RELATIONS
    // ──────────────────────────────────────────

    public function courier(): BelongsTo
    {
        return $this->belongsTo(Courier::class);
    }

    // ──────────────────────────────────────────
    // ACCESSORS
    // ──────────────────────────────────────────

    /**
     * Obtenir la configuration du challenge
     */
    public function getConfigAttribute(): array
    {
        return self::CHALLENGE_CONFIGS[$this->challenge_type] ?? [];
    }

    /**
     * Tier actuel (niveau atteint)
     */
    public function getCurrentTierAttribute(): ?array
    {
        $config = $this->config;
        if (empty($config['tiers'])) return null;

        return $config['tiers'][$this->tier_reached - 1] ?? null;
    }

    /**
     * Prochain tier à atteindre
     */
    public function getNextTierAttribute(): ?array
    {
        $config = $this->config;
        if (empty($config['tiers'])) return null;

        return $config['tiers'][$this->tier_reached] ?? null;
    }

    /**
     * Progression vers le prochain tier en %
     */
    public function getProgressPercentAttribute(): int
    {
        $nextTier = $this->next_tier;
        if (!$nextTier) return 100;

        $previousTarget = $this->tier_reached > 0 
            ? ($this->config['tiers'][$this->tier_reached - 1]['target'] ?? 0)
            : 0;

        $targetRange = $nextTier['target'] - $previousTarget;
        $currentProgress = $this->current_progress - $previousTarget;

        if ($targetRange <= 0) return 100;
        return min(100, (int) round(($currentProgress / $targetRange) * 100));
    }

    /**
     * Challenge complété (tous les tiers atteints)
     */
    public function getIsCompletedAttribute(): bool
    {
        $totalTiers = count($this->config['tiers'] ?? []);
        return $this->tier_reached >= $totalTiers;
    }

    // ──────────────────────────────────────────
    // SCOPES
    // ──────────────────────────────────────────

    public function scopeForCourier($query, int $courierId)
    {
        return $query->where('courier_id', $courierId);
    }

    public function scopeForDate($query, $date)
    {
        return $query->whereDate('period_date', $date);
    }

    public function scopeToday($query)
    {
        return $query->whereDate('period_date', today());
    }

    public function scopeOfType($query, string $challengeType)
    {
        return $query->where('challenge_type', $challengeType);
    }

    // ──────────────────────────────────────────
    // MÉTHODES
    // ──────────────────────────────────────────

    /**
     * Incrémenter la progression
     */
    public function incrementProgress(int $amount = 1): void
    {
        $this->increment('current_progress', $amount);
        $this->checkTierUp();
    }

    /**
     * Vérifier si un nouveau tier est atteint
     */
    public function checkTierUp(): void
    {
        $config = $this->config;
        if (empty($config['tiers'])) return;

        $newTier = $this->tier_reached;
        $totalReward = 0;
        $totalXp = 0;

        foreach ($config['tiers'] as $index => $tier) {
            if ($index >= $this->tier_reached && $this->current_progress >= $tier['target']) {
                $newTier = $index + 1;
                $totalReward += $tier['reward'];
                $totalXp += $tier['xp'] ?? 0;
            }
        }

        if ($newTier > $this->tier_reached) {
            $this->update([
                'tier_reached' => $newTier,
                'rewards_earned' => $this->rewards_earned + $totalReward,
            ]);

            // Ajouter XP au livreur
            if ($totalXp > 0) {
                $this->courier->increment('total_xp', $totalXp);
            }

            // Créditer la récompense
            if ($totalReward > 0 && $this->courier->wallet) {
                $this->courier->wallet->credit(
                    $totalReward,
                    'challenge_reward',
                    "Récompense challenge: {$config['description']}"
                );
            }
        }
    }

    /**
     * Obtenir ou créer la progression pour un livreur et un challenge
     */
    public static function getOrCreate(Courier $courier, string $challengeType, ?string $date = null): self
    {
        $date = $date ?? today()->toDateString();

        return self::firstOrCreate(
            [
                'courier_id' => $courier->id,
                'challenge_type' => $challengeType,
                'period_date' => $date,
            ],
            [
                'current_progress' => 0,
                'tier_reached' => 0,
                'rewards_earned' => 0,
            ]
        );
    }
}
