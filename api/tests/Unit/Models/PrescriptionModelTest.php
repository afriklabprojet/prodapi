<?php

namespace Tests\Unit\Models;

use App\Models\Prescription;
use Tests\TestCase;

class PrescriptionModelTest extends TestCase
{
    public function test_fillable_fields(): void
    {
        $model = new Prescription();
        $fillable = $model->getFillable();
        $this->assertContains('customer_id', $fillable);
        $this->assertContains('pharmacy_id', $fillable);
        $this->assertContains('status', $fillable);
        $this->assertContains('notes', $fillable);
        $this->assertContains('extracted_medications', $fillable);
        $this->assertContains('matched_products', $fillable);
        $this->assertContains('ocr_confidence', $fillable);
    }

    public function test_casts(): void
    {
        $model = new Prescription();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('validated_at', $casts);
        $this->assertArrayHasKey('extracted_medications', $casts);
        $this->assertArrayHasKey('matched_products', $casts);
        $this->assertArrayHasKey('unmatched_medications', $casts);
    }
}
