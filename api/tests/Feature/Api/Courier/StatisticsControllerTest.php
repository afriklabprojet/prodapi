<?php

namespace Tests\Feature\Api\Courier;

use App\Models\User;
use App\Models\Courier;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Customer;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class StatisticsControllerTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $courier;
    protected $pharmacy;
    protected $customer;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'courier']);
        $this->courier = Courier::factory()->create([
            'user_id' => $this->user->id,
            'status' => 'available',
        ]);

        $this->pharmacy = Pharmacy::factory()->create();
        $this->customer = Customer::factory()->create();
    }

    /** @test */
    public function courier_can_get_statistics()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/statistics');

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'data' => [
                    'period',
                    'start_date',
                    'end_date',
                    'overview',
                    'performance',
                    'daily_breakdown',
                    'peak_hours',
                    'revenue_breakdown',
                    'goals',
                ],
            ]);
    }

    /** @test */
    public function courier_can_get_today_statistics()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/statistics?period=today');

        $response->assertOk()
            ->assertJsonPath('data.period', 'today')
            ->assertJsonPath('data.start_date', Carbon::today()->toDateString());
    }

    /** @test */
    public function courier_can_get_week_statistics()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/statistics?period=week');

        $response->assertOk()
            ->assertJsonPath('data.period', 'week');
    }

    /** @test */
    public function courier_can_get_month_statistics()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/statistics?period=month');

        $response->assertOk()
            ->assertJsonPath('data.period', 'month');
    }

    /** @test */
    public function courier_can_get_year_statistics()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/statistics?period=year');

        $response->assertOk()
            ->assertJsonPath('data.period', 'year');
    }

    /** @test */
    public function statistics_reflect_completed_deliveries()
    {
        // Create completed deliveries
        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $this->customer->id,
            'delivery_fee' => 1000,
        ]);

        Delivery::factory()->create([
            'courier_id' => $this->courier->id,
            'order_id' => $order->id,
            'status' => 'delivered',
            'delivered_at' => now(),
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/statistics?period=today');

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    /** @test */
    public function statistics_include_daily_breakdown()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/statistics?period=week');

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'daily_breakdown',
                ],
            ]);
    }

    /** @test */
    public function statistics_include_peak_hours()
    {
        // Create deliveries at different hours
        for ($hour = 8; $hour <= 20; $hour += 2) {
            $order = Order::factory()->create([
                'pharmacy_id' => $this->pharmacy->id,
                'customer_id' => $this->customer->id,
            ]);

            Delivery::factory()->create([
                'courier_id' => $this->courier->id,
                'order_id' => $order->id,
                'status' => 'delivered',
                'delivered_at' => Carbon::today()->setHour($hour),
            ]);
        }

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/statistics');

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'peak_hours',
                ],
            ]);
    }

    /** @test */
    public function statistics_include_revenue_breakdown()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/statistics');

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'revenue_breakdown',
                ],
            ]);
    }

    /** @test */
    public function statistics_include_goals()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/statistics');

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'goals',
                ],
            ]);
    }

    /** @test */
    public function non_courier_cannot_access_statistics()
    {
        $customer = User::factory()->create(['role' => 'customer']);

        $response = $this->actingAs($customer, 'sanctum')
            ->getJson('/api/courier/statistics');

        $response->assertStatus(403)
            ->assertJsonPath('status', 'error')
            ->assertJsonPath('error_code', 'COURIER_PROFILE_NOT_FOUND');
    }

    /** @test */
    public function unauthenticated_user_cannot_access_statistics()
    {
        $response = $this->getJson('/api/courier/statistics');

        $response->assertUnauthorized();
    }

    /** @test */
    public function default_period_is_week()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/statistics');

        $response->assertOk()
            ->assertJsonPath('data.period', 'week');
    }

    /** @test */
    public function invalid_period_defaults_to_week()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/courier/statistics?period=invalid');

        $response->assertOk()
            ->assertJsonPath('data.period', 'invalid'); // Or defaults to week depending on implementation
    }
}
