<?php

namespace Tests\Feature\Api\Pharmacy;

use App\Models\DutyZone;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DutyZoneControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_anyone_can_list_duty_zones(): void
    {
        $response = $this->getJson('/api/duty-zones');

        $response->assertOk();
    }

    public function test_anyone_can_view_duty_zone(): void
    {
        $zone = DutyZone::factory()->create();

        $response = $this->getJson("/api/duty-zones/{$zone->id}");

        $response->assertOk();
    }

    public function test_returns_404_for_nonexistent_zone(): void
    {
        $response = $this->getJson('/api/duty-zones/99999');

        $response->assertStatus(404);
    }
}
