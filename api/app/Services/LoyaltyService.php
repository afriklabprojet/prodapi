<?php

namespace App\Services;

use App\Models\CustomerLoyaltyPoint;
use App\Models\LoyaltyRedemption;
use App\Models\LoyaltyReward;
use App\Models\Order;
use App\Models\User;
use Illuminate\Support\Str;

class LoyaltyService
{
    // Points per 1000 FCFA spent
    private const POINTS_PER_1000_FCFA = 10;

    // Tier thresholds (total earned points)
    private const TIERS = [
        'bronze'   => 0,
        'silver'   => 500,
        'gold'     => 2000,
        'platinum' => 5000,
    ];

    // Tier discount percentages
    private const TIER_DISCOUNTS = [
        'bronze'   => 0,
        'silver'   => 5,
        'gold'     => 10,
        'platinum' => 15,
    ];

    /**
     * Award points for a delivered order.
     */
    public function awardPointsForOrder(Order $order): CustomerLoyaltyPoint
    {
        $points = $this->calculatePointsForAmount((float) $order->total_amount);

        return CustomerLoyaltyPoint::create([
            'user_id'     => $order->customer_id,
            'points'      => $points,
            'type'        => 'earned',
            'source'      => 'order',
            'source_id'   => $order->id,
            'description' => "Points gagnés pour la commande #{$order->reference}",
        ]);
    }

    /**
     * Award bonus points (referral, promo, etc.).
     */
    public function awardBonusPoints(int $userId, int $points, string $source, ?string $description = null): CustomerLoyaltyPoint
    {
        return CustomerLoyaltyPoint::create([
            'user_id'     => $userId,
            'points'      => $points,
            'type'        => 'bonus',
            'source'      => $source,
            'description' => $description ?? "Bonus de {$points} points",
        ]);
    }

    /**
     * Get loyalty summary for a user.
     */
    public function getSummary(int $userId): array
    {
        $totalEarned = CustomerLoyaltyPoint::forUser($userId)
            ->whereIn('type', ['earned', 'bonus'])
            ->sum('points');

        $totalRedeemed = abs(CustomerLoyaltyPoint::forUser($userId)
            ->where('type', 'redeemed')
            ->sum('points'));

        $availablePoints = $totalEarned - $totalRedeemed;
        $tier = $this->getTierForPoints($totalEarned);
        $nextTier = $this->getNextTier($tier);

        return [
            'total_points'         => (int) $totalEarned,
            'available_points'     => max(0, (int) $availablePoints),
            'redeemed_points'      => (int) $totalRedeemed,
            'tier'                 => $tier,
            'tier_discount'        => self::TIER_DISCOUNTS[$tier],
            'next_tier'            => $nextTier,
            'next_tier_points'     => $nextTier ? self::TIERS[$nextTier] : null,
            'progress_to_next_tier'=> $nextTier 
                ? min(1.0, round($totalEarned / self::TIERS[$nextTier], 2)) 
                : 1.0,
            'points_to_next_tier'  => $nextTier 
                ? max(0, self::TIERS[$nextTier] - $totalEarned) 
                : 0,
        ];
    }

    /**
     * Get available rewards for a user's tier.
     */
    public function getAvailableRewards(int $userId): array
    {
        $summary = $this->getSummary($userId);

        $rewards = LoyaltyReward::active()
            ->forTier($summary['tier'])
            ->orderBy('points_cost')
            ->get();

        return $rewards->map(function ($reward) use ($summary) {
            return [
                'id'          => $reward->id,
                'name'        => $reward->name,
                'description' => $reward->description,
                'type'        => $reward->type,
                'points_cost' => $reward->points_cost,
                'value'       => $reward->value,
                'value_type'  => $reward->value_type,
                'can_redeem'  => $summary['available_points'] >= $reward->points_cost,
            ];
        })->toArray();
    }

    /**
     * Redeem a reward.
     */
    public function redeemReward(int $userId, int $rewardId): LoyaltyRedemption
    {
        $reward = LoyaltyReward::active()->findOrFail($rewardId);
        $summary = $this->getSummary($userId);

        // Verify tier eligibility
        if (!$this->isTierEligible($summary['tier'], $reward->min_tier)) {
            throw new \RuntimeException('Votre niveau de fidélité ne permet pas cette récompense.');
        }

        // Verify points
        if ($summary['available_points'] < $reward->points_cost) {
            throw new \RuntimeException('Points insuffisants pour cette récompense.');
        }

        // Deduct points
        CustomerLoyaltyPoint::create([
            'user_id'     => $userId,
            'points'      => -$reward->points_cost,
            'type'        => 'redeemed',
            'source'      => 'reward',
            'source_id'   => $reward->id,
            'description' => "Échange: {$reward->name}",
        ]);

        // Create redemption
        $redemption = LoyaltyRedemption::create([
            'user_id'           => $userId,
            'loyalty_reward_id' => $reward->id,
            'points_spent'      => $reward->points_cost,
            'status'            => 'pending',
            'code'              => strtoupper(Str::random(8)),
            'expires_at'        => now()->addDays(30),
        ]);

        // Increment reward redemption count
        $reward->increment('redemptions_count');

        return $redemption->load('reward');
    }

    /**
     * Get points history for a user.
     */
    public function getHistory(int $userId, int $perPage = 20)
    {
        return CustomerLoyaltyPoint::forUser($userId)
            ->latest()
            ->paginate($perPage);
    }

    /**
     * Get all tier info (for display).
     */
    public function getTiersInfo(): array
    {
        $tiers = [];
        foreach (self::TIERS as $name => $threshold) {
            $tiers[] = [
                'name'           => $name,
                'required_points'=> $threshold,
                'discount'       => self::TIER_DISCOUNTS[$name],
            ];
        }
        return $tiers;
    }

    // ── Private ──────────────────────────────────────────────────

    private function calculatePointsForAmount(float $amount): int
    {
        return (int) floor(($amount / 1000) * self::POINTS_PER_1000_FCFA);
    }

    private function getTierForPoints(int $totalPoints): string
    {
        $currentTier = 'bronze';
        foreach (self::TIERS as $tier => $threshold) {
            if ($totalPoints >= $threshold) {
                $currentTier = $tier;
            }
        }
        return $currentTier;
    }

    private function getNextTier(string $currentTier): ?string
    {
        $tiers = array_keys(self::TIERS);
        $index = array_search($currentTier, $tiers);
        return ($index !== false && $index < count($tiers) - 1)
            ? $tiers[$index + 1]
            : null;
    }

    private function isTierEligible(string $userTier, string $requiredTier): bool
    {
        $tiers = array_keys(self::TIERS);
        return array_search($userTier, $tiers) >= array_search($requiredTier, $tiers);
    }
}
