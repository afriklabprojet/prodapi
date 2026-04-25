<?php

namespace App\Jobs;

use App\Mail\AdminAlertMail;
use App\Models\Wallet;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

/**
 * Audit quotidien des soldes wallets.
 * Compare le solde stocké avec la somme des transactions.
 * Alerte si des écarts sont détectés.
 *
 * Exécuté tous les jours à 2h du matin.
 */
class ReconcileWalletBalancesJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public int $timeout = 300;

    public function middleware(): array
    {
        return [new WithoutOverlapping('reconcile-wallet-balances')];
    }

    public function handle(): void
    {
        $discrepancies = [];
        $checked = 0;

        // Note: pas d'eager-load walletable car le wallet "platform" n'a pas de classe morph
        // (walletable_type='platform', walletable_id=0 est un singleton système).
        Wallet::chunk(100, function ($wallets) use (&$discrepancies, &$checked) {
            foreach ($wallets as $wallet) {
                $checked++;

                $creditSum = $wallet->transactions()
                    ->where('type', 'CREDIT')
                    ->where('status', 'completed')
                    ->sum('amount');

                $debitSum = $wallet->transactions()
                    ->where('type', 'DEBIT')
                    ->where('status', 'completed')
                    ->sum('amount');

                $expectedBalance = round((float) $creditSum - (float) $debitSum, 2);
                $actualBalance = round((float) $wallet->balance, 2);
                $diff = round($actualBalance - $expectedBalance, 2);

                if (abs($diff) > 0.01) {
                    // Résolution sûre du nom (évite MorphTo sur "platform")
                    $ownerName = 'N/A';
                    if ($wallet->walletable_type === 'platform') {
                        $ownerName = 'Plateforme';
                    } else {
                        try {
                            $ownerName = $wallet->walletable?->name ?? 'N/A';
                        } catch (\Throwable $e) {
                            $ownerName = 'N/A';
                        }
                    }

                    $discrepancies[] = [
                        'wallet_id' => $wallet->id,
                        'owner_type' => $wallet->walletable_type,
                        'owner_id' => $wallet->walletable_id,
                        'owner_name' => $ownerName,
                        'stored_balance' => $actualBalance,
                        'computed_balance' => $expectedBalance,
                        'difference' => $diff,
                    ];
                }
            }
        });

        if (count($discrepancies) > 0) {
            Log::warning('ReconcileWalletBalances: discrepancies found', [
                'count' => count($discrepancies),
                'discrepancies' => $discrepancies,
            ]);

            try {
                Mail::to(config('mail.admin_address', 'admin@drlpharma.com'))
                    ->send(new AdminAlertMail('wallet_reconciliation', [
                        'discrepancy_count' => count($discrepancies),
                        'total_checked' => $checked,
                        'discrepancies' => array_slice($discrepancies, 0, 20),
                    ]));
            } catch (\Throwable $e) {
                Log::debug('ReconcileWalletBalances: email notification failed', [
                    'error' => $e->getMessage(),
                ]);
            }
        }

        Log::info('ReconcileWalletBalances: complete', [
            'checked' => $checked,
            'discrepancies' => count($discrepancies),
        ]);
    }

    public function failed(\Throwable $exception): void
    {
        Log::error('ReconcileWalletBalancesJob failed', [
            'error' => $exception->getMessage(),
        ]);
    }
}
