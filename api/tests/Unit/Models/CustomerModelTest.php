<?php

namespace Tests\Unit\Models;

use App\Models\Customer;
use Tests\TestCase;

class CustomerModelTest extends TestCase
{
    public function test_fillable_attributes(): void
    {
        $customer = new Customer();
        $this->assertContains('user_id', $customer->getFillable());
    }

    public function test_user_relationship(): void
    {
        $customer = new Customer();
        $relation = $customer->user();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $relation);
    }

    public function test_wallet_relationship(): void
    {
        $customer = new Customer();
        $relation = $customer->wallet();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\MorphOne::class, $relation);
    }
}
