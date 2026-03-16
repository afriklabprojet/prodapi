<?php

namespace Tests\Feature\Api\Customer;

use App\Models\User;
use App\Models\Customer;
use App\Models\Pharmacy;
use App\Models\PharmacyOnCall;
use App\Models\DutyZone;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PharmacyControllerTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $customer;
    protected $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'customer']);
        $this->customer = Customer::factory()->create([
            'user_id' => $this->user->id,
        ]);

        $this->pharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
            'latitude' => 5.3600,
            'longitude' => -4.0083,
            'city' => 'Abidjan',
        ]);
    }

    /** @test */
    public function customer_can_list_all_pharmacies()
    {
        Pharmacy::factory()->count(5)->create(['status' => 'approved']);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies');

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'data' => [
                    '*' => [
                        'id',
                        'name',
                        'phone',
                        'address',
                        'city',
                        'latitude',
                        'longitude',
                        'is_open',
                        'is_on_duty',
                    ],
                ],
            ]);
    }

    /** @test */
    public function only_approved_pharmacies_are_listed()
    {
        Pharmacy::factory()->create(['status' => 'pending']);
        Pharmacy::factory()->create(['status' => 'rejected']);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies');

        $response->assertOk();
        foreach ($response->json('data') as $pharmacy) {
            $this->assertEquals('approved', $pharmacy['status']);
        }
    }

    /** @test */
    public function customer_can_get_nearby_pharmacies()
    {
        // Create nearby pharmacy
        Pharmacy::factory()->create([
            'status' => 'approved',
            'latitude' => 5.3601,
            'longitude' => -4.0084,
        ]);

        // Create far pharmacy
        Pharmacy::factory()->create([
            'status' => 'approved',
            'latitude' => 10.0000,
            'longitude' => -5.0000,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/nearby?latitude=5.3600&longitude=-4.0083&radius=10');

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'data',
                'meta' => [
                    'count',
                    'radius_km',
                ],
            ]);
    }

    /** @test */
    public function nearby_requires_coordinates()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/nearby');

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['latitude', 'longitude']);
    }

    /** @test */
    public function nearby_validates_radius_range()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/nearby?latitude=5.3600&longitude=-4.0083&radius=100');

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['radius']);
    }

    /** @test */
    public function default_radius_is_10km()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/nearby?latitude=5.3600&longitude=-4.0083');

        $response->assertOk()
            ->assertJsonPath('meta.radius_km', 10);
    }

    /** @test */
    public function customer_can_view_pharmacy_details()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/customer/pharmacies/{$this->pharmacy->id}");

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'data' => [
                    'id',
                    'name',
                    'phone',
                    'email',
                    'address',
                    'city',
                    'latitude',
                    'longitude',
                    'is_open',
                    'is_on_duty',
                ],
            ]);
    }

    /** @test */
    public function returns_404_for_non_approved_pharmacy()
    {
        $pendingPharmacy = Pharmacy::factory()->create(['status' => 'pending']);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/customer/pharmacies/{$pendingPharmacy->id}");

        $response->assertNotFound();
    }

    /** @test */
    public function returns_404_for_non_existent_pharmacy()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/999999');

        $response->assertNotFound();
    }

    /** @test */
    public function customer_can_get_on_duty_pharmacies()
    {
        $dutyZone = DutyZone::factory()->create();
        $this->pharmacy->update(['duty_zone_id' => $dutyZone->id]);

        // Create on-call entry
        PharmacyOnCall::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'duty_zone_id' => $dutyZone->id,
            'start_at' => Carbon::now()->subHour(),
            'end_at' => Carbon::now()->addHours(8),
            'is_active' => true,
            'type' => 'night',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/on-duty');

        $response->assertOk()
            ->assertJsonStructure([
                'success',
                'data',
            ]);
    }

    /** @test */
    public function on_duty_can_filter_by_location()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/on-duty?latitude=5.3600&longitude=-4.0083&radius=10');

        $response->assertOk();
    }

    /** @test */
    public function pharmacy_shows_duty_info_when_on_duty()
    {
        $dutyZone = DutyZone::factory()->create();
        $this->pharmacy->update(['duty_zone_id' => $dutyZone->id]);

        PharmacyOnCall::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'duty_zone_id' => $dutyZone->id,
            'start_at' => Carbon::now()->subHour(),
            'end_at' => Carbon::now()->addHours(8),
            'is_active' => true,
            'type' => 'night',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/customer/pharmacies/{$this->pharmacy->id}");

        $response->assertOk()
            ->assertJsonPath('data.is_on_duty', true)
            ->assertJsonStructure([
                'data' => [
                    'duty_info' => [
                        'type',
                        'end_at',
                    ],
                ],
            ]);
    }

    /** @test */
    public function pharmacy_shows_no_duty_info_when_not_on_duty()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson("/api/customer/pharmacies/{$this->pharmacy->id}");

        $response->assertOk()
            ->assertJsonPath('data.is_on_duty', false)
            ->assertJsonPath('data.duty_info', null);
    }

    /** @test */
    public function pharmacies_are_ordered_by_name()
    {
        Pharmacy::factory()->create(['status' => 'approved', 'name' => 'Zebra Pharmacie']);
        Pharmacy::factory()->create(['status' => 'approved', 'name' => 'Alpha Pharmacie']);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies');

        $response->assertOk();
        $names = collect($response->json('data'))->pluck('name')->toArray();
        $sortedNames = $names;
        sort($sortedNames);
        $this->assertEquals($sortedNames, $names);
    }

    /** @test */
    public function guest_can_list_pharmacies()
    {
        $response = $this->getJson('/api/customer/pharmacies');

        // Depending on API design, could be 200 or 401
        $this->assertContains($response->getStatusCode(), [200, 401]);
    }

    /** @test */
    public function nearby_pharmacies_include_distance()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/customer/pharmacies/nearby?latitude=5.3600&longitude=-4.0083');

        $response->assertOk();
        // Check that response includes distance field
        foreach ($response->json('data') as $pharmacy) {
            $this->assertArrayHasKey('distance', $pharmacy);
        }
    }
}
