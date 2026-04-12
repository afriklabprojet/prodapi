<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\WalletTransaction;
use App\Services\CustomerWalletService;
use Illuminate\Database\Eloquent\Collection as EloquentCollection;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CustomerWalletControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    private User $customer;

    protected function setUp(): void
    {
        parent::setUp();

        $this->customer = User::factory()->create([
            'role' => 'customer',
            'phone_verified_at' => now(),
            'must_change_password' => false,
        ]);
    }

    private function actingAsCustomer()
    {
        return $this->actingAs($this->customer, 'sanctum');
    }

    private function makeTx(array $attrs = []): WalletTransaction
    {
        $tx = new WalletTransaction(array_merge([
            'type' => 'credit',
            'category' => 'topup',
            'amount' => 5000,
            'balance_after' => 5000,
            'reference' => 'TX-123',
            'description' => 'Rechargement',
            'status' => 'completed',
            'payment_method' => 'orange',
        ], $attrs));
        $tx->id = 1;
        $tx->created_at = now();
        return $tx;
    }

    // ─── INDEX ───────────────────────────────────────────────────────────────

    public function test_index_returns_balance_and_stats(): void
    {
        $this->mock(CustomerWalletService::class, function ($mock) {
            $mock->shouldReceive('getBalance')->andReturn([
                'balance' => 5000,
                'currency' => 'XOF',
            ]);
            $mock->shouldReceive('getStatistics')->andReturn([
                'total_spent' => 10000,
                'total_topped_up' => 15000,
            ]);
        });

        $response = $this->actingAsCustomer()->getJson('/api/customer/wallet');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.balance', 5000)
            ->assertJsonPath('data.currency', 'XOF')
            ->assertJsonStructure(['data' => ['statistics']]);
    }

    public function test_index_requires_auth(): void
    {
        $this->getJson('/api/customer/wallet')->assertUnauthorized();
    }

    // ─── TOP UP ──────────────────────────────────────────────────────────────

    public function test_topup_success(): void
    {
        $tx = $this->makeTx();

        $this->mock(CustomerWalletService::class, function ($mock) use ($tx) {
            $mock->shouldReceive('topUp')->andReturn($tx);
            $mock->shouldReceive('getBalance')->andReturn([
                'balance' => 5000,
                'currency' => 'XOF',
            ]);
        });

        $response = $this->actingAsCustomer()->postJson('/api/customer/wallet/topup', [
            'amount' => 5000,
            'payment_method' => 'orange',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['transaction', 'wallet']]);
    }

    public function test_topup_validation_min_amount(): void
    {
        $response = $this->actingAsCustomer()->postJson('/api/customer/wallet/topup', [
            'amount' => 50,
            'payment_method' => 'orange',
        ]);

        $response->assertUnprocessable();
    }

    public function test_topup_validation_invalid_method(): void
    {
        $response = $this->actingAsCustomer()->postJson('/api/customer/wallet/topup', [
            'amount' => 1000,
            'payment_method' => 'bitcoin',
        ]);

        $response->assertUnprocessable();
    }

    public function test_topup_service_failure_returns_400(): void
    {
        $this->mock(CustomerWalletService::class, function ($mock) {
            $mock->shouldReceive('topUp')->andThrow(new \Exception('Paiement échoué'));
        });

        $response = $this->actingAsCustomer()->postJson('/api/customer/wallet/topup', [
            'amount' => 5000,
            'payment_method' => 'orange',
        ]);

        $response->assertStatus(400)
            ->assertJsonPath('success', false);
    }

    // ─── WITHDRAW ────────────────────────────────────────────────────────────

    public function test_withdraw_success(): void
    {
        $tx = $this->makeTx(['type' => 'debit', 'category' => 'withdrawal', 'amount' => 2000, 'balance_after' => 3000, 'reference' => 'WD-123', 'description' => 'Retrait', 'status' => 'pending', 'payment_method' => 'mtn']);

        $this->mock(CustomerWalletService::class, function ($mock) use ($tx) {
            $mock->shouldReceive('requestWithdrawal')->andReturn($tx);
            $mock->shouldReceive('getBalance')->andReturn([
                'balance' => 3000,
                'currency' => 'XOF',
            ]);
        });

        $response = $this->actingAsCustomer()->postJson('/api/customer/wallet/withdraw', [
            'amount' => 2000,
            'payment_method' => 'mtn',
            'phone_number' => '+22507000001',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_withdraw_validation(): void
    {
        $response = $this->actingAsCustomer()->postJson('/api/customer/wallet/withdraw', [
            'amount' => 100, // Below 500 min
            'payment_method' => 'mtn',
            'phone_number' => '+22507000001',
        ]);

        $response->assertUnprocessable();
    }

    public function test_withdraw_insufficient_balance_returns_error(): void
    {
        $this->mock(CustomerWalletService::class, function ($mock) {
            $mock->shouldReceive('requestWithdrawal')
                ->andThrow(new \Exception('Solde insuffisant'));
        });

        $response = $this->actingAsCustomer()->postJson('/api/customer/wallet/withdraw', [
            'amount' => 50000,
            'payment_method' => 'wave',
            'phone_number' => '+22507000001',
        ]);

        $response->assertStatus(400);
    }

    // ─── TRANSACTIONS ────────────────────────────────────────────────────────

    public function test_transactions_returns_history(): void
    {
        $tx = $this->makeTx(['reference' => 'TX-1']);

        $this->mock(CustomerWalletService::class, function ($mock) use ($tx) {
            $mock->shouldReceive('getTransactionHistory')->andReturn(new EloquentCollection([$tx]));
        });

        $response = $this->actingAsCustomer()->getJson('/api/customer/wallet/transactions');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(1, 'data');
    }

    public function test_transactions_with_category_filter(): void
    {
        $this->mock(CustomerWalletService::class, function ($mock) {
            $mock->shouldReceive('getTransactionHistory')
                ->with(\Mockery::any(), 50, 'topup')
                ->andReturn(new EloquentCollection([]));
        });

        $response = $this->actingAsCustomer()->getJson('/api/customer/wallet/transactions?category=topup');

        $response->assertOk();
    }

    public function test_transactions_with_limit(): void
    {
        $this->mock(CustomerWalletService::class, function ($mock) {
            $mock->shouldReceive('getTransactionHistory')
                ->with(\Mockery::any(), 10, null)
                ->andReturn(new EloquentCollection([]));
        });

        $response = $this->actingAsCustomer()->getJson('/api/customer/wallet/transactions?limit=10');

        $response->assertOk();
    }

    // ─── PAY ORDER ───────────────────────────────────────────────────────────

    public function test_pay_order_success(): void
    {
        $tx = $this->makeTx(['type' => 'debit', 'category' => 'order_payment', 'amount' => 3500, 'balance_after' => 1500, 'reference' => 'PAY-123', 'description' => 'Paiement commande', 'payment_method' => 'wallet']);

        $this->mock(CustomerWalletService::class, function ($mock) use ($tx) {
            $mock->shouldReceive('payOrder')->andReturn($tx);
            $mock->shouldReceive('getBalance')->andReturn([
                'balance' => 1500,
                'currency' => 'XOF',
            ]);
        });

        $response = $this->actingAsCustomer()->postJson('/api/customer/wallet/pay-order', [
            'amount' => 3500,
            'order_reference' => 'ORD-ABC123',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_pay_order_validation(): void
    {
        $response = $this->actingAsCustomer()->postJson('/api/customer/wallet/pay-order', []);

        $response->assertUnprocessable();
    }

    public function test_pay_order_insufficient_balance(): void
    {
        $this->mock(CustomerWalletService::class, function ($mock) {
            $mock->shouldReceive('payOrder')
                ->andThrow(new \Exception('Solde insuffisant'));
        });

        $response = $this->actingAsCustomer()->postJson('/api/customer/wallet/pay-order', [
            'amount' => 100000,
            'order_reference' => 'ORD-XYZ',
        ]);

        $response->assertStatus(400);
    }
}
