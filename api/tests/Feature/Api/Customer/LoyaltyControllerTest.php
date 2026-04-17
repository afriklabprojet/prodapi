<?php

namespace Tests\Feature\Api\Customer;

use App\Models\Customer;
use App\Models\User;
use App\Services\LoyaltyService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery;
use Tests\TestCase;

class LoyaltyControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $this->user->id]);
    }

    protected function mockLoyaltyService(): void
    {
        $mock = Mockery::mock(LoyaltyService::class);
        $mock->shouldReceive('getSummary')->andReturn([
            'points' => 150,
            'tier' => 'bronze',
            'next_tier_points' => 500,
        ]);
        $mock->shouldReceive('getAvailableRewards')->andReturn([]);
        $mock->shouldReceive('getTiersInfo')->andReturn([]);
        $mock->shouldReceive('getHistory')->andReturn([]);
        $this->app->instance(LoyaltyService::class, $mock);
    }

    public function test_customer_can_get_loyalty_summary(): void
    {
        $this->mockLoyaltyService();

        $response = $this->actingAs($this->user)->getJson('/api/customer/loyalty');

        $response->assertOk()
            ->assertJsonStructure(['success', 'data' => ['summary', 'rewards', 'tiers', 'history']]);
    }

    public function test_customer_can_get_loyalty_history(): void
    {
        $this->mockLoyaltyService();

        $response = $this->actingAs($this->user)->getJson('/api/customer/loyalty/history');

        $response->assertOk()->assertJsonStructure(['success', 'data']);
    }

    public function test_redeem_requires_reward_id(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/customer/loyalty/redeem', []);

        $response->assertStatus(422);
    }

    public function test_unauthenticated_cannot_access_loyalty(): void
    {
        $response = $this->getJson('/api/customer/loyalty');
        $response->assertStatus(401);
    }

    public function test_non_customer_cannot_access_loyalty(): void
    {
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);

        $response = $this->actingAs($pharmacyUser)->getJson('/api/customer/loyalty');
        $response->assertStatus(403);
    }
}
