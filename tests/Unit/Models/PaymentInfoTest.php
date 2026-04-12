<?php

namespace Tests\Unit\Models;

use App\Models\PaymentInfo;
use App\Models\Pharmacy;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class PaymentInfoTest extends TestCase
{
    use RefreshDatabase;

    private Pharmacy $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();
        $this->pharmacy = Pharmacy::factory()->create();
    }

    #[Test]
    public function it_has_fillable_attributes(): void
    {
        $model = new PaymentInfo();
        $fillable = $model->getFillable();

        $this->assertContains('pharmacy_id', $fillable);
        $this->assertContains('type', $fillable);
        $this->assertContains('bank_name', $fillable);
        $this->assertContains('holder_name', $fillable);
        $this->assertContains('account_number', $fillable);
        $this->assertContains('iban', $fillable);
        $this->assertContains('operator', $fillable);
        $this->assertContains('phone_number', $fillable);
        $this->assertContains('is_primary', $fillable);
        $this->assertContains('is_verified', $fillable);
        $this->assertContains('verified_at', $fillable);
    }

    #[Test]
    public function it_casts_is_primary_as_boolean(): void
    {
        $model = new PaymentInfo();
        $casts = $model->getCasts();

        $this->assertSame('boolean', $casts['is_primary']);
    }

    #[Test]
    public function it_casts_is_verified_as_boolean(): void
    {
        $model = new PaymentInfo();
        $casts = $model->getCasts();

        $this->assertSame('boolean', $casts['is_verified']);
    }

    #[Test]
    public function it_casts_verified_at_as_datetime(): void
    {
        $model = new PaymentInfo();
        $casts = $model->getCasts();

        $this->assertSame('datetime', $casts['verified_at']);
    }

    #[Test]
    public function it_has_pharmacy_relationship(): void
    {
        $model = new PaymentInfo();
        $relation = $model->pharmacy();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_can_be_created_with_bank_info(): void
    {
        $paymentInfo = PaymentInfo::create([
            'pharmacy_id' => $this->pharmacy->id,
            'type' => 'bank',
            'bank_name' => 'Ecobank',
            'holder_name' => 'Pharmacie Test',
            'account_number' => '1234567890',
            'is_primary' => true,
            'is_verified' => false,
        ]);

        $this->assertDatabaseHas('payment_infos', [
            'pharmacy_id' => $this->pharmacy->id,
            'type' => 'bank',
            'bank_name' => 'Ecobank',
        ]);
    }

    #[Test]
    public function it_can_be_created_with_mobile_money_info(): void
    {
        $paymentInfo = PaymentInfo::create([
            'pharmacy_id' => $this->pharmacy->id,
            'type' => 'mobile_money',
            'operator' => 'Flooz',
            'phone_number' => '+22890123456',
            'holder_name' => 'Pharmacie Test',
            'is_primary' => true,
            'is_verified' => true,
            'verified_at' => now(),
        ]);

        $this->assertDatabaseHas('payment_infos', [
            'pharmacy_id' => $this->pharmacy->id,
            'type' => 'mobile_money',
            'operator' => 'Flooz',
        ]);
    }

    #[Test]
    public function it_can_access_pharmacy_through_relationship(): void
    {
        $paymentInfo = PaymentInfo::create([
            'pharmacy_id' => $this->pharmacy->id,
            'type' => 'bank',
            'bank_name' => 'UTB',
            'holder_name' => 'Test Holder',
            'is_primary' => false,
        ]);

        $this->assertEquals($this->pharmacy->id, $paymentInfo->pharmacy->id);
    }

    #[Test]
    public function it_can_mark_as_verified(): void
    {
        $paymentInfo = PaymentInfo::create([
            'pharmacy_id' => $this->pharmacy->id,
            'type' => 'bank',
            'bank_name' => 'BTCI',
            'holder_name' => 'Holder',
            'is_primary' => true,
            'is_verified' => false,
        ]);

        $paymentInfo->update([
            'is_verified' => true,
            'verified_at' => now(),
        ]);

        $paymentInfo->refresh();

        $this->assertTrue($paymentInfo->is_verified);
        $this->assertNotNull($paymentInfo->verified_at);
    }
}
