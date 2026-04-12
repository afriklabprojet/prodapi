<?php

namespace Tests\Unit\Http\Resources;

use App\Http\Resources\OnCallResource;
use Illuminate\Http\Request;
use Tests\TestCase;

class OnCallResourceTest extends TestCase
{
    public function test_it_transforms_to_array(): void
    {
        $data = (object) [
            'id' => 1,
            'pharmacy_id' => 10,
            'duty_zone_id' => 5,
            'start_at' => now(),
            'end_at' => now()->addHours(8),
            'type' => 'night',
            'is_active' => 1,
            'created_at' => now(),
        ];

        $resource = new OnCallResource($data);
        $result = $resource->toArray(Request::create('/'));

        $this->assertEquals(1, $result['id']);
        $this->assertEquals(10, $result['pharmacy_id']);
        $this->assertEquals(5, $result['duty_zone_id']);
        $this->assertEquals('night', $result['type']);
        $this->assertTrue($result['is_active']);
        $this->assertIsString($result['start_at']);
        $this->assertIsString($result['end_at']);
        $this->assertIsString($result['created_at']);
    }

    public function test_it_handles_null_dates(): void
    {
        $data = (object) [
            'id' => 2,
            'pharmacy_id' => 11,
            'duty_zone_id' => null,
            'start_at' => null,
            'end_at' => null,
            'type' => 'day',
            'is_active' => 0,
            'created_at' => null,
        ];

        $resource = new OnCallResource($data);
        $result = $resource->toArray(Request::create('/'));

        $this->assertNull($result['start_at']);
        $this->assertNull($result['end_at']);
        $this->assertNull($result['created_at']);
        $this->assertFalse($result['is_active']);
    }
}
