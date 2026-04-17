<?php

namespace Tests\Unit\Models;

use App\Models\CommissionLine;
use Tests\TestCase;

class CommissionLineTest extends TestCase
{
    public function test_fillable_attributes(): void
    {
        $line = new CommissionLine();
        $fillable = $line->getFillable();
        $this->assertContains('commission_id', $fillable);
        $this->assertContains('actor_type', $fillable);
        $this->assertContains('actor_id', $fillable);
        $this->assertContains('rate', $fillable);
        $this->assertContains('amount', $fillable);
    }

    public function test_casts_rate_as_decimal(): void
    {
        $line = new CommissionLine();
        $casts = $line->getCasts();
        $this->assertSame('decimal:2', $casts['rate']);
    }

    public function test_casts_amount_as_decimal(): void
    {
        $line = new CommissionLine();
        $casts = $line->getCasts();
        $this->assertSame('decimal:2', $casts['amount']);
    }

    public function test_commission_relationship(): void
    {
        $line = new CommissionLine();
        $relation = $line->commission();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $relation);
    }

    public function test_actor_relationship(): void
    {
        $line = new CommissionLine();
        $relation = $line->actor();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\MorphTo::class, $relation);
    }
}
