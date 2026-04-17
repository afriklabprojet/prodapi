<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Rembourser le retrait échoué de 5000 CFA (wallet_transaction id=2, reference CWTH-DQYOD5WN)
 * Le retrait Jeko a échoué mais le wallet n'a jamais été remboursé.
 */
return new class extends Migration
{
    public function up(): void
    {
        // Vérifier que la transaction existe et est toujours failed
        $failedTx = DB::table('wallet_transactions')
            ->where('id', 2)
            ->where('reference', 'CWTH-DQYOD5WN')
            ->where('status', 'failed')
            ->where('type', 'DEBIT')
            ->where('amount', 5000)
            ->first();

        if (!$failedTx) {
            Log::info('Migration refund: transaction CWTH-DQYOD5WN not found or already refunded, skipping');
            return;
        }

        // Vérifier qu'aucun remboursement n'existe déjà
        $existingRefund = DB::table('wallet_transactions')
            ->where('reference', 'REFUND-CWTH-DQYOD5WN')
            ->exists();

        if ($existingRefund) {
            Log::info('Migration refund: refund already exists for CWTH-DQYOD5WN, skipping');
            return;
        }

        $walletId = $failedTx->wallet_id;
        $wallet = DB::table('wallets')->where('id', $walletId)->first();

        if (!$wallet) {
            Log::error('Migration refund: wallet not found', ['wallet_id' => $walletId]);
            return;
        }

        DB::transaction(function () use ($wallet, $walletId) {
            $newBalance = (float) $wallet->balance + 5000;

            // Créer la transaction de remboursement
            DB::table('wallet_transactions')->insert([
                'wallet_id' => $walletId,
                'type' => 'CREDIT',
                'amount' => 5000,
                'balance_after' => $newBalance,
                'reference' => 'REFUND-CWTH-DQYOD5WN',
                'description' => 'Remboursement retrait échoué du 18/03/2026 (correction automatique)',
                'metadata' => json_encode(['original_reference' => 'CWTH-DQYOD5WN', 'reason' => 'jeko_payout_failed_no_refund']),
                'category' => 'refund',
                'status' => 'completed',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // Mettre à jour le solde du wallet
            DB::table('wallets')
                ->where('id', $walletId)
                ->update([
                    'balance' => $newBalance,
                    'updated_at' => now(),
                ]);

            // Marquer la transaction originale comme remboursée
            DB::table('wallet_transactions')
                ->where('id', 2)
                ->update([
                    'status' => 'refunded',
                    'updated_at' => now(),
                ]);

            Log::info('Migration refund: 5000 CFA refunded to wallet', [
                'wallet_id' => $walletId,
                'new_balance' => $newBalance,
            ]);
        });
    }

    public function down(): void
    {
        // Supprimer le remboursement si rollback
        $refund = DB::table('wallet_transactions')
            ->where('reference', 'REFUND-CWTH-DQYOD5WN')
            ->first();

        if ($refund) {
            $walletId = $refund->wallet_id;

            DB::transaction(function () use ($walletId, $refund) {
                DB::table('wallet_transactions')
                    ->where('reference', 'REFUND-CWTH-DQYOD5WN')
                    ->delete();

                DB::table('wallets')
                    ->where('id', $walletId)
                    ->decrement('balance', 5000);

                DB::table('wallet_transactions')
                    ->where('id', 2)
                    ->update(['status' => 'failed', 'updated_at' => now()]);
            });
        }
    }
};
