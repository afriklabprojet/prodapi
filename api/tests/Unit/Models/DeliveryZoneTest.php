<?php

namespace Tests\Unit\Models;

use App\Models\DeliveryZone;
use App\Models\Pharmacy;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class DeliveryZoneTest extends TestCase
{
    use RefreshDatabase;

    private Pharmacy $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();
        $this->pharmacy = Pharmacy::factory()->create();
    }

    #[Test]
    public function it_has_fillable_attributes(): void
    {
        $model = new DeliveryZone();
        $fillable = $model->getFillable();

        $this->assertContains('pharmacy_id', $fillable);
        $this->assertContains('name', $fillable);
        $this->assertContains('polygon', $fillable);
        $this->assertContains('radius_km', $fillable);
        $this->assertContains('is_active', $fillable);
    }

    #[Test]
    public function it_casts_polygon_as_array(): void
    {
        $model = new DeliveryZone();
        $casts = $model->getCasts();

        $this->assertSame('array', $casts['polygon']);
    }

    #[Test]
    public function it_casts_radius_km_as_float(): void
    {
        $model = new DeliveryZone();
        $casts = $model->getCasts();

        $this->assertSame('float', $casts['radius_km']);
    }

    #[Test]
    public function it_casts_is_active_as_boolean(): void
    {
        $model = new DeliveryZone();
        $casts = $model->getCasts();

        $this->assertSame('boolean', $casts['is_active']);
    }

    #[Test]
    public function it_has_pharmacy_relationship(): void
    {
        $model = new DeliveryZone();
        $relation = $model->pharmacy();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_computes_points_count_attribute(): void
    {
        $zone = DeliveryZone::create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Zone Test',
            'polygon' => [
                ['lat' => 6.1, 'lng' => 1.2],
                ['lat' => 6.2, 'lng' => 1.3],
                ['lat' => 6.15, 'lng' => 1.4],
            ],
            'is_active' => true,
        ]);

        $this->assertEquals(3, $zone->points_count);
    }

    #[Test]
    public function it_returns_zero_points_for_empty_polygon(): void
    {
        $zone = DeliveryZone::create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Zone Vide',
            'polygon' => [],
            'is_active' => true,
        ]);

        $this->assertEquals(0, $zone->points_count);
    }

    #[Test]
    public function it_allows_points_when_zone_is_inactive(): void
    {
        $zone = DeliveryZone::create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Zone Inactive',
            'polygon' => [
                ['lat' => 6.1, 'lng' => 1.2],
                ['lat' => 6.2, 'lng' => 1.3],
                ['lat' => 6.15, 'lng' => 1.4],
            ],
            'is_active' => false,
        ]);

        // Point should be allowed when zone is inactive
        $this->assertTrue($zone->containsPoint(0, 0));
    }

    #[Test]
    public function it_allows_points_when_polygon_is_empty(): void
    {
        $zone = DeliveryZone::create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Zone Sans Polygone',
            'polygon' => [],
            'is_active' => true,
        ]);

        // Point should be allowed when polygon is empty
        $this->assertTrue($zone->containsPoint(6.15, 1.25));
    }

    #[Test]
    public function it_returns_true_when_no_zone_defined(): void
    {
        $result = DeliveryZone::isInDeliveryZone($this->pharmacy->id, 6.15, 1.25);

        $this->assertTrue($result);
    }

    #[Test]
    public function it_clears_cache_on_save(): void
    {
        Cache::shouldReceive('remember')
            ->andReturnNull();
        Cache::shouldReceive('forget')
            ->with("delivery_zone:{$this->pharmacy->id}")
            ->once();

        $zone = new DeliveryZone([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Zone Test',
            'polygon' => [['lat' => 6.1, 'lng' => 1.2]],
            'is_active' => true,
        ]);
        $zone->save();
    }

    #[Test]
    public function it_clears_cache_on_delete(): void
    {
        $zone = DeliveryZone::create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Zone to Delete',
            'polygon' => [['lat' => 6.1, 'lng' => 1.2]],
            'is_active' => true,
        ]);

        Cache::shouldReceive('forget')
            ->with("delivery_zone:{$this->pharmacy->id}")
            ->once();

        $zone->delete();
    }

    #[Test]
    public function it_detects_point_inside_polygon(): void
    {
        // Create a square polygon around Lomé center
        $zone = DeliveryZone::create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Lomé Zone',
            'polygon' => [
                ['lat' => 6.10, 'lng' => 1.10],
                ['lat' => 6.10, 'lng' => 1.30],
                ['lat' => 6.20, 'lng' => 1.30],
                ['lat' => 6.20, 'lng' => 1.10],
            ],
            'is_active' => true,
        ]);

        // Point inside the polygon
        $this->assertTrue($zone->containsPoint(6.15, 1.20));
    }

    #[Test]
    public function it_detects_point_outside_polygon(): void
    {
        // Create a square polygon around Lomé center
        $zone = DeliveryZone::create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Lomé Zone',
            'polygon' => [
                ['lat' => 6.10, 'lng' => 1.10],
                ['lat' => 6.10, 'lng' => 1.30],
                ['lat' => 6.20, 'lng' => 1.30],
                ['lat' => 6.20, 'lng' => 1.10],
            ],
            'is_active' => true,
        ]);

        // Point outside the polygon
        $this->assertFalse($zone->containsPoint(6.50, 1.50));
    }

    #[Test]
    public function it_checks_is_in_delivery_zone_with_active_zone(): void
    {
        // Clear cache for this pharmacy
        Cache::forget("delivery_zone:{$this->pharmacy->id}");

        $zone = DeliveryZone::create([
            'pharmacy_id' => $this->pharmacy->id,
            'name' => 'Active Zone',
            'polygon' => [
                ['lat' => 6.10, 'lng' => 1.10],
                ['lat' => 6.10, 'lng' => 1.30],
                ['lat' => 6.20, 'lng' => 1.30],
                ['lat' => 6.20, 'lng' => 1.10],
            ],
            'is_active' => true,
        ]);

        // Clear cache after creation
        Cache::forget("delivery_zone:{$this->pharmacy->id}");

        // Point inside
        $this->assertTrue(DeliveryZone::isInDeliveryZone($this->pharmacy->id, 6.15, 1.20));
        
        // Clear cache and check point outside
        Cache::forget("delivery_zone:{$this->pharmacy->id}");
        $this->assertFalse(DeliveryZone::isInDeliveryZone($this->pharmacy->id, 6.50, 1.50));
    }
}
