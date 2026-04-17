<?php

namespace Tests\Unit\Models;

use App\Models\CustomerAddress;
use Tests\TestCase;

class CustomerAddressTest extends TestCase
{
    public function test_fillable_fields(): void
    {
        $model = new CustomerAddress();
        $fillable = $model->getFillable();
        $this->assertContains('user_id', $fillable);
        $this->assertContains('label', $fillable);
        $this->assertContains('address', $fillable);
        $this->assertContains('city', $fillable);
        $this->assertContains('latitude', $fillable);
        $this->assertContains('longitude', $fillable);
        $this->assertContains('is_default', $fillable);
    }

    public function test_casts(): void
    {
        $model = new CustomerAddress();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('is_default', $casts);
    }

    public function test_has_user_relationship(): void
    {
        $model = new CustomerAddress();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->user());
    }

    public function test_full_address_accessor(): void
    {
        $model = new CustomerAddress();
        $model->address = '123 Main St';
        $model->city = 'Abidjan';
        $this->assertNotNull($model->full_address);
    }

    public function test_has_coordinates_accessor(): void
    {
        $model = new CustomerAddress();
        $model->latitude = null;
        $model->longitude = null;
        $this->assertFalse($model->has_coordinates);

        $model->latitude = 5.3;
        $model->longitude = -4.0;
        $this->assertTrue($model->has_coordinates);
    }
}
