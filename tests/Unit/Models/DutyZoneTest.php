<?php

namespace Tests\Unit\Models;

use App\Models\DutyZone;
use App\Models\Pharmacy;
use App\Models\PharmacyOnCall;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class DutyZoneTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_has_fillable_attributes(): void
    {
        $model = new DutyZone();
        $fillable = $model->getFillable();

        $this->assertContains('name', $fillable);
        $this->assertContains('city', $fillable);
        $this->assertContains('description', $fillable);
        $this->assertContains('is_active', $fillable);
        $this->assertContains('latitude', $fillable);
        $this->assertContains('longitude', $fillable);
        $this->assertContains('radius', $fillable);
    }

    #[Test]
    public function it_casts_latitude_as_decimal(): void
    {
        $model = new DutyZone();
        $casts = $model->getCasts();

        $this->assertSame('decimal:8', $casts['latitude']);
    }

    #[Test]
    public function it_casts_longitude_as_decimal(): void
    {
        $model = new DutyZone();
        $casts = $model->getCasts();

        $this->assertSame('decimal:8', $casts['longitude']);
    }

    #[Test]
    public function it_casts_radius_as_decimal(): void
    {
        $model = new DutyZone();
        $casts = $model->getCasts();

        $this->assertSame('decimal:2', $casts['radius']);
    }

    #[Test]
    public function it_casts_is_active_as_boolean(): void
    {
        $model = new DutyZone();
        $casts = $model->getCasts();

        $this->assertSame('boolean', $casts['is_active']);
    }

    #[Test]
    public function it_has_pharmacies_relationship(): void
    {
        $model = new DutyZone();
        $relation = $model->pharmacies();

        $this->assertInstanceOf(HasMany::class, $relation);
    }

    #[Test]
    public function it_has_on_calls_relationship(): void
    {
        $model = new DutyZone();
        $relation = $model->onCalls();

        $this->assertInstanceOf(HasMany::class, $relation);
    }

    #[Test]
    public function it_can_be_created_with_factory(): void
    {
        $zone = DutyZone::factory()->create();

        $this->assertDatabaseHas('duty_zones', ['id' => $zone->id]);
    }

    #[Test]
    public function it_can_have_associated_pharmacies(): void
    {
        $zone = DutyZone::factory()->create();
        $pharmacy = Pharmacy::factory()->create(['duty_zone_id' => $zone->id]);

        $this->assertTrue($zone->pharmacies->contains($pharmacy));
    }

    #[Test]
    public function it_can_have_associated_on_calls(): void
    {
        $zone = DutyZone::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        
        $onCall = PharmacyOnCall::factory()->create([
            'duty_zone_id' => $zone->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $this->assertTrue($zone->onCalls->contains($onCall));
    }
}
