<?php

namespace Tests\Feature\Api\Pharmacy;

use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class PharmacyDashboardControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Pharmacy $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->pharmacy->users()->attach($this->user->id, ['role' => 'titulaire']);
    }

    public function test_pharmacy_can_view_week_stats(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/stats/week');

        $response->assertOk()
            ->assertJsonStructure([
                'this_week_orders',
                'last_week_orders',
                'trend_percent',
                'peak_day_label',
                'critical_products_count',
                'expiring_products_count',
                'expired_products_count',
            ]);
    }

    public function test_week_stats_returns_correct_order_counts(): void
    {
        Carbon::setTestNow(Carbon::parse('2025-07-15 10:00:00'));

        Order::factory()->count(3)->create([
            'pharmacy_id' => $this->pharmacy->id,
            'created_at' => Carbon::parse('2025-07-14 12:00:00'),
        ]);
        Order::factory()->count(2)->create([
            'pharmacy_id' => $this->pharmacy->id,
            'created_at' => Carbon::parse('2025-07-08 12:00:00'),
        ]);

        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/stats/week');

        $response->assertOk();
        $this->assertEquals(3, $response->json('this_week_orders'));
        $this->assertEquals(2, $response->json('last_week_orders'));
        $this->assertEquals(50, $response->json('trend_percent'));

        Carbon::setTestNow();
    }

    public function test_week_stats_returns_null_trend_when_no_last_week(): void
    {
        Carbon::setTestNow(Carbon::parse('2025-07-15 10:00:00'));

        Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'created_at' => Carbon::parse('2025-07-14 12:00:00'),
        ]);

        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/stats/week');

        $response->assertOk();
        $this->assertEquals(1, $response->json('this_week_orders'));
        $this->assertEquals(0, $response->json('last_week_orders'));
        $this->assertNull($response->json('trend_percent'));

        Carbon::setTestNow();
    }

    public function test_week_stats_counts_critical_products(): void
    {
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'stock_quantity' => 0,
            'low_stock_threshold' => 5,
        ]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'stock_quantity' => 2,
            'low_stock_threshold' => 10,
        ]);
        Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'stock_quantity' => 50,
            'low_stock_threshold' => 5,
        ]);

        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/stats/week');

        $response->assertOk();
        $this->assertEquals(2, $response->json('critical_products_count'));
    }

    public function test_unauthenticated_cannot_view_stats(): void
    {
        $response = $this->getJson('/api/pharmacy/stats/week');
        $response->assertStatus(401);
    }

    public function test_non_pharmacy_user_cannot_view_stats(): void
    {
        /** @var User $customer */
        $customer = User::factory()->create(['role' => 'customer']);
        $response = $this->actingAs($customer)->getJson('/api/pharmacy/stats/week');
        $response->assertStatus(403);
    }
}
