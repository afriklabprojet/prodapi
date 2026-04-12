<?php

namespace Tests\Unit\Models;

use App\Models\DutyZone;
use App\Models\Pharmacy;
use App\Models\PharmacyOnCall;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class PharmacyOnCallTest extends TestCase
{
    use RefreshDatabase;

    private Pharmacy $pharmacy;
    private DutyZone $dutyZone;

    protected function setUp(): void
    {
        parent::setUp();
        $this->pharmacy = Pharmacy::factory()->create();
        $this->dutyZone = DutyZone::factory()->create();
    }

    #[Test]
    public function it_has_fillable_attributes(): void
    {
        $model = new PharmacyOnCall();
        $fillable = $model->getFillable();

        $this->assertContains('pharmacy_id', $fillable);
        $this->assertContains('duty_zone_id', $fillable);
        $this->assertContains('start_at', $fillable);
        $this->assertContains('end_at', $fillable);
        $this->assertContains('type', $fillable);
        $this->assertContains('is_active', $fillable);
    }

    #[Test]
    public function it_casts_start_at_as_datetime(): void
    {
        $model = new PharmacyOnCall();
        $casts = $model->getCasts();

        $this->assertSame('datetime', $casts['start_at']);
    }

    #[Test]
    public function it_casts_end_at_as_datetime(): void
    {
        $model = new PharmacyOnCall();
        $casts = $model->getCasts();

        $this->assertSame('datetime', $casts['end_at']);
    }

    #[Test]
    public function it_casts_is_active_as_boolean(): void
    {
        $model = new PharmacyOnCall();
        $casts = $model->getCasts();

        $this->assertSame('boolean', $casts['is_active']);
    }

    #[Test]
    public function it_has_pharmacy_relationship(): void
    {
        $model = new PharmacyOnCall();
        $relation = $model->pharmacy();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_has_duty_zone_relationship(): void
    {
        $model = new PharmacyOnCall();
        $relation = $model->dutyZone();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_can_be_created_with_factory(): void
    {
        $onCall = PharmacyOnCall::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'duty_zone_id' => $this->dutyZone->id,
        ]);

        $this->assertDatabaseHas('pharmacy_on_calls', ['id' => $onCall->id]);
    }

    #[Test]
    public function it_can_access_pharmacy_through_relationship(): void
    {
        $onCall = PharmacyOnCall::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'duty_zone_id' => $this->dutyZone->id,
        ]);

        $this->assertEquals($this->pharmacy->id, $onCall->pharmacy->id);
    }

    #[Test]
    public function it_can_access_duty_zone_through_relationship(): void
    {
        $onCall = PharmacyOnCall::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'duty_zone_id' => $this->dutyZone->id,
        ]);

        $this->assertEquals($this->dutyZone->id, $onCall->dutyZone->id);
    }

    #[Test]
    public function it_can_be_scheduled_for_future(): void
    {
        $startAt = now()->addDays(5);
        $endAt = now()->addDays(6);

        $onCall = PharmacyOnCall::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'duty_zone_id' => $this->dutyZone->id,
            'start_at' => $startAt,
            'end_at' => $endAt,
            'is_active' => true,
        ]);

        $this->assertTrue($onCall->start_at->isFuture());
    }

    #[Test]
    public function it_can_be_deactivated(): void
    {
        $onCall = PharmacyOnCall::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'duty_zone_id' => $this->dutyZone->id,
            'is_active' => true,
        ]);

        $onCall->update(['is_active' => false]);
        $onCall->refresh();

        $this->assertFalse($onCall->is_active);
    }
}
