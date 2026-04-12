<?php

namespace Tests\Unit\Models;

use App\Models\Courier;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class WalletTransactionTest extends TestCase
{
    use RefreshDatabase;

    public function test_fillable_attributes(): void
    {
        $tx = new WalletTransaction();
        $fillable = $tx->getFillable();
        $this->assertContains('wallet_id', $fillable);
        $this->assertContains('type', $fillable);
        $this->assertContains('amount', $fillable);
        $this->assertContains('balance_after', $fillable);
        $this->assertContains('reference', $fillable);
        $this->assertContains('description', $fillable);
        $this->assertContains('metadata', $fillable);
        $this->assertContains('category', $fillable);
        $this->assertContains('status', $fillable);
        $this->assertContains('payment_method', $fillable);
    }

    public function test_casts_amount_as_decimal(): void
    {
        $tx = new WalletTransaction();
        $casts = $tx->getCasts();
        $this->assertSame('decimal:2', $casts['amount']);
    }

    public function test_casts_balance_after_as_decimal(): void
    {
        $tx = new WalletTransaction();
        $casts = $tx->getCasts();
        $this->assertSame('decimal:2', $casts['balance_after']);
    }

    public function test_casts_metadata_as_array(): void
    {
        $tx = new WalletTransaction();
        $casts = $tx->getCasts();
        $this->assertSame('array', $casts['metadata']);
    }

    public function test_wallet_relationship(): void
    {
        $tx = new WalletTransaction();
        $relation = $tx->wallet();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $relation);
    }

    #[Test]
    public function it_scopes_credit_transactions(): void
    {
        $user = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $user->id]);
        $wallet = Wallet::factory()->create([
            'walletable_type' => Courier::class,
            'walletable_id' => $courier->id,
        ]);

        WalletTransaction::create([
            'wallet_id' => $wallet->id,
            'type' => 'CREDIT',
            'amount' => 1000,
            'balance_after' => 1000,
            'reference' => 'REF001',
            'description' => 'Deposit',
        ]);

        WalletTransaction::create([
            'wallet_id' => $wallet->id,
            'type' => 'DEBIT',
            'amount' => 500,
            'balance_after' => 500,
            'reference' => 'REF002',
            'description' => 'Withdrawal',
        ]);

        WalletTransaction::create([
            'wallet_id' => $wallet->id,
            'type' => 'CREDIT',
            'amount' => 200,
            'balance_after' => 700,
            'reference' => 'REF003',
            'description' => 'Commission',
        ]);

        $credits = WalletTransaction::credits()->get();
        $this->assertCount(2, $credits);
        $this->assertTrue($credits->every(fn($tx) => $tx->type === 'CREDIT'));
    }

    #[Test]
    public function it_scopes_debit_transactions(): void
    {
        $user = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $user->id]);
        $wallet = Wallet::factory()->create([
            'walletable_type' => Courier::class,
            'walletable_id' => $courier->id,
        ]);

        WalletTransaction::create([
            'wallet_id' => $wallet->id,
            'type' => 'CREDIT',
            'amount' => 1000,
            'balance_after' => 1000,
            'reference' => 'REF001',
            'description' => 'Deposit',
        ]);

        WalletTransaction::create([
            'wallet_id' => $wallet->id,
            'type' => 'DEBIT',
            'amount' => 500,
            'balance_after' => 500,
            'reference' => 'REF002',
            'description' => 'Withdrawal',
        ]);

        WalletTransaction::create([
            'wallet_id' => $wallet->id,
            'type' => 'DEBIT',
            'amount' => 100,
            'balance_after' => 400,
            'reference' => 'REF003',
            'description' => 'Fee',
        ]);

        $debits = WalletTransaction::debits()->get();
        $this->assertCount(2, $debits);
        $this->assertTrue($debits->every(fn($tx) => $tx->type === 'DEBIT'));
    }
}
