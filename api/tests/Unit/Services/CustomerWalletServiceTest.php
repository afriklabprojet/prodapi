<?php

namespace Tests\Unit\Services;

use App\Exceptions\InsufficientBalanceException;
use App\Exceptions\InvalidAmountException;
use App\Services\CustomerWalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CustomerWalletServiceTest extends TestCase
{
    use RefreshDatabase;

    private CustomerWalletService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new CustomerWalletService();
    }

    public function test_it_can_be_instantiated(): void
    {
        $this->assertInstanceOf(CustomerWalletService::class, $this->service);
    }

    public function test_topup_rejects_zero_amount(): void
    {
        $this->expectException(InvalidAmountException::class);

        $user = \App\Models\User::factory()->create(['role' => 'customer']);
        $this->service->topUp($user, 0, 'WAVE');
    }

    public function test_topup_rejects_negative_amount(): void
    {
        $this->expectException(InvalidAmountException::class);

        $user = \App\Models\User::factory()->create(['role' => 'customer']);
        $this->service->topUp($user, -100, 'MTN');
    }

    public function test_pay_order_rejects_zero_amount(): void
    {
        $this->expectException(InvalidAmountException::class);

        $user = \App\Models\User::factory()->create(['role' => 'customer']);
        $this->service->payOrder($user, 0, 'CMD-001');
    }

    public function test_pay_order_rejects_negative_amount(): void
    {
        $this->expectException(InvalidAmountException::class);

        $user = \App\Models\User::factory()->create(['role' => 'customer']);
        $this->service->payOrder($user, -500, 'CMD-002');
    }

    public function test_refund_rejects_zero_amount(): void
    {
        $this->expectException(InvalidAmountException::class);

        $user = \App\Models\User::factory()->create(['role' => 'customer']);
        $this->service->refund($user, 0, 'Test refund');
    }

    public function test_refund_rejects_negative_amount(): void
    {
        $this->expectException(InvalidAmountException::class);

        $user = \App\Models\User::factory()->create(['role' => 'customer']);
        $this->service->refund($user, -100, 'Test refund');
    }

    public function test_get_or_create_wallet_creates_wallet(): void
    {
        $user = \App\Models\User::factory()->create(['role' => 'customer']);
        $wallet = $this->service->getOrCreateWallet($user);

        $this->assertNotNull($wallet);
        $this->assertEquals(0, $wallet->balance);
        $this->assertEquals('XOF', $wallet->currency);
    }

    public function test_get_or_create_wallet_returns_existing(): void
    {
        $user = \App\Models\User::factory()->create(['role' => 'customer']);

        $wallet1 = $this->service->getOrCreateWallet($user);
        $wallet2 = $this->service->getOrCreateWallet($user);

        $this->assertEquals($wallet1->id, $wallet2->id);
    }

    public function test_topup_credits_wallet(): void
    {
        $user = \App\Models\User::factory()->create(['role' => 'customer']);
        $transaction = $this->service->topUp($user, 5000, 'WAVE');

        $this->assertNotNull($transaction);
        $this->assertEquals('topup', $transaction->category);
        $this->assertEquals('completed', $transaction->status);
    }

    public function test_pay_order_insufficient_balance(): void
    {
        $this->expectException(InsufficientBalanceException::class);

        $user = \App\Models\User::factory()->create(['role' => 'customer']);
        $this->service->getOrCreateWallet($user); // creates wallet with 0 balance
        $this->service->payOrder($user, 5000, 'CMD-003');
    }

    public function test_pay_order_with_sufficient_balance(): void
    {
        $user = \App\Models\User::factory()->create(['role' => 'customer']);
        $this->service->topUp($user, 10000, 'WAVE');
        $transaction = $this->service->payOrder($user, 5000, 'CMD-004');

        $this->assertNotNull($transaction);
        $this->assertEquals('order_payment', $transaction->category);
        $this->assertEquals('completed', $transaction->status);
    }

    public function test_refund_credits_wallet(): void
    {
        $user = \App\Models\User::factory()->create(['role' => 'customer']);
        $transaction = $this->service->refund($user, 3000, 'Order cancelled');

        $this->assertNotNull($transaction);
        $this->assertEquals('refund', $transaction->category);
        $this->assertEquals('completed', $transaction->status);
    }

    public function test_get_balance_returns_correct_structure(): void
    {
        $user = \App\Models\User::factory()->create(['role' => 'customer']);
        $balance = $this->service->getBalance($user);

        $this->assertArrayHasKey('balance', $balance);
        $this->assertArrayHasKey('currency', $balance);
        $this->assertArrayHasKey('pending_withdrawals', $balance);
        $this->assertArrayHasKey('available_balance', $balance);
        $this->assertArrayHasKey('minimum_withdrawal', $balance);
        $this->assertEquals('XOF', $balance['currency']);
    }

    public function test_get_transaction_history_returns_collection(): void
    {
        $user = \App\Models\User::factory()->create(['role' => 'customer']);
        $history = $this->service->getTransactionHistory($user);

        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Collection::class, $history);
    }

    public function test_get_transaction_history_with_category_filter(): void
    {
        $user = \App\Models\User::factory()->create(['role' => 'customer']);
        $this->service->topUp($user, 5000, 'WAVE');
        
        $history = $this->service->getTransactionHistory($user, 50, 'topup');
        $this->assertTrue($history->count() >= 1);
    }

    public function test_get_statistics_returns_correct_structure(): void
    {
        $user = \App\Models\User::factory()->create(['role' => 'customer']);
        $stats = $this->service->getStatistics($user);

        $this->assertArrayHasKey('total_topups', $stats);
        $this->assertArrayHasKey('total_order_payments', $stats);
        $this->assertArrayHasKey('total_refunds', $stats);
        $this->assertArrayHasKey('total_withdrawals', $stats);
        $this->assertArrayHasKey('orders_paid', $stats);
    }
}
