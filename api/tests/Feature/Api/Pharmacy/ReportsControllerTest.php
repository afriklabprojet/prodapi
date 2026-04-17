<?php

namespace Tests\Feature\Api\Pharmacy;

use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReportsControllerTest extends TestCase
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

    public function test_pharmacy_can_view_overview(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/reports/overview?period=month');

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_pharmacy_can_view_sales_report(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/reports/sales?period=week');

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_pharmacy_can_view_orders_report(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/reports/orders?period=month');

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_pharmacy_can_view_inventory_report(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/reports/inventory');

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_pharmacy_can_view_stock_alerts(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/reports/stock-alerts');

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_pharmacy_can_export_report(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/reports/export?period=month');

        $response->assertOk();
    }

    public function test_unauthenticated_cannot_view_reports(): void
    {
        $response = $this->getJson('/api/pharmacy/reports/overview');

        $response->assertStatus(401);
    }
}
