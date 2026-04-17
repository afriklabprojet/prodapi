<?php

namespace Tests\Feature\Api\Pharmacy;

use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeliveryZoneControllerTest extends TestCase
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

    public function test_pharmacy_can_view_delivery_zone(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/delivery-zone');

        $response->assertOk();
    }

    public function test_pharmacy_can_create_delivery_zone(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/delivery-zone', [
            'name' => 'Zone Cocody',
            'polygon' => [
                ['lat' => 5.35, 'lng' => -3.98],
                ['lat' => 5.36, 'lng' => -3.97],
                ['lat' => 5.35, 'lng' => -3.96],
            ],
            'radius_km' => 5,
            'is_active' => true,
        ]);

        $response->assertSuccessful();
    }

    public function test_create_zone_requires_polygon(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/delivery-zone', [
            'name' => 'Zone Test',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('polygon');
    }

    public function test_polygon_requires_minimum_3_points(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/delivery-zone', [
            'polygon' => [
                ['lat' => 5.35, 'lng' => -3.98],
                ['lat' => 5.36, 'lng' => -3.97],
            ],
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('polygon');
    }

    public function test_pharmacy_can_delete_delivery_zone(): void
    {
        $response = $this->actingAs($this->user)->deleteJson('/api/pharmacy/delivery-zone');

        $response->assertOk();
    }

    public function test_unauthenticated_cannot_access_delivery_zone(): void
    {
        $response = $this->getJson('/api/pharmacy/delivery-zone');

        $response->assertStatus(401);
    }
}
