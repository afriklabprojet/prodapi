<?php

namespace Tests\Unit\Models;

use App\Models\Pharmacy;
use Tests\TestCase;

class PharmacyModelTest extends TestCase
{
    public function test_fillable_attributes(): void
    {
        $pharmacy = new Pharmacy();
        $fillable = $pharmacy->getFillable();
        $this->assertContains('name', $fillable);
        $this->assertContains('phone', $fillable);
        $this->assertContains('email', $fillable);
        $this->assertContains('address', $fillable);
        $this->assertContains('city', $fillable);
        $this->assertContains('status', $fillable);
        $this->assertContains('is_active', $fillable);
        $this->assertContains('is_open', $fillable);
        $this->assertContains('latitude', $fillable);
        $this->assertContains('longitude', $fillable);
    }

    public function test_casts(): void
    {
        $pharmacy = new Pharmacy();
        $casts = $pharmacy->getCasts();
        $this->assertSame('float', $casts['latitude']);
        $this->assertSame('float', $casts['longitude']);
        $this->assertSame('boolean', $casts['is_active']);
        $this->assertSame('boolean', $casts['is_featured']);
        $this->assertSame('boolean', $casts['is_open']);
        $this->assertSame('boolean', $casts['auto_withdraw_enabled']);
        $this->assertSame('datetime', $casts['approved_at']);
        $this->assertSame('decimal:4', $casts['commission_rate_platform']);
    }

    public function test_guarded_prevents_withdrawal_pin_mass_assign(): void
    {
        $pharmacy = new Pharmacy();
        $this->assertContains('withdrawal_pin', $pharmacy->getGuarded());
    }

    public function test_wallet_relationship(): void
    {
        $pharmacy = new Pharmacy();
        $relation = $pharmacy->wallet();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\MorphOne::class, $relation);
    }

    public function test_orders_relationship(): void
    {
        $pharmacy = new Pharmacy();
        $relation = $pharmacy->orders();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\HasMany::class, $relation);
    }

    public function test_users_relationship(): void
    {
        $pharmacy = new Pharmacy();
        $relation = $pharmacy->users();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsToMany::class, $relation);
    }

    public function test_duty_zone_relationship(): void
    {
        $pharmacy = new Pharmacy();
        $relation = $pharmacy->dutyZone();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $relation);
    }

    public function test_uses_soft_deletes(): void
    {
        $pharmacy = new Pharmacy();
        $this->assertContains('Illuminate\Database\Eloquent\SoftDeletes', class_uses_recursive($pharmacy));
    }
}
