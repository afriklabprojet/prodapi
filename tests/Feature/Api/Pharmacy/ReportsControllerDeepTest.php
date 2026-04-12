<?php

namespace Tests\Feature\Api\Pharmacy;

use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Product;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

/**
 * Deep tests for Pharmacy\ReportsController targeting uncovered branches:
 * - "no pharmacy" early-return in all 6 methods
 * - periodStart() for week / quarter / year variants
 * - overview() growth calculation when yesterday > 0
 * - stockAlerts() out_of_stock / low_stock / expiring_soon / expired loops
 * - sales() with delivered orders (daily breakdown + top products)
 * - export() with delivered orders
 */
class ReportsControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    // ─────────────────────────────────────────────────────────
    // "No pharmacy" branches – each endpoint returns empty data
    // ─────────────────────────────────────────────────────────

    private function makePharmacyUserWithoutPharmacy(): User
    {
        return User::factory()->create(['role' => 'pharmacy']);
    }

    private function makePharmacyUserWithPharmacy(): array
    {
        $user     = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $pharmacy->users()->attach($user->id, ['role' => 'titulaire']);
        return [$user, $pharmacy];
    }

    #[Test]
    public function overview_returns_empty_data_when_user_has_no_pharmacy(): void
    {
        $user = $this->makePharmacyUserWithoutPharmacy();

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/overview');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.orders.total', 0)
            ->assertJsonPath('data.inventory.total_products', 0);
    }

    #[Test]
    public function sales_returns_empty_data_when_user_has_no_pharmacy(): void
    {
        $user = $this->makePharmacyUserWithoutPharmacy();

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/sales');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.total_revenue', 0)
            ->assertJsonPath('data.total_orders', 0);
    }

    #[Test]
    public function orders_returns_empty_data_when_user_has_no_pharmacy(): void
    {
        $user = $this->makePharmacyUserWithoutPharmacy();

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/orders');

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    #[Test]
    public function inventory_returns_empty_data_when_user_has_no_pharmacy(): void
    {
        $user = $this->makePharmacyUserWithoutPharmacy();

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/inventory');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.total_products', 0);
    }

    #[Test]
    public function stock_alerts_returns_empty_alerts_when_user_has_no_pharmacy(): void
    {
        $user = $this->makePharmacyUserWithoutPharmacy();

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/stock-alerts');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.alerts', []);
    }

    #[Test]
    public function export_returns_empty_data_when_user_has_no_pharmacy(): void
    {
        $user = $this->makePharmacyUserWithoutPharmacy();

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/export');

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    // ─────────────────────────────────────────────────────────
    // periodStart() – week / quarter / year variants
    // ─────────────────────────────────────────────────────────

    #[Test]
    public function overview_accepts_week_period(): void
    {
        [$user] = $this->makePharmacyUserWithPharmacy();

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/overview?period=week');

        $response->assertOk()->assertJsonPath('data.period', 'week');
    }

    #[Test]
    public function overview_accepts_quarter_period(): void
    {
        [$user] = $this->makePharmacyUserWithPharmacy();

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/overview?period=quarter');

        $response->assertOk()->assertJsonPath('data.period', 'quarter');
    }

    #[Test]
    public function overview_accepts_year_period(): void
    {
        [$user] = $this->makePharmacyUserWithPharmacy();

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/overview?period=year');

        $response->assertOk()->assertJsonPath('data.period', 'year');
    }

    #[Test]
    public function sales_accepts_quarter_period(): void
    {
        [$user] = $this->makePharmacyUserWithPharmacy();

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/sales?period=quarter');

        $response->assertOk()->assertJsonPath('success', true);
    }

    #[Test]
    public function sales_accepts_year_period(): void
    {
        [$user] = $this->makePharmacyUserWithPharmacy();

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/sales?period=year');

        $response->assertOk()->assertJsonPath('success', true);
    }

    // ─────────────────────────────────────────────────────────
    // overview() – growth calculation when yesterday has sales
    // ─────────────────────────────────────────────────────────

    #[Test]
    public function overview_calculates_growth_when_yesterday_has_sales(): void
    {
        [$user, $pharmacy] = $this->makePharmacyUserWithPharmacy();
        $customer          = User::factory()->create(['role' => 'customer']);

        // Yesterday delivered order
        Order::factory()->create([
            'pharmacy_id'   => $pharmacy->id,
            'customer_id'   => $customer->id,
            'status'        => 'delivered',
            'payment_status'=> 'paid',
            'total_amount'  => 10000,
            'created_at'    => Carbon::yesterday(),
        ]);

        // Today delivered order (double the amount → 100% growth)
        Order::factory()->create([
            'pharmacy_id'   => $pharmacy->id,
            'customer_id'   => $customer->id,
            'status'        => 'delivered',
            'payment_status'=> 'paid',
            'total_amount'  => 20000,
            'created_at'    => Carbon::today(),
        ]);

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/overview?period=month');

        $response->assertOk();
        $sales = $response->json('data.sales');

        $this->assertEquals(20000.0, $sales['today']);
        $this->assertEquals(10000.0, $sales['yesterday']);
        $this->assertEquals(100.0, $sales['growth']);
    }

    #[Test]
    public function overview_growth_is_zero_when_no_yesterday_sales(): void
    {
        [$user, $pharmacy] = $this->makePharmacyUserWithPharmacy();
        $customer          = User::factory()->create(['role' => 'customer']);

        Order::factory()->create([
            'pharmacy_id'   => $pharmacy->id,
            'customer_id'   => $customer->id,
            'status'        => 'delivered',
            'payment_status'=> 'paid',
            'total_amount'  => 15000,
            'created_at'    => Carbon::today(),
        ]);

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/overview?period=month');

        $response->assertOk();
        $this->assertEquals(0, $response->json('data.sales.growth'));
    }

    // ─────────────────────────────────────────────────────────
    // overview() – inventory stats
    // ─────────────────────────────────────────────────────────

    #[Test]
    public function overview_counts_inventory_stats_correctly(): void
    {
        [$user, $pharmacy] = $this->makePharmacyUserWithPharmacy();

        // Normal product
        Product::factory()->create([
            'pharmacy_id'        => $pharmacy->id,
            'stock_quantity'     => 50,
            'low_stock_threshold'=> 10,
            'is_available'       => true,
        ]);

        // Low-stock product
        Product::factory()->create([
            'pharmacy_id'        => $pharmacy->id,
            'stock_quantity'     => 5,
            'low_stock_threshold'=> 10,
            'is_available'       => true,
        ]);

        // Out-of-stock
        Product::factory()->create([
            'pharmacy_id'        => $pharmacy->id,
            'stock_quantity'     => 0,
            'is_available'       => true,
        ]);

        // Expiring soon (in 15 days)
        Product::factory()->create([
            'pharmacy_id'        => $pharmacy->id,
            'stock_quantity'     => 20,
            'low_stock_threshold'=> 5,
            'is_available'       => true,
            'expiry_date'        => Carbon::now()->addDays(15)->toDateString(),
        ]);

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/overview?period=month');

        $response->assertOk();
        $inv = $response->json('data.inventory');

        $this->assertEquals(4, $inv['total_products']);
        $this->assertGreaterThanOrEqual(1, $inv['low_stock']);
        $this->assertGreaterThanOrEqual(1, $inv['out_of_stock']);
        $this->assertGreaterThanOrEqual(1, $inv['expiring_soon']);
    }

    // ─────────────────────────────────────────────────────────
    // stockAlerts() – each alert type
    // ─────────────────────────────────────────────────────────

    #[Test]
    public function stock_alerts_includes_out_of_stock_products(): void
    {
        [$user, $pharmacy] = $this->makePharmacyUserWithPharmacy();

        Product::factory()->create([
            'pharmacy_id'    => $pharmacy->id,
            'stock_quantity' => 0,
            'is_available'   => true,
            'name'           => 'Empty Stock Product',
        ]);

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/stock-alerts');

        $response->assertOk();
        $alerts = collect($response->json('data.alerts'));
        $outOfStock = $alerts->where('type', 'out_of_stock');

        $this->assertTrue($outOfStock->isNotEmpty());
        $this->assertEquals('Empty Stock Product', $outOfStock->first()['product_name']);
    }

    #[Test]
    public function stock_alerts_includes_low_stock_products(): void
    {
        [$user, $pharmacy] = $this->makePharmacyUserWithPharmacy();

        Product::factory()->create([
            'pharmacy_id'        => $pharmacy->id,
            'stock_quantity'     => 3,
            'low_stock_threshold'=> 10,
            'is_available'       => true,
            'name'               => 'Low Stock Product',
        ]);

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/stock-alerts');

        $response->assertOk();
        $alerts   = collect($response->json('data.alerts'));
        $lowStock = $alerts->where('type', 'low_stock');

        $this->assertTrue($lowStock->isNotEmpty());
        $this->assertEquals('Low Stock Product', $lowStock->first()['product_name']);
        $this->assertEquals(3, $lowStock->first()['current_quantity']);
    }

    #[Test]
    public function stock_alerts_includes_expiring_soon_products(): void
    {
        [$user, $pharmacy] = $this->makePharmacyUserWithPharmacy();

        Product::factory()->create([
            'pharmacy_id'    => $pharmacy->id,
            'stock_quantity' => 50,
            'is_available'   => true,
            'expiry_date'    => Carbon::now()->addDays(10)->toDateString(),
            'name'           => 'Expiring Soon Product',
        ]);

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/stock-alerts');

        $response->assertOk();
        $alerts      = collect($response->json('data.alerts'));
        $expiringSoon = $alerts->where('type', 'expiring_soon');

        $this->assertTrue($expiringSoon->isNotEmpty());
        $this->assertEquals('Expiring Soon Product', $expiringSoon->first()['product_name']);
        $this->assertNotNull($expiringSoon->first()['expiry_date']);
    }

    #[Test]
    public function stock_alerts_includes_expired_products(): void
    {
        [$user, $pharmacy] = $this->makePharmacyUserWithPharmacy();

        Product::factory()->create([
            'pharmacy_id'    => $pharmacy->id,
            'stock_quantity' => 20,
            'is_available'   => true,
            'expiry_date'    => Carbon::now()->subDays(5)->toDateString(),
            'name'           => 'Expired Product',
        ]);

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/stock-alerts');

        $response->assertOk();
        $alerts  = collect($response->json('data.alerts'));
        $expired = $alerts->where('type', 'expired');

        $this->assertTrue($expired->isNotEmpty());
        $this->assertEquals('Expired Product', $expired->first()['product_name']);
    }

    #[Test]
    public function stock_alerts_alert_structure_is_correct(): void
    {
        [$user, $pharmacy] = $this->makePharmacyUserWithPharmacy();

        Product::factory()->create([
            'pharmacy_id'        => $pharmacy->id,
            'stock_quantity'     => 0,
            'low_stock_threshold'=> 5,
            'is_available'       => true,
            'price'              => 5000,
            'expiry_date'        => Carbon::now()->addDays(60)->toDateString(),
        ]);

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/stock-alerts');

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'alerts' => [
                        '*' => [
                            'product_id',
                            'product_name',
                            'type',
                            'current_quantity',
                            'threshold',
                            'price',
                        ],
                    ],
                ],
            ]);
    }

    // ─────────────────────────────────────────────────────────
    // sales() – with actual delivered orders
    // ─────────────────────────────────────────────────────────

    #[Test]
    public function sales_returns_correct_revenue_and_order_count(): void
    {
        [$user, $pharmacy] = $this->makePharmacyUserWithPharmacy();
        $customer          = User::factory()->create(['role' => 'customer']);

        Order::factory()->count(3)->create([
            'pharmacy_id'   => $pharmacy->id,
            'customer_id'   => $customer->id,
            'status'        => 'delivered',
            'payment_status'=> 'paid',
            'total_amount'  => 10000,
        ]);

        // Cancelled order should NOT be counted
        Order::factory()->create([
            'pharmacy_id'   => $pharmacy->id,
            'customer_id'   => $customer->id,
            'status'        => 'cancelled',
            'total_amount'  => 5000,
        ]);

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/sales?period=month');

        $response->assertOk();
        $data = $response->json('data');

        $this->assertEquals(30000.0, $data['total_revenue']);
        $this->assertEquals(3, $data['total_orders']);
        $this->assertEquals(10000.0, $data['average_order_value']);
    }

    #[Test]
    public function sales_returns_daily_breakdown_structure(): void
    {
        [$user, $pharmacy] = $this->makePharmacyUserWithPharmacy();
        $customer          = User::factory()->create(['role' => 'customer']);

        Order::factory()->create([
            'pharmacy_id'   => $pharmacy->id,
            'customer_id'   => $customer->id,
            'status'        => 'delivered',
            'payment_status'=> 'paid',
            'total_amount'  => 8000,
        ]);

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/sales?period=month');

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'daily_breakdown',
                    'top_products',
                ],
            ]);
    }

    // ─────────────────────────────────────────────────────────
    // inventory() – with actual products
    // ─────────────────────────────────────────────────────────

    #[Test]
    public function inventory_returns_correct_stats(): void
    {
        [$user, $pharmacy] = $this->makePharmacyUserWithPharmacy();

        Product::factory()->create([
            'pharmacy_id'    => $pharmacy->id,
            'stock_quantity' => 100,
            'is_available'   => true,
        ]);
        Product::factory()->create([
            'pharmacy_id'    => $pharmacy->id,
            'stock_quantity' => 0,
            'is_available'   => true,
        ]);
        Product::factory()->create([
            'pharmacy_id'    => $pharmacy->id,
            'stock_quantity' => 50,
            'is_available'   => false,
        ]);

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/inventory');

        $response->assertOk();
        $data = $response->json('data');

        $this->assertEquals(3, $data['total_products']);
        $this->assertEquals(2, $data['active_products']); // only is_available=true
        $this->assertGreaterThanOrEqual(1, $data['out_of_stock']);
    }

    // ─────────────────────────────────────────────────────────
    // orders() – with actual orders grouped by status
    // ─────────────────────────────────────────────────────────

    #[Test]
    public function orders_report_groups_by_status(): void
    {
        [$user, $pharmacy] = $this->makePharmacyUserWithPharmacy();
        $customer          = User::factory()->create(['role' => 'customer']);

        Order::factory()->count(2)->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $customer->id,
            'status'      => 'delivered',
        ]);
        Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $customer->id,
            'status'      => 'pending',
        ]);

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/orders?period=month');

        $response->assertOk()->assertJsonPath('success', true);
        $data = $response->json('data');

        $this->assertArrayHasKey('delivered', $data);
        $this->assertEquals(2, $data['delivered']);
        $this->assertArrayHasKey('pending', $data);
    }

    // ─────────────────────────────────────────────────────────
    // export() – returns delivered orders
    // ─────────────────────────────────────────────────────────

    #[Test]
    public function export_returns_delivered_orders_for_period(): void
    {
        [$user, $pharmacy] = $this->makePharmacyUserWithPharmacy();
        $customer          = User::factory()->create(['role' => 'customer']);

        Order::factory()->count(2)->create([
            'pharmacy_id'   => $pharmacy->id,
            'customer_id'   => $customer->id,
            'status'        => 'delivered',
            'payment_status'=> 'paid',
        ]);
        // Pending should not appear in export
        Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $customer->id,
            'status'      => 'pending',
        ]);

        $response = $this->actingAs($user)->getJson('/api/pharmacy/reports/export?period=month');

        $response->assertOk()->assertJsonPath('success', true);

        // At most delivered orders should be in the export
        foreach ($response->json('data') as $order) {
            $this->assertEquals('delivered', $order['status']);
        }
    }
}
