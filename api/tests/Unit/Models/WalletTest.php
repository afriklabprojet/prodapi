<?php

namespace Tests\Unit\Models;

use App\Exceptions\InsufficientBalanceException;
use App\Models\Courier;
use App\Models\Pharmacy;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class WalletTest extends TestCase
{
    use RefreshDatabase;

    protected Wallet $wallet;
    protected Courier $courier;
    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Create user and courier manually to avoid factory circular dependency
        $this->user = User::factory()->create(['role' => 'courier']);
        $this->courier = Courier::create([
            'user_id' => $this->user->id,
            'name' => 'Test Courier',
            'phone' => '+2250102030405',
            'vehicle_type' => 'motorcycle',
            'vehicle_number' => 'AB-1234-CD',
            'license_number' => 'CI12345678',
            'status' => 'available',
            'latitude' => 5.36,
            'longitude' => -4.01,
            'kyc_status' => 'approved',
        ]);
        
        $this->wallet = Wallet::create([
            'walletable_type' => Courier::class,
            'walletable_id' => $this->courier->id,
            'balance' => 10000,
            'currency' => 'XOF',
        ]);
    }

    // ========================================================================
    // CREDIT TESTS
    // ========================================================================

    #[Test]
    public function it_can_credit_wallet()
    {
        $initialBalance = $this->wallet->balance;
        
        $transaction = $this->wallet->credit(5000, 'TEST-CR-001', 'Test credit');
        
        $this->wallet->refresh();
        
        $this->assertEquals($initialBalance + 5000, $this->wallet->balance);
        $this->assertInstanceOf(WalletTransaction::class, $transaction);
        $this->assertEquals('CREDIT', $transaction->type);
        $this->assertEquals(5000, $transaction->amount);
        $this->assertEquals($initialBalance + 5000, $transaction->balance_after);
    }

    #[Test]
    public function it_rejects_negative_credit_amount()
    {
        $this->expectException(\InvalidArgumentException::class);
        
        $this->wallet->credit(-500, 'TEST-CR-NEG', 'Negative credit');
    }

    #[Test]
    public function it_rejects_zero_credit_amount()
    {
        $this->expectException(\InvalidArgumentException::class);
        
        $this->wallet->credit(0, 'TEST-CR-ZERO', 'Zero credit');
    }

    #[Test]
    public function credit_is_idempotent_with_same_reference()
    {
        $reference = 'TEST-CR-IDEMPOTENT';
        
        $transaction1 = $this->wallet->credit(5000, $reference, 'First credit');
        $transaction2 = $this->wallet->credit(5000, $reference, 'Duplicate credit');
        
        $this->wallet->refresh();
        
        // Same transaction returned (idempotent)
        $this->assertEquals($transaction1->id, $transaction2->id);
        
        // Balance only credited once
        $this->assertEquals(15000, $this->wallet->balance);
        
        // Only one transaction exists
        $this->assertEquals(1, WalletTransaction::where('reference', $reference)->count());
    }

    // ========================================================================
    // DEBIT TESTS
    // ========================================================================

    #[Test]
    public function it_can_debit_wallet()
    {
        $initialBalance = $this->wallet->balance;
        
        $transaction = $this->wallet->debit(3000, 'TEST-DB-001', 'Test debit');
        
        $this->wallet->refresh();
        
        $this->assertEquals($initialBalance - 3000, $this->wallet->balance);
        $this->assertInstanceOf(WalletTransaction::class, $transaction);
        $this->assertEquals('DEBIT', $transaction->type);
        $this->assertEquals(3000, $transaction->amount);
        $this->assertEquals($initialBalance - 3000, $transaction->balance_after);
    }

    #[Test]
    public function it_rejects_negative_debit_amount()
    {
        $this->expectException(\InvalidArgumentException::class);
        
        $this->wallet->debit(-500, 'TEST-DB-NEG', 'Negative debit');
    }

    #[Test]
    public function it_rejects_zero_debit_amount()
    {
        $this->expectException(\InvalidArgumentException::class);
        
        $this->wallet->debit(0, 'TEST-DB-ZERO', 'Zero debit');
    }

    #[Test]
    public function it_rejects_debit_when_insufficient_balance()
    {
        $this->expectException(InsufficientBalanceException::class);
        
        $this->wallet->debit(20000, 'TEST-DB-INSUF', 'Exceeds balance');
    }

    #[Test]
    public function debit_is_idempotent_with_same_reference()
    {
        $reference = 'TEST-DB-IDEMPOTENT';
        
        $transaction1 = $this->wallet->debit(3000, $reference, 'First debit');
        $transaction2 = $this->wallet->debit(3000, $reference, 'Duplicate debit');
        
        $this->wallet->refresh();
        
        // Same transaction returned (idempotent)
        $this->assertEquals($transaction1->id, $transaction2->id);
        
        // Balance only debited once
        $this->assertEquals(7000, $this->wallet->balance);
        
        // Only one transaction exists
        $this->assertEquals(1, WalletTransaction::where('reference', $reference)->count());
    }

    #[Test]
    public function it_prevents_negative_balance()
    {
        // Set balance to exactly 5000
        $this->wallet->update(['balance' => 5000]);
        
        // Try to debit 5001 (1 more than balance)
        $this->expectException(InsufficientBalanceException::class);
        
        $this->wallet->debit(5001, 'TEST-DB-BOUNDARY', 'Boundary test');
    }

    #[Test]
    public function it_allows_debit_equal_to_balance()
    {
        $this->wallet->update(['balance' => 5000]);
        
        $transaction = $this->wallet->debit(5000, 'TEST-DB-EXACT', 'Exact balance debit');
        
        $this->wallet->refresh();
        
        $this->assertEquals(0, $this->wallet->balance);
        $this->assertEquals(0, $transaction->balance_after);
    }

    // ========================================================================
    // HELPER METHODS TESTS
    // ========================================================================

    #[Test]
    public function it_checks_sufficient_balance()
    {
        $this->wallet->update(['balance' => 5000]);
        
        $this->assertTrue($this->wallet->hasSufficientBalance(5000));
        $this->assertTrue($this->wallet->hasSufficientBalance(4999));
        $this->assertFalse($this->wallet->hasSufficientBalance(5001));
    }

    #[Test]
    public function it_gets_or_creates_wallet_for_entity()
    {
        $newUser = User::factory()->create(['role' => 'courier']);
        $newCourier = Courier::create([
            'user_id' => $newUser->id,
            'name' => 'New Test Courier',
            'phone' => '+2250506070809',
            'vehicle_type' => 'bicycle',
            'vehicle_number' => 'XY-5678-ZZ',
            'license_number' => 'CI87654321',
            'status' => 'available',
            'latitude' => 5.35,
            'longitude' => -4.02,
            'kyc_status' => 'approved',
        ]);
        
        // Wallet doesn't exist yet
        $this->assertNull(Wallet::where([
            'walletable_type' => Courier::class,
            'walletable_id' => $newCourier->id,
        ])->first());
        
        // Get or create using firstOrCreate
        $wallet = Wallet::firstOrCreate(
            [
                'walletable_type' => Courier::class,
                'walletable_id' => $newCourier->id,
            ],
            [
                'balance' => 0,
                'currency' => 'XOF',
            ]
        );
        
        $this->assertInstanceOf(Wallet::class, $wallet);
        $this->assertEquals(0, $wallet->balance);
        $this->assertEquals('XOF', $wallet->currency);
        
        // Second call returns same wallet
        $wallet2 = Wallet::firstOrCreate(
            [
                'walletable_type' => Courier::class,
                'walletable_id' => $newCourier->id,
            ],
            [
                'balance' => 0,
                'currency' => 'XOF',
            ]
        );
        $this->assertEquals($wallet->id, $wallet2->id);
    }

    // ========================================================================
    // POLYMORPHIC RELATION TESTS
    // ========================================================================

    #[Test]
    public function it_can_belong_to_courier()
    {
        $wallet = Wallet::where([
            'walletable_type' => Courier::class,
            'walletable_id' => $this->courier->id,
        ])->first();
        
        $this->assertInstanceOf(Courier::class, $wallet->walletable);
        $this->assertEquals($this->courier->id, $wallet->walletable->id);
    }

    #[Test]
    public function it_can_belong_to_pharmacy()
    {
        $pharmacy = Pharmacy::factory()->create();
        $wallet = Wallet::create([
            'walletable_type' => Pharmacy::class,
            'walletable_id' => $pharmacy->id,
            'balance' => 50000,
            'currency' => 'XOF',
        ]);
        
        $this->assertInstanceOf(Pharmacy::class, $wallet->walletable);
        $this->assertEquals($pharmacy->id, $wallet->walletable->id);
    }

    // ========================================================================
    // TRANSACTION HISTORY TESTS
    // ========================================================================

    #[Test]
    public function it_tracks_transaction_history()
    {
        $this->wallet->credit(1000, 'CR-001', 'Credit 1');
        $this->wallet->credit(2000, 'CR-002', 'Credit 2');
        $this->wallet->debit(500, 'DB-001', 'Debit 1');
        
        $transactions = $this->wallet->transactions()->orderBy('id')->get();
        
        $this->assertCount(3, $transactions);
        
        // Verify order and types
        $this->assertEquals('CREDIT', $transactions[0]->type);
        $this->assertEquals(1000, $transactions[0]->amount);
        
        $this->assertEquals('CREDIT', $transactions[1]->type);
        $this->assertEquals(2000, $transactions[1]->amount);
        
        $this->assertEquals('DEBIT', $transactions[2]->type);
        $this->assertEquals(500, $transactions[2]->amount);
    }

    #[Test]
    public function it_stores_metadata_in_transactions()
    {
        $metadata = [
            'order_id' => 123,
            'delivery_id' => 456,
            'notes' => 'Special delivery',
        ];
        
        $transaction = $this->wallet->credit(
            1000,
            'CR-META',
            'Credit with metadata',
            $metadata
        );
        
        $this->assertEquals($metadata, $transaction->metadata);
    }
}
