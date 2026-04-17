<?php

namespace Tests\Unit\Models;

use App\Models\LoyaltyRedemption;
use App\Models\LoyaltyReward;
use App\Models\Order;
use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class LoyaltyRedemptionTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private LoyaltyReward $reward;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create(['role' => 'customer']);
        $this->reward = LoyaltyReward::create([
            'name' => 'Test Reward',
            'description' => 'Test description',
            'type' => 'discount',
            'points_cost' => 100,
            'value' => 500,
            'value_type' => 'fixed',
            'is_active' => true,
        ]);
    }

    #[Test]
    public function it_has_fillable_attributes(): void
    {
        $model = new LoyaltyRedemption();
        $fillable = $model->getFillable();

        $this->assertContains('user_id', $fillable);
        $this->assertContains('loyalty_reward_id', $fillable);
        $this->assertContains('points_spent', $fillable);
        $this->assertContains('status', $fillable);
        $this->assertContains('code', $fillable);
        $this->assertContains('order_id', $fillable);
        $this->assertContains('applied_at', $fillable);
        $this->assertContains('expires_at', $fillable);
    }

    #[Test]
    public function it_casts_points_spent_as_integer(): void
    {
        $model = new LoyaltyRedemption();
        $casts = $model->getCasts();

        $this->assertSame('integer', $casts['points_spent']);
    }

    #[Test]
    public function it_casts_timestamps_as_datetime(): void
    {
        $model = new LoyaltyRedemption();
        $casts = $model->getCasts();

        $this->assertSame('datetime', $casts['applied_at']);
        $this->assertSame('datetime', $casts['expires_at']);
    }

    #[Test]
    public function it_has_user_relationship(): void
    {
        $model = new LoyaltyRedemption();
        $relation = $model->user();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_has_reward_relationship(): void
    {
        $model = new LoyaltyRedemption();
        $relation = $model->reward();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_has_order_relationship(): void
    {
        $model = new LoyaltyRedemption();
        $relation = $model->order();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_can_be_created_in_database(): void
    {
        $redemption = LoyaltyRedemption::create([
            'user_id' => $this->user->id,
            'loyalty_reward_id' => $this->reward->id,
            'points_spent' => 100,
            'status' => 'pending',
            'code' => 'TEST123',
        ]);

        $this->assertDatabaseHas('loyalty_redemptions', [
            'user_id' => $this->user->id,
            'loyalty_reward_id' => $this->reward->id,
            'code' => 'TEST123',
        ]);
    }

    #[Test]
    public function it_can_access_user_through_relationship(): void
    {
        $redemption = LoyaltyRedemption::create([
            'user_id' => $this->user->id,
            'loyalty_reward_id' => $this->reward->id,
            'points_spent' => 100,
            'status' => 'pending',
            'code' => 'USER123',
        ]);

        $this->assertEquals($this->user->id, $redemption->user->id);
    }

    #[Test]
    public function it_can_access_reward_through_relationship(): void
    {
        $redemption = LoyaltyRedemption::create([
            'user_id' => $this->user->id,
            'loyalty_reward_id' => $this->reward->id,
            'points_spent' => 100,
            'status' => 'pending',
            'code' => 'REWARD123',
        ]);

        $this->assertEquals($this->reward->id, $redemption->reward->id);
    }

    #[Test]
    public function it_can_be_linked_to_order(): void
    {
        $order = Order::factory()->create();

        $redemption = LoyaltyRedemption::create([
            'user_id' => $this->user->id,
            'loyalty_reward_id' => $this->reward->id,
            'points_spent' => 100,
            'status' => 'applied',
            'code' => 'ORDER123',
            'order_id' => $order->id,
            'applied_at' => now(),
        ]);

        $this->assertEquals($order->id, $redemption->order->id);
    }
}
