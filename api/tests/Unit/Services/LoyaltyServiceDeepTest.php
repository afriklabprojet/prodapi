<?php

namespace Tests\Unit\Services;

use App\Models\CustomerLoyaltyPoint;
use App\Models\LoyaltyRedemption;
use App\Models\LoyaltyReward;
use App\Models\Order;
use App\Models\User;
use App\Services\LoyaltyService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class LoyaltyServiceDeepTest extends TestCase
{
    use RefreshDatabase;

    private LoyaltyService $service;

    protected function setUp(): void
    {
        parent::setUp();
        Log::spy();
        $this->service = new LoyaltyService();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════

    private function callPrivate(object $obj, string $method, array $args = []): mixed
    {
        $ref = new \ReflectionMethod($obj, $method);
        $ref->setAccessible(true);
        return $ref->invoke($obj, ...$args);
    }

    private function createReward(array $overrides = []): LoyaltyReward
    {
        return LoyaltyReward::create(array_merge([
            'name' => 'Test Reward',
            'description' => 'A test reward',
            'type' => 'discount',
            'points_cost' => 100,
            'value' => 500,
            'value_type' => 'fixed',
            'min_tier' => 'bronze',
            'is_active' => true,
            'max_redemptions' => 100,
            'redemptions_count' => 0,
            'expires_at' => null,
        ], $overrides));
    }

    private function giveUserPoints(int $userId, int $points, string $type = 'earned'): void
    {
        CustomerLoyaltyPoint::create([
            'user_id' => $userId,
            'points' => $type === 'redeemed' ? -$points : $points,
            'type' => $type,
            'source' => 'test',
            'description' => 'Test points',
        ]);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // calculatePointsForAmount (private)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function calculate_points_for_exact_thousands(): void
    {
        $this->assertEquals(10, $this->callPrivate($this->service, 'calculatePointsForAmount', [1000.0]));
        $this->assertEquals(50, $this->callPrivate($this->service, 'calculatePointsForAmount', [5000.0]));
        $this->assertEquals(100, $this->callPrivate($this->service, 'calculatePointsForAmount', [10000.0]));
    }

    #[Test]
    public function calculate_points_floors_result(): void
    {
        // 1500 / 1000 = 1.5 => floor(1.5 * 10) = 15
        $this->assertEquals(15, $this->callPrivate($this->service, 'calculatePointsForAmount', [1500.0]));
        // 999 / 1000 = 0.999 => floor(0.999 * 10) = 9
        $this->assertEquals(9, $this->callPrivate($this->service, 'calculatePointsForAmount', [999.0]));
    }

    #[Test]
    public function calculate_points_for_zero(): void
    {
        $this->assertEquals(0, $this->callPrivate($this->service, 'calculatePointsForAmount', [0.0]));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getTierForPoints (private)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function get_tier_returns_bronze_for_zero(): void
    {
        $this->assertEquals('bronze', $this->callPrivate($this->service, 'getTierForPoints', [0]));
    }

    #[Test]
    public function get_tier_returns_silver_at_500(): void
    {
        $this->assertEquals('silver', $this->callPrivate($this->service, 'getTierForPoints', [500]));
    }

    #[Test]
    public function get_tier_returns_gold_at_2000(): void
    {
        $this->assertEquals('gold', $this->callPrivate($this->service, 'getTierForPoints', [2000]));
    }

    #[Test]
    public function get_tier_returns_platinum_at_5000(): void
    {
        $this->assertEquals('platinum', $this->callPrivate($this->service, 'getTierForPoints', [5000]));
    }

    #[Test]
    public function get_tier_returns_bronze_for_499(): void
    {
        $this->assertEquals('bronze', $this->callPrivate($this->service, 'getTierForPoints', [499]));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getNextTier (private)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function get_next_tier_from_bronze(): void
    {
        $this->assertEquals('silver', $this->callPrivate($this->service, 'getNextTier', ['bronze']));
    }

    #[Test]
    public function get_next_tier_from_gold(): void
    {
        $this->assertEquals('platinum', $this->callPrivate($this->service, 'getNextTier', ['gold']));
    }

    #[Test]
    public function get_next_tier_from_platinum_is_null(): void
    {
        $this->assertNull($this->callPrivate($this->service, 'getNextTier', ['platinum']));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // isTierEligible (private)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function tier_eligible_same_tier(): void
    {
        $this->assertTrue($this->callPrivate($this->service, 'isTierEligible', ['gold', 'gold']));
    }

    #[Test]
    public function tier_eligible_higher_than_required(): void
    {
        $this->assertTrue($this->callPrivate($this->service, 'isTierEligible', ['platinum', 'bronze']));
    }

    #[Test]
    public function tier_not_eligible_lower_than_required(): void
    {
        $this->assertFalse($this->callPrivate($this->service, 'isTierEligible', ['bronze', 'gold']));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // awardPointsForOrder
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function award_points_for_order_creates_record(): void
    {
        $user = User::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $user->id,
            'total_amount' => 5000,
            'reference' => 'ORD-TEST001',
        ]);

        $point = $this->service->awardPointsForOrder($order);

        $this->assertInstanceOf(CustomerLoyaltyPoint::class, $point);
        $this->assertEquals($user->id, $point->user_id);
        $this->assertEquals(50, $point->points); // 5000/1000*10
        $this->assertEquals('earned', $point->type);
        $this->assertEquals('order', $point->source);
        $this->assertEquals($order->id, $point->source_id);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // awardBonusPoints
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function award_bonus_points_with_description(): void
    {
        $user = User::factory()->create();
        $point = $this->service->awardBonusPoints($user->id, 50, 'referral', 'Parrainage récompense');

        $this->assertEquals(50, $point->points);
        $this->assertEquals('bonus', $point->type);
        $this->assertEquals('referral', $point->source);
        $this->assertEquals('Parrainage récompense', $point->description);
    }

    #[Test]
    public function award_bonus_points_default_description(): void
    {
        $user = User::factory()->create();
        $point = $this->service->awardBonusPoints($user->id, 25, 'promo');

        $this->assertStringContainsString('25 points', $point->description);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getSummary
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function get_summary_for_new_user(): void
    {
        $user = User::factory()->create();
        $summary = $this->service->getSummary($user->id);

        $this->assertEquals(0, $summary['total_points']);
        $this->assertEquals(0, $summary['available_points']);
        $this->assertEquals(0, $summary['redeemed_points']);
        $this->assertEquals('bronze', $summary['tier']);
        $this->assertEquals(0, $summary['tier_discount']);
        $this->assertEquals('silver', $summary['next_tier']);
        $this->assertEquals(500, $summary['next_tier_points']);
    }

    #[Test]
    public function get_summary_with_earned_and_redeemed_points(): void
    {
        $user = User::factory()->create();
        $this->giveUserPoints($user->id, 600, 'earned');
        $this->giveUserPoints($user->id, 100, 'redeemed');

        $summary = $this->service->getSummary($user->id);

        $this->assertEquals(600, $summary['total_points']);
        $this->assertEquals(500, $summary['available_points']);
        $this->assertEquals(100, $summary['redeemed_points']);
        $this->assertEquals('silver', $summary['tier']);
        $this->assertEquals(5, $summary['tier_discount']);
    }

    #[Test]
    public function get_summary_platinum_has_no_next_tier(): void
    {
        $user = User::factory()->create();
        $this->giveUserPoints($user->id, 6000, 'earned');

        $summary = $this->service->getSummary($user->id);

        $this->assertEquals('platinum', $summary['tier']);
        $this->assertNull($summary['next_tier']);
        $this->assertNull($summary['next_tier_points']);
        $this->assertEquals(1.0, $summary['progress_to_next_tier']);
        $this->assertEquals(0, $summary['points_to_next_tier']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getAvailableRewards
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function get_available_rewards_maps_correctly(): void
    {
        $user = User::factory()->create();
        $this->giveUserPoints($user->id, 200, 'earned');

        $reward = $this->createReward([
            'name' => 'Discount 500F',
            'points_cost' => 100,
            'min_tier' => 'bronze',
        ]);

        $rewards = $this->service->getAvailableRewards($user->id);

        $this->assertCount(1, $rewards);
        $this->assertEquals('Discount 500F', $rewards[0]['name']);
        $this->assertEquals(100, $rewards[0]['points_cost']);
        $this->assertTrue($rewards[0]['can_redeem']);
    }

    #[Test]
    public function get_available_rewards_shows_cannot_redeem_when_insufficient(): void
    {
        $user = User::factory()->create();
        $this->giveUserPoints($user->id, 50, 'earned');

        $this->createReward(['points_cost' => 100, 'min_tier' => 'bronze']);

        $rewards = $this->service->getAvailableRewards($user->id);

        $this->assertCount(1, $rewards);
        $this->assertFalse($rewards[0]['can_redeem']);
    }

    #[Test]
    public function get_available_rewards_filters_by_tier(): void
    {
        $user = User::factory()->create();
        $this->giveUserPoints($user->id, 200, 'earned'); // bronze tier

        $this->createReward(['name' => 'Bronze reward', 'min_tier' => 'bronze']);
        $this->createReward(['name' => 'Gold reward', 'min_tier' => 'gold']);

        $rewards = $this->service->getAvailableRewards($user->id);

        // Should only include bronze-tier reward
        $names = array_column($rewards, 'name');
        $this->assertContains('Bronze reward', $names);
        $this->assertNotContains('Gold reward', $names);
    }

    #[Test]
    public function get_available_rewards_excludes_inactive(): void
    {
        $user = User::factory()->create();
        $this->giveUserPoints($user->id, 200, 'earned');

        $this->createReward(['name' => 'Active', 'is_active' => true, 'min_tier' => 'bronze']);
        $this->createReward(['name' => 'Inactive', 'is_active' => false, 'min_tier' => 'bronze']);

        $rewards = $this->service->getAvailableRewards($user->id);
        $names = array_column($rewards, 'name');
        $this->assertContains('Active', $names);
        $this->assertNotContains('Inactive', $names);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // redeemReward
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function redeem_reward_success(): void
    {
        $user = User::factory()->create();
        $this->giveUserPoints($user->id, 500, 'earned');

        $reward = $this->createReward([
            'name' => 'Free delivery',
            'points_cost' => 100,
            'min_tier' => 'bronze',
        ]);

        $redemption = $this->service->redeemReward($user->id, $reward->id);

        $this->assertInstanceOf(LoyaltyRedemption::class, $redemption);
        $this->assertEquals($user->id, $redemption->user_id);
        $this->assertEquals($reward->id, $redemption->loyalty_reward_id);
        $this->assertEquals(100, $redemption->points_spent);
        $this->assertEquals('pending', $redemption->status);
        $this->assertNotNull($redemption->code);
        $this->assertEquals(8, strlen($redemption->code));

        // Points should be deducted
        $this->assertDatabaseHas('customer_loyalty_points', [
            'user_id' => $user->id,
            'type' => 'redeemed',
            'points' => -100,
        ]);

        // Reward redemption count incremented
        $this->assertEquals(1, $reward->fresh()->redemptions_count);
    }

    #[Test]
    public function redeem_reward_throws_when_tier_ineligible(): void
    {
        $user = User::factory()->create();
        $this->giveUserPoints($user->id, 200, 'earned'); // bronze tier

        $reward = $this->createReward([
            'points_cost' => 100,
            'min_tier' => 'gold', // requires gold
        ]);

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('niveau de fidélité');

        $this->service->redeemReward($user->id, $reward->id);
    }

    #[Test]
    public function redeem_reward_throws_when_insufficient_points(): void
    {
        $user = User::factory()->create();
        $this->giveUserPoints($user->id, 50, 'earned'); // only 50 points

        $reward = $this->createReward([
            'points_cost' => 100,
            'min_tier' => 'bronze',
        ]);

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('Points insuffisants');

        $this->service->redeemReward($user->id, $reward->id);
    }

    #[Test]
    public function redeem_reward_loads_reward_relation(): void
    {
        $user = User::factory()->create();
        $this->giveUserPoints($user->id, 500, 'earned');

        $reward = $this->createReward(['points_cost' => 50, 'min_tier' => 'bronze']);

        $redemption = $this->service->redeemReward($user->id, $reward->id);

        $this->assertTrue($redemption->relationLoaded('reward'));
        $this->assertEquals($reward->id, $redemption->reward->id);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getHistory
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function get_history_returns_paginated(): void
    {
        $user = User::factory()->create();
        for ($i = 0; $i < 5; $i++) {
            $this->giveUserPoints($user->id, 10 * ($i + 1), 'earned');
        }

        $history = $this->service->getHistory($user->id, 3);

        $this->assertCount(3, $history);
        $this->assertEquals(5, $history->total());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getTiersInfo
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function get_tiers_info_returns_all_tiers(): void
    {
        $tiers = $this->service->getTiersInfo();

        $this->assertCount(4, $tiers);
        $names = array_column($tiers, 'name');
        $this->assertEquals(['bronze', 'silver', 'gold', 'platinum'], $names);
        $this->assertEquals(0, $tiers[0]['required_points']);
        $this->assertEquals(15, $tiers[3]['discount']);
    }
}
