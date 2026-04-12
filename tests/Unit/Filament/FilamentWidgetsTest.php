<?php

namespace Tests\Unit\Filament;

use App\Filament\Resources\CommissionResource\Pages\CommissionStatsWidget;
use App\Filament\Pages\PayoutOverview\PayoutStatsWidget;
use App\Filament\Widgets\DeliveryPerformanceChart;
use App\Filament\Widgets\FinanceOverviewWidget;
use App\Filament\Widgets\PendingKYCWidget;
use App\Filament\Widgets\PendingPrescriptionsWidget;
use App\Filament\Widgets\StatsOverview;
use App\Models\Commission;
use App\Models\CommissionLine;
use App\Models\Courier;
use App\Models\Customer;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Payment;
use App\Models\Pharmacy;
use App\Models\Prescription;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use App\Models\WithdrawalRequest;
use Illuminate\Foundation\Testing\RefreshDatabase;
use ReflectionClass;
use Tests\TestCase;

class FilamentWidgetsTest extends TestCase
{
    use RefreshDatabase;

    // ═══════════════════════════════════════════════════════════════
    //  StatsOverview Widget
    // ═══════════════════════════════════════════════════════════════

    public function test_stats_overview_returns_eight_stats(): void
    {
        // Create minimal data to prevent query errors
        $user = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        $courier = Courier::factory()->create(['status' => 'available', 'kyc_status' => 'approved']);

        $widget = new StatsOverview();
        $reflection = new ReflectionClass($widget);
        $method = $reflection->getMethod('getStats');
        $method->setAccessible(true);

        $stats = $method->invoke($widget);

        $this->assertIsArray($stats);
        $this->assertCount(8, $stats);
    }

    public function test_stats_overview_reflects_order_data(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        $customer = Customer::factory()->create(['user_id' => $user->id]);

        Order::factory()->count(3)->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $customer->id,
            'status'      => 'delivered',
            'total_amount' => 5000,
            'created_at'  => today(),
        ]);

        $widget = new StatsOverview();
        $reflection = new ReflectionClass($widget);
        $method = $reflection->getMethod('getStats');
        $method->setAccessible(true);

        $stats = $method->invoke($widget);

        // First stat is today's orders
        $this->assertStringContainsString('3', $stats[0]->getValue());
    }

    // ═══════════════════════════════════════════════════════════════
    //  FinanceOverviewWidget
    // ═══════════════════════════════════════════════════════════════

    public function test_finance_overview_returns_four_stats(): void
    {
        $widget = new FinanceOverviewWidget();
        $reflection = new ReflectionClass($widget);
        $method = $reflection->getMethod('getStats');
        $method->setAccessible(true);

        $stats = $method->invoke($widget);

        $this->assertIsArray($stats);
        $this->assertCount(4, $stats);
    }

    public function test_finance_overview_polling_interval(): void
    {
        $reflection = new ReflectionClass(FinanceOverviewWidget::class);
        $prop = $reflection->getProperty('pollingInterval');
        $prop->setAccessible(true);
        $this->assertSame('30s', $prop->getValue());
    }

    public function test_finance_overview_with_commission_data(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $customer = Customer::factory()->create();
        $order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $customer->id,
        ]);

        Commission::factory()->create([
            'order_id' => $order->id,
            'total_amount' => 1000,
            'created_at' => now(),
        ]);

        $widget = new FinanceOverviewWidget();
        $reflection = new ReflectionClass($widget);
        $method = $reflection->getMethod('getStats');
        $method->setAccessible(true);

        $stats = $method->invoke($widget);
        $this->assertCount(4, $stats);
    }

    // ═══════════════════════════════════════════════════════════════
    //  DeliveryPerformanceChart
    // ═══════════════════════════════════════════════════════════════

    public function test_delivery_performance_chart_type_is_bar(): void
    {
        $widget = new DeliveryPerformanceChart();
        $reflection = new ReflectionClass($widget);
        $method = $reflection->getMethod('getType');
        $method->setAccessible(true);

        $this->assertSame('bar', $method->invoke($widget));
    }

    public function test_delivery_performance_chart_has_options(): void
    {
        $widget = new DeliveryPerformanceChart();
        $reflection = new ReflectionClass($widget);
        $method = $reflection->getMethod('getOptions');
        $method->setAccessible(true);

        $options = $method->invoke($widget);

        $this->assertIsArray($options);
        $this->assertArrayHasKey('plugins', $options);
        $this->assertArrayHasKey('scales', $options);
    }

    public function test_delivery_performance_chart_polling_interval(): void
    {
        $reflection = new ReflectionClass(DeliveryPerformanceChart::class);
        $prop = $reflection->getProperty('pollingInterval');
        $prop->setAccessible(true);
        $this->assertSame('60s', $prop->getValue());
    }

    // ═══════════════════════════════════════════════════════════════
    //  PendingKYCWidget
    // ═══════════════════════════════════════════════════════════════

    public function test_pending_kyc_widget_can_view_when_pending(): void
    {
        Courier::factory()->create(['kyc_status' => 'pending_review']);

        $this->assertTrue(PendingKYCWidget::canView());
    }

    public function test_pending_kyc_widget_cannot_view_when_none_pending(): void
    {
        $this->assertFalse(PendingKYCWidget::canView());
    }

    public function test_pending_kyc_widget_heading(): void
    {
        $reflection = new ReflectionClass(PendingKYCWidget::class);
        $prop = $reflection->getProperty('heading');
        $prop->setAccessible(true);
        $this->assertStringContainsString('KYC', $prop->getValue());
    }

    public function test_pending_kyc_render_document_thumbnail_empty(): void
    {
        $widget = new PendingKYCWidget();
        $reflection = new ReflectionClass($widget);
        $method = $reflection->getMethod('renderDocumentThumbnail');
        $method->setAccessible(true);

        $result = $method->invoke($widget, null);
        $this->assertStringContainsString('N/A', $result);
    }

    public function test_pending_kyc_render_document_thumbnail_empty_string(): void
    {
        $widget = new PendingKYCWidget();
        $reflection = new ReflectionClass($widget);
        $method = $reflection->getMethod('renderDocumentThumbnail');
        $method->setAccessible(true);

        $result = $method->invoke($widget, '');
        $this->assertStringContainsString('N/A', $result);
    }

    // ═══════════════════════════════════════════════════════════════
    //  PendingPrescriptionsWidget
    // ═══════════════════════════════════════════════════════════════

    public function test_pending_prescriptions_widget_can_view_when_pending(): void
    {
        $customer = Customer::factory()->create();
        Prescription::factory()->create([
            'customer_id' => $customer->id,
            'status' => 'pending',
        ]);

        $this->assertTrue(PendingPrescriptionsWidget::canView());
    }

    public function test_pending_prescriptions_widget_cannot_view_when_none_pending(): void
    {
        $this->assertFalse(PendingPrescriptionsWidget::canView());
    }

    public function test_pending_prescriptions_widget_heading(): void
    {
        $reflection = new ReflectionClass(PendingPrescriptionsWidget::class);
        $prop = $reflection->getProperty('heading');
        $prop->setAccessible(true);
        $this->assertStringContainsString('Ordonnances', $prop->getValue());
    }

    // ═══════════════════════════════════════════════════════════════
    //  CommissionStatsWidget
    // ═══════════════════════════════════════════════════════════════

    public function test_commission_stats_widget_returns_four_stats(): void
    {
        $widget = new CommissionStatsWidget();
        $reflection = new ReflectionClass($widget);
        $method = $reflection->getMethod('getStats');
        $method->setAccessible(true);

        $stats = $method->invoke($widget);
        $this->assertIsArray($stats);
        $this->assertCount(4, $stats);
    }

    public function test_commission_stats_widget_with_data(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $customer = Customer::factory()->create();
        $order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $customer->id,
        ]);

        $commission = Commission::factory()->create([
            'order_id' => $order->id,
            'total_amount' => 2000,
            'calculated_at' => now(),
        ]);

        CommissionLine::create([
            'commission_id' => $commission->id,
            'actor_type' => 'platform',
            'actor_id' => 0,
            'amount' => 200,
            'rate' => 10,
        ]);

        CommissionLine::create([
            'commission_id' => $commission->id,
            'actor_type' => 'App\Models\Pharmacy',
            'actor_id' => $pharmacy->id,
            'amount' => 1700,
            'rate' => 85,
        ]);

        CommissionLine::create([
            'commission_id' => $commission->id,
            'actor_type' => 'App\Models\Courier',
            'actor_id' => 1,
            'amount' => 100,
            'rate' => 5,
        ]);

        $widget = new CommissionStatsWidget();
        $reflection = new ReflectionClass($widget);
        $method = $reflection->getMethod('getStats');
        $method->setAccessible(true);

        $stats = $method->invoke($widget);
        $this->assertCount(4, $stats);
    }

    // ═══════════════════════════════════════════════════════════════
    //  PayoutStatsWidget
    // ═══════════════════════════════════════════════════════════════

    public function test_payout_stats_widget_returns_four_stats(): void
    {
        // Ensure the platform wallet exists
        Wallet::firstOrCreate([
            'walletable_type' => 'platform',
            'walletable_id' => 0,
        ], [
            'balance' => 0,
            'currency' => 'XOF',
        ]);

        $widget = new PayoutStatsWidget();
        $reflection = new ReflectionClass($widget);
        $method = $reflection->getMethod('getStats');
        $method->setAccessible(true);

        $stats = $method->invoke($widget);
        $this->assertIsArray($stats);
        $this->assertCount(4, $stats);
    }

    public function test_payout_stats_widget_with_wallet_data(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        Wallet::factory()->create([
            'walletable_type' => 'App\Models\Pharmacy',
            'walletable_id' => $pharmacy->id,
            'balance' => 50000,
        ]);

        $courier = Courier::factory()->create();
        Wallet::factory()->create([
            'walletable_type' => 'App\Models\Courier',
            'walletable_id' => $courier->id,
            'balance' => 25000,
        ]);

        // Platform wallet
        Wallet::firstOrCreate([
            'walletable_type' => 'platform',
            'walletable_id' => 0,
        ], [
            'balance' => 100000,
            'currency' => 'XOF',
        ]);

        $widget = new PayoutStatsWidget();
        $reflection = new ReflectionClass($widget);
        $method = $reflection->getMethod('getStats');
        $method->setAccessible(true);

        $stats = $method->invoke($widget);
        $this->assertCount(4, $stats);

        // Verify pharmacy stat description mentions pharmacies
        $this->assertStringContainsString('pharmacie', $stats[0]->getDescription());
        // Verify courier stat description mentions livreurs
        $this->assertStringContainsString('livreur', $stats[1]->getDescription());
    }
}
