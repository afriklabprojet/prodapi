<?php

namespace App\Http\Controllers\Api\Courier;

use App\Http\Controllers\Controller;
use App\Services\WalletService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class WalletController extends Controller
{
    public function __construct(
        private WalletService $walletService,
    ) {}

    /**
     * Get wallet balance and info
     */
    public function index(Request $request)
    {
        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur non trouvé',
            ], 403);
        }

        $balance = $this->walletService->getBalance($courier);
        $stats = $this->walletService->getStatistics($courier);
        $transactions = $this->walletService->getTransactionHistory($courier, 20);

        $formattedTransactions = $transactions->map(function ($tx) {
            return [
                'id' => $tx->id,
                'type' => $tx->type,
                'category' => $tx->category,
                'amount' => (float) $tx->amount,
                'balance_after' => (float) $tx->balance_after,
                'reference' => $tx->reference,
                'description' => $tx->description,
                'status' => $tx->status,
                'delivery_id' => $tx->delivery_id,
                'created_at' => $tx->created_at->toIso8601String(),
            ];
        });

        return response()->json([
            'success' => true,
            'status' => 'success',
            'data' => array_merge($balance, [
                'pending_payouts' => $balance['pending_withdrawals'] ?? 0,
                'total_topups' => $stats['total_topups'] ?? 0,
                'total_earnings' => $stats['total_delivery_earnings'] ?? ($stats['total_earnings'] ?? 0),
                'total_commissions' => $stats['total_commissions'] ?? 0,
                'deliveries_count' => $stats['deliveries_count'] ?? 0,
                'statistics' => $stats,
                'transactions' => $formattedTransactions,
            ]),
        ]);
    }

    /**
     * Top up wallet (requires a confirmed JEKO payment reference)
     * 
     * SECURITY H-3: payment_reference is now REQUIRED and verified against
     * a real JekoPayment record that must be in SUCCESS status, belong to
     * the authenticated user, and not already consumed.
     * The wallet topup is now handled automatically by ProcessPaymentResultJob
     * when the JEKO webhook confirms. This endpoint is kept for manual/legacy
     * flows but is now safe against forged references.
     */
    public function topUp(Request $request)
    {
        $validated = $request->validate([
            'amount' => 'required|numeric|min:100|max:1000000',
            'payment_method' => 'required|string|in:orange,orange_money,mtn,mtn_money,moov,moov_money,wave,djamo',
            'payment_reference' => 'required|string',
        ]);

        $validated['payment_method'] = match ($validated['payment_method']) {
            'orange_money' => 'orange',
            'mtn_money' => 'mtn',
            'moov_money' => 'moov',
            default => $validated['payment_method'],
        };

        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur non trouvé',
            ], 403);
        }

        // SÉCURITÉ H-3: Vérifier que la référence de paiement correspond à un
        // JekoPayment confirmé, appartenant à cet utilisateur, et non déjà consommé
        $jekoPayment = \App\Models\JekoPayment::where('reference', $validated['payment_reference'])
            ->where('user_id', $request->user()->id)
            ->first();

        if (!$jekoPayment) {
            return response()->json([
                'success' => false,
                'message' => 'Référence de paiement invalide',
            ], 400);
        }

        if (!$jekoPayment->isSuccess()) {
            return response()->json([
                'success' => false,
                'message' => 'Ce paiement n\'a pas été confirmé',
            ], 400);
        }

        if ($jekoPayment->business_processed) {
            return response()->json([
                'success' => false,
                'message' => 'Ce paiement a déjà été traité',
            ], 409);
        }

        // Vérifier la cohérence du montant (centimes → FCFA)
        $expectedAmount = (float) $jekoPayment->amount_cents / 100;
        if (abs($expectedAmount - (float) $validated['amount']) > 0.01) {
            Log::warning('Wallet topUp: amount mismatch', [
                'courier_id' => $courier->id,
                'request_amount' => $validated['amount'],
                'jeko_amount' => $expectedAmount,
                'reference' => $validated['payment_reference'],
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Montant incohérent avec le paiement',
            ], 400);
        }

        try {
            $transaction = $this->walletService->topUp(
                $courier,
                $validated['amount'],
                $validated['payment_method'],
                $validated['payment_reference']
            );

            // Marquer le JekoPayment comme traité (idempotence)
            $jekoPayment->update(['business_processed' => true]);

            $balance = $this->walletService->getBalance($courier);

            return response()->json([
                'success' => true,
                'status' => 'success',
                'message' => 'Rechargement effectué avec succès',
                'data' => [
                    'transaction' => [
                        'id' => $transaction->id,
                        'amount' => (float) $transaction->amount,
                        'balance_after' => (float) ($transaction->balance_after ?? $balance['balance']),
                        'reference' => $transaction->reference,
                        'status' => $transaction->status,
                    ],
                    'wallet' => [
                        'balance' => $balance['balance'],
                        'currency' => $balance['currency'],
                        'can_deliver' => $balance['can_deliver'],
                    ],
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Wallet top-up failed', [
                'courier_id' => $courier->id,
                'amount' => $request->amount,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        }
    }

    /**
     * Request a withdrawal
     */
    public function withdraw(Request $request)
    {
        $validated = $request->validate([
            'amount' => 'required|numeric|min:500',
            'payment_method' => 'required|string|in:orange,orange_money,mtn,mtn_money,moov,moov_money,wave,djamo',
            'phone_number' => ['required', 'string', 'max:20', 'regex:/^\+?[0-9]{8,20}$/'],
        ]);

        $validated['payment_method'] = match ($validated['payment_method']) {
            'orange_money' => 'orange',
            'mtn_money' => 'mtn',
            'moov_money' => 'moov',
            default => $validated['payment_method'],
        };

        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur non trouvé',
            ], 403);
        }

        try {
            $result = $this->walletService->requestWithdrawal(
                $courier,
                $validated['amount'],
                $validated['payment_method'],
                $validated['phone_number']
            );

            $transaction = $result['transaction'];
            $withdrawalRequest = $result['withdrawal_request'];
            $balance = $this->walletService->getBalance($courier);

            return response()->json([
                'success' => true,
                'status' => 'success',
                'message' => 'Demande de retrait enregistrée',
                'data' => [
                    'withdrawal_request' => [
                        'id' => $withdrawalRequest->id,
                        'reference' => $withdrawalRequest->reference,
                        'status' => $withdrawalRequest->status,
                    ],
                    'transaction' => [
                        'id' => $transaction->id,
                        'amount' => (float) $transaction->amount,
                        'reference' => $transaction->reference,
                        'status' => $transaction->status,
                    ],
                    'wallet' => [
                        'balance' => $balance['balance'],
                        'available_balance' => $balance['available_balance'],
                        'currency' => $balance['currency'],
                    ],
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        }
    }

    /**
     * Check if courier can deliver (sufficient balance)
     */
    public function canDeliver(Request $request)
    {
        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur non trouvé',
            ], 403);
        }

        $canDeliver = $this->walletService->canCompleteDelivery($courier);
        $balance = $this->walletService->getBalance($courier);
        $commissionAmount = WalletService::getCommissionAmount();

        return response()->json([
            'success' => true,
            'data' => [
                'can_deliver' => $canDeliver,
                'balance' => $balance['balance'],
                'commission_amount' => $commissionAmount,
                'minimum_balance' => $commissionAmount,
                'currency' => $balance['currency'],
            ],
        ]);
    }

    /**
     * Get earnings history
     */
    public function earningsHistory(Request $request)
    {
        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur non trouvé',
            ], 403);
        }

        $limit = min($request->input('limit', 50), 100);
        $transactions = $this->walletService->getTransactionHistory($courier, $limit);

        $formatted = $transactions->map(function ($tx) {
            return [
                'id' => $tx->id,
                'type' => $tx->type,
                'category' => $tx->category,
                'amount' => (float) $tx->amount,
                'balance_after' => (float) $tx->balance_after,
                'reference' => $tx->reference,
                'description' => $tx->description,
                'status' => $tx->status,
                'created_at' => $tx->created_at->toIso8601String(),
            ];
        });

        return response()->json([
            'success' => true,
            'status' => 'success',
            'data' => [
                'transactions' => $formatted,
                'totals' => [
                    'count' => $formatted->count(),
                    'credits' => (float) $transactions->where('type', 'CREDIT')->sum('amount'),
                    'debits' => (float) $transactions->where('type', 'DEBIT')->sum('amount'),
                ],
                'pagination' => [
                    'limit' => $limit,
                    'returned' => $formatted->count(),
                ],
            ],
        ]);
    }
}
