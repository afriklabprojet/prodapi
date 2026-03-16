<?php

namespace Tests\Feature\Api\Pharmacy;

use App\Models\User;
use App\Models\Pharmacy;
use App\Models\PharmacyOnCall;
use App\Models\DutyZone;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OnCallControllerTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $pharmacy;
    protected $dutyZone;

    protected function setUp(): void
    {
        parent::setUp();

        $this->dutyZone = DutyZone::factory()->create([
            'name' => 'Abidjan Nord',
        ]);

        $this->user = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
            'duty_zone_id' => $this->dutyZone->id,
        ]);
        $this->pharmacy->users()->attach($this->user->id);
    }

    /** @test */
    public function pharmacy_can_list_on_call_shifts()
    {
        PharmacyOnCall::factory()->count(3)->create([
            'pharmacy_id' => $this->pharmacy->id,
            'duty_zone_id' => $this->dutyZone->id,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/pharmacy/on-calls');

        $response->assertOk()
            ->assertJsonStructure([
                'status',
                'data' => [
                    'data' => [
                        '*' => [
                            'id',
                            'pharmacy_id',
                            'duty_zone_id',
                            'start_at',
                            'end_at',
                            'type',
                            'is_active',
                        ],
                    ],
                ],
            ]);
    }

    /** @test */
    public function pharmacy_can_filter_active_shifts_only()
    {
        PharmacyOnCall::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'duty_zone_id' => $this->dutyZone->id,
            'is_active' => true,
            'start_at' => now()->addDay(),
            'end_at' => now()->addDays(2),
        ]);

        PharmacyOnCall::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'duty_zone_id' => $this->dutyZone->id,
            'is_active' => false,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/pharmacy/on-calls?active_only=true');

        $response->assertOk();
    }

    /** @test */
    public function pharmacy_can_declare_on_call_shift()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/pharmacy/on-calls', [
                'start_at' => Carbon::now()->addHour()->toDateTimeString(),
                'end_at' => Carbon::now()->addHours(8)->toDateTimeString(),
                'type' => 'night',
            ]);

        $response->assertCreated()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('message', 'On-call shift declared successfully.')
            ->assertJsonStructure([
                'status',
                'message',
                'data' => [
                    'id',
                    'pharmacy_id',
                    'duty_zone_id',
                    'start_at',
                    'end_at',
                    'type',
                    'is_active',
                ],
            ]);

        $this->assertDatabaseHas('pharmacy_on_calls', [
            'pharmacy_id' => $this->pharmacy->id,
            'type' => 'night',
            'is_active' => true,
        ]);
    }

    /** @test */
    public function on_call_declaration_requires_valid_dates()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/pharmacy/on-calls', [
                'start_at' => Carbon::now()->subHour()->toDateTimeString(), // Past date
                'end_at' => Carbon::now()->addHours(8)->toDateTimeString(),
                'type' => 'night',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['start_at']);
    }

    /** @test */
    public function end_date_must_be_after_start_date()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/pharmacy/on-calls', [
                'start_at' => Carbon::now()->addHours(8)->toDateTimeString(),
                'end_at' => Carbon::now()->addHour()->toDateTimeString(), // Before start
                'type' => 'night',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['end_at']);
    }

    /** @test */
    public function on_call_type_must_be_valid()
    {
        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/pharmacy/on-calls', [
                'start_at' => Carbon::now()->addHour()->toDateTimeString(),
                'end_at' => Carbon::now()->addHours(8)->toDateTimeString(),
                'type' => 'invalid_type',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['type']);
    }

    /** @test */
    public function pharmacy_can_update_on_call_shift()
    {
        $onCall = PharmacyOnCall::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'duty_zone_id' => $this->dutyZone->id,
            'type' => 'night',
            'is_active' => true,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->putJson("/api/pharmacy/on-calls/{$onCall->id}", [
                'type' => 'weekend',
            ]);

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('message', 'On-call shift updated successfully.');

        $this->assertDatabaseHas('pharmacy_on_calls', [
            'id' => $onCall->id,
            'type' => 'weekend',
        ]);
    }

    /** @test */
    public function pharmacy_can_deactivate_on_call_shift()
    {
        $onCall = PharmacyOnCall::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'duty_zone_id' => $this->dutyZone->id,
            'is_active' => true,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->putJson("/api/pharmacy/on-calls/{$onCall->id}", [
                'is_active' => false,
            ]);

        $response->assertOk();

        $this->assertDatabaseHas('pharmacy_on_calls', [
            'id' => $onCall->id,
            'is_active' => false,
        ]);
    }

    /** @test */
    public function pharmacy_can_delete_on_call_shift()
    {
        $onCall = PharmacyOnCall::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'duty_zone_id' => $this->dutyZone->id,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->deleteJson("/api/pharmacy/on-calls/{$onCall->id}");

        $response->assertOk()
            ->assertJsonPath('status', 'success');

        $this->assertDatabaseMissing('pharmacy_on_calls', [
            'id' => $onCall->id,
        ]);
    }

    /** @test */
    public function pharmacy_cannot_modify_other_pharmacy_shifts()
    {
        $otherPharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $onCall = PharmacyOnCall::factory()->create([
            'pharmacy_id' => $otherPharmacy->id,
            'duty_zone_id' => $this->dutyZone->id,
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->putJson("/api/pharmacy/on-calls/{$onCall->id}", [
                'type' => 'weekend',
            ]);

        $response->assertNotFound();
    }

    /** @test */
    public function pharmacy_without_zone_cannot_declare_shift()
    {
        $pharmacyNoZone = Pharmacy::factory()->create([
            'status' => 'approved',
            'duty_zone_id' => null,
        ]);
        $userNoZone = User::factory()->create(['role' => 'pharmacy']);
        $pharmacyNoZone->users()->attach($userNoZone->id);

        $response = $this->actingAs($userNoZone, 'sanctum')
            ->postJson('/api/pharmacy/on-calls', [
                'start_at' => Carbon::now()->addHour()->toDateTimeString(),
                'end_at' => Carbon::now()->addHours(8)->toDateTimeString(),
                'type' => 'night',
            ]);

        $response->assertStatus(422)
            ->assertJsonPath('status', 'error');
    }

    /** @test */
    public function user_without_pharmacy_cannot_access()
    {
        $userNoPharmacy = User::factory()->create(['role' => 'pharmacy']);

        $response = $this->actingAs($userNoPharmacy, 'sanctum')
            ->getJson('/api/pharmacy/on-calls');

        $response->assertStatus(403);
    }

    /** @test */
    public function unauthenticated_user_cannot_access()
    {
        $response = $this->getJson('/api/pharmacy/on-calls');

        $response->assertUnauthorized();
    }
}
