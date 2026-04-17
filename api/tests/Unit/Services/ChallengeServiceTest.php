<?php

namespace Tests\Unit\Services;

use App\Models\BonusMultiplier;
use App\Models\Challenge;
use App\Models\Courier;
use App\Models\Wallet;
use App\Services\ChallengeService;
use App\Services\WalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class ChallengeServiceTest extends TestCase
{
    use RefreshDatabase;

    protected ChallengeService $service;
    protected Courier $courier;
    protected Wallet $wallet;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = app(ChallengeService::class);
        
        $this->courier = Courier::factory()->create();
        $this->wallet = Wallet::factory()->create([
            'walletable_type' => Courier::class,
            'walletable_id' => $this->courier->id,
            'balance' => 0,
        ]);
    }

    // =================================================================
    // getAvailableChallenges Tests
    // =================================================================

    #[Test]
    public function it_returns_empty_when_no_challenges()
    {
        $challenges = $this->service->getAvailableChallenges($this->courier);

        $this->assertIsArray($challenges);
        $this->assertEmpty($challenges);
    }

    #[Test]
    public function it_returns_active_challenges()
    {
        $challenge = Challenge::factory()->create([
            'is_active' => true,
            'title' => 'Deliver 10 orders',
            'target_value' => 10,
            'reward_amount' => 5000,
        ]);

        $challenges = $this->service->getAvailableChallenges($this->courier);

        $this->assertCount(1, $challenges);
        $this->assertEquals('Deliver 10 orders', $challenges[0]['title']);
        $this->assertEquals(10, $challenges[0]['target_value']);
        $this->assertEquals(5000, $challenges[0]['reward_amount']);
    }

    #[Test]
    public function it_excludes_inactive_challenges()
    {
        Challenge::factory()->create(['is_active' => false]);
        Challenge::factory()->create(['is_active' => true]);

        $challenges = $this->service->getAvailableChallenges($this->courier);

        $this->assertCount(1, $challenges);
    }

    #[Test]
    public function it_excludes_future_challenges()
    {
        Challenge::factory()->create([
            'is_active' => true,
            'starts_at' => now()->addDays(5),
        ]);
        Challenge::factory()->create([
            'is_active' => true,
            'starts_at' => now()->subDays(1),
        ]);

        $challenges = $this->service->getAvailableChallenges($this->courier);

        $this->assertCount(1, $challenges);
    }

    #[Test]
    public function it_excludes_expired_challenges()
    {
        Challenge::factory()->create([
            'is_active' => true,
            'ends_at' => now()->subDays(1),
        ]);
        Challenge::factory()->create([
            'is_active' => true,
            'ends_at' => now()->addDays(5),
        ]);

        $challenges = $this->service->getAvailableChallenges($this->courier);

        $this->assertCount(1, $challenges);
    }

    #[Test]
    public function it_includes_courier_progress_for_challenges()
    {
        $challenge = Challenge::factory()->create([
            'is_active' => true,
            'target_value' => 10,
            'reward_amount' => 1000,
        ]);

        // Attach with progress
        $this->courier->challenges()->attach($challenge->id, [
            'current_progress' => 5,
            'status' => 'in_progress',
        ]);

        $challenges = $this->service->getAvailableChallenges($this->courier);

        $this->assertEquals(5, $challenges[0]['current_progress']);
        $this->assertEquals('in_progress', $challenges[0]['status']);
        $this->assertFalse($challenges[0]['can_claim']);
    }

    #[Test]
    public function it_marks_completed_challenge_as_claimable()
    {
        $challenge = Challenge::factory()->create([
            'is_active' => true,
            'target_value' => 5,
        ]);

        $this->courier->challenges()->attach($challenge->id, [
            'current_progress' => 5,
            'status' => 'completed',
        ]);

        $challenges = $this->service->getAvailableChallenges($this->courier);

        $this->assertEquals('completed', $challenges[0]['status']);
        $this->assertTrue($challenges[0]['can_claim']);
    }

    // =================================================================
    // getActiveBonuses Tests
    // =================================================================

    #[Test]
    public function it_returns_empty_when_no_bonuses()
    {
        $bonuses = $this->service->getActiveBonuses();

        $this->assertIsArray($bonuses);
        $this->assertEmpty($bonuses);
    }

    #[Test]
    public function it_returns_active_bonuses()
    {
        BonusMultiplier::factory()->create([
            'is_active' => true,
            'multiplier' => 1.5,
        ]);

        $bonuses = $this->service->getActiveBonuses();

        $this->assertCount(1, $bonuses);
        $this->assertEquals(1.5, $bonuses[0]['multiplier']);
    }

    #[Test]
    public function it_excludes_inactive_bonuses()
    {
        BonusMultiplier::factory()->create(['is_active' => false]);
        BonusMultiplier::factory()->create(['is_active' => true]);

        $bonuses = $this->service->getActiveBonuses();

        $this->assertCount(1, $bonuses);
    }

    #[Test]
    public function it_excludes_expired_bonuses()
    {
        BonusMultiplier::factory()->create([
            'is_active' => true,
            'ends_at' => now()->subHours(1),
        ]);
        BonusMultiplier::factory()->create([
            'is_active' => true,
            'ends_at' => now()->addHours(1),
        ]);

        $bonuses = $this->service->getActiveBonuses();

        $this->assertCount(1, $bonuses);
    }

    // =================================================================
    // claimReward Tests
    // =================================================================

    #[Test]
    public function it_throws_exception_for_nonexistent_challenge()
    {
        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Challenge introuvable');

        $this->service->claimReward($this->courier, 99999);
    }

    #[Test]
    public function it_throws_exception_when_challenge_not_started()
    {
        $challenge = Challenge::factory()->create([
            'is_active' => true,
            'reward_amount' => 1000,
        ]);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('pas encore complété');

        $this->service->claimReward($this->courier, $challenge->id);
    }

    #[Test]
    public function it_throws_exception_when_challenge_not_completed()
    {
        $challenge = Challenge::factory()->create([
            'is_active' => true,
            'target_value' => 10,
            'reward_amount' => 1000,
        ]);

        $this->courier->challenges()->attach($challenge->id, [
            'current_progress' => 5,
            'status' => 'in_progress',
        ]);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('pas encore complété');

        $this->service->claimReward($this->courier, $challenge->id);
    }

    #[Test]
    public function it_throws_exception_when_reward_already_claimed()
    {
        $challenge = Challenge::factory()->create([
            'is_active' => true,
            'reward_amount' => 1000,
        ]);

        $this->courier->challenges()->attach($challenge->id, [
            'current_progress' => 10,
            'status' => 'rewarded',
            'rewarded_at' => now(),
        ]);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('déjà réclamée');

        $this->service->claimReward($this->courier, $challenge->id);
    }

    #[Test]
    public function it_claims_reward_successfully()
    {
        $challenge = Challenge::factory()->create([
            'is_active' => true,
            'title' => 'Weekly challenge',
            'target_value' => 5,
            'reward_amount' => 2500,
        ]);

        $this->courier->challenges()->attach($challenge->id, [
            'current_progress' => 5,
            'status' => 'completed',
        ]);

        $result = $this->service->claimReward($this->courier, $challenge->id);

        $this->assertArrayHasKey('message', $result);
        $this->assertEquals(2500, $result['reward_amount']);
        $this->assertArrayHasKey('transaction_id', $result);

        // Verify pivot updated
        $pivot = $this->courier->challenges()->where('challenge_id', $challenge->id)->first()->pivot;
        $this->assertEquals('rewarded', $pivot->status);
        $this->assertNotNull($pivot->rewarded_at);

        // Verify wallet credited
        $this->wallet->refresh();
        $this->assertEquals(2500, $this->wallet->balance);
    }
}
