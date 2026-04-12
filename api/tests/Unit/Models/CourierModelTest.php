<?php

namespace Tests\Unit\Models;

use App\Models\Courier;
use Tests\TestCase;

class CourierModelTest extends TestCase
{
    public function test_fillable_attributes(): void
    {
        $courier = new Courier();
        $fillable = $courier->getFillable();
        $this->assertContains('user_id', $fillable);
        $this->assertContains('name', $fillable);
        $this->assertContains('phone', $fillable);
        $this->assertContains('vehicle_type', $fillable);
        $this->assertContains('status', $fillable);
        $this->assertContains('rating', $fillable);
        $this->assertContains('latitude', $fillable);
        $this->assertContains('longitude', $fillable);
        $this->assertContains('kyc_status', $fillable);
    }

    public function test_casts(): void
    {
        $courier = new Courier();
        $casts = $courier->getCasts();
        $this->assertSame('float', $casts['latitude']);
        $this->assertSame('float', $casts['longitude']);
        $this->assertSame('decimal:1', $casts['rating']);
        $this->assertSame('integer', $casts['completed_deliveries']);
        $this->assertSame('datetime', $casts['last_location_update']);
        $this->assertSame('datetime', $casts['kyc_verified_at']);
    }

    public function test_user_relationship(): void
    {
        $courier = new Courier();
        $relation = $courier->user();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $relation);
    }

    public function test_deliveries_relationship(): void
    {
        $courier = new Courier();
        $relation = $courier->deliveries();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\HasMany::class, $relation);
    }

    public function test_wallet_relationship(): void
    {
        $courier = new Courier();
        $relation = $courier->wallet();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\MorphOne::class, $relation);
    }

    public function test_commission_lines_relationship(): void
    {
        $courier = new Courier();
        $relation = $courier->commissionLines();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\MorphMany::class, $relation);
    }

    public function test_uses_soft_deletes(): void
    {
        $courier = new Courier();
        $this->assertContains('Illuminate\Database\Eloquent\SoftDeletes', class_uses_recursive($courier));
    }
}
