<?php

namespace Tests\Unit\Models;

use App\Models\PayoutRequest;
use App\Models\Pharmacy;
use App\Models\Wallet;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class PayoutRequestTest extends TestCase
{
    use RefreshDatabase;

    private Wallet $wallet;

    protected function setUp(): void
    {
        parent::setUp();
        $pharmacy = Pharmacy::factory()->create();
        $this->wallet = Wallet::factory()->create([
            'walletable_type' => Pharmacy::class,
            'walletable_id' => $pharmacy->id,
        ]);
    }

    #[Test]
    public function it_has_fillable_attributes(): void
    {
        $model = new PayoutRequest();
        $fillable = $model->getFillable();

        $this->assertContains('wallet_id', $fillable);
        $this->assertContains('amount', $fillable);
        $this->assertContains('status', $fillable);
        $this->assertContains('payment_method', $fillable);
        $this->assertContains('payment_details', $fillable);
        $this->assertContains('rejection_reason', $fillable);
        $this->assertContains('processed_at', $fillable);
    }

    #[Test]
    public function it_casts_amount_as_decimal(): void
    {
        $model = new PayoutRequest();
        $casts = $model->getCasts();

        $this->assertSame('decimal:2', $casts['amount']);
    }

    #[Test]
    public function it_casts_payment_details_as_array(): void
    {
        $model = new PayoutRequest();
        $casts = $model->getCasts();

        $this->assertSame('array', $casts['payment_details']);
    }

    #[Test]
    public function it_casts_processed_at_as_datetime(): void
    {
        $model = new PayoutRequest();
        $casts = $model->getCasts();

        $this->assertSame('datetime', $casts['processed_at']);
    }

    #[Test]
    public function it_has_wallet_relationship(): void
    {
        $model = new PayoutRequest();
        $relation = $model->wallet();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_can_be_created_in_database(): void
    {
        $payout = PayoutRequest::create([
            'wallet_id' => $this->wallet->id,
            'amount' => 10000.00,
            'status' => 'pending',
            'payment_method' => 'mobile_money',
            'payment_details' => [
                'operator' => 'Flooz',
                'phone' => '+22890123456',
            ],
        ]);

        $this->assertDatabaseHas('payout_requests', [
            'wallet_id' => $this->wallet->id,
            'status' => 'pending',
        ]);
    }

    #[Test]
    public function it_can_store_payment_details(): void
    {
        $details = [
            'operator' => 'TMoney',
            'phone' => '+22891234567',
            'holder_name' => 'Test User',
        ];

        $payout = PayoutRequest::create([
            'wallet_id' => $this->wallet->id,
            'amount' => 5000.00,
            'status' => 'pending',
            'payment_method' => 'mobile_money',
            'payment_details' => $details,
        ]);

        $payout->refresh();
        $this->assertEquals($details, $payout->payment_details);
    }

    #[Test]
    public function it_can_access_wallet_through_relationship(): void
    {
        $payout = PayoutRequest::create([
            'wallet_id' => $this->wallet->id,
            'amount' => 5000.00,
            'status' => 'pending',
            'payment_method' => 'bank',
        ]);

        $this->assertEquals($this->wallet->id, $payout->wallet->id);
    }

    #[Test]
    public function it_can_be_processed(): void
    {
        $payout = PayoutRequest::create([
            'wallet_id' => $this->wallet->id,
            'amount' => 5000.00,
            'status' => 'pending',
            'payment_method' => 'bank',
        ]);

        $payout->update([
            'status' => 'completed',
            'processed_at' => now(),
        ]);

        $payout->refresh();

        $this->assertEquals('completed', $payout->status);
        $this->assertNotNull($payout->processed_at);
    }

    #[Test]
    public function it_can_be_rejected(): void
    {
        $payout = PayoutRequest::create([
            'wallet_id' => $this->wallet->id,
            'amount' => 5000.00,
            'status' => 'pending',
            'payment_method' => 'bank',
        ]);

        $payout->update([
            'status' => 'rejected',
            'rejection_reason' => 'Insufficient documentation',
            'processed_at' => now(),
        ]);

        $payout->refresh();

        $this->assertEquals('rejected', $payout->status);
        $this->assertEquals('Insufficient documentation', $payout->rejection_reason);
    }
}
