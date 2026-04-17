<?php

namespace Tests\Unit\Http\Resources;

use App\Http\Resources\PrescriptionResource;
use App\Models\Prescription;
use Illuminate\Http\Request;
use Tests\TestCase;

class PrescriptionResourceTest extends TestCase
{
    public function test_it_transforms_basic_fields(): void
    {
        $user = new \App\Models\User();
        $user->id = 99;
        $user->role = 'admin';

        $data = (new Prescription())->forceFill([
            'id' => 1,
            'status' => 'pending',
            'source' => 'upload',
            'notes' => 'Test notes',
            'images' => ['/prescriptions/test.jpg'],
            'quote_amount' => 15000,
            'pharmacy_notes' => 'OK',
            'admin_notes' => 'Validated',
            'validated_by' => $user->id,
            'customer_id' => 1,
            'created_at' => now(),
            'validated_at' => now(),
            'analysis_status' => 'completed',
            'analysis_error' => null,
            'analyzed_at' => now(),
            'ocr_confidence' => 0.95,
            'ocr_raw_text' => 'Sample text',
            'extracted_medications' => ['Paracetamol'],
            'matched_products' => [],
            'unmatched_medications' => [],
            'fulfillment_status' => 'none',
            'dispensing_count' => 0,
            'first_dispensed_at' => null,
            'image_hash' => 'abc123',
        ]);

        $resource = new PrescriptionResource($data);
        $request = Request::create('/');
        $request->setUserResolver(fn() => $user);
        $result = $resource->toArray($request);

        $this->assertEquals(1, $result['id']);
        $this->assertEquals('pending', $result['status']);
        $this->assertEquals('upload', $result['source']);
        $this->assertEquals(15000.0, $result['quote_amount']);
        $this->assertEquals(1, $result['customer_id']);
        $this->assertEquals(0.95, $result['ocr_confidence']);
        $this->assertEquals(0, $result['dispensing_count']);
    }

    public function test_null_quote_amount_returns_null(): void
    {
        $user = new \App\Models\User();
        $user->id = 99;
        $user->role = 'admin';

        $data = (new Prescription())->forceFill([
            'id' => 2,
            'status' => 'pending',
            'source' => 'scan',
            'notes' => null,
            'images' => [],
            'quote_amount' => null,
            'pharmacy_notes' => null,
            'admin_notes' => null,
            'validated_by' => null,
            'customer_id' => 1,
            'created_at' => now(),
            'validated_at' => null,
            'analysis_status' => null,
            'analysis_error' => null,
            'analyzed_at' => null,
            'ocr_confidence' => null,
            'ocr_raw_text' => null,
            'extracted_medications' => null,
            'matched_products' => null,
            'unmatched_medications' => null,
            'fulfillment_status' => null,
            'dispensing_count' => null,
            'first_dispensed_at' => null,
            'image_hash' => null,
        ]);

        $resource = new PrescriptionResource($data);
        $request = Request::create('/');
        $request->setUserResolver(fn() => $user);
        $result = $resource->toArray($request);

        $this->assertNull($result['quote_amount']);
        $this->assertNull($result['ocr_confidence']);
        $this->assertNull($result['validated_by']);
        $this->assertEquals('none', $result['fulfillment_status']);
    }
}
