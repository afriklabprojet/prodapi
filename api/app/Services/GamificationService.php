<?php

namespace App\Services;

use App\Models\Courier;
use App\Models\CourierChallengeProgress;
use App\Models\Delivery;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class GamificationService
{
    /**
     * Badges disponibles
     */
    const BADGES = [
        'first_delivery' => [
            'name' => 'Première livraison',
            'description' => 'Complétez votre première livraison',
            'icon' => '🚀',
            'xp' => 50,
        ],
        'ten_deliveries' => [
            'name' => 'Débutant',
            'description' => '10 livraisons complétées',
            'icon' => '⭐',
            'xp' => 100,
        ],
        'fifty_deliveries' => [
            'name' => 'Confirmé',
            'description' => '50 livraisons complétées',
            'icon' => '🌟',
            'xp' => 250,
        ],
        'hundred_deliveries' => [
            'name' => 'Expert',
            'description' => '100 livraisons complétées',
            'icon' => '💫',
            'xp' => 500,
        ],
        'five_hundred_deliveries' => [
            'name' => 'Vétéran',
            'description' => '500 livraisons complétées',
            'icon' => '🏆',
            'xp' => 2000,
        ],
        'perfect_week' => [
            'name' => 'Semaine parfaite',
            'description' => '100% de livraisons à l\'heure cette semaine',
            'icon' => '✨',
            'xp' => 300,
        ],
        'night_owl' => [
            'name' => 'Oiseau de nuit',
            'description' => '20 livraisons de nuit (22h-6h)',
            'icon' => '🦉',
            'xp' => 200,
        ],
        'speed_demon' => [
            'name' => 'As de la vitesse',
            'description' => '10 livraisons avec 5+ minutes d\'avance sur l\'ETA',
            'icon' => '⚡',
            'xp' => 250,
        ],
        'five_star' => [
            'name' => 'Excellence',
            'description' => 'Maintenir 5 étoiles sur 50 livraisons consécutives',
            'icon' => '🌠',
            'xp' => 500,
        ],
        'streak_master' => [
            'name' => 'Série en cours',
            'description' => '30 jours d\'activité consécutifs',
            'icon' => '🔥',
            'xp' => 1000,
        ],
    ];

    /**
     * XP par action
     */
    const XP_REWARDS = [
        'delivery_completed' => 25,
        'on_time_delivery' => 10,
        'early_delivery' => 20,
        'five_star_rating' => 15,
        'peak_hour_delivery' => 15,
        'batch_delivery' => 30,
        'night_delivery' => 20,
    ];

    /**
     * Traiter une livraison complétée
     */
    public function onDeliveryCompleted(Delivery $delivery): void
    {
        $courier = $delivery->courier;
        if (!$courier) return;

        $xpEarned = 0;
        $actions = [];

        // XP de base
        $xpEarned += self::XP_REWARDS['delivery_completed'];
        $actions[] = 'delivery_completed';

        // Vérifier la ponctualité
        if ($this->wasOnTime($delivery)) {
            $xpEarned += self::XP_REWARDS['on_time_delivery'];
            $actions[] = 'on_time_delivery';

            // Livraison en avance (5+ minutes)
            if ($this->wasEarly($delivery, 300)) {
                $xpEarned += self::XP_REWARDS['early_delivery'];
                $actions[] = 'early_delivery';
            }
        }

        // Heure de pointe
        if ($this->isPeakHour($delivery->completed_at)) {
            $xpEarned += self::XP_REWARDS['peak_hour_delivery'];
            $actions[] = 'peak_hour_delivery';
        }

        // Livraison de nuit
        if ($this->isNightDelivery($delivery->completed_at)) {
            $xpEarned += self::XP_REWARDS['night_delivery'];
            $actions[] = 'night_delivery';
        }

        // Livraison batch
        if ($delivery->order->order_batch_id) {
            $xpEarned += self::XP_REWARDS['batch_delivery'];
            $actions[] = 'batch_delivery';
        }

        // Ajouter l'XP
        $courier->addXp($xpEarned, implode(',', $actions));

        // Mettre à jour le streak
        $courier->updateStreak();

        // Vérifier les badges
        $this->checkBadges($courier);

        // Mettre à jour les challenges
        $this->updateChallenges($courier, $delivery);

        Log::info("Gamification: Courier {$courier->id} earned {$xpEarned} XP", [
            'actions' => $actions,
            'total_xp' => $courier->total_xp + $xpEarned,
        ]);
    }

    /**
     * Traiter une note 5 étoiles
     */
    public function onFiveStarRating(Delivery $delivery): void
    {
        $courier = $delivery->courier;
        if (!$courier) return;

        $courier->addXp(self::XP_REWARDS['five_star_rating'], 'five_star_rating');
        
        // Mettre à jour le challenge de note parfaite
        $progress = CourierChallengeProgress::getOrCreate(
            $courier,
            CourierChallengeProgress::CHALLENGE_PERFECT_RATING,
            today()->toDateString()
        );
        $progress->incrementProgress();
    }

    /**
     * Vérifier et attribuer les badges
     */
    public function checkBadges(Courier $courier): void
    {
        $existingBadges = $courier->badges ?? [];
        $completed = $courier->completed_deliveries;

        // Badges de livraisons
        $milestoneBadges = [
            'first_delivery' => 1,
            'ten_deliveries' => 10,
            'fifty_deliveries' => 50,
            'hundred_deliveries' => 100,
            'five_hundred_deliveries' => 500,
        ];

        foreach ($milestoneBadges as $badge => $threshold) {
            if ($completed >= $threshold && !in_array($badge, $existingBadges)) {
                $this->awardBadge($courier, $badge);
            }
        }

        // Badge streak
        if ($courier->current_streak_days >= 30 && !in_array('streak_master', $existingBadges)) {
            $this->awardBadge($courier, 'streak_master');
        }
    }

    /**
     * Attribuer un badge
     */
    public function awardBadge(Courier $courier, string $badge): void
    {
        if (!isset(self::BADGES[$badge])) {
            return;
        }

        $courier->addBadge($badge);
        $courier->addXp(self::BADGES[$badge]['xp'], "badge:{$badge}");

        // Créditer un bonus si applicable
        $bonusAmount = $this->getBadgeBonus($badge);
        if ($bonusAmount > 0 && $courier->wallet) {
            $courier->wallet->credit(
                $bonusAmount,
                'badge_reward',
                "Badge obtenu: " . self::BADGES[$badge]['name']
            );
        }

        Log::info("Gamification: Courier {$courier->id} earned badge {$badge}");
    }

    /**
     * Bonus monétaire pour certains badges
     */
    protected function getBadgeBonus(string $badge): int
    {
        $bonuses = [
            'first_delivery' => 500,
            'fifty_deliveries' => 2000,
            'hundred_deliveries' => 5000,
            'five_hundred_deliveries' => 15000,
            'streak_master' => 10000,
        ];

        return $bonuses[$badge] ?? 0;
    }

    /**
     * Mettre à jour les challenges
     */
    protected function updateChallenges(Courier $courier, Delivery $delivery): void
    {
        // Challenge journalier
        $dailyProgress = CourierChallengeProgress::getOrCreate(
            $courier,
            CourierChallengeProgress::CHALLENGE_DAILY_STREAK
        );
        $dailyProgress->incrementProgress();

        // Challenge heure de pointe
        if ($this->isPeakHour($delivery->completed_at)) {
            $peakProgress = CourierChallengeProgress::getOrCreate(
                $courier,
                CourierChallengeProgress::CHALLENGE_PEAK_HOUR_HERO
            );
            $peakProgress->incrementProgress();
        }

        // Challenge vitesse
        if ($this->wasEarly($delivery, 300)) {
            $speedProgress = CourierChallengeProgress::getOrCreate(
                $courier,
                CourierChallengeProgress::CHALLENGE_SPEED_DEMON
            );
            $speedProgress->incrementProgress();
        }
    }

    /**
     * Obtenir le tableau de bord gamification d'un livreur
     */
    public function getDashboard(Courier $courier): array
    {
        // Progression vers le prochain tier
        $currentXp = $courier->total_xp ?? 0;
        $currentTier = $courier->tier ?? Courier::TIER_BRONZE;
        $nextTier = $this->getNextTier($currentTier);
        $xpForNextTier = $nextTier ? Courier::TIER_XP_THRESHOLDS[$nextTier] : null;

        $tierProgress = null;
        if ($xpForNextTier) {
            $currentThreshold = Courier::TIER_XP_THRESHOLDS[$currentTier];
            $xpInCurrentTier = $currentXp - $currentThreshold;
            $xpNeededForNext = $xpForNextTier - $currentThreshold;
            $tierProgress = min(100, round(($xpInCurrentTier / $xpNeededForNext) * 100));
        }

        // Challenges du jour
        $todayChallenges = CourierChallengeProgress::forCourier($courier->id)
            ->today()
            ->get()
            ->map(function ($progress) {
                return [
                    'type' => $progress->challenge_type,
                    'description' => $progress->config['description'] ?? '',
                    'current_progress' => $progress->current_progress,
                    'tier_reached' => $progress->tier_reached,
                    'next_target' => $progress->next_tier['target'] ?? null,
                    'next_reward' => $progress->next_tier['reward'] ?? null,
                    'progress_percent' => $progress->progress_percent,
                    'is_completed' => $progress->is_completed,
                ];
            });

        // Si aucun challenge aujourd'hui, initialiser
        if ($todayChallenges->isEmpty()) {
            $this->initializeDailyChallenges($courier);
            $todayChallenges = CourierChallengeProgress::forCourier($courier->id)
                ->today()
                ->get();
        }

        return [
            'xp' => [
                'total' => $currentXp,
                'tier' => $currentTier,
                'tier_label' => ucfirst($currentTier),
                'next_tier' => $nextTier,
                'xp_for_next_tier' => $xpForNextTier,
                'tier_progress' => $tierProgress,
            ],
            'streak' => [
                'days' => $courier->current_streak_days ?? 0,
                'last_active' => $courier->last_active_date?->format('Y-m-d'),
            ],
            'badges' => collect($courier->badges ?? [])->map(function ($badge) {
                return [
                    'id' => $badge,
                    ...self::BADGES[$badge] ?? [],
                ];
            }),
            'challenges' => $todayChallenges,
            'tier_benefits' => $courier->tier_benefits,
        ];
    }

    /**
     * Initialiser les challenges journaliers
     */
    public function initializeDailyChallenges(Courier $courier): void
    {
        $challengeTypes = [
            CourierChallengeProgress::CHALLENGE_DAILY_STREAK,
            CourierChallengeProgress::CHALLENGE_PEAK_HOUR_HERO,
        ];

        foreach ($challengeTypes as $type) {
            CourierChallengeProgress::getOrCreate($courier, $type);
        }
    }

    /**
     * Obtenir le leaderboard
     */
    public function getLeaderboard(int $limit = 20, string $period = 'weekly'): Collection
    {
        $startDate = match($period) {
            'daily' => today(),
            'weekly' => now()->startOfWeek(),
            'monthly' => now()->startOfMonth(),
            default => now()->startOfWeek(),
        };

        // Leaderboard basé sur les livraisons complétées dans la période
        return Courier::where('kyc_status', 'verified')
            ->withCount(['deliveries' => function ($q) use ($startDate) {
                $q->whereIn('status', ['delivered', 'completed'])
                    ->where('completed_at', '>=', $startDate);
            }])
            ->orderByDesc('deliveries_count')
            ->limit($limit)
            ->get()
            ->map(function ($courier, $index) {
                return [
                    'rank' => $index + 1,
                    'courier_id' => $courier->id,
                    'name' => $courier->name,
                    'tier' => $courier->tier,
                    'total_xp' => $courier->total_xp,
                    'deliveries_count' => $courier->deliveries_count,
                ];
            });
    }

    /**
     * Vérifications utilitaires
     */
    protected function wasOnTime(Delivery $delivery): bool
    {
        if (!$delivery->original_eta_seconds || !$delivery->assigned_at || !$delivery->completed_at) {
            return true;
        }

        $actualSeconds = $delivery->assigned_at->diffInSeconds($delivery->completed_at);
        return $actualSeconds <= ($delivery->original_eta_seconds + 300); // 5 min de tolérance
    }

    protected function wasEarly(Delivery $delivery, int $secondsThreshold): bool
    {
        if (!$delivery->original_eta_seconds || !$delivery->assigned_at || !$delivery->completed_at) {
            return false;
        }

        $actualSeconds = $delivery->assigned_at->diffInSeconds($delivery->completed_at);
        return $actualSeconds < ($delivery->original_eta_seconds - $secondsThreshold);
    }

    protected function isPeakHour($dateTime): bool
    {
        if (!$dateTime) return false;
        $hour = (int) $dateTime->format('H');
        return ($hour >= 11 && $hour < 14) || ($hour >= 18 && $hour < 22);
    }

    protected function isNightDelivery($dateTime): bool
    {
        if (!$dateTime) return false;
        $hour = (int) $dateTime->format('H');
        return $hour >= 22 || $hour < 6;
    }

    protected function getNextTier(string $currentTier): ?string
    {
        $tiers = array_keys(Courier::TIER_XP_THRESHOLDS);
        $currentIndex = array_search($currentTier, $tiers);
        
        if ($currentIndex === false || $currentIndex >= count($tiers) - 1) {
            return null;
        }

        return $tiers[$currentIndex + 1];
    }
}
