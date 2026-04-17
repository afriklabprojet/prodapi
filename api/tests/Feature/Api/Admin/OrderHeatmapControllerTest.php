<?php

namespace Tests\Feature\Api\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OrderHeatmapControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $admin;

    protected function setUp(): void
    {
        parent::setUp();

        $this->admin = User::factory()->create(['role' => 'admin']);
    }

    public function test_admin_can_view_order_heatmap(): void
    {
        $response = $this->actingAs($this->admin)->getJson('/api/admin/heatmap/orders?period=week');

        $response->assertOk();
    }

    public function test_admin_can_view_pharmacy_heatmap(): void
    {
        $response = $this->actingAs($this->admin)->getJson('/api/admin/heatmap/pharmacies?period=month');

        $response->assertOk();
    }

    public function test_non_admin_cannot_view_heatmap(): void
    {
        /** @var User $customer */
        $customer = User::factory()->create(['role' => 'customer']);

        $response = $this->actingAs($customer)->getJson('/api/admin/heatmap/orders');

        $response->assertStatus(403);
    }

    public function test_unauthenticated_cannot_view_heatmap(): void
    {
        $response = $this->getJson('/api/admin/heatmap/orders');

        $response->assertStatus(401);
    }
}
