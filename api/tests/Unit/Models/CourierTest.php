<?php

namespace Tests\Unit\Models;

use App\Models\Courier;
use App\Models\Delivery;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CourierTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $courier;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'courier']);
        $this->courier = Courier::factory()->create([
            'user_id' => $this->user->id,
            'status' => 'available',
            'latitude' => 5.3600,
            'longitude' => -4.0083,
        ]);
    }

    /** @test */
    public function it_belongs_to_a_user()
    {
        $this->assertInstanceOf(User::class, $this->courier->user);
        $this->assertEquals($this->user->id, $this->courier->user->id);
    }

    /** @test */
    public function it_has_many_deliveries()
    {
        Delivery::factory()->count(3)->create([
            'courier_id' => $this->courier->id,
        ]);

        $this->assertCount(3, $this->courier->deliveries);
    }

    /** @test */
    public function it_has_wallet_relationship()
    {
        $wallet = Wallet::factory()->create([
            'walletable_type' => Courier::class,
            'walletable_id' => $this->courier->id,
        ]);

        $this->assertInstanceOf(Wallet::class, $this->courier->wallet);
        $this->assertEquals($wallet->id, $this->courier->wallet->id);
    }

    /** @test */
    public function it_updates_location()
    {
        $this->courier->updateLocation(5.3700, -4.0100);

        $this->courier->refresh();

        $this->assertEquals(5.3700, $this->courier->latitude);
        $this->assertEquals(-4.0100, $this->courier->longitude);
    }

    /** @test */
    public function it_tracks_status()
    {
        $this->assertEquals('available', $this->courier->status);

        $this->courier->update(['status' => 'offline']);

        $this->assertEquals('offline', $this->courier->fresh()->status);
    }

    /** @test */
    public function it_tracks_is_available()
    {
        $this->courier->update(['status' => 'available']);
        $this->assertTrue($this->courier->fresh()->status === 'available');

        $this->courier->update(['status' => 'busy']);
        $this->assertFalse($this->courier->fresh()->status === 'available');
    }

    /** @test */
    public function it_has_fillable_attributes()
    {
        $courier = new Courier();
        
        $this->assertContains('user_id', $courier->getFillable());
        $this->assertContains('status', $courier->getFillable());
        $this->assertContains('latitude', $courier->getFillable());
        $this->assertContains('longitude', $courier->getFillable());
    }

    /** @test */
    public function it_soft_deletes()
    {
        $this->courier->delete();

        $this->assertSoftDeleted($this->courier);
        $this->assertNull(Courier::find($this->courier->id));
        $this->assertNotNull(Courier::withTrashed()->find($this->courier->id));
    }

    /** @test */
    public function scope_available_returns_available_couriers()
    {
        Courier::factory()->create([
            'user_id' => User::factory()->create(['role' => 'courier'])->id,
            'status' => 'offline',
        ]);

        $available = Courier::where('status', 'available')->get();

        $this->assertEquals(1, $available->count());
        $this->assertEquals('available', $available->first()->status);
    }

    /** @test */
    public function it_stores_vehicle_info()
    {
        $courier = Courier::factory()->create([
            'user_id' => User::factory()->create(['role' => 'courier'])->id,
            'vehicle_type' => 'motorcycle',
            'vehicle_number' => 'ABC-1234',
        ]);

        $this->assertEquals('motorcycle', $courier->vehicle_type);
        $this->assertEquals('ABC-1234', $courier->vehicle_number);
    }

    /** @test */
    public function it_counts_completed_deliveries()
    {
        Delivery::factory()->count(5)->create([
            'courier_id' => $this->courier->id,
            'status' => 'delivered',
        ]);

        Delivery::factory()->count(2)->create([
            'courier_id' => $this->courier->id,
            'status' => 'pending',
        ]);

        $completed = $this->courier->deliveries()
            ->where('status', 'delivered')
            ->count();

        $this->assertEquals(5, $completed);
    }

    /** @test */
    public function it_gets_active_deliveries()
    {
        Delivery::factory()->create([
            'courier_id' => $this->courier->id,
            'status' => 'assigned',
        ]);

        Delivery::factory()->create([
            'courier_id' => $this->courier->id,
            'status' => 'picked_up',
        ]);

        Delivery::factory()->create([
            'courier_id' => $this->courier->id,
            'status' => 'delivered',
        ]);

        $active = $this->courier->deliveries()
            ->whereIn('status', ['assigned', 'picked_up'])
            ->get();

        $this->assertCount(2, $active);
    }

    /** @test */
    public function it_casts_coordinates_correctly()
    {
        $this->assertIsFloat($this->courier->latitude);
        $this->assertIsFloat($this->courier->longitude);
    }
}
