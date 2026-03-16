<?php

namespace Tests\Unit\Models;

use App\Models\Pharmacy;
use App\Models\User;
use App\Models\Order;
use App\Models\Product;
use App\Models\PharmacyOnCall;
use App\Models\DutyZone;
use App\Models\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PharmacyTest extends TestCase
{
    use RefreshDatabase;

    protected $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();

        $this->pharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
            'latitude' => 5.3600,
            'longitude' => -4.0083,
        ]);
    }

    /** @test */
    public function it_has_users_relationship()
    {
        $user = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy->users()->attach($user->id, ['role' => 'owner']);

        $this->assertCount(1, $this->pharmacy->users);
        $this->assertEquals($user->id, $this->pharmacy->users->first()->id);
    }

    /** @test */
    public function it_has_many_orders()
    {
        $user = User::factory()->create(['role' => 'customer']);
        Order::factory()->count(3)->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $user->id,
        ]);

        $this->assertCount(3, $this->pharmacy->orders);
    }

    /** @test */
    public function it_has_duty_zone_relationship()
    {
        $dutyZone = DutyZone::factory()->create();
        $this->pharmacy->update(['duty_zone_id' => $dutyZone->id]);

        $this->pharmacy->refresh();

        $this->assertInstanceOf(DutyZone::class, $this->pharmacy->dutyZone);
        $this->assertEquals($dutyZone->id, $this->pharmacy->dutyZone->id);
    }

    /** @test */
    public function it_has_wallet_relationship()
    {
        $wallet = Wallet::factory()->create([
            'walletable_type' => Pharmacy::class,
            'walletable_id' => $this->pharmacy->id,
        ]);

        $this->assertInstanceOf(Wallet::class, $this->pharmacy->wallet);
        $this->assertEquals($wallet->id, $this->pharmacy->wallet->id);
    }

    /** @test */
    public function is_approved_returns_true_for_approved_pharmacy()
    {
        $this->assertTrue($this->pharmacy->isApproved());
    }

    /** @test */
    public function is_approved_returns_false_for_pending_pharmacy()
    {
        $pending = Pharmacy::factory()->create(['status' => 'pending']);

        $this->assertFalse($pending->isApproved());
    }

    /** @test */
    public function scope_approved_returns_only_approved_pharmacies()
    {
        Pharmacy::factory()->create(['status' => 'pending']);
        Pharmacy::factory()->create(['status' => 'rejected']);

        $approved = Pharmacy::approved()->get();

        $this->assertEquals(1, $approved->count());
        $this->assertEquals('approved', $approved->first()->status);
    }

    /** @test */
    public function scope_pending_returns_only_pending_pharmacies()
    {
        Pharmacy::factory()->create(['status' => 'pending']);
        Pharmacy::factory()->create(['status' => 'rejected']);

        $pending = Pharmacy::pending()->get();

        $this->assertEquals(1, $pending->count());
        $this->assertEquals('pending', $pending->first()->status);
    }

    /** @test */
    public function scope_near_location_finds_nearby_pharmacies()
    {
        // Create a pharmacy very close
        $nearbyPharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
            'latitude' => 5.3601,
            'longitude' => -4.0084,
        ]);

        // Create a pharmacy far away
        Pharmacy::factory()->create([
            'status' => 'approved',
            'latitude' => 10.0000,
            'longitude' => -5.0000,
        ]);

        $nearby = Pharmacy::approved()
            ->nearLocation(5.3600, -4.0083, 5)
            ->get();

        // Should find the original pharmacy and the nearby one
        $this->assertGreaterThanOrEqual(2, $nearby->count());
    }

    /** @test */
    public function scope_near_location_rejects_invalid_coordinates()
    {
        $result = Pharmacy::nearLocation(100, -4.0083)->get(); // Invalid latitude

        $this->assertEquals(0, $result->count());
    }

    /** @test */
    public function it_soft_deletes()
    {
        $this->pharmacy->delete();

        $this->assertSoftDeleted($this->pharmacy);
        $this->assertNull(Pharmacy::find($this->pharmacy->id));
        $this->assertNotNull(Pharmacy::withTrashed()->find($this->pharmacy->id));
    }

    /** @test */
    public function it_casts_coordinates_to_float()
    {
        $this->assertIsFloat($this->pharmacy->latitude);
        $this->assertIsFloat($this->pharmacy->longitude);
    }

    /** @test */
    public function it_casts_commission_rates_to_decimal()
    {
        $pharmacy = Pharmacy::factory()->create([
            'commission_rate_platform' => 0.1234,
            'commission_rate_pharmacy' => 0.5678,
        ]);

        $this->assertEquals('0.1234', $pharmacy->commission_rate_platform);
        $this->assertEquals('0.5678', $pharmacy->commission_rate_pharmacy);
    }

    /** @test */
    public function it_has_fillable_attributes()
    {
        $pharmacy = new Pharmacy();
        
        $this->assertContains('name', $pharmacy->getFillable());
        $this->assertContains('phone', $pharmacy->getFillable());
        $this->assertContains('address', $pharmacy->getFillable());
        $this->assertContains('city', $pharmacy->getFillable());
        $this->assertContains('status', $pharmacy->getFillable());
        $this->assertContains('latitude', $pharmacy->getFillable());
        $this->assertContains('longitude', $pharmacy->getFillable());
    }

    /** @test */
    public function it_casts_approved_at_to_datetime()
    {
        $pharmacy = Pharmacy::factory()->create([
            'approved_at' => now(),
        ]);

        $this->assertInstanceOf(\Carbon\Carbon::class, $pharmacy->approved_at);
    }

    /** @test */
    public function it_casts_is_featured_to_boolean()
    {
        $pharmacy = Pharmacy::factory()->create([
            'is_featured' => 1,
        ]);

        $this->assertIsBool($pharmacy->is_featured);
        $this->assertTrue($pharmacy->is_featured);
    }

    /** @test */
    public function it_stores_rejection_reason()
    {
        $pharmacy = Pharmacy::factory()->create([
            'status' => 'rejected',
            'rejection_reason' => 'Invalid license',
        ]);

        $this->assertEquals('rejected', $pharmacy->status);
        $this->assertEquals('Invalid license', $pharmacy->rejection_reason);
    }

    /** @test */
    public function it_stores_withdrawal_settings()
    {
        $pharmacy = Pharmacy::factory()->create([
            'withdrawal_threshold' => 50000,
            'auto_withdraw_enabled' => true,
        ]);

        $this->assertEquals(50000, $pharmacy->withdrawal_threshold);
        $this->assertTrue($pharmacy->auto_withdraw_enabled);
    }

    /** @test */
    public function pivot_table_stores_user_role()
    {
        $user = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy->users()->attach($user->id, ['role' => 'owner']);

        $attachedUser = $this->pharmacy->users()->first();
        $this->assertEquals('owner', $attachedUser->pivot->role);
    }
}
