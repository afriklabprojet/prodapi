<?php

namespace Tests\Unit\Models;

use App\Models\Payment;
use Tests\TestCase;

class PaymentTest extends TestCase
{
    public function test_fillable_fields(): void
    {
        $model = new Payment();
        $fillable = $model->getFillable();
        $this->assertContains('order_id', $fillable);
        $this->assertContains('provider', $fillable);
        $this->assertContains('reference', $fillable);
        $this->assertContains('amount', $fillable);
        $this->assertContains('status', $fillable);
    }

    public function test_casts(): void
    {
        $model = new Payment();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('confirmed_at', $casts);
    }

    public function test_has_order_relationship(): void
    {
        $model = new Payment();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->order());
    }
}
