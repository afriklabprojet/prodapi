<?php

namespace Tests\Unit\Models;

use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Prescription;
use App\Models\PrescriptionDispensing;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class PrescriptionDispensingTest extends TestCase
{
    use RefreshDatabase;

    private Prescription $prescription;
    private Pharmacy $pharmacy;
    private User $pharmacist;

    protected function setUp(): void
    {
        parent::setUp();
        $this->prescription = Prescription::factory()->create();
        $this->pharmacy = Pharmacy::factory()->create();
        $this->pharmacist = User::factory()->create(['role' => 'pharmacy']);
    }

    #[Test]
    public function it_has_fillable_attributes(): void
    {
        $model = new PrescriptionDispensing();
        $fillable = $model->getFillable();

        $this->assertContains('prescription_id', $fillable);
        $this->assertContains('pharmacy_id', $fillable);
        $this->assertContains('order_id', $fillable);
        $this->assertContains('medication_name', $fillable);
        $this->assertContains('product_id', $fillable);
        $this->assertContains('quantity_prescribed', $fillable);
        $this->assertContains('quantity_dispensed', $fillable);
        $this->assertContains('dispensed_at', $fillable);
        $this->assertContains('dispensed_by', $fillable);
    }

    #[Test]
    public function it_casts_dispensed_at_as_datetime(): void
    {
        $model = new PrescriptionDispensing();
        $casts = $model->getCasts();

        $this->assertSame('datetime', $casts['dispensed_at']);
    }

    #[Test]
    public function it_casts_quantities_as_integer(): void
    {
        $model = new PrescriptionDispensing();
        $casts = $model->getCasts();

        $this->assertSame('integer', $casts['quantity_prescribed']);
        $this->assertSame('integer', $casts['quantity_dispensed']);
    }

    #[Test]
    public function it_has_prescription_relationship(): void
    {
        $model = new PrescriptionDispensing();
        $relation = $model->prescription();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_has_pharmacy_relationship(): void
    {
        $model = new PrescriptionDispensing();
        $relation = $model->pharmacy();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_has_product_relationship(): void
    {
        $model = new PrescriptionDispensing();
        $relation = $model->product();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_has_dispensed_by_relationship(): void
    {
        $model = new PrescriptionDispensing();
        $relation = $model->dispensedBy();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_has_order_relationship(): void
    {
        $model = new PrescriptionDispensing();
        $relation = $model->order();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_can_be_created_in_database(): void
    {
        $dispensing = PrescriptionDispensing::create([
            'prescription_id' => $this->prescription->id,
            'pharmacy_id' => $this->pharmacy->id,
            'medication_name' => 'Paracetamol 500mg',
            'quantity_prescribed' => 20,
            'quantity_dispensed' => 20,
            'dispensed_at' => now(),
            'dispensed_by' => $this->pharmacist->id,
        ]);

        $this->assertDatabaseHas('prescription_dispensings', [
            'prescription_id' => $this->prescription->id,
            'medication_name' => 'Paracetamol 500mg',
        ]);
    }

    #[Test]
    public function it_can_be_linked_to_product(): void
    {
        $product = Product::factory()->create(['pharmacy_id' => $this->pharmacy->id]);

        $dispensing = PrescriptionDispensing::create([
            'prescription_id' => $this->prescription->id,
            'pharmacy_id' => $this->pharmacy->id,
            'product_id' => $product->id,
            'medication_name' => $product->name,
            'quantity_prescribed' => 10,
            'quantity_dispensed' => 10,
            'dispensed_at' => now(),
            'dispensed_by' => $this->pharmacist->id,
        ]);

        $this->assertEquals($product->id, $dispensing->product->id);
    }

    #[Test]
    public function it_can_be_linked_to_order(): void
    {
        $order = Order::factory()->create();

        $dispensing = PrescriptionDispensing::create([
            'prescription_id' => $this->prescription->id,
            'pharmacy_id' => $this->pharmacy->id,
            'order_id' => $order->id,
            'medication_name' => 'Amoxicillin 500mg',
            'quantity_prescribed' => 15,
            'quantity_dispensed' => 15,
            'dispensed_at' => now(),
            'dispensed_by' => $this->pharmacist->id,
        ]);

        $this->assertEquals($order->id, $dispensing->order->id);
    }

    #[Test]
    public function it_can_access_prescription_through_relationship(): void
    {
        $dispensing = PrescriptionDispensing::create([
            'prescription_id' => $this->prescription->id,
            'pharmacy_id' => $this->pharmacy->id,
            'medication_name' => 'Ibuprofen 400mg',
            'quantity_prescribed' => 10,
            'quantity_dispensed' => 10,
            'dispensed_at' => now(),
            'dispensed_by' => $this->pharmacist->id,
        ]);

        $this->assertEquals($this->prescription->id, $dispensing->prescription->id);
    }

    #[Test]
    public function it_can_access_pharmacist_through_dispensed_by(): void
    {
        $dispensing = PrescriptionDispensing::create([
            'prescription_id' => $this->prescription->id,
            'pharmacy_id' => $this->pharmacy->id,
            'medication_name' => 'Aspirin 100mg',
            'quantity_prescribed' => 30,
            'quantity_dispensed' => 30,
            'dispensed_at' => now(),
            'dispensed_by' => $this->pharmacist->id,
        ]);

        $this->assertEquals($this->pharmacist->id, $dispensing->dispensedBy->id);
    }
}
