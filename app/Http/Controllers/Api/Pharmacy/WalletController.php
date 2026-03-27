<?php

namespace App\Http\Controllers\Api\Pharmacy;

use App\Enums\JekoPaymentMethod;
use App\Http\Controllers\Controller;
use App\Models\Pharmacy;
use App\Models\Setting;
use App\Models\WithdrawalRequest;
use App\Services\JekoPaymentService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class WalletController extends Controller
{
    protected ?JekoPaymentService $jekoService;

    public function __construct(?JekoPaymentService $jekoService = null)
    {
        $this->jekoService = $jekoService;
    }

    /**
     * Get wallet balance and transaction history
     */
    public function index(Request $request)
    {
        $user = Auth::user();
        
        // Find pharmacy associated with user
        $pharmacy = $user->pharmacies()->firstOrFail();
        
        // Retrieve or create wallet
        $wallet = $pharmacy->wallet()->firstOrCreate([], [
            'currency' => 'XOF',
            'balance' => 0
        ]);
        
        // Get recent transactions (30 dernières pour l'affichage)
        $transactions = $wallet->transactions()
            ->latest()
            ->limit(30)
            ->get()
            ->map(function ($tx) {
                return [
                    'id' => $tx->id,
                    'amount' => $tx->amount,
                    'type' => $tx->type, // credit/debit
                    'description' => $tx->description,
                    'reference' => $tx->reference,
                    'date' => $tx->created_at->format('d/m/Y H:i'),
                ];
            });
        
        // Calculer le total des gains sur TOUTES les transactions (pas seulement les 30 dernières)
        $totalEarnings = $wallet->transactions()->where('type', 'credit')->sum('amount');
        $totalCommissionPaid = $wallet->transactions()->where('type', 'debit')->sum('amount');
            
        return response()->json([
            'status' => 'success',
            'data' => [
                'balance' => $wallet->balance,
                'currency' => $wallet->currency,
                'transactions' => $transactions,
                'total_earnings' => $totalEarnings,
                'total_commission_paid' => $totalCommissionPaid,
            ]
        ]);
    }

    /**
     * Get wallet statistics for a period
     */
    public function stats(Request $request)
    {
        $user = Auth::user();
        $pharmacy = $user->pharmacies()->firstOrFail();
        $wallet = $pharmacy->wallet;
        
        if (!$wallet) {
            return response()->json([
                'status' => 'success',
                'data' => [
                    'total_credits' => 0,
                    'total_debits' => 0,
                    'transaction_count' => 0,
                    'average_transaction' => 0,
                    'period' => $request->get('period', 'month'),
                ]
            ]);
        }
        
        $period = $request->get('period', 'month');
        $query = $wallet->transactions();
        
        // Filter by period
        switch ($period) {
            case 'today':
                $query->whereDate('created_at', now());
                break;
            case 'week':
                $query->where('created_at', '>=', now()->startOfWeek());
                break;
            case 'month':
                $query->where('created_at', '>=', now()->startOfMonth());
                break;
            case 'year':
                $query->where('created_at', '>=', now()->startOfYear());
                break;
        }
        
        $transactions = $query->selectRaw("
            COALESCE(SUM(CASE WHEN type = 'credit' THEN amount ELSE 0 END), 0) as total_credits,
            COALESCE(SUM(CASE WHEN type = 'debit' THEN amount ELSE 0 END), 0) as total_debits,
            COUNT(*) as tx_count
        ")->first();

        $totalCredits = (float) $transactions->total_credits;
        $totalDebits = (float) $transactions->total_debits;
        $count = (int) $transactions->tx_count;
        
        return response()->json([
            'status' => 'success',
            'data' => [
                'total_credits' => $totalCredits,
                'total_debits' => $totalDebits,
                'transaction_count' => $count,
                'average_transaction' => $count > 0 ? ($totalCredits + $totalDebits) / $count : 0,
                'period' => $period,
            ]
        ]);
    }

    /**
     * Request a withdrawal via JEKO Payment
     * REQUIRES: PIN configured + PIN confirmation
     */
    public function withdraw(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:1000',
            'payment_method' => 'required|in:bank,orange,mtn,moov,wave,djamo',
            'phone' => 'required_if:payment_method,orange,mtn,moov,wave,djamo|string',
            'bank_details' => 'required_if:payment_method,bank|array',
            'bank_details.bank_code' => 'required_if:payment_method,bank|string',
            'bank_details.account_number' => 'required_if:payment_method,bank|string',
            'bank_details.holder_name' => 'required_if:payment_method,bank|string',
            'pin' => 'required|string|digits:4', // PIN de confirmation requis
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Donnees invalides',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $user = Auth::user();
        $pharmacy = $user->pharmacies()->firstOrFail();
        
        // Vérifier si un PIN est configuré
        if (!$pharmacy->hasPinConfigured()) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Vous devez configurer un code PIN avant de faire un retrait',
                'code' => 'PIN_NOT_CONFIGURED'
            ], 400);
        }

        // Vérifier si le PIN est verrouillé
        if ($pharmacy->isPinLocked()) {
            $minutes = $pharmacy->pinLockRemainingMinutes();
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => "Code PIN verrouillé. Réessayez dans {$minutes} minutes.",
                'code' => 'PIN_LOCKED',
                'locked_until' => $pharmacy->pin_locked_until,
            ], 423);
        }

        // Vérifier le PIN
        if (!$pharmacy->verifyWithdrawalPin($request->pin)) {
            $remaining = 5 - $pharmacy->fresh()->pin_attempts;
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => "Code PIN incorrect. {$remaining} tentative(s) restante(s).",
                'code' => 'PIN_INVALID',
                'attempts_remaining' => $remaining,
            ], 401);
        }
        
        $wallet = $pharmacy->wallet;
        
        if (!$wallet || $wallet->balance < $request->amount) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Solde insuffisant'
            ], 400);
        }
        
        // Create withdrawal request record and debit wallet atomically
        $reference = 'WD-' . strtoupper(Str::random(8));
        
        try {
            $withdrawal = DB::transaction(function () use ($wallet, $pharmacy, $request, $reference) {
                // Relock wallet inside transaction
                $wallet = $wallet->lockForUpdate()->first() ?? $wallet->fresh();
                
                if ($wallet->balance < $request->amount) {
                    throw new \Exception('Solde insuffisant');
                }
            
            // Débiter le portefeuille avec création de transaction
            $wallet->debit($request->amount, $reference, 'Retrait en cours de traitement');
            
            return WithdrawalRequest::create([
                'wallet_id' => $wallet->id,
                'pharmacy_id' => $pharmacy->id,
                'amount' => $request->amount,
                'payment_method' => $request->payment_method,
                'phone' => $request->phone,
                'bank_details' => $request->bank_details,
                'reference' => $reference,
                'status' => 'pending',
            ]);
        });
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 400);
        }

        try {
            // Determine Jeko payment method
            $jekoMethod = $this->mapPaymentMethod($request->payment_method);
            $amountCents = (int) ($request->amount * 100);

            if ($request->payment_method === 'bank') {
                // Bank transfer payout
                $jekoPayment = $this->jekoService->createBankPayout(
                    $withdrawal,
                    $amountCents,
                    $request->bank_details,
                    $user,
                    "Retrait pharmacie {$pharmacy->name}"
                );
            } else {
                // Mobile Money payout
                $jekoPayment = $this->jekoService->createPayout(
                    $withdrawal,
                    $amountCents,
                    $request->phone,
                    $jekoMethod,
                    $user,
                    "Retrait pharmacie {$pharmacy->name}"
                );
            }

            // Update withdrawal with Jeko reference
            $withdrawal->update([
                'jeko_reference' => $jekoPayment->reference,
                'jeko_payment_id' => $jekoPayment->id,
                'status' => 'processing',
            ]);

            return response()->json([
                'success' => true,
                'status' => 'success',
                'message' => 'Retrait en cours de traitement via JEKO Pay',
                'data' => [
                    'reference' => $reference,
                    'jeko_reference' => $jekoPayment->reference,
                    'status' => 'processing',
                    'amount' => $request->amount,
                    'payment_method' => $request->payment_method,
                ]
            ]);

        } catch (\Exception $e) {
            // Rembourser le wallet et marquer comme échoué
            DB::transaction(function () use ($wallet, $withdrawal, $e) {
                $wallet->credit($withdrawal->amount, 'refund', 'Échec du retrait: ' . $e->getMessage());
                $withdrawal->update(['status' => 'failed', 'error_message' => $e->getMessage()]);
            });

            // Log l'erreur technique
            Log::error('Withdrawal failed', [
                'reference' => $reference ?? null,
                'pharmacy_id' => $pharmacy->id ?? null,
                'amount' => $request->amount,
                'error' => $e->getMessage(),
            ]);

            // Message user-friendly
            $userMessage = match (true) {
                str_contains($e->getMessage(), 'Cannot POST') => 'Service de paiement temporairement indisponible. Veuillez réessayer plus tard.',
                str_contains($e->getMessage(), 'timeout') => 'Le service de paiement met trop de temps à répondre. Veuillez réessayer.',
                str_contains($e->getMessage(), 'connexion') => 'Impossible de contacter le service de paiement. Vérifiez votre connexion.',
                default => 'Une erreur est survenue lors du retrait. Veuillez réessayer ou contacter le support.',
            };

            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => $userMessage,
                'code' => 'PAYOUT_ERROR',
            ], 500);
        }
    }

    /**
     * Map payment method string to JekoPaymentMethod enum (Côte d'Ivoire)
     */
    private function mapPaymentMethod(string $method): JekoPaymentMethod
    {
        return match ($method) {
            'orange' => JekoPaymentMethod::ORANGE,
            'mtn' => JekoPaymentMethod::MTN,
            'moov' => JekoPaymentMethod::MOOV,
            'wave' => JekoPaymentMethod::WAVE,
            'djamo' => JekoPaymentMethod::DJAMO,
            'bank' => JekoPaymentMethod::BANK_TRANSFER,
            default => JekoPaymentMethod::ORANGE, // Default to Orange
        };
    }

    /**
     * Save bank information
     */
    public function saveBankInfo(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'bank_name' => 'required|string|max:100',
            'holder_name' => 'required|string|max:100',
            'account_number' => 'required|string|max:50',
            'iban' => 'nullable|string|max:50',
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Donnees invalides',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $user = Auth::user();
        $pharmacy = $user->pharmacies()->firstOrFail();
        
        // Save or update payment info
        $pharmacy->paymentInfo()->updateOrCreate(
            ['type' => 'bank'],
            [
                'bank_name' => $request->bank_name,
                'holder_name' => $request->holder_name,
                'account_number' => $request->account_number,
                'iban' => $request->iban,
                'is_primary' => true,
            ]
        );
        
        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'Informations bancaires enregistrees'
        ]);
    }

    /**
     * Save Mobile Money information
     */
    public function saveMobileMoneyInfo(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'operator' => 'required|string|max:50',
            'phone_number' => 'required|string|max:20',
            'account_name' => 'required|string|max:100',
            'is_primary' => 'boolean',
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Donnees invalides',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $user = Auth::user();
        $pharmacy = $user->pharmacies()->firstOrFail();
        
        // If this is primary, unset others
        if ($request->get('is_primary', true)) {
            $pharmacy->paymentInfo()->where('type', 'mobile_money')->update(['is_primary' => false]);
        }
        
        // Save or update payment info
        $pharmacy->paymentInfo()->updateOrCreate(
            ['type' => 'mobile_money', 'phone_number' => $request->phone_number],
            [
                'operator' => $request->operator,
                'holder_name' => $request->account_name,
                'is_primary' => $request->get('is_primary', true),
            ]
        );
        
        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'Informations Mobile Money enregistrees'
        ]);
    }

    /**
     * Get withdrawal settings
     */
    public function getWithdrawalSettings()
    {
        $user = Auth::user();
        $pharmacy = $user->pharmacies()->firstOrFail();
        
        // Get global settings from Filament Settings
        $minThreshold = (int) Setting::get('withdrawal_threshold_min', 10000);
        $maxThreshold = (int) Setting::get('withdrawal_threshold_max', 500000);
        $defaultThreshold = (int) Setting::get('withdrawal_threshold_default', 50000);
        $stepThreshold = (int) Setting::get('withdrawal_threshold_step', 5000);
        $autoWithdrawGlobalEnabled = (bool) Setting::get('auto_withdraw_enabled_global', true);
        $requirePin = (bool) Setting::get('withdrawal_require_pin', true);
        $requireMobileMoney = (bool) Setting::get('withdrawal_require_mobile_money', true);
        
        return response()->json([
            'success' => true,
            'status' => 'success',
            'data' => [
                'threshold' => $pharmacy->withdrawal_threshold ?? $defaultThreshold,
                'auto_withdraw' => $pharmacy->auto_withdraw_enabled ?? false,
                'has_pin' => !empty($pharmacy->withdrawal_pin),
                'has_mobile_money' => $pharmacy->paymentInfo()->where('type', 'mobile_money')->exists(),
                'has_bank_info' => $pharmacy->paymentInfo()->where('type', 'bank')->exists(),
                // Global settings from Filament admin
                'config' => [
                    'min_threshold' => $minThreshold,
                    'max_threshold' => $maxThreshold,
                    'default_threshold' => $defaultThreshold,
                    'step' => $stepThreshold,
                    'auto_withdraw_allowed' => $autoWithdrawGlobalEnabled,
                    'require_pin' => $requirePin,
                    'require_mobile_money' => $requireMobileMoney,
                ],
            ]
        ]);
    }

    /**
     * Set withdrawal threshold
     */
    public function setWithdrawalThreshold(Request $request)
    {
        // Get global limits from Filament Settings
        $minThreshold = (int) Setting::get('withdrawal_threshold_min', 10000);
        $maxThreshold = (int) Setting::get('withdrawal_threshold_max', 500000);
        $autoWithdrawGlobalEnabled = (bool) Setting::get('auto_withdraw_enabled_global', true);
        
        $validator = Validator::make($request->all(), [
            'threshold' => "required|numeric|min:{$minThreshold}|max:{$maxThreshold}",
            'auto_withdraw' => 'required|boolean',
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Donnees invalides',
                'errors' => $validator->errors()
            ], 422);
        }
        
        // Check if auto-withdraw is globally allowed
        if ($request->auto_withdraw && !$autoWithdrawGlobalEnabled) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Le retrait automatique est desactive par l\'administrateur',
            ], 403);
        }
        
        $user = Auth::user();
        $pharmacy = $user->pharmacies()->firstOrFail();
        
        $pharmacy->update([
            'withdrawal_threshold' => $request->threshold,
            'auto_withdraw_enabled' => $request->auto_withdraw,
        ]);
        
        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'Seuil de retrait configure',
            'data' => [
                'threshold' => $pharmacy->withdrawal_threshold,
                'auto_withdraw' => $pharmacy->auto_withdraw_enabled,
            ]
        ]);
    }

    /**
     * Export transactions
     */
    public function exportTransactions(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'format' => 'required|in:pdf,excel,csv',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Donnees invalides',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $user = Auth::user();
        $pharmacy = $user->pharmacies()->firstOrFail();
        $wallet = $pharmacy->wallet;
        
        if (!$wallet) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Aucun portefeuille trouve'
            ], 404);
        }
        
        // Get transactions for the period
        $transactions = $wallet->transactions()
            ->whereBetween('created_at', [$request->start_date, $request->end_date])
            ->orderBy('created_at', 'desc')
            ->get();
        
        // For now, return a placeholder URL (in production, generate actual file)
        $filename = 'releve_' . now()->format('Y-m-d') . '.' . $request->format;
        
        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'Export genere',
            'download_url' => url('/exports/' . $filename),
            'transaction_count' => $transactions->count(),
        ]);
    }

    // ========================================================================
    // PIN MANAGEMENT
    // ========================================================================

    /**
     * Get PIN status
     */
    public function getPinStatus()
    {
        $user = Auth::user();
        $pharmacy = $user->pharmacies()->firstOrFail();

        return response()->json([
            'status' => 'success',
            'data' => [
                'has_pin' => $pharmacy->hasPinConfigured(),
                'pin_set_at' => $pharmacy->pin_set_at,
                'is_locked' => $pharmacy->isPinLocked(),
                'locked_until' => $pharmacy->pin_locked_until,
                'lock_remaining_minutes' => $pharmacy->pinLockRemainingMinutes(),
            ]
        ]);
    }

    /**
     * Set/Configure withdrawal PIN (first time)
     */
    public function setPin(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'pin' => 'required|string|digits:4',
            'pin_confirmation' => 'required|string|same:pin',
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Donnees invalides',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $user = Auth::user();
        $pharmacy = $user->pharmacies()->firstOrFail();

        // Si PIN déjà configuré, utiliser changePin
        if ($pharmacy->hasPinConfigured()) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Un code PIN est déjà configuré. Utilisez la modification de PIN.',
                'code' => 'PIN_ALREADY_SET'
            ], 400);
        }

        $pharmacy->setWithdrawalPin($request->pin);

        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'Code PIN configuré avec succès'
        ]);
    }

    /**
     * Change withdrawal PIN (requires current PIN)
     */
    public function changePin(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'current_pin' => 'required|string|digits:4',
            'new_pin' => 'required|string|digits:4|different:current_pin',
            'new_pin_confirmation' => 'required|string|same:new_pin',
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Donnees invalides',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $user = Auth::user();
        $pharmacy = $user->pharmacies()->firstOrFail();

        if (!$pharmacy->hasPinConfigured()) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Aucun code PIN configuré',
                'code' => 'PIN_NOT_SET'
            ], 400);
        }

        // Vérifier si verrouillé
        if ($pharmacy->isPinLocked()) {
            $minutes = $pharmacy->pinLockRemainingMinutes();
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => "Code PIN verrouillé. Réessayez dans {$minutes} minutes.",
                'code' => 'PIN_LOCKED',
            ], 423);
        }

        // Vérifier le PIN actuel
        if (!$pharmacy->verifyWithdrawalPin($request->current_pin)) {
            $remaining = 5 - $pharmacy->fresh()->pin_attempts;
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => "Code PIN actuel incorrect. {$remaining} tentative(s) restante(s).",
                'code' => 'PIN_INVALID',
            ], 401);
        }

        // Définir le nouveau PIN
        $pharmacy->setWithdrawalPin($request->new_pin);

        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'Code PIN modifié avec succès'
        ]);
    }

    /**
     * Verify PIN (for client-side confirmation dialogs)
     */
    public function verifyPin(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'pin' => 'required|string|digits:4',
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Code PIN requis',
            ], 422);
        }
        
        $user = Auth::user();
        $pharmacy = $user->pharmacies()->firstOrFail();

        if (!$pharmacy->hasPinConfigured()) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Aucun code PIN configuré',
                'code' => 'PIN_NOT_SET'
            ], 400);
        }

        if ($pharmacy->isPinLocked()) {
            $minutes = $pharmacy->pinLockRemainingMinutes();
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => "Code PIN verrouillé. Réessayez dans {$minutes} minutes.",
                'code' => 'PIN_LOCKED',
            ], 423);
        }

        if (!$pharmacy->verifyWithdrawalPin($request->pin)) {
            $remaining = 5 - $pharmacy->fresh()->pin_attempts;
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => "Code PIN incorrect. {$remaining} tentative(s) restante(s).",
                'code' => 'PIN_INVALID',
                'is_valid' => false,
            ], 401);
        }

        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'Code PIN valide',
            'is_valid' => true,
        ]);
    }

    // ========================================================================
    // PAYMENT INFO WITH PIN PROTECTION
    // ========================================================================

    /**
     * Update bank information (requires PIN)
     */
    public function updateBankInfo(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'pin' => 'required|string|digits:4',
            'bank_name' => 'required|string|max:100',
            'holder_name' => 'required|string|max:100',
            'account_number' => 'required|string|max:50',
            'iban' => 'nullable|string|max:50',
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Donnees invalides',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $user = Auth::user();
        $pharmacy = $user->pharmacies()->firstOrFail();

        // Vérifier le PIN
        if (!$pharmacy->hasPinConfigured()) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Configurez un code PIN avant de modifier les informations bancaires',
                'code' => 'PIN_NOT_CONFIGURED'
            ], 400);
        }

        if ($pharmacy->isPinLocked()) {
            $minutes = $pharmacy->pinLockRemainingMinutes();
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => "Code PIN verrouillé. Réessayez dans {$minutes} minutes.",
                'code' => 'PIN_LOCKED',
            ], 423);
        }

        if (!$pharmacy->verifyWithdrawalPin($request->pin)) {
            $remaining = 5 - $pharmacy->fresh()->pin_attempts;
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => "Code PIN incorrect. {$remaining} tentative(s) restante(s).",
                'code' => 'PIN_INVALID',
            ], 401);
        }
        
        // Mise à jour des infos bancaires
        $pharmacy->paymentInfo()->updateOrCreate(
            ['type' => 'bank'],
            [
                'bank_name' => $request->bank_name,
                'holder_name' => $request->holder_name,
                'account_number' => $request->account_number,
                'iban' => $request->iban,
                'is_primary' => true,
            ]
        );
        
        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'Informations bancaires mises à jour'
        ]);
    }

    /**
     * Update Mobile Money information (requires PIN)
     */
    public function updateMobileMoneyInfo(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'pin' => 'required|string|digits:4',
            'operator' => 'required|string|max:50',
            'phone_number' => 'required|string|max:20',
            'account_name' => 'required|string|max:100',
            'is_primary' => 'boolean',
        ]);
        
        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Donnees invalides',
                'errors' => $validator->errors()
            ], 422);
        }
        
        $user = Auth::user();
        $pharmacy = $user->pharmacies()->firstOrFail();

        // Vérifier le PIN
        if (!$pharmacy->hasPinConfigured()) {
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => 'Configurez un code PIN avant de modifier les informations Mobile Money',
                'code' => 'PIN_NOT_CONFIGURED'
            ], 400);
        }

        if ($pharmacy->isPinLocked()) {
            $minutes = $pharmacy->pinLockRemainingMinutes();
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => "Code PIN verrouillé. Réessayez dans {$minutes} minutes.",
                'code' => 'PIN_LOCKED',
            ], 423);
        }

        if (!$pharmacy->verifyWithdrawalPin($request->pin)) {
            $remaining = 5 - $pharmacy->fresh()->pin_attempts;
            return response()->json([
                'success' => false,
                'status' => 'error',
                'message' => "Code PIN incorrect. {$remaining} tentative(s) restante(s).",
                'code' => 'PIN_INVALID',
            ], 401);
        }
        
        // If this is primary, unset others
        if ($request->get('is_primary', true)) {
            $pharmacy->paymentInfo()->where('type', 'mobile_money')->update(['is_primary' => false]);
        }
        
        // Update payment info
        $pharmacy->paymentInfo()->updateOrCreate(
            ['type' => 'mobile_money', 'phone_number' => $request->phone_number],
            [
                'operator' => $request->operator,
                'holder_name' => $request->account_name,
                'is_primary' => $request->get('is_primary', true),
            ]
        );
        
        return response()->json([
            'success' => true,
            'status' => 'success',
            'message' => 'Informations Mobile Money mises à jour'
        ]);
    }

    /**
     * Get payment information
     */
    public function getPaymentInfo()
    {
        $user = Auth::user();
        $pharmacy = $user->pharmacies()->firstOrFail();

        $bankInfo = $pharmacy->paymentInfo()->where('type', 'bank')->first();
        $mobileInfo = $pharmacy->paymentInfo()->where('type', 'mobile_money')->get();

        return response()->json([
            'status' => 'success',
            'data' => [
                'has_pin' => $pharmacy->hasPinConfigured(),
                'bank' => $bankInfo ? [
                    'bank_name' => $bankInfo->bank_name,
                    'holder_name' => $bankInfo->holder_name,
                    'account_number' => $this->maskAccountNumber($bankInfo->account_number),
                    'iban' => $bankInfo->iban ? $this->maskAccountNumber($bankInfo->iban) : null,
                ] : null,
                'mobile_money' => $mobileInfo->map(function ($info) {
                    return [
                        'id' => $info->id,
                        'operator' => $info->operator,
                        'phone_number' => $this->maskPhoneNumber($info->phone_number),
                        'holder_name' => $info->holder_name,
                        'is_primary' => $info->is_primary,
                    ];
                }),
            ]
        ]);
    }

    /**
     * Masquer un numéro de compte (afficher seulement les 4 derniers chiffres)
     */
    private function maskAccountNumber(?string $number): ?string
    {
        if (!$number || strlen($number) < 4) {
            return $number;
        }
        return str_repeat('*', strlen($number) - 4) . substr($number, -4);
    }

    /**
     * Masquer un numéro de téléphone
     */
    private function maskPhoneNumber(?string $phone): ?string
    {
        if (!$phone || strlen($phone) < 4) {
            return $phone;
        }
        return substr($phone, 0, 4) . str_repeat('*', strlen($phone) - 6) . substr($phone, -2);
    }
}
