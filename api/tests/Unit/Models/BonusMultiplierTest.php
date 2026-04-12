<?php

namespace Tests\Unit\Models;

use App\Models\BonusMultiplier;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class BonusMultiplierTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_has_fillable_attributes(): void
    {
        $model = new BonusMultiplier();
        $fillable = $model->getFillable();

        $this->assertContains('name', $fillable);
        $this->assertContains('description', $fillable);
        $this->assertContains('type', $fillable);
        $this->assertContains('multiplier', $fillable);
        $this->assertContains('flat_bonus', $fillable);
        $this->assertContains('conditions', $fillable);
        $this->assertContains('is_active', $fillable);
        $this->assertContains('starts_at', $fillable);
        $this->assertContains('ends_at', $fillable);
    }

    #[Test]
    public function it_casts_multiplier_as_decimal(): void
    {
        $model = new BonusMultiplier();
        $casts = $model->getCasts();

        $this->assertSame('decimal:2', $casts['multiplier']);
    }

    #[Test]
    public function it_casts_flat_bonus_as_integer(): void
    {
        $model = new BonusMultiplier();
        $casts = $model->getCasts();

        $this->assertSame('integer', $casts['flat_bonus']);
    }

    #[Test]
    public function it_casts_conditions_as_array(): void
    {
        $model = new BonusMultiplier();
        $casts = $model->getCasts();

        $this->assertSame('array', $casts['conditions']);
    }

    #[Test]
    public function it_casts_is_active_as_boolean(): void
    {
        $model = new BonusMultiplier();
        $casts = $model->getCasts();

        $this->assertSame('boolean', $casts['is_active']);
    }

    #[Test]
    public function it_casts_timestamps_as_datetime(): void
    {
        $model = new BonusMultiplier();
        $casts = $model->getCasts();

        $this->assertSame('datetime', $casts['starts_at']);
        $this->assertSame('datetime', $casts['ends_at']);
    }

    #[Test]
    public function it_can_be_created_with_factory(): void
    {
        $bonus = BonusMultiplier::factory()->create();

        $this->assertDatabaseHas('bonus_multipliers', ['id' => $bonus->id]);
    }

    #[Test]
    public function it_can_store_conditions_as_json(): void
    {
        $conditions = ['min_deliveries' => 5, 'time_range' => ['18:00', '22:00']];
        
        $bonus = BonusMultiplier::factory()->create([
            'conditions' => $conditions,
        ]);

        $bonus->refresh();
        $this->assertEquals($conditions, $bonus->conditions);
    }

    #[Test]
    public function it_can_be_inactive(): void
    {
        $bonus = BonusMultiplier::factory()->inactive()->create();

        $this->assertFalse($bonus->is_active);
    }

    #[Test]
    public function it_can_be_expired(): void
    {
        $bonus = BonusMultiplier::factory()->expired()->create();

        $this->assertTrue($bonus->ends_at->isPast());
    }
}
