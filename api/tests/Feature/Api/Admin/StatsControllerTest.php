<?php

namespace Tests\Feature\Api\Admin;

use App\Models\Courier;
use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class StatsControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $admin;

    protected function setUp(): void
    {
        parent::setUp();

        $this->admin = User::factory()->create(['role' => 'admin']);
        Cache::flush();
    }

    public function test_admin_can_view_dashboard_stats(): void
    {
        $response = $this->actingAs($this->admin)->getJson('/api/admin/stats/dashboard');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'today',
                    'revenue',
                    'health',
                ],
            ]);
    }

    public function test_admin_can_view_revenue(): void
    {
        $response = $this->actingAs($this->admin)->getJson('/api/admin/stats/revenue');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'revenue',
                    'platform_commissions',
                    'payment_conversion',
                    'daily_trend',
                ],
            ]);
    }

    public function test_admin_can_view_today_stats(): void
    {
        $response = $this->actingAs($this->admin)->getJson('/api/admin/stats/today');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'date',
                    'orders',
                    'payments',
                    'signups',
                ],
            ]);
    }

    public function test_today_stats_reflect_actual_data(): void
    {
        Order::factory()->count(3)->create(['status' => 'delivered']);
        Order::factory()->count(1)->create(['status' => 'cancelled']);

        Cache::flush();

        $response = $this->actingAs($this->admin)->getJson('/api/admin/stats/today');

        $response->assertOk();
        $orders = $response->json('data.orders');
        $this->assertEquals(4, $orders['total']);
        $this->assertEquals(3, $orders['delivered']);
        $this->assertEquals(1, $orders['cancelled']);
    }

    public function test_admin_can_view_events(): void
    {
        $response = $this->actingAs($this->admin)->getJson('/api/admin/stats/events?limit=10');

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_admin_can_view_funnel(): void
    {
        $response = $this->actingAs($this->admin)->getJson('/api/admin/stats/funnel?days=7');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'funnel' => [
                        'signups',
                        'phone_verified',
                        'first_order',
                        'payment_initiated',
                        'payment_completed',
                        'order_delivered',
                    ],
                    'period_days',
                ],
            ]);
    }

    public function test_funnel_reflects_actual_data(): void
    {
        User::factory()->count(5)->create(['role' => 'customer']);
        User::factory()->count(2)->create(['role' => 'customer', 'phone_verified_at' => now()]);

        Cache::flush();

        $response = $this->actingAs($this->admin)->getJson('/api/admin/stats/funnel?days=30');

        $response->assertOk();
        $funnel = $response->json('data.funnel');
        // admin + 7 customers = at least 7 customer signups
        $this->assertGreaterThanOrEqual(7, $funnel['signups']);
        $this->assertGreaterThanOrEqual(2, $funnel['phone_verified']);
    }

    public function test_admin_can_view_alerts(): void
    {
        $response = $this->actingAs($this->admin)->getJson('/api/admin/stats/alerts');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'alerts',
                    'alert_count',
                    'checked_at',
                ],
            ]);
    }

    public function test_alerts_detect_stale_orders(): void
    {
        Order::factory()->create([
            'status' => 'pending',
            'created_at' => now()->subHours(2),
        ]);

        $response = $this->actingAs($this->admin)->getJson('/api/admin/stats/alerts');

        $response->assertOk();
        $alerts = collect($response->json('data.alerts'));
        $staleAlert = $alerts->firstWhere('type', 'stale_orders');
        $this->assertNotNull($staleAlert);
        $this->assertEquals(1, $staleAlert['count']);
    }

    public function test_health_shows_system_metrics(): void
    {
        $response = $this->actingAs($this->admin)->getJson('/api/admin/stats/dashboard');

        $response->assertOk();
        $health = $response->json('data.health');
        $this->assertArrayHasKey('queue_size', $health);
        $this->assertArrayHasKey('failed_jobs', $health);
        $this->assertArrayHasKey('pending_orders', $health);
        $this->assertArrayHasKey('active_couriers', $health);
    }

    public function test_non_admin_cannot_access_stats(): void
    {
        /** @var User $customer */
        $customer = User::factory()->create(['role' => 'customer']);

        $response = $this->actingAs($customer)->getJson('/api/admin/stats/dashboard');

        $response->assertStatus(403);
    }

    public function test_unauthenticated_cannot_access_stats(): void
    {
        $response = $this->getJson('/api/admin/stats/dashboard');

        $response->assertStatus(401);
    }
}
