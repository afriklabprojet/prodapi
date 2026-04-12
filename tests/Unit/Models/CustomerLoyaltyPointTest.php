<?php

namespace Tests\Unit\Models;

use App\Models\CustomerLoyaltyPoint;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class CustomerLoyaltyPointTest extends TestCase
{
    use RefreshDatabase;

    public function test_fillable_fields(): void
    {
        $model = new CustomerLoyaltyPoint();
        $fillable = $model->getFillable();
        $this->assertContains('user_id', $fillable);
        $this->assertContains('points', $fillable);
        $this->assertContains('type', $fillable);
        $this->assertContains('source', $fillable);
        $this->assertContains('description', $fillable);
    }

    public function test_casts(): void
    {
        $model = new CustomerLoyaltyPoint();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('points', $casts);
    }

    public function test_has_user_relationship(): void
    {
        $model = new CustomerLoyaltyPoint();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->user());
    }

    #[Test]
    public function it_scopes_earned_points(): void
    {
        $user = User::factory()->create();

        CustomerLoyaltyPoint::create([
            'user_id' => $user->id,
            'points' => 100,
            'type' => 'earned',
            'source' => 'order',
            'description' => 'Points gagnés',
        ]);

        CustomerLoyaltyPoint::create([
            'user_id' => $user->id,
            'points' => -50,
            'type' => 'redeemed',
            'source' => 'order',
            'description' => 'Points utilisés',
        ]);

        CustomerLoyaltyPoint::create([
            'user_id' => $user->id,
            'points' => 200,
            'type' => 'earned',
            'source' => 'promo',
            'description' => 'Points bonus',
        ]);

        $earned = CustomerLoyaltyPoint::earned()->get();
        $this->assertCount(2, $earned);
        $this->assertTrue($earned->every(fn($p) => $p->type === 'earned'));
    }

    #[Test]
    public function it_scopes_redeemed_points(): void
    {
        $user = User::factory()->create();

        CustomerLoyaltyPoint::create([
            'user_id' => $user->id,
            'points' => 100,
            'type' => 'earned',
            'source' => 'order',
            'description' => 'Points gagnés',
        ]);

        CustomerLoyaltyPoint::create([
            'user_id' => $user->id,
            'points' => -50,
            'type' => 'redeemed',
            'source' => 'order',
            'description' => 'Points utilisés',
        ]);

        CustomerLoyaltyPoint::create([
            'user_id' => $user->id,
            'points' => -30,
            'type' => 'redeemed',
            'source' => 'order',
            'description' => 'Points utilisés',
        ]);

        $redeemed = CustomerLoyaltyPoint::redeemed()->get();
        $this->assertCount(2, $redeemed);
        $this->assertTrue($redeemed->every(fn($p) => $p->type === 'redeemed'));
    }

    #[Test]
    public function it_scopes_points_for_user(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        CustomerLoyaltyPoint::create([
            'user_id' => $user1->id,
            'points' => 100,
            'type' => 'earned',
            'source' => 'order',
            'description' => 'User 1',
        ]);

        CustomerLoyaltyPoint::create([
            'user_id' => $user2->id,
            'points' => 200,
            'type' => 'earned',
            'source' => 'order',
            'description' => 'User 2',
        ]);

        $user1Points = CustomerLoyaltyPoint::forUser($user1->id)->get();
        $this->assertCount(1, $user1Points);
        $this->assertEquals('User 1', $user1Points->first()->description);
    }
}
