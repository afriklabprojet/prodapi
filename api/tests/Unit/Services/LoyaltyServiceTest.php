<?php

namespace Tests\Unit\Services;

use App\Models\Order;
use App\Models\User;
use App\Services\LoyaltyService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LoyaltyServiceTest extends TestCase
{
    use RefreshDatabase;

    private LoyaltyService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new LoyaltyService();
    }

    public function test_award_points_for_order(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        $order = new Order([
            'customer_id' => $user->id,
            'reference' => 'CMD-TEST-001',
            'status' => 'delivered',
            'payment_status' => 'paid',
            'total_amount' => 10000,
            'subtotal' => 10000,
            'currency' => 'XOF',
        ]);
        $order->id = 1;

        $result = $this->service->awardPointsForOrder($order);

        $this->assertNotNull($result);
        $this->assertEquals($user->id, $result->user_id);
        $this->assertEquals(100, $result->points);
    }

    public function test_get_summary_returns_correct_structure(): void
    {
        $user = User::factory()->create(['role' => 'customer']);

        $summary = $this->service->getSummary($user->id);

        $this->assertArrayHasKey('total_points', $summary);
        $this->assertArrayHasKey('available_points', $summary);
        $this->assertArrayHasKey('redeemed_points', $summary);
        $this->assertArrayHasKey('tier', $summary);
        $this->assertArrayHasKey('tier_discount', $summary);
        $this->assertArrayHasKey('next_tier', $summary);
    }

    public function test_user_starts_at_bronze_tier(): void
    {
        $user = User::factory()->create(['role' => 'customer']);

        $summary = $this->service->getSummary($user->id);

        $this->assertEquals('bronze', $summary['tier']);
        $this->assertEquals(0, $summary['tier_discount']);
        $this->assertEquals(0, $summary['total_points']);
    }

    public function test_get_tiers_info_returns_all_tiers(): void
    {
        $tiers = $this->service->getTiersInfo();

        $this->assertIsArray($tiers);
        $this->assertNotEmpty($tiers);

        $tierNames = array_column($tiers, 'name');
        $this->assertContains('bronze', $tierNames);
        $this->assertContains('silver', $tierNames);
        $this->assertContains('gold', $tierNames);
        $this->assertContains('platinum', $tierNames);
    }

    public function test_get_history_returns_paginated_results(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        $history = $this->service->getHistory($user->id);

        $this->assertIsObject($history);
    }

    public function test_get_available_rewards(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        $rewards = $this->service->getAvailableRewards($user->id);

        $this->assertIsArray($rewards);
    }
}
