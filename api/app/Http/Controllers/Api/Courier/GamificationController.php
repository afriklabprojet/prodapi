<?php

namespace App\Http\Controllers\Api\Courier;

use App\Http\Controllers\Controller;
use App\Models\Courier;
use App\Models\Delivery;
use App\Services\ChallengeService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class GamificationController extends Controller
{
    public function __construct(
        protected ChallengeService $challengeService,
    ) {}

    /**
     * Récupérer toutes les données de gamification pour l'écran principal
     * 
     * GET /api/courier/gamification
     */
    public function index(Request $request): JsonResponse
    {
        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil coursier non trouvé',
                'error_code' => 'INCOMPLETE_KYC',
            ], 403);
        }

        // Calculer le niveau basé sur l'XP
        $level = $this->calculateLevel($courier);

        // Récupérer les badges (challenges complétés)
        $badges = $this->getBadges($courier);

        // Récupérer les badges récents (7 derniers jours)
        $recentBadges = $this->getRecentBadges($courier);

        // Récupérer le leaderboard
        $leaderboard = $this->getLeaderboard();

        // Position de l'utilisateur actuel
        $myRank = $this->getCurrentUserRank($courier);

        // Statistiques
        $stats = $this->getStats($courier);

        return response()->json([
            'success' => true,
            'data' => [
                'level' => $level,
                'badges' => $badges,
                'recent_badges' => $recentBadges,
                'leaderboard' => $leaderboard,
                'my_rank' => $myRank,
                'stats' => $stats,
            ],
        ]);
    }

    /**
     * Calculer le niveau du livreur basé sur son XP (livraisons + notes)
     */
    private function calculateLevel(Courier $courier): array
    {
        $completedDeliveries = $courier->deliveries()->where('status', 'delivered')->count();
        $rating = $courier->rating ?? 5;
        
        // XP: 10 points par livraison + bonus pour bonne note
        $baseXP = $completedDeliveries * 10;
        $ratingBonus = floor(($rating - 4) * $completedDeliveries * 2); // Bonus si rating > 4
        $totalXP = max(0, $baseXP + $ratingBonus);

        // Définition des niveaux
        $levels = [
            ['level' => 1, 'title' => 'Débutant', 'xp' => 0, 'color' => 'bronze'],
            ['level' => 5, 'title' => 'Apprenti', 'xp' => 500, 'color' => 'bronze'],
            ['level' => 10, 'title' => 'Confirmé', 'xp' => 1500, 'color' => 'silver'],
            ['level' => 15, 'title' => 'Expert', 'xp' => 3000, 'color' => 'silver'],
            ['level' => 20, 'title' => 'Vétéran', 'xp' => 5000, 'color' => 'gold'],
            ['level' => 30, 'title' => 'Maître', 'xp' => 10000, 'color' => 'gold'],
            ['level' => 40, 'title' => 'Champion', 'xp' => 20000, 'color' => 'platinum'],
            ['level' => 50, 'title' => 'Légende', 'xp' => 50000, 'color' => 'diamond'],
        ];

        // Trouver le niveau actuel
        $currentLevel = $levels[0];
        $nextLevel = $levels[1] ?? null;

        for ($i = count($levels) - 1; $i >= 0; $i--) {
            if ($totalXP >= $levels[$i]['xp']) {
                $currentLevel = $levels[$i];
                $nextLevel = $levels[$i + 1] ?? null;
                break;
            }
        }

        $currentXP = $nextLevel 
            ? $totalXP - $currentLevel['xp'] 
            : $totalXP - $currentLevel['xp'];
        $requiredXP = $nextLevel 
            ? $nextLevel['xp'] - $currentLevel['xp'] 
            : 10000;

        return [
            'level' => $currentLevel['level'],
            'title' => $currentLevel['title'],
            'color' => $currentLevel['color'],
            'current_xp' => $currentXP,
            'required_xp' => $requiredXP,
            'total_xp' => $totalXP,
            'perks' => $this->getPerksForLevel($currentLevel['level']),
        ];
    }

    /**
     * Avantages par niveau
     */
    private function getPerksForLevel(int $level): array
    {
        $perks = [];
        
        if ($level >= 5) $perks[] = 'Accès aux livraisons premium';
        if ($level >= 10) $perks[] = 'Badge visible par les clients';
        if ($level >= 15) $perks[] = 'Bonus de fidélité +5%';
        if ($level >= 20) $perks[] = 'Priorité sur les commandes';
        if ($level >= 30) $perks[] = 'Bonus de fidélité +10%';
        if ($level >= 40) $perks[] = 'Support prioritaire';
        if ($level >= 50) $perks[] = 'Accès VIP';
        
        return $perks;
    }

    /**
     * Récupérer les badges basés sur les challenges complétés
     */
    private function getBadges(Courier $courier): array
    {
        $completedDeliveries = $courier->deliveries()->where('status', 'delivered')->count();
        $rating = $courier->rating ?? 5;

        // Badges basés sur les métriques réelles
        $badgeDefinitions = [
            // Badges de livraison
            [
                'id' => 'first_delivery',
                'name' => 'Première Livraison',
                'description' => 'Effectuer votre première livraison',
                'icon' => 'delivery',
                'color' => 'bronze',
                'category' => 'deliveries',
                'required_value' => 1,
                'current_value' => $completedDeliveries,
            ],
            [
                'id' => 'delivery_10',
                'name' => '10 Livraisons',
                'description' => 'Effectuer 10 livraisons',
                'icon' => 'delivery',
                'color' => 'bronze',
                'category' => 'deliveries',
                'required_value' => 10,
                'current_value' => $completedDeliveries,
            ],
            [
                'id' => 'delivery_50',
                'name' => '50 Livraisons',
                'description' => 'Effectuer 50 livraisons',
                'icon' => 'delivery',
                'color' => 'silver',
                'category' => 'deliveries',
                'required_value' => 50,
                'current_value' => $completedDeliveries,
            ],
            [
                'id' => 'delivery_100',
                'name' => 'Centurion',
                'description' => 'Effectuer 100 livraisons',
                'icon' => 'medal',
                'color' => 'gold',
                'category' => 'deliveries',
                'required_value' => 100,
                'current_value' => $completedDeliveries,
            ],
            [
                'id' => 'delivery_500',
                'name' => 'Légende',
                'description' => 'Effectuer 500 livraisons',
                'icon' => 'trophy',
                'color' => 'gold',
                'category' => 'deliveries',
                'required_value' => 500,
                'current_value' => $completedDeliveries,
            ],
            // Badges de satisfaction
            [
                'id' => 'five_star',
                'name' => '5 Étoiles',
                'description' => 'Maintenir une note de 5 étoiles',
                'icon' => 'star',
                'color' => 'gold',
                'category' => 'rating',
                'required_value' => 5,
                'current_value' => (int) floor($rating),
            ],
            [
                'id' => 'four_star_plus',
                'name' => 'Excellence',
                'description' => 'Maintenir une note supérieure à 4.5',
                'icon' => 'verified',
                'color' => 'green',
                'category' => 'rating',
                'required_value' => 45, // 4.5 * 10
                'current_value' => (int) floor($rating * 10),
            ],
        ];

        // Ajouter les badges depuis les challenges complétés
        $challengeBadges = $courier->challenges()
            ->wherePivot('status', 'completed')
            ->get()
            ->map(fn ($challenge) => [
                'id' => 'challenge_' . $challenge->id,
                'name' => $challenge->title,
                'description' => $challenge->description,
                'icon' => $challenge->icon ?? 'star',
                'color' => $this->parseColor($challenge->color),
                'category' => 'general',
                'required_value' => $challenge->target_value ?? 1,
                'current_value' => $challenge->pivot->current_progress ?? $challenge->target_value,
                'is_unlocked' => true,
                'unlocked_at' => $challenge->pivot->completed_at,
            ])
            ->toArray();

        // Combiner et marquer les badges débloqués
        $allBadges = array_merge(
            array_map(function ($badge) {
                $isUnlocked = $badge['current_value'] >= $badge['required_value'];
                return array_merge($badge, [
                    'is_unlocked' => $isUnlocked,
                    'unlocked_at' => $isUnlocked ? now()->toISOString() : null,
                ]);
            }, $badgeDefinitions),
            $challengeBadges
        );

        return $allBadges;
    }

    /**
     * Badges débloqués récemment (7 derniers jours)
     */
    private function getRecentBadges(Courier $courier): array
    {
        return $courier->challenges()
            ->wherePivot('status', 'completed')
            ->wherePivot('completed_at', '>=', now()->subDays(7))
            ->get()
            ->map(fn ($challenge) => [
                'id' => 'challenge_' . $challenge->id,
                'name' => $challenge->title,
                'description' => $challenge->description,
                'icon' => $challenge->icon ?? 'star',
                'color' => $this->parseColor($challenge->color),
                'unlocked_at' => $challenge->pivot->completed_at,
            ])
            ->toArray();
    }

    /**
     * Convertir les couleurs hex en noms
     */
    private function parseColor(?string $color): string
    {
        if (!$color) return 'blue';
        
        $colorMap = [
            '#FFD700' => 'gold',
            '#C0C0C0' => 'silver',
            '#CD7F32' => 'bronze',
            '#00FF00' => 'green',
            '#0000FF' => 'blue',
            '#800080' => 'purple',
            '#FF0000' => 'red',
            '#FFA500' => 'orange',
        ];

        return $colorMap[$color] ?? strtolower(str_replace('#', '', $color));
    }

    /**
     * Récupérer le leaderboard
     */
    private function getLeaderboard(string $period = 'week', int $limit = 10): array
    {
        $startDate = match ($period) {
            'day' => now()->startOfDay(),
            'week' => now()->startOfWeek(),
            'month' => now()->startOfMonth(),
            default => now()->startOfWeek(),
        };

        return Courier::query()
            ->select([
                'couriers.id',
                'couriers.rating',
                'users.name',
                'users.avatar',
            ])
            ->join('users', 'couriers.user_id', '=', 'users.id')
            ->withCount(['deliveries as deliveries_count' => function ($query) use ($startDate) {
                $query->where('status', 'delivered')
                    ->where('delivered_at', '>=', $startDate);
            }])
            ->orderByDesc('deliveries_count')
            ->limit($limit)
            ->get()
            ->map(function ($courier, $index) {
                return [
                    'rank' => $index + 1,
                    'courier_id' => $courier->id,
                    'name' => $courier->name,
                    'avatar' => $courier->avatar,
                    'deliveries_count' => $courier->deliveries_count,
                    'score' => $courier->deliveries_count * 10,
                    'level' => $this->estimateLevel($courier->deliveries_count),
                ];
            })
            ->toArray();
    }

    /**
     * Estimer le niveau basé sur le nombre de livraisons
     */
    private function estimateLevel(int $deliveries): int
    {
        $xp = $deliveries * 10;
        
        if ($xp >= 50000) return 50;
        if ($xp >= 20000) return 40;
        if ($xp >= 10000) return 30;
        if ($xp >= 5000) return 20;
        if ($xp >= 3000) return 15;
        if ($xp >= 1500) return 10;
        if ($xp >= 500) return 5;
        return 1;
    }

    /**
     * Rang de l'utilisateur actuel
     */
    private function getCurrentUserRank(Courier $courier): ?array
    {
        $startDate = now()->startOfWeek();

        $deliveriesCount = $courier->deliveries()
            ->where('status', 'delivered')
            ->where('delivered_at', '>=', $startDate)
            ->count();

        // Calculer le rang
        $rank = Courier::query()
            ->withCount(['deliveries as deliveries_count' => function ($query) use ($startDate) {
                $query->where('status', 'delivered')
                    ->where('delivered_at', '>=', $startDate);
            }])
            ->having('deliveries_count', '>', $deliveriesCount)
            ->count() + 1;

        return [
            'rank' => $rank,
            'courier_id' => $courier->id,
            'name' => $courier->user->name,
            'avatar' => $courier->user->avatar,
            'deliveries_count' => $deliveriesCount,
            'score' => $deliveriesCount * 10,
            'level' => $this->estimateLevel($deliveriesCount),
        ];
    }

    /**
     * Statistiques pour la gamification
     */
    private function getStats(Courier $courier): array
    {
        $totalDeliveries = $courier->deliveries()->where('status', 'delivered')->count();
        
        // Calculer le streak (jours consécutifs avec au moins 1 livraison)
        $currentStreak = $this->calculateStreak($courier);
        
        return [
            'total_deliveries' => $totalDeliveries,
            'current_streak' => $currentStreak,
            'best_streak' => $currentStreak, // Pour l'instant, on utilise le streak actuel
            'total_earnings' => (int) ($courier->commissionLines()->sum('amount') ?? 0),
        ];
    }

    /**
     * Calculer le streak (jours consécutifs)
     */
    private function calculateStreak(Courier $courier): int
    {
        $streak = 0;
        $date = now()->startOfDay();

        while (true) {
            $hasDelivery = $courier->deliveries()
                ->where('status', 'delivered')
                ->whereDate('delivered_at', $date)
                ->exists();

            if (!$hasDelivery) {
                // Si pas de livraison aujourd'hui, vérifier hier
                if ($date->isToday()) {
                    $date = $date->subDay();
                    continue;
                }
                break;
            }

            $streak++;
            $date = $date->subDay();
        }

        return $streak;
    }
}
