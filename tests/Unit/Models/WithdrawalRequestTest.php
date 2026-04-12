<?php

namespace Tests\Unit\Models;

use App\Models\Courier;
use App\Models\Pharmacy;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WithdrawalRequest;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class WithdrawalRequestTest extends TestCase
{
    use RefreshDatabase;

    private Pharmacy $pharmacy;
    private Courier $courier;
    private Wallet $pharmacyWallet;
    private Wallet $courierWallet;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->pharmacy = Pharmacy::factory()->create();
        $this->pharmacyWallet = Wallet::factory()->create([
            'walletable_type' => Pharmacy::class,
            'walletable_id' => $this->pharmacy->id,
        ]);

        $courierUser = User::factory()->create(['role' => 'courier']);
        $this->courier = Courier::factory()->create(['user_id' => $courierUser->id]);
        $this->courierWallet = Wallet::factory()->create([
            'walletable_type' => Courier::class,
            'walletable_id' => $this->courier->id,
        ]);
    }

    #[Test]
    public function it_has_fillable_attributes(): void
    {
        $model = new WithdrawalRequest();
        $fillable = $model->getFillable();

        $this->assertContains('wallet_id', $fillable);
        $this->assertContains('requestable_type', $fillable);
        $this->assertContains('requestable_id', $fillable);
        $this->assertContains('pharmacy_id', $fillable);
        $this->assertContains('amount', $fillable);
        $this->assertContains('payment_method', $fillable);
        $this->assertContains('account_details', $fillable);
        $this->assertContains('reference', $fillable);
        $this->assertContains('status', $fillable);
        $this->assertContains('processed_at', $fillable);
        $this->assertContains('completed_at', $fillable);
        $this->assertContains('admin_notes', $fillable);
        $this->assertContains('error_message', $fillable);
        $this->assertContains('jeko_reference', $fillable);
        $this->assertContains('jeko_payment_id', $fillable);
        $this->assertContains('phone', $fillable);
        $this->assertContains('bank_details', $fillable);
    }

    #[Test]
    public function it_casts_amount_as_decimal(): void
    {
        $model = new WithdrawalRequest();
        $casts = $model->getCasts();

        $this->assertSame('decimal:2', $casts['amount']);
    }

    #[Test]
    public function it_casts_account_details_as_array(): void
    {
        $model = new WithdrawalRequest();
        $casts = $model->getCasts();

        $this->assertSame('array', $casts['account_details']);
    }

    #[Test]
    public function it_casts_bank_details_as_array(): void
    {
        $model = new WithdrawalRequest();
        $casts = $model->getCasts();

        $this->assertSame('array', $casts['bank_details']);
    }

    #[Test]
    public function it_casts_timestamps_as_datetime(): void
    {
        $model = new WithdrawalRequest();
        $casts = $model->getCasts();

        $this->assertSame('datetime', $casts['processed_at']);
        $this->assertSame('datetime', $casts['completed_at']);
    }

    #[Test]
    public function it_has_wallet_relationship(): void
    {
        $model = new WithdrawalRequest();
        $relation = $model->wallet();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_has_requestable_morph_relationship(): void
    {
        $model = new WithdrawalRequest();
        $relation = $model->requestable();

        $this->assertInstanceOf(MorphTo::class, $relation);
    }

    #[Test]
    public function it_has_pharmacy_relationship(): void
    {
        $model = new WithdrawalRequest();
        $relation = $model->pharmacy();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_can_be_created_for_pharmacy(): void
    {
        $withdrawal = WithdrawalRequest::create([
            'wallet_id' => $this->pharmacyWallet->id,
            'requestable_type' => Pharmacy::class,
            'requestable_id' => $this->pharmacy->id,
            'amount' => 50000.00,
            'payment_method' => 'mobile_money',
            'status' => 'pending',
            'reference' => 'WR-PHARM-001',
            'phone' => '+22890123456',
        ]);

        $this->assertDatabaseHas('withdrawal_requests', [
            'wallet_id' => $this->pharmacyWallet->id,
            'requestable_type' => Pharmacy::class,
        ]);
    }

    #[Test]
    public function it_can_be_created_for_courier(): void
    {
        $withdrawal = WithdrawalRequest::create([
            'wallet_id' => $this->courierWallet->id,
            'requestable_type' => Courier::class,
            'requestable_id' => $this->courier->id,
            'amount' => 15000.00,
            'payment_method' => 'mobile_money',
            'status' => 'pending',
            'reference' => 'WR-COUR-001',
            'phone' => '+22891234567',
        ]);

        $this->assertDatabaseHas('withdrawal_requests', [
            'wallet_id' => $this->courierWallet->id,
            'requestable_type' => Courier::class,
        ]);
    }

    #[Test]
    public function it_identifies_pharmacy_request(): void
    {
        $withdrawal = WithdrawalRequest::create([
            'wallet_id' => $this->pharmacyWallet->id,
            'requestable_type' => Pharmacy::class,
            'requestable_id' => $this->pharmacy->id,
            'amount' => 50000.00,
            'payment_method' => 'bank',
            'status' => 'pending',
            'reference' => 'WR-PHARM-002',
        ]);

        $this->assertTrue($withdrawal->isFromPharmacy());
        $this->assertFalse($withdrawal->isFromCourier());
    }

    #[Test]
    public function it_identifies_courier_request(): void
    {
        $withdrawal = WithdrawalRequest::create([
            'wallet_id' => $this->courierWallet->id,
            'requestable_type' => Courier::class,
            'requestable_id' => $this->courier->id,
            'amount' => 10000.00,
            'payment_method' => 'mobile_money',
            'status' => 'pending',
            'reference' => 'WR-COUR-002',
        ]);

        $this->assertTrue($withdrawal->isFromCourier());
        $this->assertFalse($withdrawal->isFromPharmacy());
    }

    #[Test]
    public function it_scopes_pharmacy_requests(): void
    {
        $pharmacyWithdrawal = WithdrawalRequest::create([
            'wallet_id' => $this->pharmacyWallet->id,
            'requestable_type' => Pharmacy::class,
            'requestable_id' => $this->pharmacy->id,
            'amount' => 50000.00,
            'payment_method' => 'bank',
            'status' => 'pending',
            'reference' => 'WR-PHARM-003',
        ]);

        $courierWithdrawal = WithdrawalRequest::create([
            'wallet_id' => $this->courierWallet->id,
            'requestable_type' => Courier::class,
            'requestable_id' => $this->courier->id,
            'amount' => 10000.00,
            'payment_method' => 'mobile_money',
            'status' => 'pending',
            'reference' => 'WR-COUR-003',
        ]);

        $pharmacyIds = WithdrawalRequest::fromPharmacies()->pluck('id')->toArray();

        $this->assertContains($pharmacyWithdrawal->id, $pharmacyIds);
        $this->assertNotContains($courierWithdrawal->id, $pharmacyIds);
    }

    #[Test]
    public function it_scopes_courier_requests(): void
    {
        $pharmacyWithdrawal = WithdrawalRequest::create([
            'wallet_id' => $this->pharmacyWallet->id,
            'requestable_type' => Pharmacy::class,
            'requestable_id' => $this->pharmacy->id,
            'amount' => 50000.00,
            'payment_method' => 'bank',
            'status' => 'pending',
            'reference' => 'WR-PHARM-004',
        ]);

        $courierWithdrawal = WithdrawalRequest::create([
            'wallet_id' => $this->courierWallet->id,
            'requestable_type' => Courier::class,
            'requestable_id' => $this->courier->id,
            'amount' => 10000.00,
            'payment_method' => 'mobile_money',
            'status' => 'pending',
            'reference' => 'WR-COUR-004',
        ]);

        $courierIds = WithdrawalRequest::fromCouriers()->pluck('id')->toArray();

        $this->assertContains($courierWithdrawal->id, $courierIds);
        $this->assertNotContains($pharmacyWithdrawal->id, $courierIds);
    }

    #[Test]
    public function it_can_store_bank_details(): void
    {
        $bankDetails = [
            'bank_name' => 'Ecobank',
            'account_number' => '1234567890',
            'holder_name' => 'Pharmacie Test',
        ];

        $withdrawal = WithdrawalRequest::create([
            'wallet_id' => $this->pharmacyWallet->id,
            'requestable_type' => Pharmacy::class,
            'requestable_id' => $this->pharmacy->id,
            'amount' => 100000.00,
            'payment_method' => 'bank',
            'status' => 'pending',
            'reference' => 'WR-PHARM-005',
            'bank_details' => $bankDetails,
        ]);

        $withdrawal->refresh();
        $this->assertEquals($bankDetails, $withdrawal->bank_details);
    }

    #[Test]
    public function it_can_be_processed(): void
    {
        $withdrawal = WithdrawalRequest::create([
            'wallet_id' => $this->pharmacyWallet->id,
            'requestable_type' => Pharmacy::class,
            'requestable_id' => $this->pharmacy->id,
            'amount' => 50000.00,
            'payment_method' => 'mobile_money',
            'status' => 'pending',
            'reference' => 'WR-PHARM-006',
        ]);

        $withdrawal->update([
            'status' => 'processing',
            'processed_at' => now(),
        ]);

        $withdrawal->refresh();

        $this->assertEquals('processing', $withdrawal->status);
        $this->assertNotNull($withdrawal->processed_at);
    }

    #[Test]
    public function it_can_be_completed(): void
    {
        $withdrawal = WithdrawalRequest::create([
            'wallet_id' => $this->pharmacyWallet->id,
            'requestable_type' => Pharmacy::class,
            'requestable_id' => $this->pharmacy->id,
            'amount' => 50000.00,
            'payment_method' => 'mobile_money',
            'status' => 'processing',
            'reference' => 'WR-PHARM-007',
            'processed_at' => now()->subMinute(),
        ]);

        $withdrawal->update([
            'status' => 'completed',
            'completed_at' => now(),
            'jeko_reference' => 'JEKO123456',
        ]);

        $withdrawal->refresh();

        $this->assertEquals('completed', $withdrawal->status);
        $this->assertNotNull($withdrawal->completed_at);
        $this->assertEquals('JEKO123456', $withdrawal->jeko_reference);
    }

    #[Test]
    public function it_can_have_error_message(): void
    {
        $withdrawal = WithdrawalRequest::create([
            'wallet_id' => $this->courierWallet->id,
            'requestable_type' => Courier::class,
            'requestable_id' => $this->courier->id,
            'amount' => 10000.00,
            'payment_method' => 'mobile_money',
            'status' => 'failed',
            'reference' => 'WR-COUR-005',
            'error_message' => 'Insufficient balance on payment provider',
        ]);

        $this->assertEquals('Insufficient balance on payment provider', $withdrawal->error_message);
    }

    #[Test]
    public function it_returns_pharmacy_name_for_requester_name(): void
    {
        $withdrawal = WithdrawalRequest::create([
            'wallet_id' => $this->pharmacyWallet->id,
            'requestable_type' => Pharmacy::class,
            'requestable_id' => $this->pharmacy->id,
            'amount' => 50000.00,
            'payment_method' => 'bank',
            'status' => 'pending',
            'reference' => 'WR-PHARM-008',
        ]);

        $this->assertEquals($this->pharmacy->name, $withdrawal->requester_name);
    }

    #[Test]
    public function it_returns_courier_name_for_requester_name(): void
    {
        $withdrawal = WithdrawalRequest::create([
            'wallet_id' => $this->courierWallet->id,
            'requestable_type' => Courier::class,
            'requestable_id' => $this->courier->id,
            'amount' => 10000.00,
            'payment_method' => 'mobile_money',
            'status' => 'pending',
            'reference' => 'WR-COUR-006',
        ]);

        $this->assertEquals($this->courier->name, $withdrawal->requester_name);
    }

    #[Test]
    public function it_returns_pharmacie_for_requester_type(): void
    {
        $withdrawal = WithdrawalRequest::create([
            'wallet_id' => $this->pharmacyWallet->id,
            'requestable_type' => Pharmacy::class,
            'requestable_id' => $this->pharmacy->id,
            'amount' => 50000.00,
            'payment_method' => 'bank',
            'status' => 'pending',
            'reference' => 'WR-PHARM-009',
        ]);

        $this->assertEquals('Pharmacie', $withdrawal->requester_type);
    }

    #[Test]
    public function it_returns_livreur_for_requester_type(): void
    {
        $withdrawal = WithdrawalRequest::create([
            'wallet_id' => $this->courierWallet->id,
            'requestable_type' => Courier::class,
            'requestable_id' => $this->courier->id,
            'amount' => 10000.00,
            'payment_method' => 'mobile_money',
            'status' => 'pending',
            'reference' => 'WR-COUR-007',
        ]);

        $this->assertEquals('Livreur', $withdrawal->requester_type);
    }

    #[Test]
    public function it_returns_inconnu_when_no_requestable(): void
    {
        $withdrawal = new WithdrawalRequest([
            'wallet_id' => $this->pharmacyWallet->id,
            'amount' => 50000.00,
            'payment_method' => 'bank',
            'status' => 'pending',
            'reference' => 'WR-NO-REQ',
        ]);

        $this->assertEquals('Inconnu', $withdrawal->requester_name);
        $this->assertEquals('Inconnu', $withdrawal->requester_type);
    }
}
