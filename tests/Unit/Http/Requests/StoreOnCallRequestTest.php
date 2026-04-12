<?php

namespace Tests\Unit\Http\Requests;

use App\Http\Requests\Api\Pharmacy\StoreOnCallRequest;
use Illuminate\Support\Facades\Validator;
use Tests\TestCase;

class StoreOnCallRequestTest extends TestCase
{
    private function validate(array $data): \Illuminate\Validation\Validator
    {
        $request = new StoreOnCallRequest();
        return Validator::make($data, $request->rules());
    }

    public function test_authorize_returns_true(): void
    {
        $request = new StoreOnCallRequest();
        $this->assertTrue($request->authorize());
    }

    public function test_valid_data_passes(): void
    {
        $data = [
            'start_at' => now()->addHour()->toDateTimeString(),
            'end_at' => now()->addHours(9)->toDateTimeString(),
            'type' => 'night',
        ];

        $validator = $this->validate($data);
        $this->assertFalse($validator->fails());
    }

    public function test_start_at_required(): void
    {
        $validator = $this->validate([
            'end_at' => now()->addHours(9)->toDateTimeString(),
            'type' => 'night',
        ]);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('start_at', $validator->errors()->toArray());
    }

    public function test_end_at_required(): void
    {
        $validator = $this->validate([
            'start_at' => now()->addHour()->toDateTimeString(),
            'type' => 'night',
        ]);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('end_at', $validator->errors()->toArray());
    }

    public function test_type_required(): void
    {
        $validator = $this->validate([
            'start_at' => now()->addHour()->toDateTimeString(),
            'end_at' => now()->addHours(9)->toDateTimeString(),
        ]);
        $this->assertTrue($validator->fails());
        $this->assertArrayHasKey('type', $validator->errors()->toArray());
    }

    public function test_type_must_be_valid(): void
    {
        $validator = $this->validate([
            'start_at' => now()->addHour()->toDateTimeString(),
            'end_at' => now()->addHours(9)->toDateTimeString(),
            'type' => 'invalid_type',
        ]);
        $this->assertTrue($validator->fails());
    }

    public function test_all_valid_types(): void
    {
        foreach (['night', 'weekend', 'holiday', 'emergency'] as $type) {
            $validator = $this->validate([
                'start_at' => now()->addHour()->toDateTimeString(),
                'end_at' => now()->addHours(9)->toDateTimeString(),
                'type' => $type,
            ]);
            $this->assertFalse($validator->fails(), "Type '{$type}' should be valid");
        }
    }

    public function test_end_at_must_be_after_start_at(): void
    {
        $validator = $this->validate([
            'start_at' => now()->addHours(9)->toDateTimeString(),
            'end_at' => now()->addHour()->toDateTimeString(),
            'type' => 'night',
        ]);
        $this->assertTrue($validator->fails());
    }

    public function test_custom_messages_are_defined(): void
    {
        $request = new StoreOnCallRequest();
        $messages = $request->messages();

        $this->assertArrayHasKey('start_at.required', $messages);
        $this->assertArrayHasKey('end_at.required', $messages);
        $this->assertArrayHasKey('type.required', $messages);
        $this->assertArrayHasKey('type.in', $messages);
    }
}
