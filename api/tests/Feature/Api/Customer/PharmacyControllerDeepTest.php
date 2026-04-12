<?php

namespace Tests\Feature\Api\Customer;

use App\Models\Customer;
use App\Models\DutyZone;
use App\Models\Pharmacy;
use App\Models\PharmacyOnCall;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

/**
 * Deep tests targeting uncovered branches in Customer\PharmacyController:
 * - featured() method (all three paths)
 * - onDuty() distance calculation branch
 * - onDuty() duty_info non-null branch
 * - nearby() no-GPS fallback branch execution
 * - index() duty_info populated
 */
class PharmacyControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $this->user->id]);
    }

    // ──────────────────────────────────────────────────────────────────────
    // featured() – happy path: featured pharmacies exist
    // ──────────────────────────────────────────────────────────────────────

    #[Test]
    public function featured_returns_featured_pharmacies(): void
    {
        Pharmacy::factory()->create([
            'status'      => 'approved',
            'is_featured' => true,
            'name'        => 'Star Pharma',
        ]);
        Pharmacy::factory()->create([
            'status'      => 'approved',
            'is_featured' => false,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/featured');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'data' => ['*' => ['id', 'name', 'is_featured', 'is_on_duty']],
            ]);

        foreach ($response->json('data') as $item) {
            $this->assertTrue($item['is_featured']);
        }
    }

    #[Test]
    public function featured_includes_duty_info_when_pharmacy_is_on_duty(): void
    {
        $dutyZone = DutyZone::factory()->create();
        $pharmacy = Pharmacy::factory()->create([
            'status'        => 'approved',
            'is_featured'   => true,
            'duty_zone_id'  => $dutyZone->id,
        ]);

        PharmacyOnCall::factory()->create([
            'pharmacy_id'  => $pharmacy->id,
            'duty_zone_id' => $dutyZone->id,
            'start_at'     => Carbon::now()->subHour(),
            'end_at'       => Carbon::now()->addHours(8),
            'is_active'    => true,
            'type'         => 'night',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/featured');

        $response->assertOk();

        $data     = $response->json('data');
        $matching = collect($data)->firstWhere('id', $pharmacy->id);

        $this->assertNotNull($matching);
        $this->assertTrue($matching['is_on_duty']);
        $this->assertNotNull($matching['duty_info']);
        $this->assertEquals('night', $matching['duty_info']['type']);
    }

    #[Test]
    public function featured_payload_includes_no_duty_info_when_pharmacy_not_on_duty(): void
    {
        Pharmacy::factory()->create([
            'status'      => 'approved',
            'is_featured' => true,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/featured');

        $response->assertOk();

        foreach ($response->json('data') as $item) {
            $this->assertFalse($item['is_on_duty']);
            $this->assertNull($item['duty_info']);
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // featured() – first fallback: is_open pharmacies
    // ──────────────────────────────────────────────────────────────────────

    #[Test]
    public function featured_falls_back_to_open_pharmacies_when_none_featured(): void
    {
        // No featured pharmacies; is_open defaults to true in migration
        Pharmacy::factory()->create([
            'status'      => 'approved',
            'is_featured' => false,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/featured');

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertNotEmpty($response->json('data'));
    }

    // ──────────────────────────────────────────────────────────────────────
    // featured() – second fallback: any approved pharmacy
    // ──────────────────────────────────────────────────────────────────────

    #[Test]
    public function featured_falls_back_to_any_approved_when_no_open_pharmacies(): void
    {
        // No featured, no is_open pharmacies
        Pharmacy::factory()->create([
            'status'      => 'approved',
            'is_featured' => false,
            'is_open'     => false,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/featured');

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertNotEmpty($response->json('data'));
    }

    // ──────────────────────────────────────────────────────────────────────
    // onDuty() – distance is calculated when caller provides coordinates
    // ──────────────────────────────────────────────────────────────────────

    #[Test]
    public function on_duty_calculates_distance_when_pharmacy_has_coordinates(): void
    {
        $dutyZone = DutyZone::factory()->create();
        $pharmacy = Pharmacy::factory()->create([
            'status'       => 'approved',
            'latitude'     => 5.3601,
            'longitude'    => -4.0084,
            'duty_zone_id' => $dutyZone->id,
        ]);

        PharmacyOnCall::factory()->create([
            'pharmacy_id'  => $pharmacy->id,
            'duty_zone_id' => $dutyZone->id,
            'start_at'     => Carbon::now()->subHour(),
            'end_at'       => Carbon::now()->addHours(8),
            'is_active'    => true,
            'type'         => 'weekend',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/on-duty?latitude=5.3600&longitude=-4.0083');

        $response->assertOk();

        $data     = $response->json('data');
        $matching = collect($data)->firstWhere('id', $pharmacy->id);

        $this->assertNotNull($matching, 'On-duty pharmacy should appear in response');
        $this->assertNotNull($matching['distance'], 'Distance should be calculated');
        $this->assertIsFloat($matching['distance']);
        $this->assertTrue($matching['is_on_duty']);
        $this->assertTrue($matching['is_open']);
    }

    #[Test]
    public function on_duty_distance_is_null_when_no_location_params_provided(): void
    {
        $dutyZone = DutyZone::factory()->create();
        $pharmacy = Pharmacy::factory()->create([
            'status'       => 'approved',
            'latitude'     => 5.3601,
            'longitude'    => -4.0084,
            'duty_zone_id' => $dutyZone->id,
        ]);

        PharmacyOnCall::factory()->create([
            'pharmacy_id'  => $pharmacy->id,
            'duty_zone_id' => $dutyZone->id,
            'start_at'     => Carbon::now()->subHour(),
            'end_at'       => Carbon::now()->addHours(8),
            'is_active'    => true,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/on-duty');

        $response->assertOk();

        $data     = $response->json('data');
        $matching = collect($data)->firstWhere('id', $pharmacy->id);

        $this->assertNotNull($matching);
        $this->assertNull($matching['distance']);
    }

    #[Test]
    public function on_duty_pharmacy_without_coordinates_has_null_distance_even_with_location(): void
    {
        $dutyZone = DutyZone::factory()->create();
        $pharmacy = Pharmacy::factory()->create([
            'status'       => 'approved',
            'latitude'     => null,
            'longitude'    => null,
            'duty_zone_id' => $dutyZone->id,
        ]);

        PharmacyOnCall::factory()->create([
            'pharmacy_id'  => $pharmacy->id,
            'duty_zone_id' => $dutyZone->id,
            'start_at'     => Carbon::now()->subHour(),
            'end_at'       => Carbon::now()->addHours(8),
            'is_active'    => true,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/on-duty?latitude=5.3600&longitude=-4.0083');

        $response->assertOk();

        $data     = $response->json('data');
        $matching = collect($data)->firstWhere('id', $pharmacy->id);

        $this->assertNotNull($matching);
        $this->assertNull($matching['distance']);
    }

    #[Test]
    public function on_duty_includes_duty_info_for_on_duty_pharmacies(): void
    {
        $dutyZone = DutyZone::factory()->create();
        $pharmacy = Pharmacy::factory()->create([
            'status'       => 'approved',
            'duty_zone_id' => $dutyZone->id,
        ]);

        PharmacyOnCall::factory()->create([
            'pharmacy_id'  => $pharmacy->id,
            'duty_zone_id' => $dutyZone->id,
            'start_at'     => Carbon::now()->subHour(),
            'end_at'       => Carbon::now()->addHours(8),
            'is_active'    => true,
            'type'         => 'night',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/on-duty');

        $response->assertOk();

        $data     = $response->json('data');
        $matching = collect($data)->firstWhere('id', $pharmacy->id);

        $this->assertNotNull($matching);
        $this->assertNotNull($matching['duty_info']);
        $this->assertEquals('night', $matching['duty_info']['type']);
        $this->assertArrayHasKey('end_at', $matching['duty_info']);
    }

    // ──────────────────────────────────────────────────────────────────────
    // onDuty() – sorted by proximity: nearest first
    // ──────────────────────────────────────────────────────────────────────

    #[Test]
    public function on_duty_results_sorted_by_distance_when_location_provided(): void
    {
        $dutyZone = DutyZone::factory()->create();

        $near = Pharmacy::factory()->create([
            'status'       => 'approved',
            'latitude'     => 5.3601,
            'longitude'    => -4.0084,
            'duty_zone_id' => $dutyZone->id,
        ]);

        $far = Pharmacy::factory()->create([
            'status'       => 'approved',
            'latitude'     => 6.5000,
            'longitude'    => -5.0000,
            'duty_zone_id' => $dutyZone->id,
        ]);

        foreach ([$near, $far] as $ph) {
            PharmacyOnCall::factory()->create([
                'pharmacy_id'  => $ph->id,
                'duty_zone_id' => $dutyZone->id,
                'start_at'     => Carbon::now()->subHour(),
                'end_at'       => Carbon::now()->addHours(8),
                'is_active'    => true,
            ]);
        }

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/on-duty?latitude=5.3600&longitude=-4.0083');

        $response->assertOk();

        $ids = collect($response->json('data'))->pluck('id')->toArray();
        $nearIdx = array_search($near->id, $ids);
        $farIdx  = array_search($far->id, $ids);

        $this->assertNotFalse($nearIdx);
        $this->assertNotFalse($farIdx);
        $this->assertLessThan($farIdx, $nearIdx, 'Nearest pharmacy should appear before farther one');
    }

    // ──────────────────────────────────────────────────────────────────────
    // index() – duty_info populated for an on-duty pharmacy
    // ──────────────────────────────────────────────────────────────────────

    #[Test]
    public function index_shows_duty_info_for_on_duty_pharmacy(): void
    {
        $dutyZone = DutyZone::factory()->create();
        $pharmacy = Pharmacy::factory()->create([
            'status'       => 'approved',
            'duty_zone_id' => $dutyZone->id,
        ]);

        PharmacyOnCall::factory()->create([
            'pharmacy_id'  => $pharmacy->id,
            'duty_zone_id' => $dutyZone->id,
            'start_at'     => Carbon::now()->subHour(),
            'end_at'       => Carbon::now()->addHours(8),
            'is_active'    => true,
            'type'         => 'weekend',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies');

        $response->assertOk();

        $data     = $response->json('data');
        $matching = collect($data)->firstWhere('id', $pharmacy->id);

        $this->assertNotNull($matching);
        $this->assertTrue($matching['is_on_duty']);
        $this->assertNotNull($matching['duty_info']);
        $this->assertEquals('weekend', $matching['duty_info']['type']);
    }

    // ──────────────────────────────────────────────────────────────────────
    // nearby() – no-GPS pharmacy appears in fallback block
    // ──────────────────────────────────────────────────────────────────────

    #[Test]
    public function nearby_includes_pharmacy_without_gps_as_fallback(): void
    {
        Pharmacy::factory()->create([
            'status'    => 'approved',
            'latitude'  => null,
            'longitude' => null,
            'name'      => 'No GPS Pharma',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/nearby?latitude=5.3600&longitude=-4.0083&radius=10');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['success', 'data', 'meta' => ['count', 'nearby_count', 'radius_km']]);

        $names = collect($response->json('data'))->pluck('name')->toArray();
        $this->assertContains('No GPS Pharma', $names);
    }

    #[Test]
    public function nearby_meta_nearby_count_reflects_geo_pharmacies_only(): void
    {
        Pharmacy::factory()->create([
            'status'    => 'approved',
            'latitude'  => 5.3601,
            'longitude' => -4.0084,
        ]);
        Pharmacy::factory()->create([
            'status'    => 'approved',
            'latitude'  => null,
            'longitude' => null,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/nearby?latitude=5.3600&longitude=-4.0083&radius=50');

        $response->assertOk();

        $meta = $response->json('meta');
        $this->assertArrayHasKey('nearby_count', $meta);
        $this->assertArrayHasKey('count', $meta);
        // Total count must be >= nearby_count (no-GPS pharmacies add to total)
        $this->assertGreaterThanOrEqual($meta['nearby_count'], $meta['count']);
    }

    // ──────────────────────────────────────────────────────────────────────
    // featured() – validates response structure matches controller output
    // ──────────────────────────────────────────────────────────────────────

    #[Test]
    public function featured_returns_empty_data_when_no_approved_pharmacies(): void
    {
        // No pharmacies at all
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/featured');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data', []);
    }
}
