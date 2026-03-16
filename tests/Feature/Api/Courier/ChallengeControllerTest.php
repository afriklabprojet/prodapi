<?php

namespace Tests\Feature\Api\Courier;

use App\Models\User;
use App\Models\Courier;
use App\Services\ChallengeService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Mockery;

class ChallengeControllerTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $courier;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'courier']);
        $this->courier = Courier::factory()->create([
            'user_id' => $this->user->id,
            'status' => 'available',
        ]);
    }

    /** @test */
    public function courier_can_list_challenges()
    {
        $this->mock(ChallengeService::class, function ($mock) {
            $mock->shouldReceive('getAvailableChallenges')
                ->andReturn([
                    [
                        'id' => 1,
                        'name' => 'Daily Sprint',
                        'description' => 'Complete 5 deliveries today',
                        'type' => 'daily',
                        'target' => 5,
                        'progress' => 3,
                        'reward' => 500,
                        'status' => 'in_progress',
                        'can_claim' => false,
                    ],
                    [
                        'id' => 2,
                        'name' => 'Weekly Challenge',
                        'description' => 'Complete 20 deliveries this week',
                        'type' => 'weekly',
                        'target' => 20,
                        'progress' => 20,
                        'reward' => 2000,
                        'status' => 'completed',
                        'can_claim' => true,
                    ],
                ]);
            $mock->shouldReceive('getActiveBonuses')
                ->andReturn([
                    [
                        'id' => 1,
                        'name' => 'Rush Hour Bonus',
                        'multiplier' => 1.5,
                        'start_time' => '18:00',
                        'end_time' => '21:00',
                        'is_active' => true,
                    ],
                ]);
        });

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/challenges');

        $response->assertOk()
            ->assertJsonStructure([
                'status',
                'data' => [
                    'challenges' => [
                        'in_progress',
                        'completed',
                        'rewarded',
                        'all',
                    ],
                    'active_bonuses',
                    'stats' => [
                        'total_challenges',
                        'in_progress_count',
                        'completed_count',
                        'rewarded_count',
                        'can_claim_count',
                    ],
                ],
            ]);
    }

    /** @test */
    public function courier_can_claim_challenge_reward()
    {
        $this->mock(ChallengeService::class, function ($mock) {
            $mock->shouldReceive('claimReward')
                ->with(Mockery::any(), 1)
                ->andReturn([
                    'message' => 'Récompense réclamée avec succès',
                    'reward_amount' => 2000,
                    'transaction_id' => 123,
                ]);
        });

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/courier/challenges/1/claim');

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.reward_amount', 2000)
            ->assertJsonPath('data.transaction_id', 123);
    }

    /** @test */
    public function cannot_claim_incomplete_challenge()
    {
        $this->mock(ChallengeService::class, function ($mock) {
            $mock->shouldReceive('claimReward')
                ->andThrow(new \Exception('Challenge pas encore complété'));
        });

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/courier/challenges/1/claim');

        $response->assertStatus(400)
            ->assertJsonPath('status', 'error')
            ->assertJsonPath('message', 'Challenge pas encore complété');
    }

    /** @test */
    public function cannot_claim_already_claimed_reward()
    {
        $this->mock(ChallengeService::class, function ($mock) {
            $mock->shouldReceive('claimReward')
                ->andThrow(new \Exception('Récompense déjà réclamée'));
        });

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/courier/challenges/1/claim');

        $response->assertStatus(400)
            ->assertJsonPath('status', 'error')
            ->assertJsonPath('message', 'Récompense déjà réclamée');
    }

    /** @test */
    public function courier_can_get_active_bonuses()
    {
        $this->mock(ChallengeService::class, function ($mock) {
            $mock->shouldReceive('getActiveBonuses')
                ->andReturn([
                    [
                        'id' => 1,
                        'name' => 'Rush Hour Bonus',
                        'multiplier' => 1.5,
                        'start_time' => '18:00',
                        'end_time' => '21:00',
                        'is_active' => true,
                    ],
                ]);
        });

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/bonuses');

        $response->assertOk()
            ->assertJsonStructure([
                'status',
                'data',
            ]);
    }

    /** @test */
    public function non_courier_cannot_access_challenges()
    {
        $customer = User::factory()->create(['role' => 'customer']);

        $response = $this->actingAs($customer, 'sanctum')
            ->getJson('/api/courier/challenges');

        $response->assertStatus(403);
    }

    /** @test */
    public function unauthenticated_user_cannot_access_challenges()
    {
        $response = $this->getJson('/api/courier/challenges');

        $response->assertUnauthorized();
    }

    /** @test */
    public function challenges_include_stats()
    {
        $this->mock(ChallengeService::class, function ($mock) {
            $mock->shouldReceive('getAvailableChallenges')
                ->andReturn([
                    ['id' => 1, 'status' => 'in_progress', 'can_claim' => false],
                    ['id' => 2, 'status' => 'completed', 'can_claim' => true],
                    ['id' => 3, 'status' => 'rewarded', 'can_claim' => false],
                ]);
            $mock->shouldReceive('getActiveBonuses')->andReturn([]);
        });

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/challenges');

        $response->assertOk()
            ->assertJsonPath('data.stats.total_challenges', 3)
            ->assertJsonPath('data.stats.in_progress_count', 1)
            ->assertJsonPath('data.stats.completed_count', 1)
            ->assertJsonPath('data.stats.rewarded_count', 1)
            ->assertJsonPath('data.stats.can_claim_count', 1);
    }
}
