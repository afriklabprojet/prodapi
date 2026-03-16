<?php

namespace App\Http\Controllers\Api;

use App\Enums\JekoPaymentMethod;
use App\Http\Controllers\Controller;
use App\Models\Courier;
use App\Models\JekoPayment;
use App\Models\Order;
use App\Models\Wallet;
use App\Services\JekoPaymentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;

class JekoPaymentController extends Controller
{
    public function __construct(
        private JekoPaymentService $jekoService
    ) {}

    /**
     * Initier un paiement pour une commande
     * POST /api/payments/initiate
     */
    public function initiate(Request $request): JsonResponse
    {
        Log::info('=== JEKO PAYMENT INITIATE START ===', [
            'input' => $request->all(),
            'user_id' => Auth::id(),
        ]);

        $request->validate([
            'type' => 'required|in:order,wallet_topup',
            'order_id' => 'required_if:type,order|integer|exists:orders,id',
            'amount' => 'required_if:type,wallet_topup|numeric|min:500',
            'payment_method' => ['required', Rule::in(JekoPaymentMethod::values())],
        ]);

        Log::info('=== VALIDATION PASSED ===');

        $user = Auth::user();
        $type = $request->type;
        $method = JekoPaymentMethod::from($request->payment_method);

        try {
            if ($type === 'order') {
                Log::info('=== PROCESSING ORDER PAYMENT ===');
                return $this->initiateOrderPayment($request->order_id, $method, $user);
            } else {
                Log::info('=== PROCESSING WALLET TOPUP ===', ['amount' => $request->amount]);
                return $this->initiateWalletTopup($request->amount, $method, $user);
            }
        } catch (\Exception $e) {
            Log::error('=== PAYMENT INITIATION FAILED ===', [
                'type' => $type,
                'user_id' => $user->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Exception: ' . $e->getMessage(),
            ], 400);
        }
    }

    /**
     * Initier le paiement d'une commande
     * 
     * SECURITY V-009: Vérification qu'aucun paiement n'est déjà en cours
     */
    private function initiateOrderPayment(int $orderId, JekoPaymentMethod $method, $user): JsonResponse
    {
        $order = Order::findOrFail($orderId);

        // SECURITY: Vérifier que la commande appartient à l'utilisateur (via customer_id)
        if ($order->customer_id !== $user->id) {
            return response()->json([
                'status' => 'error',
                'message' => 'Cette commande ne vous appartient pas',
            ], 403);
        }

        // Vérifier que la commande n'est pas déjà payée
        if ($order->payment_status === 'paid') {
            return response()->json([
                'status' => 'error',
                'message' => 'Cette commande est déjà payée',
            ], 400);
        }

        // Auto-expire stale payments (>30min stuck in pending/processing)
        JekoPayment::where('payable_type', Order::class)
            ->where('payable_id', $order->id)
            ->whereIn('status', [
                \App\Enums\JekoPaymentStatus::PENDING,
                \App\Enums\JekoPaymentStatus::PROCESSING,
            ])
            ->where('created_at', '<', now()->subMinutes(30))
            ->update(['status' => 'expired', 'error_message' => 'Auto-expired: timeout']);

        // SECURITY V-009: Vérifier qu'il n'y a pas de paiement en cours pour cette commande
        $existingPayment = JekoPayment::where('payable_type', Order::class)
            ->where('payable_id', $order->id)
            ->whereIn('status', [
                \App\Enums\JekoPaymentStatus::PENDING,
                \App\Enums\JekoPaymentStatus::PROCESSING,
            ])
            ->first();

        if ($existingPayment) {
            return response()->json([
                'status' => 'error',
                'message' => 'Un paiement est déjà en cours pour cette commande',
                'data' => [
                    'existing_reference' => $existingPayment->reference,
                    'redirect_url' => $existingPayment->redirect_url,
                ],
            ], 409);
        }

        // Montant en centimes
        $amountCents = (int) ($order->total * 100);

        $payment = $this->jekoService->createRedirectPayment(
            $order,
            $amountCents,
            $method,
            $user,
            "Paiement commande #{$order->id}"
        );

        return response()->json([
            'status' => 'success',
            'message' => 'Paiement initié',
            'data' => [
                'reference' => $payment->reference,
                'redirect_url' => $payment->redirect_url,
                'amount' => $payment->amount,
                'currency' => $payment->currency,
                'payment_method' => $payment->payment_method->value,
            ],
        ]);
    }

    /**
     * Initier un rechargement de wallet
     * 
     * SECURITY V-009: Vérification qu'aucun paiement n'est déjà en cours
     */
    private function initiateWalletTopup(float $amount, JekoPaymentMethod $method, $user): JsonResponse
    {
        // Trouver le wallet du courier
        $courier = Courier::where('user_id', $user->id)->first();
        
        if (!$courier) {
            return response()->json([
                'status' => 'error',
                'message' => 'Profil coursier non trouvé',
            ], 404);
        }

        // Obtenir ou créer le wallet
        $wallet = Wallet::firstOrCreate(
            [
                'walletable_type' => Courier::class,
                'walletable_id' => $courier->id,
            ],
            [
                'balance' => 0,
                'currency' => 'XOF',
            ]
        );

        // Auto-expire stale payments (>30min stuck in pending/processing)
        JekoPayment::where('payable_type', Wallet::class)
            ->where('payable_id', $wallet->id)
            ->whereIn('status', [
                \App\Enums\JekoPaymentStatus::PENDING,
                \App\Enums\JekoPaymentStatus::PROCESSING,
            ])
            ->where('created_at', '<', now()->subMinutes(30))
            ->update(['status' => 'expired', 'error_message' => 'Auto-expired: timeout']);

        // SECURITY V-009: Vérifier qu'il n'y a pas de paiement en cours pour ce wallet
        $existingPayment = JekoPayment::where('payable_type', Wallet::class)
            ->where('payable_id', $wallet->id)
            ->whereIn('status', [
                \App\Enums\JekoPaymentStatus::PENDING,
                \App\Enums\JekoPaymentStatus::PROCESSING,
            ])
            ->first();

        if ($existingPayment) {
            return response()->json([
                'status' => 'error',
                'message' => 'Un rechargement est déjà en cours',
                'data' => [
                    'existing_reference' => $existingPayment->reference,
                    'redirect_url' => $existingPayment->redirect_url,
                ],
            ], 409);
        }

        // Montant en centimes
        $amountCents = (int) ($amount * 100);

        $payment = $this->jekoService->createRedirectPayment(
            $wallet,
            $amountCents,
            $method,
            $user,
            "Rechargement wallet"
        );

        return response()->json([
            'status' => 'success',
            'message' => 'Rechargement initié',
            'data' => [
                'reference' => $payment->reference,
                'redirect_url' => $payment->redirect_url,
                'amount' => $payment->amount,
                'currency' => $payment->currency,
                'payment_method' => $payment->payment_method->value,
            ],
        ]);
    }

    /**
     * Vérifier le statut d'un paiement
     * GET /api/payments/{reference}/status
     * 
     * SECURITY: V-001 - Vérification que le paiement appartient à l'utilisateur authentifié
     */
    public function status(string $reference): JsonResponse
    {
        $user = Auth::user();
        
        // SÉCURITÉ: Vérifier que le paiement appartient à l'utilisateur connecté
        $payment = JekoPayment::byReference($reference)
            ->where('user_id', $user->id)
            ->first();

        if (!$payment) {
            // Message générique pour ne pas révéler l'existence du paiement
            return response()->json([
                'status' => 'error',
                'message' => 'Paiement non trouvé',
            ], 404);
        }

        // Si pas encore finalisé, vérifier auprès de JEKO
        if (!$payment->isFinal()) {
            $payment = $this->jekoService->checkPaymentStatus($payment);
        }

        return response()->json([
            'status' => 'success',
            'data' => [
                'reference' => $payment->reference,
                'payment_status' => $payment->status->value,
                'payment_status_label' => $payment->status->label(),
                'amount' => $payment->amount,
                'currency' => $payment->currency,
                'payment_method' => $payment->payment_method->value,
                'is_final' => $payment->isFinal(),
                'completed_at' => $payment->completed_at?->toIso8601String(),
                'error_message' => $payment->error_message,
            ],
        ]);
    }

    /**
     * Liste des paiements de l'utilisateur
     * GET /api/payments
     */
    public function index(Request $request): JsonResponse
    {
        $user = Auth::user();

        $payments = JekoPayment::where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'status' => 'success',
            'data' => $payments->map(fn($p) => [
                'reference' => $p->reference,
                'amount' => $p->amount,
                'currency' => $p->currency,
                'payment_method' => $p->payment_method->value,
                'payment_method_label' => $p->payment_method->label(),
                'status' => $p->status->value,
                'status_label' => $p->status->label(),
                'created_at' => $p->created_at->toIso8601String(),
                'completed_at' => $p->completed_at?->toIso8601String(),
            ]),
            'meta' => [
                'current_page' => $payments->currentPage(),
                'last_page' => $payments->lastPage(),
                'total' => $payments->total(),
            ],
        ]);
    }

    /**
     * Obtenir les méthodes de paiement disponibles
     * GET /api/payments/methods
     */
    public function methods(): JsonResponse
    {
        return response()->json([
            'status' => 'success',
            'data' => $this->jekoService->getAvailableMethods(),
        ]);
    }

    /**
     * Callback succès (redirection depuis JEKO)
     * GET /api/payments/callback/success
     */
    public function callbackSuccess(Request $request): JsonResponse
    {
        $reference = $request->query('reference');
        
        if (!$reference) {
            return response()->json([
                'status' => 'error',
                'message' => 'Référence manquante',
            ], 400);
        }

        $payment = JekoPayment::byReference($reference)->first();

        if (!$payment) {
            return response()->json([
                'status' => 'error',
                'message' => 'Paiement non trouvé',
            ], 404);
        }

        // Vérifier le statut réel (le webhook est la source de vérité)
        if (!$payment->isFinal()) {
            $payment = $this->jekoService->checkPaymentStatus($payment);
        }

        return response()->json([
            'status' => 'success',
            'message' => $payment->isSuccess() 
                ? 'Paiement effectué avec succès' 
                : 'Paiement en cours de vérification',
            'data' => [
                'reference' => $payment->reference,
                'payment_status' => $payment->status->value,
                'is_success' => $payment->isSuccess(),
            ],
        ]);
    }

    /**
     * Callback erreur (redirection depuis JEKO)
     * GET /api/payments/callback/error
     */
    public function callbackError(Request $request): JsonResponse
    {
        $reference = $request->query('reference');
        
        if (!$reference) {
            return response()->json([
                'status' => 'error',
                'message' => 'Référence manquante',
            ], 400);
        }

        $payment = JekoPayment::byReference($reference)->first();

        if (!$payment) {
            return response()->json([
                'status' => 'error',
                'message' => 'Paiement non trouvé',
            ], 404);
        }

        // Vérifier le statut réel
        if (!$payment->isFinal()) {
            $payment = $this->jekoService->checkPaymentStatus($payment);
        }

        return response()->json([
            'status' => 'error',
            'message' => $payment->error_message ?? 'Le paiement a échoué',
            'data' => [
                'reference' => $payment->reference,
                'payment_status' => $payment->status->value,
            ],
        ]);
    }

    /**
     * SANDBOX: Confirmation de paiement en mode test
     * GET /api/payments/sandbox/confirm
     * 
     * Cette route est utilisée uniquement en développement quand les clés JEKO ne sont pas configurées.
     * Elle simule un paiement réussi et met à jour la commande.
     */
    public function sandboxConfirm(Request $request)
    {
        $reference = $request->query('reference');
        $orderId = $request->query('order_id');
        
        if (!$reference) {
            return response()->json([
                'status' => 'error',
                'message' => 'Référence manquante',
            ], 400);
        }

        try {
            // Essayer d'abord avec PaymentIntent (nouveau système)
            $paymentIntent = \App\Models\PaymentIntent::where('reference', $reference)->first();
            
            if ($paymentIntent) {
                // Marquer le paiement comme réussi
                $paymentIntent->update([
                    'status' => 'SUCCESS',
                ]);

                // Mettre à jour la commande
                $order = $paymentIntent->order;
                if ($order) {
                    $order->update([
                        'payment_status' => 'paid',
                        'paid_at' => now(),
                    ]);

                    Log::info('SANDBOX: PaymentIntent confirmed', [
                        'reference' => $reference,
                        'order_id' => $order->id,
                    ]);

                    // Retourner une page HTML de succès
                    return response()->view('payments.sandbox-success', [
                        'payment' => [
                            'reference' => $reference,
                            'amount' => $order->total_amount,
                            'order_reference' => $order->reference,
                        ],
                        'message' => 'Paiement confirmé avec succès (mode sandbox)',
                    ]);
                }
            }

            // Fallback: Essayer avec JekoPayment (ancien système)
            $payment = $this->jekoService->confirmSandboxPayment($reference);

            return response()->view('payments.sandbox-success', [
                'payment' => $payment,
                'message' => 'Paiement confirmé avec succès (mode sandbox)',
            ]);

        } catch (\Exception $e) {
            Log::error('SANDBOX: Confirmation failed', [
                'reference' => $reference,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage(),
            ], 400);
        }
    }

    /**
     * Annuler un paiement en attente
     * POST /api/courier/payments/{reference}/cancel
     */
    public function cancel(string $reference): JsonResponse
    {
        $user = Auth::user();
        
        $payment = JekoPayment::byReference($reference)->first();

        if (!$payment) {
            return response()->json([
                'status' => 'error',
                'message' => 'Paiement non trouvé',
            ], 404);
        }

        // Vérifier que le paiement appartient à l'utilisateur
        if ($payment->user_id !== $user->id) {
            return response()->json([
                'status' => 'error',
                'message' => 'Ce paiement ne vous appartient pas',
            ], 403);
        }

        // Vérifier que le paiement peut être annulé (pas déjà finalisé)
        if ($payment->isFinal()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Ce paiement ne peut plus être annulé',
            ], 400);
        }

        // Annuler le paiement
        $payment->update([
            'status' => \App\Enums\JekoPaymentStatus::FAILED,
            'error_message' => 'Annulé par l\'utilisateur',
            'completed_at' => now(),
        ]);

        Log::info('Payment cancelled by user', [
            'reference' => $reference,
            'user_id' => $user->id,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Paiement annulé',
            'data' => [
                'reference' => $payment->reference,
                'payment_status' => 'cancelled',
            ],
        ]);
    }
}
