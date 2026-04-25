<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Services\CustomerWalletService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class WalletController extends Controller
{
    public function __construct(
        private CustomerWalletService $walletService,
    ) {}

    /**
     * Solde, stats et dernières transactions
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $balance = $this->walletService->getBalance($user);
        $stats = $this->walletService->getStatistics($user);

        return response()->json([
            'success' => true,
            'data' => array_merge($balance, [
                'statistics' => $stats,
            ]),
        ]);
    }

    /**
     * Recharger le wallet
     */
    public function topUp(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:100',
            'payment_method' => 'required|string|in:orange,mtn,moov,wave',
            'payment_reference' => 'nullable|string',
        ]);

        try {
            $transaction = $this->walletService->topUp(
                $request->user(),
                $request->amount,
                $request->payment_method,
                $request->payment_reference
            );

            $balance = $this->walletService->getBalance($request->user());

            return response()->json([
                'success' => true,
                'message' => 'Rechargement effectué avec succès',
                'data' => [
                    'transaction' => $this->formatTransaction($transaction),
                    'wallet' => $balance,
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Customer wallet top-up failed', [
                'user_id' => $request->user()->id,
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
     * Demander un retrait
     */
    public function withdraw(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:500',
            'payment_method' => 'required|string|in:orange,mtn,moov,wave',
            'phone_number' => 'required|string|max:20',
        ]);

        $user = $request->user();

        // SECURITY: verrou atomique pour empêcher les retraits concurrents (double-clic, retry).
        // TTL court (60s) couvrant largement la latence Jeko. Lock distribué via cache store.
        $lock = Cache::lock("customer_withdraw_user_{$user->id}", 60);

        if (!$lock->get()) {
            Log::warning('Customer withdrawal: concurrent request blocked', [
                'user_id' => $user->id,
                'amount' => $request->amount,
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Un retrait est déjà en cours. Veuillez patienter.',
            ], 429);
        }

        try {
            $transaction = $this->walletService->requestWithdrawal(
                $user,
                $request->amount,
                $request->payment_method,
                $request->phone_number
            );

            $balance = $this->walletService->getBalance($user);

            return response()->json([
                'success' => true,
                'message' => 'Demande de retrait enregistrée',
                'data' => [
                    'transaction' => $this->formatTransaction($transaction),
                    'wallet' => $balance,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        } finally {
            $lock->release();
        }
    }

    /**
     * Historique des transactions
     */
    public function transactions(Request $request)
    {
        $request->validate([
            'limit' => 'nullable|integer|min:1|max:100',
            'category' => 'nullable|string|in:topup,order_payment,refund,withdrawal',
        ]);

        $limit = min($request->input('limit', 50), 100);
        $category = $request->input('category');

        $transactions = $this->walletService->getTransactionHistory(
            $request->user(),
            $limit,
            $category
        );

        $formatted = $transactions->map(fn ($tx) => $this->formatTransaction($tx));

        return response()->json([
            'success' => true,
            'data' => $formatted,
        ]);
    }

    /**
     * Payer une commande avec le wallet
     */
    public function payOrder(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:1',
            'order_reference' => 'required|string',
        ]);

        try {
            $transaction = $this->walletService->payOrder(
                $request->user(),
                $request->amount,
                $request->order_reference
            );

            $balance = $this->walletService->getBalance($request->user());

            return response()->json([
                'success' => true,
                'message' => 'Paiement effectué',
                'data' => [
                    'transaction' => $this->formatTransaction($transaction),
                    'wallet' => $balance,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 400);
        }
    }

    private function formatTransaction($tx): array
    {
        return [
            'id' => $tx->id,
            'type' => $tx->type,
            'category' => $tx->category,
            'amount' => (float) $tx->amount,
            'balance_after' => (float) $tx->balance_after,
            'reference' => $tx->reference,
            'description' => $tx->description,
            'status' => $tx->status,
            'payment_method' => $tx->payment_method,
            'created_at' => $tx->created_at->toIso8601String(),
        ];
    }
}
