<?php

namespace Tests\Unit\Models;

use App\Models\LoyaltyRedemption;
use App\Models\LoyaltyReward;
use App\Models\User;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class LoyaltyRewardTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_has_fillable_attributes(): void
    {
        $model = new LoyaltyReward();
        $fillable = $model->getFillable();

        $this->assertContains('name', $fillable);
        $this->assertContains('description', $fillable);
        $this->assertContains('type', $fillable);
        $this->assertContains('points_cost', $fillable);
        $this->assertContains('value', $fillable);
        $this->assertContains('value_type', $fillable);
        $this->assertContains('min_tier', $fillable);
        $this->assertContains('is_active', $fillable);
        $this->assertContains('max_redemptions', $fillable);
        $this->assertContains('redemptions_count', $fillable);
        $this->assertContains('expires_at', $fillable);
    }

    #[Test]
    public function it_casts_integers_correctly(): void
    {
        $model = new LoyaltyReward();
        $casts = $model->getCasts();

        $this->assertSame('integer', $casts['points_cost']);
        $this->assertSame('integer', $casts['value']);
        $this->assertSame('integer', $casts['max_redemptions']);
        $this->assertSame('integer', $casts['redemptions_count']);
    }

    #[Test]
    public function it_casts_is_active_as_boolean(): void
    {
        $model = new LoyaltyReward();
        $casts = $model->getCasts();

        $this->assertSame('boolean', $casts['is_active']);
    }

    #[Test]
    public function it_casts_expires_at_as_datetime(): void
    {
        $model = new LoyaltyReward();
        $casts = $model->getCasts();

        $this->assertSame('datetime', $casts['expires_at']);
    }

    #[Test]
    public function it_has_redemptions_relationship(): void
    {
        $model = new LoyaltyReward();
        $relation = $model->redemptions();

        $this->assertInstanceOf(HasMany::class, $relation);
    }

    #[Test]
    public function it_can_be_created_in_database(): void
    {
        $reward = LoyaltyReward::create([
            'name' => 'Free Delivery',
            'description' => 'Get free delivery on your next order',
            'type' => 'delivery',
            'points_cost' => 50,
            'value' => 1000,
            'value_type' => 'fixed',
            'is_active' => true,
        ]);

        $this->assertDatabaseHas('loyalty_rewards', [
            'name' => 'Free Delivery',
            'points_cost' => 50,
        ]);
    }

    #[Test]
    public function it_scopes_active_rewards(): void
    {
        // Create active reward
        $activeReward = LoyaltyReward::create([
            'name' => 'Active Reward',
            'type' => 'discount',
            'points_cost' => 100,
            'value' => 500,
            'is_active' => true,
        ]);

        // Create inactive reward
        $inactiveReward = LoyaltyReward::create([
            'name' => 'Inactive Reward',
            'type' => 'discount',
            'points_cost' => 100,
            'value' => 500,
            'is_active' => false,
        ]);

        // Create expired reward
        $expiredReward = LoyaltyReward::create([
            'name' => 'Expired Reward',
            'type' => 'discount',
            'points_cost' => 100,
            'value' => 500,
            'is_active' => true,
            'expires_at' => now()->subDay(),
        ]);

        $activeIds = LoyaltyReward::active()->pluck('id')->toArray();

        $this->assertContains($activeReward->id, $activeIds);
        $this->assertNotContains($inactiveReward->id, $activeIds);
        $this->assertNotContains($expiredReward->id, $activeIds);
    }

    #[Test]
    public function it_scopes_rewards_with_max_redemptions_reached(): void
    {
        // Reward with redemptions available
        $availableReward = LoyaltyReward::create([
            'name' => 'Available Reward',
            'type' => 'discount',
            'points_cost' => 100,
            'value' => 500,
            'is_active' => true,
            'max_redemptions' => 10,
            'redemptions_count' => 5,
        ]);

        // Reward with max redemptions reached
        $maxedReward = LoyaltyReward::create([
            'name' => 'Maxed Reward',
            'type' => 'discount',
            'points_cost' => 100,
            'value' => 500,
            'is_active' => true,
            'max_redemptions' => 10,
            'redemptions_count' => 10,
        ]);

        $activeIds = LoyaltyReward::active()->pluck('id')->toArray();

        $this->assertContains($availableReward->id, $activeIds);
        $this->assertNotContains($maxedReward->id, $activeIds);
    }

    #[Test]
    public function it_scopes_rewards_for_tier(): void
    {
        $bronzeReward = LoyaltyReward::create([
            'name' => 'Bronze Reward',
            'type' => 'discount',
            'points_cost' => 50,
            'value' => 200,
            'is_active' => true,
            'min_tier' => 'bronze',
        ]);

        $goldReward = LoyaltyReward::create([
            'name' => 'Gold Reward',
            'type' => 'discount',
            'points_cost' => 200,
            'value' => 1000,
            'is_active' => true,
            'min_tier' => 'gold',
        ]);

        $silverTierIds = LoyaltyReward::forTier('silver')->pluck('id')->toArray();

        $this->assertContains($bronzeReward->id, $silverTierIds);
        $this->assertNotContains($goldReward->id, $silverTierIds);
    }

    #[Test]
    public function it_can_have_redemptions(): void
    {
        $reward = LoyaltyReward::create([
            'name' => 'Test Reward',
            'type' => 'discount',
            'points_cost' => 100,
            'value' => 500,
            'is_active' => true,
        ]);

        $user = User::factory()->create(['role' => 'customer']);

        LoyaltyRedemption::create([
            'user_id' => $user->id,
            'loyalty_reward_id' => $reward->id,
            'points_spent' => 100,
            'status' => 'pending',
            'code' => 'REDEMPTION123',
        ]);

        $this->assertEquals(1, $reward->redemptions()->count());
    }
}
