<?php

namespace Tests\Feature\Api\Admin;

use App\Models\Courier;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExportControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $admin;

    protected function setUp(): void
    {
        parent::setUp();

        $this->admin = User::factory()->create(['role' => 'admin']);
    }

    public function test_admin_can_export_orders(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $customer = User::factory()->create(['role' => 'customer']);
        Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $customer->id,
            'status' => 'delivered',
        ]);

        $response = $this->actingAs($this->admin)->get('/api/admin/export/orders');

        $response->assertOk();
        $this->assertStringContainsString('text/csv', $response->headers->get('Content-Type'));
    }

    public function test_admin_can_export_orders_with_date_range(): void
    {
        $response = $this->actingAs($this->admin)->get('/api/admin/export/orders?from=2025-01-01&to=2025-12-31');

        $response->assertOk();
        $this->assertStringContainsString('text/csv', $response->headers->get('Content-Type'));
    }

    public function test_admin_can_export_deliveries(): void
    {
        $courier = Courier::factory()->create();
        $order = Order::factory()->create();
        Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
        ]);

        $response = $this->actingAs($this->admin)->get('/api/admin/export/deliveries');

        $response->assertOk();
        $this->assertStringContainsString('text/csv', $response->headers->get('Content-Type'));
    }

    public function test_admin_can_export_revenue(): void
    {
        Order::factory()->create(['status' => 'delivered', 'total_amount' => 10000]);

        $response = $this->actingAs($this->admin)->get('/api/admin/export/revenue?group_by=month');

        $response->assertOk();
        $this->assertStringContainsString('text/csv', $response->headers->get('Content-Type'));
    }

    public function test_admin_can_export_pharmacies(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $owner = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy->users()->attach($owner->id, ['role' => 'titulaire']);

        $response = $this->actingAs($this->admin)->get('/api/admin/export/pharmacies');

        $response->assertOk();
        $this->assertStringContainsString('text/csv', $response->headers->get('Content-Type'));
    }

    public function test_admin_can_export_couriers(): void
    {
        Courier::factory()->create();

        $response = $this->actingAs($this->admin)->get('/api/admin/export/couriers');

        $response->assertOk();
        $this->assertStringContainsString('text/csv', $response->headers->get('Content-Type'));
    }

    public function test_export_validates_date_range(): void
    {
        $response = $this->actingAs($this->admin)->getJson('/api/admin/export/orders?from=2025-12-31&to=2025-01-01');

        $response->assertStatus(422)->assertJsonValidationErrors('to');
    }

    public function test_non_admin_cannot_export(): void
    {
        /** @var User $customer */
        $customer = User::factory()->create(['role' => 'customer']);

        $response = $this->actingAs($customer)->getJson('/api/admin/export/orders');

        $response->assertStatus(403);
    }

    public function test_csv_contains_expected_headers_for_orders(): void
    {
        Order::factory()->create();

        $response = $this->actingAs($this->admin)->get('/api/admin/export/orders');

        $response->assertOk();
        $content = $response->streamedContent();
        $this->assertStringContainsString('Pharmacie', $content);
    }
}
