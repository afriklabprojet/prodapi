<?php

namespace Tests\Unit\Models;

use App\Models\Challenge;
use App\Models\Courier;
use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class ChallengeTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_has_fillable_attributes(): void
    {
        $model = new Challenge();
        $fillable = $model->getFillable();

        $this->assertContains('title', $fillable);
        $this->assertContains('description', $fillable);
        $this->assertContains('type', $fillable);
        $this->assertContains('metric', $fillable);
        $this->assertContains('target_value', $fillable);
        $this->assertContains('reward_amount', $fillable);
        $this->assertContains('icon', $fillable);
        $this->assertContains('color', $fillable);
        $this->assertContains('is_active', $fillable);
        $this->assertContains('starts_at', $fillable);
        $this->assertContains('ends_at', $fillable);
    }

    #[Test]
    public function it_casts_target_value_as_integer(): void
    {
        $model = new Challenge();
        $casts = $model->getCasts();

        $this->assertSame('integer', $casts['target_value']);
    }

    #[Test]
    public function it_casts_reward_amount_as_integer(): void
    {
        $model = new Challenge();
        $casts = $model->getCasts();

        $this->assertSame('integer', $casts['reward_amount']);
    }

    #[Test]
    public function it_casts_is_active_as_boolean(): void
    {
        $model = new Challenge();
        $casts = $model->getCasts();

        $this->assertSame('boolean', $casts['is_active']);
    }

    #[Test]
    public function it_casts_timestamps_as_datetime(): void
    {
        $model = new Challenge();
        $casts = $model->getCasts();

        $this->assertSame('datetime', $casts['starts_at']);
        $this->assertSame('datetime', $casts['ends_at']);
    }

    #[Test]
    public function it_has_couriers_relationship(): void
    {
        $model = new Challenge();
        $relation = $model->couriers();

        $this->assertInstanceOf(BelongsToMany::class, $relation);
    }

    #[Test]
    public function it_can_attach_couriers_with_pivot_data(): void
    {
        $challenge = Challenge::factory()->create();
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);

        $challenge->couriers()->attach($courier->id, [
            'current_progress' => 5,
            'status' => 'in_progress',
            'started_at' => now(),
        ]);

        $this->assertDatabaseHas('courier_challenges', [
            'challenge_id' => $challenge->id,
            'courier_id' => $courier->id,
            'current_progress' => 5,
            'status' => 'in_progress',
        ]);
    }

    #[Test]
    public function it_can_be_created_with_factory(): void
    {
        $challenge = Challenge::factory()->create();

        $this->assertDatabaseHas('challenges', ['id' => $challenge->id]);
    }

    #[Test]
    public function it_can_be_inactive(): void
    {
        $challenge = Challenge::factory()->inactive()->create();

        $this->assertFalse($challenge->is_active);
    }

    #[Test]
    public function it_can_be_future(): void
    {
        $challenge = Challenge::factory()->future()->create();

        $this->assertTrue($challenge->starts_at->isFuture());
    }

    #[Test]
    public function it_can_be_expired(): void
    {
        $challenge = Challenge::factory()->expired()->create();

        $this->assertTrue($challenge->ends_at->isPast());
    }
}
