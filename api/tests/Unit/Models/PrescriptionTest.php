<?php

namespace Tests\Unit\Models;

use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Prescription;
use App\Models\PrescriptionDispensing;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class PrescriptionTest extends TestCase
{
    use RefreshDatabase;

    private User $customer;
    private Pharmacy $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();
        $this->customer = User::factory()->create(['role' => 'customer']);
        $this->pharmacy = Pharmacy::factory()->create();
    }

    #[Test]
    public function it_has_fillable_attributes(): void
    {
        $model = new Prescription();
        $fillable = $model->getFillable();

        $this->assertContains('customer_id', $fillable);
        $this->assertContains('pharmacy_id', $fillable);
        $this->assertContains('order_id', $fillable);
        $this->assertContains('images', $fillable);
        $this->assertContains('notes', $fillable);
        $this->assertContains('status', $fillable);
        $this->assertContains('source', $fillable);
        $this->assertContains('extracted_medications', $fillable);
        $this->assertContains('matched_products', $fillable);
        $this->assertContains('unmatched_medications', $fillable);
        $this->assertContains('ocr_confidence', $fillable);
        $this->assertContains('fulfillment_status', $fillable);
    }

    #[Test]
    public function it_casts_dates_correctly(): void
    {
        $model = new Prescription();
        $casts = $model->getCasts();

        $this->assertSame('datetime', $casts['validated_at']);
        $this->assertSame('datetime', $casts['analyzed_at']);
        $this->assertSame('datetime', $casts['first_dispensed_at']);
    }

    #[Test]
    public function it_casts_arrays_correctly(): void
    {
        $model = new Prescription();
        $casts = $model->getCasts();

        $this->assertSame('array', $casts['extracted_medications']);
        $this->assertSame('array', $casts['matched_products']);
        $this->assertSame('array', $casts['unmatched_medications']);
    }

    #[Test]
    public function it_has_customer_relationship(): void
    {
        $model = new Prescription();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->customer());
    }

    #[Test]
    public function it_has_order_relationship(): void
    {
        $model = new Prescription();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->order());
    }

    #[Test]
    public function it_has_validator_relationship(): void
    {
        $model = new Prescription();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->validator());
    }

    #[Test]
    public function it_has_dispensings_relationship(): void
    {
        $model = new Prescription();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\HasMany::class, $model->dispensings());
    }

    #[Test]
    public function it_identifies_checkout_source(): void
    {
        $prescription = Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_CHECKOUT,
            'status' => Prescription::STATUS_PENDING,
            'images' => ['test.jpg'],
        ]);

        $this->assertTrue($prescription->isFromCheckout());
    }

    #[Test]
    public function it_identifies_upload_source(): void
    {
        $prescription = Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_UPLOAD,
            'status' => Prescription::STATUS_PENDING,
            'images' => ['test.jpg'],
        ]);

        $this->assertFalse($prescription->isFromCheckout());
    }

    #[Test]
    public function it_checks_if_has_order(): void
    {
        $prescriptionWithoutOrder = Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_UPLOAD,
            'status' => Prescription::STATUS_PENDING,
            'images' => ['test.jpg'],
        ]);

        $this->assertFalse($prescriptionWithoutOrder->hasOrder());

        $order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $prescriptionWithOrder = Prescription::create([
            'customer_id' => $this->customer->id,
            'order_id' => $order->id,
            'source' => Prescription::SOURCE_CHECKOUT,
            'status' => Prescription::STATUS_PENDING,
            'images' => ['test.jpg'],
        ]);

        $this->assertTrue($prescriptionWithOrder->hasOrder());
    }

    #[Test]
    public function it_scopes_pending_prescriptions(): void
    {
        Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_UPLOAD,
            'status' => Prescription::STATUS_PENDING,
            'images' => ['test.jpg'],
        ]);

        Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_UPLOAD,
            'status' => Prescription::STATUS_VALIDATED,
            'images' => ['test.jpg'],
        ]);

        $pending = Prescription::pending()->get();
        $this->assertCount(1, $pending);
        $this->assertEquals(Prescription::STATUS_PENDING, $pending->first()->status);
    }

    #[Test]
    public function it_scopes_validated_prescriptions(): void
    {
        Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_UPLOAD,
            'status' => Prescription::STATUS_PENDING,
            'images' => ['test.jpg'],
        ]);

        Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_UPLOAD,
            'status' => Prescription::STATUS_VALIDATED,
            'images' => ['test.jpg'],
        ]);

        $validated = Prescription::validated()->get();
        $this->assertCount(1, $validated);
        $this->assertEquals(Prescription::STATUS_VALIDATED, $validated->first()->status);
    }

    #[Test]
    public function it_scopes_from_checkout(): void
    {
        Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_UPLOAD,
            'status' => Prescription::STATUS_PENDING,
            'images' => ['test.jpg'],
        ]);

        Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_CHECKOUT,
            'status' => Prescription::STATUS_PENDING,
            'images' => ['test.jpg'],
        ]);

        $fromCheckout = Prescription::fromCheckout()->get();
        $this->assertCount(1, $fromCheckout);
        $this->assertEquals(Prescription::SOURCE_CHECKOUT, $fromCheckout->first()->source);
    }

    #[Test]
    public function it_checks_if_pending(): void
    {
        $prescription = Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_UPLOAD,
            'status' => Prescription::STATUS_PENDING,
            'images' => ['test.jpg'],
        ]);

        $this->assertTrue($prescription->isPending());
        $this->assertFalse($prescription->isValidated());
    }

    #[Test]
    public function it_checks_if_validated(): void
    {
        $prescription = Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_UPLOAD,
            'status' => Prescription::STATUS_VALIDATED,
            'images' => ['test.jpg'],
        ]);

        $this->assertFalse($prescription->isPending());
        $this->assertTrue($prescription->isValidated());
    }

    #[Test]
    public function it_checks_if_fully_dispensed(): void
    {
        $prescription = Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_UPLOAD,
            'status' => Prescription::STATUS_VALIDATED,
            'fulfillment_status' => 'full',
            'images' => ['test.jpg'],
        ]);

        $this->assertTrue($prescription->isFullyDispensed());
        $this->assertFalse($prescription->isPartiallyDispensed());
    }

    #[Test]
    public function it_checks_if_partially_dispensed(): void
    {
        $prescription = Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_UPLOAD,
            'status' => Prescription::STATUS_VALIDATED,
            'fulfillment_status' => 'partial',
            'images' => ['test.jpg'],
        ]);

        $this->assertFalse($prescription->isFullyDispensed());
        $this->assertTrue($prescription->isPartiallyDispensed());
    }

    #[Test]
    public function it_recalculates_fulfillment_with_no_dispensings(): void
    {
        $prescription = Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_UPLOAD,
            'status' => Prescription::STATUS_VALIDATED,
            'images' => ['test.jpg'],
        ]);

        $prescription->recalculateFulfillment();
        $prescription->refresh();

        $this->assertEquals('none', $prescription->fulfillment_status);
        $this->assertEquals(0, $prescription->dispensing_count);
    }

    #[Test]
    public function it_recalculates_fulfillment_with_partial_dispensings(): void
    {
        $prescription = Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_UPLOAD,
            'status' => Prescription::STATUS_VALIDATED,
            'extracted_medications' => [
                ['name' => 'Doliprane'],
                ['name' => 'Ibuprofène'],
            ],
            'images' => ['test.jpg'],
        ]);

        PrescriptionDispensing::create([
            'prescription_id' => $prescription->id,
            'pharmacy_id' => $this->pharmacy->id,
            'medication_name' => 'Doliprane',
            'quantity_dispensed' => 1,
            'dispensed_at' => now(),
            'dispensed_by' => $this->customer->id,
        ]);

        $prescription->recalculateFulfillment();
        $prescription->refresh();

        $this->assertEquals('partial', $prescription->fulfillment_status);
        $this->assertEquals(1, $prescription->dispensing_count);
    }

    #[Test]
    public function it_recalculates_fulfillment_with_full_dispensings(): void
    {
        $prescription = Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_UPLOAD,
            'status' => Prescription::STATUS_VALIDATED,
            'extracted_medications' => [
                ['name' => 'Doliprane'],
                ['name' => 'Ibuprofène'],
            ],
            'images' => ['test.jpg'],
        ]);

        PrescriptionDispensing::create([
            'prescription_id' => $prescription->id,
            'pharmacy_id' => $this->pharmacy->id,
            'medication_name' => 'Doliprane',
            'quantity_dispensed' => 1,
            'dispensed_at' => now(),
            'dispensed_by' => $this->customer->id,
        ]);

        PrescriptionDispensing::create([
            'prescription_id' => $prescription->id,
            'pharmacy_id' => $this->pharmacy->id,
            'medication_name' => 'Ibuprofène',
            'quantity_dispensed' => 1,
            'dispensed_at' => now(),
            'dispensed_by' => $this->customer->id,
        ]);

        $prescription->recalculateFulfillment();
        $prescription->refresh();

        $this->assertEquals('full', $prescription->fulfillment_status);
        $this->assertEquals(2, $prescription->dispensing_count);
    }

    #[Test]
    public function it_gets_raw_images(): void
    {
        $images = ['prescriptions/img1.jpg', 'prescriptions/img2.jpg'];
        
        $prescription = Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_UPLOAD,
            'status' => Prescription::STATUS_PENDING,
            'images' => $images,
        ]);

        $rawImages = $prescription->getRawImages();
        $this->assertEquals($images, $rawImages);
    }

    #[Test]
    public function it_transforms_images_to_urls(): void
    {
        $prescription = Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_UPLOAD,
            'status' => Prescription::STATUS_PENDING,
            'images' => ['prescriptions/img1.jpg'],
        ]);

        $prescription->refresh();
        $images = $prescription->images;
        
        $this->assertNotEmpty($images);
        $this->assertStringContainsString('/api/documents/', $images[0]);
    }

    #[Test]
    public function it_keeps_full_urls_unchanged(): void
    {
        $fullUrl = 'https://example.com/image.jpg';
        
        $prescription = Prescription::create([
            'customer_id' => $this->customer->id,
            'source' => Prescription::SOURCE_UPLOAD,
            'status' => Prescription::STATUS_PENDING,
            'images' => [$fullUrl],
        ]);

        $prescription->refresh();
        $images = $prescription->images;
        
        $this->assertEquals($fullUrl, $images[0]);
    }
}
