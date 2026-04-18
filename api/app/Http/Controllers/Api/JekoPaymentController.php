<?php

namespace App\Http\Controllers\Api;

use App\Enums\JekoPaymentMethod;
use App\Http\Controllers\Controller;
use App\Models\Courier;
use App\Models\Customer;
use App\Models\JekoPayment;
use App\Models\Order;
use App\Models\Wallet;
use App\Services\BusinessEventService;
use App\Services\JekoPaymentService;
use App\Traits\ApiResponder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;

class JekoPaymentController extends Controller
{
    use ApiResponder;

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
            'type' => $request->input('type'),
            'amount' => $request->input('amount'),
            'user_id' => Auth::id(),
        ]);

        $request->validate([
            'type' => 'required|in:order,wallet_topup',
            'order_id' => 'required_if:type,order|integer|exists:orders,id',
            'amount' => 'required_if:type,wallet_topup|numeric|min:500|max:1000000',
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

            return $this->paymentError(
                'Échec de l\'initialisation du paiement. ' . $e->getMessage(),
                'PAYMENT_INIT_FAILED'
            );
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
        // Cast both sides to int: PDO returns DB columns as strings, $user->id may
        // also be a string depending on the User model casts — strict !== would
        // incorrectly fail when the numeric values are equal but types differ.
        if ((int) $order->customer_id !== (int) $user->id) {
            return $this->forbidden('Cette commande ne vous appartient pas', 'ORDER_NOT_OWNED');
        }

        // Vérifier que la commande n'est pas déjà payée
        if ($order->payment_status === 'paid') {
            return $this->error(
                'Cette commande est déjà payée',
                400,
                'ORDER_ALREADY_PAID'
            );
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
            return $this->conflict(
                'Un paiement est déjà en cours pour cette commande',
                'PAYMENT_IN_PROGRESS',
                [
                    'existing_reference' => $existingPayment->reference,
                    'redirect_url' => $existingPayment->redirect_url,
                ]
            );
        }

        // Montant en centimes
        $amountCents = (int) ($order->total_amount * 100);

        $payment = $this->jekoService->createRedirectPayment(
            $order,
            $amountCents,
            $method,
            $user,
            "Paiement commande #{$order->id}"
        );

        // Track payment initiation
        BusinessEventService::paymentInitiated(
            $user->id,
            $payment->reference,
            (float) $payment->amount / 100,
            $method->value
        );

        return $this->success([
            'reference' => $payment->reference,
            'redirect_url' => $payment->redirect_url,
            'amount' => $payment->amount,
            'currency' => $payment->currency,
            'payment_method' => $payment->payment_method->value,
        ], 'Paiement initié. Suivez le lien pour compléter.');
    }

    /**
     * Initier un rechargement de wallet
     * 
     * SECURITY V-009: Vérification qu'aucun paiement n'est déjà en cours
     */
    private function initiateWalletTopup(float $amount, JekoPaymentMethod $method, $user): JsonResponse
    {
        // Détecter le type d'utilisateur (Customer ou Courier)
        $courier = Courier::where('user_id', $user->id)->first();
        $customer = Customer::where('user_id', $user->id)->first();

        if ($courier) {
            $walletable = $courier;
            $walletableType = Courier::class;
        } elseif ($customer) {
            $walletable = $customer;
            $walletableType = Customer::class;
        } else {
            // Créer un profil client automatiquement
            $customer = Customer::create(['user_id' => $user->id]);
            $walletable = $customer;
            $walletableType = Customer::class;
        }

        // Obtenir ou créer le wallet
        $wallet = Wallet::firstOrCreate(
            [
                'walletable_type' => $walletableType,
                'walletable_id' => $walletable->id,
            ],
            [
                'balance' => 0,
                'currency' => 'XOF',
            ]
        );

        // Auto-cancel only PENDING payments (not PROCESSING ones that may have webhooks incoming)
        // Skip payments that already received a webhook (payment may still be confirming)
        $cancelledCount = JekoPayment::where('payable_type', Wallet::class)
            ->where('payable_id', $wallet->id)
            ->where('status', \App\Enums\JekoPaymentStatus::PENDING)
            ->whereNull('webhook_received_at')
            ->update([
                'status' => 'failed',
                'error_message' => 'Annulé automatiquement: nouvelle tentative initiée',
                'completed_at' => now(),
            ]);

        if ($cancelledCount > 0) {
            Log::info('Auto-cancelled pending wallet topups', [
                'wallet_id' => $wallet->id,
                'user_id' => $user->id,
                'cancelled_count' => $cancelledCount,
            ]);
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

        // Track topup initiation
        BusinessEventService::paymentInitiated(
            $user->id,
            $payment->reference,
            (float) $payment->amount / 100,
            $method->value
        );

        return $this->success([
            'reference' => $payment->reference,
            'redirect_url' => $payment->redirect_url,
            'amount' => $payment->amount,
            'currency' => $payment->currency,
            'payment_method' => $payment->payment_method->value,
        ], 'Rechargement initié. Suivez le lien pour compléter.');
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
            return $this->notFound('Paiement non trouvé', 'PAYMENT_NOT_FOUND');
        }

        // Si pas encore finalisé, vérifier auprès de JEKO
        if (!$payment->isFinal()) {
            $payment = $this->jekoService->checkPaymentStatus($payment);
        }

        // Traitement synchrone: si le paiement est réussi mais pas encore crédité,
        // exécuter le job immédiatement dans le même processus (idempotent).
        // Cela évite d'attendre le prochain passage du cron queue worker (1 min).
        if ($payment->isSuccess() && !$payment->business_processed) {
            \App\Jobs\ProcessPaymentResultJob::dispatchSync($payment->id);
            $payment = $payment->fresh();
        }

        return $this->success([
            'reference' => $payment->reference,
            'payment_status' => $payment->status->value,
            'payment_status_label' => $payment->status->label(),
            'amount' => $payment->amount,
            'currency' => $payment->currency,
            'payment_method' => $payment->payment_method->value,
            'is_final' => $payment->isFinal(),
            'completed_at' => $payment->completed_at?->toIso8601String(),
            'error_message' => $payment->error_message,
        ], $payment->isFinal() ? 'Paiement finalisé' : 'Paiement en cours');
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

        return $this->paginated($payments, $payments->map(fn($p) => [
            'reference' => $p->reference,
            'amount' => $p->amount,
            'currency' => $p->currency,
            'payment_method' => $p->payment_method->value,
            'payment_method_label' => $p->payment_method->label(),
            'status' => $p->status->value,
            'status_label' => $p->status->label(),
            'created_at' => $p->created_at->toIso8601String(),
            'completed_at' => $p->completed_at?->toIso8601String(),
        ]), 'Liste des paiements');
    }

    /**
     * Obtenir les méthodes de paiement disponibles
     * GET /api/payments/methods
     */
    public function methods(): JsonResponse
    {
        return $this->success(
            $this->jekoService->getAvailableMethods(),
            'Méthodes de paiement disponibles'
        );
    }

    /**
     * Callback succès (redirection depuis JEKO)
     * GET /api/payments/callback/success
     *
     * Retourne une page HTML qui redirige automatiquement vers l'app mobile
     * via le deep link drpharma://payment/success?reference=XXX
     */
    public function callbackSuccess(Request $request)
    {
        $reference = $request->query('reference');

        if (!$reference) {
            return view('payments.callback', [
                'status' => 'error',
                'errorMessage' => 'Référence de paiement manquante.',
                'deepLink' => 'drpharma-courier://payment/error?reason=missing_reference',
            ]);
        }

        $payment = JekoPayment::byReference($reference)->first();

        if (!$payment) {
            return view('payments.callback', [
                'status' => 'error',
                'errorMessage' => 'Paiement introuvable.',
                'deepLink' => 'drpharma-courier://payment/error?reason=not_found',
            ]);
        }

        // Vérifier le statut réel (le webhook est la source de vérité)
        if (!$payment->isFinal()) {
            $payment = $this->jekoService->checkPaymentStatus($payment);
        }

        // SECURITY H-1: Ne pas dispatchSync depuis un callback non authentifié.
        // Le webhook JEKO ou l'endpoint /status (authentifié) déclenchera le traitement.
        // Ici on dispatch en async uniquement, pour que le queue worker le traite.
        if ($payment->isSuccess() && !$payment->business_processed) {
            \App\Jobs\ProcessPaymentResultJob::dispatch($payment->id)->onQueue('payments');
        }

        // Deep link vers l'app delivery (scheme = drpharma-courier)
        $deepLink = 'drpharma-courier://payment/success?reference=' . urlencode($payment->reference);

        return view('payments.callback', [
            'status' => 'success',
            'deepLink' => $deepLink,
            'reference' => $payment->reference,
        ]);
    }

    /**
     * Callback erreur (redirection depuis JEKO)
     * GET /api/payments/callback/error
     *
     * Retourne une page HTML qui redirige automatiquement vers l'app mobile
     * via le deep link drpharma://payment/error?reference=XXX
     */
    public function callbackError(Request $request)
    {
        $reference = $request->query('reference');

        if (!$reference) {
            return view('payments.callback', [
                'status' => 'error',
                'errorMessage' => 'Référence de paiement manquante.',
                'deepLink' => 'drpharma-courier://payment/error?reason=missing_reference',
            ]);
        }

        $payment = JekoPayment::byReference($reference)->first();

        if (!$payment) {
            return view('payments.callback', [
                'status' => 'error',
                'errorMessage' => 'Paiement introuvable.',
                'deepLink' => 'drpharma-courier://payment/error?reason=not_found',
            ]);
        }

        // Vérifier le statut réel
        if (!$payment->isFinal()) {
            $payment = $this->jekoService->checkPaymentStatus($payment);
        }

        // Deep link vers l'app delivery (scheme = drpharma-courier)
        $deepLink = 'drpharma-courier://payment/error?reference=' . urlencode($payment->reference)
            . '&reason=' . urlencode($payment->error_message ?? 'payment_failed');

        return view('payments.callback', [
            'status' => 'error',
            'errorMessage' => $payment->error_message ?? 'Le paiement a échoué. Veuillez réessayer.',
            'deepLink' => $deepLink,
            'reference' => $payment->reference,
        ]);
    }

    /**
     * SANDBOX: Confirmation de paiement en mode test
     * GET /api/payments/sandbox/confirm
     * 
     * Cette route est utilisée uniquement en développement quand les clés JEKO ne sont pas configurées.
     * Elle simule un paiement réussi et met à jour la commande.
     * 
     * SECURITY C-3: Double protection — route restreinte dans api.php ET guard ici
     */
    public function sandboxConfirm(Request $request)
    {
        // SÉCURITÉ: Refuser catégoriquement en production/staging
        if (!app()->environment('local', 'testing')) {
            Log::critical('SANDBOX: Tentative d\'accès à sandboxConfirm en ' . app()->environment(), [
                'ip' => $request->ip(),
                'reference' => $request->query('reference'),
            ]);
            abort(404);
        }

        $reference = $request->query('reference');
        $orderId = $request->query('order_id');
        
        if (!$reference) {
            return response()->json([
                'success' => false,
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

                // Mettre à jour la commande via la méthode centralisée
                // (gère la transition vers awaiting_validation si ordonnance requise)
                $order = $paymentIntent->order;
                if ($order) {
                    $order->markAsPaid($reference);

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

            return $this->error($e->getMessage(), 400, 'SANDBOX_CONFIRM_FAILED');
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
            return $this->notFound('Paiement non trouvé', 'PAYMENT_NOT_FOUND');
        }

        // Vérifier que le paiement appartient à l'utilisateur
        if ($payment->user_id !== $user->id) {
            return $this->forbidden('Ce paiement ne vous appartient pas', 'PAYMENT_NOT_OWNED');
        }

        // Vérifier que le paiement peut être annulé (pas déjà finalisé)
        if ($payment->isFinal()) {
            return $this->error(
                'Ce paiement ne peut plus être annulé',
                400,
                'PAYMENT_ALREADY_FINALIZED'
            );
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

        return $this->success([
            'reference' => $payment->reference,
            'payment_status' => 'cancelled',
        ], 'Paiement annulé');
    }
}
