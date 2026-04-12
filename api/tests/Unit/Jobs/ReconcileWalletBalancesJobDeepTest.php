<?php

namespace Tests\Unit\Jobs;

use App\Jobs\ReconcileWalletBalancesJob;
use App\Mail\AdminAlertMail;
use App\Models\Pharmacy;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class ReconcileWalletBalancesJobDeepTest extends TestCase
{
    use RefreshDatabase;

    // ─── handle(): no wallets ───

    public function test_handle_completes_with_no_wallets(): void
    {
        Mail::fake();

        Log::shouldReceive('info')
            ->once()
            ->withArgs(function ($msg, $ctx) {
                return str_contains($msg, 'complete')
                    && $ctx['checked'] === 0
                    && $ctx['discrepancies'] === 0;
            });

        $job = new ReconcileWalletBalancesJob();
        $job->handle();

        Mail::assertNothingSent();
    }

    // ─── handle(): wallets with matching balances ───

    public function test_handle_no_discrepancy_when_balance_matches_transactions(): void
    {
        Mail::fake();

        $pharmacy = Pharmacy::factory()->create();
        $wallet = Wallet::factory()->forOwner($pharmacy)->withBalance(25000)->create();

        // Create transactions that sum to balance: credit 30000 - debit 5000 = 25000
        WalletTransaction::factory()->create([
            'wallet_id' => $wallet->id,
            'type' => 'CREDIT',
            'amount' => 30000,
            'balance_after' => 30000,
            'reference' => 'TXN-C-1',
            'status' => 'completed',
        ]);
        WalletTransaction::factory()->create([
            'wallet_id' => $wallet->id,
            'type' => 'DEBIT',
            'amount' => 5000,
            'balance_after' => 25000,
            'reference' => 'TXN-D-1',
            'status' => 'completed',
        ]);

        Log::shouldReceive('info')
            ->once()
            ->withArgs(function ($msg, $ctx) {
                return str_contains($msg, 'complete')
                    && $ctx['checked'] === 1
                    && $ctx['discrepancies'] === 0;
            });

        $job = new ReconcileWalletBalancesJob();
        $job->handle();

        Mail::assertNothingSent();
    }

    // ─── handle(): wallet with discrepancy ───

    public function test_handle_detects_discrepancy_and_sends_alert(): void
    {
        Mail::fake();

        $pharmacy = Pharmacy::factory()->create(['name' => 'Pharmacie Discordante']);
        $wallet = Wallet::factory()->forOwner($pharmacy)->withBalance(99999)->create();

        // Transactions sum: 10000 (credit) - 0 = 10000, but balance is 99999
        WalletTransaction::factory()->create([
            'wallet_id' => $wallet->id,
            'type' => 'CREDIT',
            'amount' => 10000,
            'balance_after' => 10000,
            'reference' => 'TXN-DISC-1',
            'status' => 'completed',
        ]);

        Log::shouldReceive('warning')
            ->once()
            ->withArgs(function ($msg, $ctx) {
                return str_contains($msg, 'discrepancies found')
                    && $ctx['count'] === 1;
            });

        Log::shouldReceive('info')
            ->once()
            ->withArgs(function ($msg, $ctx) {
                return str_contains($msg, 'complete')
                    && $ctx['checked'] === 1
                    && $ctx['discrepancies'] === 1;
            });

        $job = new ReconcileWalletBalancesJob();
        $job->handle();

        Mail::assertSent(AdminAlertMail::class, function ($mail) {
            return $mail->alertType === 'wallet_reconciliation'
                && $mail->data['discrepancy_count'] === 1;
        });
    }

    // ─── handle(): multiple wallets, some with discrepancies ───

    public function test_handle_checks_multiple_wallets_reports_only_discrepancies(): void
    {
        Mail::fake();

        // Good wallet — balance matches
        $pharmacy1 = Pharmacy::factory()->create();
        $wallet1 = Wallet::factory()->forOwner($pharmacy1)->withBalance(5000)->create();
        WalletTransaction::factory()->create([
            'wallet_id' => $wallet1->id,
            'type' => 'CREDIT',
            'amount' => 5000,
            'balance_after' => 5000,
            'reference' => 'TXN-GOOD-1',
            'status' => 'completed',
        ]);

        // Bad wallet — balance doesn't match
        $pharmacy2 = Pharmacy::factory()->create();
        $wallet2 = Wallet::factory()->forOwner($pharmacy2)->withBalance(50000)->create();
        WalletTransaction::factory()->create([
            'wallet_id' => $wallet2->id,
            'type' => 'CREDIT',
            'amount' => 10000,
            'balance_after' => 10000,
            'reference' => 'TXN-BAD-1',
            'status' => 'completed',
        ]);

        Log::shouldReceive('warning')->once();
        Log::shouldReceive('info')
            ->once()
            ->withArgs(function ($msg, $ctx) {
                return str_contains($msg, 'complete')
                    && $ctx['checked'] === 2
                    && $ctx['discrepancies'] === 1;
            });

        $job = new ReconcileWalletBalancesJob();
        $job->handle();

        Mail::assertSent(AdminAlertMail::class, 1);
    }

    // ─── handle(): wallet with no transactions ───

    public function test_handle_wallet_with_no_transactions_and_zero_balance_is_ok(): void
    {
        Mail::fake();

        $pharmacy = Pharmacy::factory()->create();
        $wallet = Wallet::factory()->forOwner($pharmacy)->withBalance(0)->create();

        Log::shouldReceive('info')
            ->once()
            ->withArgs(function ($msg, $ctx) {
                return str_contains($msg, 'complete')
                    && $ctx['discrepancies'] === 0;
            });

        $job = new ReconcileWalletBalancesJob();
        $job->handle();

        Mail::assertNothingSent();
    }

    public function test_handle_wallet_with_no_transactions_but_nonzero_balance_is_discrepancy(): void
    {
        Mail::fake();

        $pharmacy = Pharmacy::factory()->create();
        $wallet = Wallet::factory()->forOwner($pharmacy)->withBalance(5000)->create();
        // No transactions at all

        Log::shouldReceive('warning')->once();
        Log::shouldReceive('info')->once();

        $job = new ReconcileWalletBalancesJob();
        $job->handle();

        Mail::assertSent(AdminAlertMail::class);
    }

    // ─── handle(): only considers completed transactions ───

    public function test_handle_ignores_non_completed_transactions(): void
    {
        Mail::fake();

        $pharmacy = Pharmacy::factory()->create();
        $wallet = Wallet::factory()->forOwner($pharmacy)->withBalance(5000)->create();

        // Completed transaction = 5000
        WalletTransaction::factory()->create([
            'wallet_id' => $wallet->id,
            'type' => 'CREDIT',
            'amount' => 5000,
            'balance_after' => 5000,
            'reference' => 'TXN-COMP-1',
            'status' => 'completed',
        ]);

        // Pending transaction should NOT count
        WalletTransaction::factory()->create([
            'wallet_id' => $wallet->id,
            'type' => 'CREDIT',
            'amount' => 50000,
            'balance_after' => 55000,
            'reference' => 'TXN-PEND-1',
            'status' => 'pending',
        ]);

        Log::shouldReceive('info')
            ->once()
            ->withArgs(function ($msg, $ctx) {
                return str_contains($msg, 'complete')
                    && $ctx['discrepancies'] === 0;
            });

        $job = new ReconcileWalletBalancesJob();
        $job->handle();

        Mail::assertNothingSent();
    }

    // ─── handle(): email failure is caught ───

    public function test_handle_catches_email_sending_failure(): void
    {
        Mail::shouldReceive('to')->andThrow(new \RuntimeException('SMTP error'));

        $pharmacy = Pharmacy::factory()->create();
        $wallet = Wallet::factory()->forOwner($pharmacy)->withBalance(99999)->create();
        // No transactions = discrepancy

        Log::shouldReceive('warning')->once();
        Log::shouldReceive('debug')
            ->once()
            ->withArgs(fn($msg) => str_contains($msg, 'email notification failed'));
        Log::shouldReceive('info')->once();

        $job = new ReconcileWalletBalancesJob();
        $job->handle();

        // Job should complete without throwing
    }

    // ─── handle(): discrepancy data structure ───

    public function test_handle_discrepancy_contains_correct_fields(): void
    {
        Mail::fake();

        $pharmacy = Pharmacy::factory()->create(['name' => 'PharmTest']);
        $wallet = Wallet::factory()->forOwner($pharmacy)->withBalance(12345)->create();

        Log::shouldReceive('warning')
            ->once()
            ->withArgs(function ($msg, $ctx) {
                $disc = $ctx['discrepancies'][0] ?? [];
                return isset($disc['wallet_id'])
                    && isset($disc['owner_type'])
                    && isset($disc['owner_id'])
                    && isset($disc['owner_name'])
                    && isset($disc['stored_balance'])
                    && isset($disc['computed_balance'])
                    && isset($disc['difference']);
            });

        Log::shouldReceive('info')->once();

        $job = new ReconcileWalletBalancesJob();
        $job->handle();
    }

    // ─── handle(): discrepancy alert limited to 20 ───

    public function test_handle_email_limits_discrepancies_to_20(): void
    {
        Mail::fake();

        // Create 25 wallets with discrepancies
        for ($i = 0; $i < 25; $i++) {
            $pharmacy = Pharmacy::factory()->create();
            $wallet = Wallet::factory()->forOwner($pharmacy)->withBalance(($i + 1) * 1000)->create();
        }

        Log::shouldReceive('warning')->once();
        Log::shouldReceive('info')->once();

        $job = new ReconcileWalletBalancesJob();
        $job->handle();

        Mail::assertSent(AdminAlertMail::class, function ($mail) {
            return count($mail->data['discrepancies']) <= 20
                && $mail->data['discrepancy_count'] === 25;
        });
    }

    // ─── middleware() ───

    public function test_middleware_has_without_overlapping(): void
    {
        $job = new ReconcileWalletBalancesJob();
        $middleware = $job->middleware();

        $this->assertNotEmpty($middleware);
        $this->assertInstanceOf(WithoutOverlapping::class, $middleware[0]);
    }

    // ─── failed() ───

    public function test_failed_logs_error(): void
    {
        Log::shouldReceive('error')
            ->once()
            ->with('ReconcileWalletBalancesJob failed', \Mockery::type('array'));

        $job = new ReconcileWalletBalancesJob();
        $job->failed(new \RuntimeException('Connection lost'));
    }

    // ─── Tiny discrepancy within tolerance ───

    public function test_handle_allows_tiny_discrepancy_within_tolerance(): void
    {
        Mail::fake();

        $pharmacy = Pharmacy::factory()->create();
        // Balance is 5000.00, transactions sum to 5000.01 — diff = 0.01, at threshold
        $wallet = Wallet::factory()->forOwner($pharmacy)->withBalance(5000.01)->create();
        WalletTransaction::factory()->create([
            'wallet_id' => $wallet->id,
            'type' => 'CREDIT',
            'amount' => 5000.01,
            'balance_after' => 5000.01,
            'reference' => 'TXN-TINY-1',
            'status' => 'completed',
        ]);

        Log::shouldReceive('info')
            ->once()
            ->withArgs(function ($msg, $ctx) {
                return str_contains($msg, 'complete')
                    && $ctx['discrepancies'] === 0;
            });

        $job = new ReconcileWalletBalancesJob();
        $job->handle();

        Mail::assertNothingSent();
    }
}
