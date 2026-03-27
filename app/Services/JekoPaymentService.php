<?php

namespace App\Services;

use App\Enums\JekoPaymentMethod;
use App\Enums\JekoPaymentStatus;
use App\Models\JekoPayment;
use App\Models\User;
use App\Notifications\NewOrderReceivedNotification;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class JekoPaymentService
{
    private string $apiUrl;
    private ?string $apiKey;
    private ?string $apiKeyId;
    private ?string $storeId;
    private ?string $webhookSecret;
    private bool $isConfigured = false;

    public function __construct()
    {
        // Utiliser ?: pour gérer les cas où la variable existe mais est vide
        $this->apiUrl = config('services.jeko.api_url') ?: 'https://api.jeko.africa';
        $this->apiKey = config('services.jeko.api_key');
        $this->apiKeyId = config('services.jeko.api_key_id');
        $this->storeId = config('services.jeko.store_id');
        $this->webhookSecret = config('services.jeko.webhook_secret');
        
        // Vérifier si Jeko est configuré (avec URL valide)
        $this->isConfigured = !empty($this->apiKey) 
            && !empty($this->apiKeyId) 
            && !empty($this->storeId)
            && filter_var($this->apiUrl, FILTER_VALIDATE_URL);
    }
    
    /**
     * Vérifie si Jeko est configuré
     */
    public function isConfigured(): bool
    {
        return $this->isConfigured;
    }

    /**
     * Créer une demande de paiement redirect JEKO
     *
     * @param Model $payable Entité payable (Order, Wallet, etc.)
     * @param int $amountCents Montant en centimes
     * @param JekoPaymentMethod $method Méthode de paiement
     * @param User|null $user Utilisateur qui initie le paiement
     * @param string|null $description Description du paiement
     * @return JekoPayment
     * @throws \Exception
     */
    public function createRedirectPayment(
        Model $payable,
        int $amountCents,
        JekoPaymentMethod $method,
        ?User $user = null,
        ?string $description = null
    ): JekoPayment {
        // Validation du montant minimum (100 centimes = 1 XOF)
        if ($amountCents < 100) {
            throw new \InvalidArgumentException('Le montant minimum est de 100 centimes (1 XOF)');
        }

        // Créer l'enregistrement local d'abord
        $payment = JekoPayment::create([
            'payable_type' => get_class($payable),
            'payable_id' => $payable->id,
            'user_id' => $user?->id,
            'amount_cents' => $amountCents,
            'currency' => 'XOF',
            'payment_method' => $method,
            'status' => JekoPaymentStatus::PENDING,
            'initiated_at' => now(),
        ]);

        // Construire les URLs de callback
        $baseUrl = config('app.url');
        $successUrl = "{$baseUrl}/api/payments/callback/success?reference={$payment->reference}";
        $errorUrl = "{$baseUrl}/api/payments/callback/error?reference={$payment->reference}";

        $payment->update([
            'success_url' => $successUrl,
            'error_url' => $errorUrl,
        ]);

        // MODE SANDBOX: Si les clés JEKO ne sont pas configurées, simuler le paiement
        if ($this->isSandboxMode()) {
            return $this->handleSandboxPayment($payment, $payable);
        }

        try {
            // Appel API JEKO avec timeout et retry
            $response = Http::withHeaders([
                'X-API-KEY' => $this->apiKey,
                'X-API-KEY-ID' => $this->apiKeyId,
                'Content-Type' => 'application/json',
            ])->timeout(15)->connectTimeout(5)->retry(2, 1000, throw: false)
            ->post("{$this->apiUrl}/partner_api/payment_requests", [
                'storeId' => $this->storeId,
                'amountCents' => $amountCents,
                'currency' => 'XOF',
                'reference' => $payment->reference,
                'paymentDetails' => [
                    'type' => 'redirect',
                    'data' => [
                        'paymentMethod' => $method->value,
                        'successUrl' => $successUrl,
                        'errorUrl' => $errorUrl,
                    ],
                ],
            ]);

            if (!$response->successful()) {
                $errorBody = $response->json();
                Log::error('JEKO API Error', [
                    'reference' => $payment->reference,
                    'status' => $response->status(),
                    'body' => $errorBody,
                ]);

                $payment->markAsFailed($errorBody['message'] ?? 'Erreur API JEKO');
                throw new \Exception($errorBody['message'] ?? 'Erreur lors de la création du paiement JEKO');
            }

            $data = $response->json();

            // Log complet de la réponse JEKO pour faciliter le diagnostic
            Log::info('JEKO API Response received', [
                'reference' => $payment->reference,
                'http_status' => $response->status(),
                'response_keys' => array_keys($data ?? []),
                'has_redirectUrl' => isset($data['redirectUrl']),
                'has_redirect_url' => isset($data['redirect_url']),
            ]);

            // Supporte à la fois camelCase (redirectUrl) et snake_case (redirect_url)
            // selon version/configuration de l'API JEKO
            $redirectUrl = $data['redirectUrl'] ?? $data['redirect_url'] ?? null;

            if (empty($redirectUrl)) {
                Log::error('JEKO API: redirect_url manquant dans la réponse', [
                    'reference' => $payment->reference,
                    'response_keys' => array_keys($data ?? []),
                    'response_body' => $data,
                ]);
                $payment->markAsFailed('Réponse JEKO invalide: redirect_url absent');
                throw new \Exception('Réponse JEKO invalide: le champ redirect_url est absent de la réponse');
            }

            // Mettre à jour avec les données JEKO
            $payment->update([
                'jeko_payment_request_id' => $data['id'] ?? null,
                'redirect_url' => $redirectUrl,
                'status' => JekoPaymentStatus::PROCESSING,
            ]);

            Log::info('JEKO Payment Created', [
                'reference' => $payment->reference,
                'jeko_id' => $data['id'] ?? null,
                'redirect_url' => $redirectUrl,
            ]);

            return $payment->fresh();

        } catch (\Illuminate\Http\Client\RequestException $e) {
            Log::error('JEKO API Request Exception', [
                'reference' => $payment->reference,
                'message' => $e->getMessage(),
            ]);

            $payment->markAsFailed('Erreur de connexion à JEKO: ' . $e->getMessage());
            throw new \Exception('Impossible de contacter le service de paiement');
        }
    }

    /**
     * Vérifier le statut d'un paiement via l'API JEKO
     */
    public function checkPaymentStatus(JekoPayment $payment): JekoPayment
    {
        if (!$payment->jeko_payment_request_id) {
            return $payment;
        }

        // Ne pas vérifier si déjà finalisé
        if ($payment->isFinal()) {
            return $payment;
        }

        try {
            $response = Http::withHeaders([
                'X-API-KEY' => $this->apiKey,
                'X-API-KEY-ID' => $this->apiKeyId,
            ])->timeout(10)->connectTimeout(5)->retry(2, 500, throw: false)
            ->get("{$this->apiUrl}/partner_api/payment_requests/{$payment->jeko_payment_request_id}");

            if (!$response->successful()) {
                Log::warning('JEKO Status Check Failed', [
                    'reference' => $payment->reference,
                    'status' => $response->status(),
                ]);
                return $payment;
            }

            $data = $response->json();
            $wasSuccess = $payment->isSuccess();
            
            $payment = $this->updatePaymentFromJekoResponse($payment, $data);

            // Si le paiement vient de passer en succès, dispatcher le traitement métier
            if ($payment->isSuccess() && !$wasSuccess && !$payment->business_processed) {
                $this->handleSuccessfulPayment($payment);
            }

            return $payment;

        } catch (\Exception $e) {
            Log::error('JEKO Status Check Exception', [
                'reference' => $payment->reference,
                'message' => $e->getMessage(),
            ]);
            return $payment;
        }
    }

    /**
     * Traiter un webhook JEKO
     * 
     * SECURITY: V-005 (anti-replay), V-006 (idempotency lock), V-008 (amount check)
     * 
     * Payload structure according to official Jeko documentation:
     * - id: Unique transaction identifier
     * - status: 'pending', 'success', 'error'
     * - amount: { amount: string, currency: string }
     * - apiTransactionableDetails: { id: string, reference: string } (for Partner API transactions)
     * - executedAt: "YYYY-MM-DD HH:mm:ss"
     */
    public function handleWebhook(array $payload, string $signature): bool
    {
        // SÉCURITÉ V-004: Valider la signature HMAC
        if (!$this->validateWebhookSignature($payload, $signature)) {
            return false;
        }

        // SÉCURITÉ V-005: Protection anti-replay via timestamp
        if (!$this->validateWebhookTimestamp($payload)) {
            return false;
        }

        // Extraire référence et ID selon la structure Jeko
        // apiTransactionableDetails (Partner API) OU transactionDetails (webhooks réels)
        $apiDetails = $payload['apiTransactionableDetails']
            ?? $payload['transactionDetails']
            ?? [];
        $reference = $apiDetails['reference'] ?? null;
        $jekoId = $apiDetails['id'] ?? $payload['id'] ?? null;

        if (!$reference && !$jekoId) {
            Log::warning('JEKO Webhook: Référence manquante', [
                'payload_keys' => array_keys($payload),
                'has_apiTransactionableDetails' => isset($payload['apiTransactionableDetails']),
            ]);
            return false;
        }

        // Trouver le paiement
        $payment = JekoPayment::byReference($reference)->first()
            ?? JekoPayment::byJekoId($jekoId)->first();

        if (!$payment) {
            Log::warning('JEKO Webhook: Paiement non trouvé', [
                'reference' => $reference,
                'jeko_id' => $jekoId,
            ]);
            return false;
        }

        // SÉCURITÉ V-006: Lock atomique pour éviter race condition
        $lockKey = "jeko_webhook_{$payment->id}";
        
        return \Illuminate\Support\Facades\Cache::lock($lockKey, 30)->block(5, function () use ($payment, $payload) {
            // Recharger le paiement pour avoir l'état le plus récent
            $payment = $payment->fresh();
            
            // Idempotency: ne pas traiter deux fois
            if ($payment->webhook_processed) {
                Log::info('JEKO Webhook: Déjà traité (idempotent)', ['reference' => $payment->reference]);
                return true;
            }

            // SÉCURITÉ V-008: Vérifier cohérence du montant
            if (!$this->validateWebhookAmount($payment, $payload)) {
                return false;
            }

            // Utiliser une transaction DB pour atomicité
            return \Illuminate\Support\Facades\DB::transaction(function () use ($payment, $payload) {
                // Mettre à jour le paiement
                $this->updatePaymentFromJekoResponse($payment, $payload);
                
                // Recharger pour avoir le nouveau statut
                $payment = $payment->fresh();

                // Si succès, exécuter la logique métier
                if ($payment->isSuccess()) {
                    $this->handleSuccessfulPayment($payment);
                }

                // Si payout (décaissement) échoué, rembourser le wallet
                if ($payment->is_payout && $payment->status === JekoPaymentStatus::FAILED) {
                    $this->handleFailedPayout($payment);
                }

                return true;
            });
        });
    }

    /**
     * SECURITY V-005: Valider le timestamp du webhook pour éviter replay attacks
     * 
     * According to Jeko docs, executedAt is in format "YYYY-MM-DD HH:mm:ss"
     */
    private function validateWebhookTimestamp(array $payload): bool
    {
        // Jeko uses executedAt field according to official documentation
        $timestamp = $payload['executedAt'] ?? $payload['timestamp'] ?? $payload['created_at'] ?? null;
        
        if (!$timestamp) {
            // Si JEKO n'envoie pas de timestamp, on log mais on accepte
            Log::info('JEKO Webhook: Pas de timestamp (executedAt) dans le payload');
            return true;
        }

        // Convertir en timestamp Unix - executedAt est au format "YYYY-MM-DD HH:mm:ss"
        if (is_string($timestamp) && !is_numeric($timestamp)) {
            $timestamp = strtotime($timestamp);
        }
        
        if ($timestamp === false) {
            Log::warning('JEKO Webhook: Format de timestamp invalide', [
                'executedAt' => $payload['executedAt'] ?? 'not set',
            ]);
            return true; // Accept if we can't parse the timestamp
        }
        
        $maxAgeSeconds = 300; // 5 minutes
        $age = abs(time() - (int)$timestamp);
        
        if ($age > $maxAgeSeconds) {
            Log::warning('JEKO Webhook: Timestamp expiré (possible replay attack)', [
                'webhook_timestamp' => $timestamp,
                'current_timestamp' => time(),
                'age_seconds' => $age,
                'max_age_seconds' => $maxAgeSeconds,
            ]);
            return false;
        }

        return true;
    }

    /**
     * SECURITY V-008: Vérifier que le montant du webhook correspond au montant attendu
     * 
     * According to Jeko docs:
     * - amount: { amount: string, currency: string }
     * - amount.amount is in smallest currency unit (e.g., 10000 = 100.00 XOF)
     */
    private function validateWebhookAmount(JekoPayment $payment, array $payload): bool
    {
        // Jeko official structure: amount.amount (string in smallest unit)
        $amountData = $payload['amount'] ?? null;
        $receivedAmountCents = null;
        
        if (is_array($amountData) && isset($amountData['amount'])) {
            // Official Jeko format: { amount: "10000", currency: "XOF" }
            $receivedAmountCents = (int) $amountData['amount'];
        } elseif (isset($payload['amountCents'])) {
            // Fallback for legacy/alternative format
            $receivedAmountCents = (int) $payload['amountCents'];
        } elseif (isset($payload['amount_cents'])) {
            // Fallback for snake_case format
            $receivedAmountCents = (int) $payload['amount_cents'];
        }
        
        if ($receivedAmountCents === null) {
            // Si pas de montant dans le webhook, on accepte (vérification via API si nécessaire)
            return true;
        }
        
        if ($receivedAmountCents !== $payment->amount_cents) {
            Log::critical('JEKO Webhook: INCOHÉRENCE MONTANT - FRAUDE POTENTIELLE', [
                'reference' => $payment->reference,
                'expected_amount_cents' => $payment->amount_cents,
                'received_amount_cents' => $receivedAmountCents,
                'difference' => $receivedAmountCents - $payment->amount_cents,
            ]);
            
            // Marquer le paiement comme suspect
            $payment->update([
                'status' => JekoPaymentStatus::FAILED,
                'error_message' => 'Montant incohérent détecté - paiement bloqué',
                'webhook_processed' => true,
            ]);
            
            return false;
        }

        return true;
    }

    /**
     * Valider la signature HMAC du webhook
     * 
     * SECURITY: V-004 - TOUJOURS valider la signature, jamais de bypass
     */
    public function validateWebhookSignature(array $payload, string $signature): bool
    {
        // SÉCURITÉ CRITIQUE: Ne JAMAIS accepter sans secret configuré
        if (empty($this->webhookSecret)) {
            Log::critical('JEKO_WEBHOOK_SECRET non configuré - TOUTES les requêtes webhook sont REJETÉES', [
                'environment' => app()->environment(),
            ]);
            return false;
        }

        // SÉCURITÉ: Rejeter si signature manquante
        if (empty($signature)) {
            Log::warning('JEKO Webhook: Signature manquante dans la requête');
            return false;
        }

        // Calculer la signature attendue
        $computedSignature = hash_hmac('sha256', json_encode($payload), $this->webhookSecret);
        
        // Comparaison timing-safe pour éviter timing attacks
        $isValid = hash_equals($computedSignature, $signature);
        
        if (!$isValid) {
            Log::warning('JEKO Webhook: Signature invalide', [
                'received_signature_prefix' => substr($signature, 0, 10) . '...',
            ]);
        }
        
        return $isValid;
    }

    /**
     * Mettre à jour un paiement depuis la réponse JEKO
     * 
     * According to official Jeko docs, status can be:
     * - 'pending': Payment is being processed
     * - 'success': Payment completed successfully
     * - 'error': Payment failed
     */
    private function updatePaymentFromJekoResponse(JekoPayment $payment, array $data): JekoPayment
    {
        $jekoStatus = strtolower($data['status'] ?? 'pending');

        // Map Jeko statuses to internal statuses according to official documentation
        $status = match ($jekoStatus) {
            'success' => JekoPaymentStatus::SUCCESS,
            'error', 'failed', 'cancelled' => JekoPaymentStatus::FAILED, // 'error' is official, others are fallbacks
            'expired' => JekoPaymentStatus::EXPIRED,
            'pending' => JekoPaymentStatus::PROCESSING, // 'pending' means still processing
            default => JekoPaymentStatus::PROCESSING,
        };

        $updateData = [
            'status' => $status,
            'webhook_received_at' => now(),
        ];

        // Store additional transaction data if present
        // This could include counterpartLabel, counterpartIdentifier, paymentMethod, etc.
        $transactionData = array_filter([
            'counterpartLabel' => $data['counterpartLabel'] ?? null,
            'counterpartIdentifier' => $data['counterpartIdentifier'] ?? null,
            'paymentMethod' => $data['paymentMethod'] ?? null,
            'transactionType' => $data['transactionType'] ?? null,
            'executedAt' => $data['executedAt'] ?? null,
        ]);
        
        if (!empty($transactionData) || isset($data['transaction'])) {
            $updateData['transaction_data'] = array_merge(
                $data['transaction'] ?? [],
                $transactionData
            );
        }

        if ($status->isFinal()) {
            $updateData['completed_at'] = now();
            $updateData['webhook_processed'] = true;
        }

        // For 'error' status, Jeko doesn't provide detailed error message in webhook
        // We set a generic message
        if ($status === JekoPaymentStatus::FAILED) {
            $updateData['error_message'] = $data['error']['message'] ?? 'Paiement échoué (error status from Jeko)';
        }

        $payment->update($updateData);

        Log::info('JEKO Payment Updated', [
            'reference' => $payment->reference,
            'old_status' => $payment->getOriginal('status'),
            'new_status' => $status->value,
            'jeko_status' => $jekoStatus,
        ]);

        return $payment->fresh();
    }

    /**
     * Exécuter la logique métier après un paiement réussi
     * Dispatch un job asynchrone pour traitement robuste avec retry
     */
    private function handleSuccessfulPayment(JekoPayment $payment): void
    {
        // Dispatch le traitement métier vers un job dédié (idempotent + retry-safe)
        \App\Jobs\ProcessPaymentResultJob::dispatch($payment->id)->onQueue('payments');

        Log::info('JEKO Payment Success: job dispatched', [
            'reference' => $payment->reference,
            'payment_id' => $payment->id,
            'payable_type' => $payment->payable_type,
        ]);
    }

    /**
     * Traiter un payout (décaissement) échoué : rembourser le wallet
     */
    private function handleFailedPayout(JekoPayment $payment): void
    {
        $payable = $payment->payable;

        if (!$payable instanceof \App\Models\Wallet) {
            Log::warning('Failed payout: payable is not a Wallet', [
                'reference' => $payment->reference,
                'payable_type' => $payment->payable_type,
            ]);
            return;
        }

        $wallet = $payable;
        $amountToRefund = (float) ($payment->amount_cents / 100);
        $refundReference = 'REFUND-' . $payment->reference;

        // Idempotent : vérifier si un remboursement existe déjà
        $existingRefund = $wallet->transactions()
            ->where('reference', $refundReference)
            ->exists();

        if ($existingRefund) {
            Log::info('Failed payout refund already exists (idempotent)', [
                'reference' => $payment->reference,
            ]);
            return;
        }

        // Chercher la transaction de débit correspondante (wallet_transaction)
        $debitTransaction = $wallet->transactions()
            ->where('category', 'withdrawal')
            ->where('type', 'DEBIT')
            ->where('status', '!=', 'refunded')
            ->where(function ($q) use ($payment, $amountToRefund) {
                $q->where('metadata', 'like', '%' . $payment->reference . '%')
                    ->orWhere(function ($q2) use ($amountToRefund) {
                        $q2->where('amount', $amountToRefund)
                            ->whereIn('status', ['processing', 'pending', 'failed']);
                    });
            })
            ->first();

        // Créditer le wallet
        $wallet->credit(
            $amountToRefund,
            $refundReference,
            "Remboursement automatique: retrait échoué ({$payment->error_message})",
            ['original_payment_reference' => $payment->reference]
        );

        // Mettre à jour le statut de la transaction de débit
        if ($debitTransaction) {
            $debitTransaction->update([
                'status' => 'refunded',
                'category' => 'withdrawal',
            ]);
        }

        Log::info('Failed payout: wallet refunded', [
            'wallet_id' => $wallet->id,
            'amount' => $amountToRefund,
            'payment_reference' => $payment->reference,
            'refund_reference' => $refundReference,
        ]);
    }

    /**
     * Traiter le paiement d'une commande
     * NOTE: Méthode conservée pour usage direct (sandbox), 
     * en production le ProcessPaymentResultJob est utilisé.
     */
    private function handleOrderPayment($order, JekoPayment $payment): void
    {
        // Idempotent : vérifier si déjà payé
        if ($order->payment_status === 'paid') {
            Log::info('Order already paid (idempotent skip)', [
                'order_id' => $order->id,
                'payment_reference' => $payment->reference,
            ]);
            return;
        }

        if (method_exists($order, 'markAsPaid')) {
            $order->markAsPaid($payment->reference);
        } else {
            $order->update([
                'payment_status' => 'paid',
                'payment_reference' => $payment->reference,
                'paid_at' => now(),
            ]);
        }

        Log::info('Order Marked as Paid', [
            'order_id' => $order->id,
            'payment_reference' => $payment->reference,
        ]);

        // Notification asynchrone via job
        $order->load(['items', 'customer', 'pharmacy.users']);
        
        if ($order->pharmacy) {
            foreach ($order->pharmacy->users as $pharmacyUser) {
                \App\Jobs\SendNotificationJob::dispatch(
                    $pharmacyUser,
                    new NewOrderReceivedNotification($order),
                    ['order_id' => $order->id, 'pharmacy_id' => $order->pharmacy_id]
                )->onQueue('notifications');
            }
        }
    }

    /**
     * Traiter le rechargement d'un wallet
     * NOTE: Méthode conservée pour usage direct (sandbox),
     * en production le ProcessPaymentResultJob est utilisé.
     */
    private function handleWalletTopup($wallet, JekoPayment $payment): void
    {
        // Idempotent : vérifier si déjà crédité avec cette référence
        $alreadyCredited = $wallet->transactions()
            ->where('reference', $payment->reference)
            ->exists();

        if ($alreadyCredited) {
            Log::info('Wallet topup already credited (idempotent skip)', [
                'wallet_id' => $wallet->id,
                'payment_reference' => $payment->reference,
            ]);
            return;
        }

        $walletService = app(\App\Services\WalletService::class);
        
        $walletService->topUp(
            $wallet->walletable,
            (float) $payment->amount / 100,
            $payment->payment_method->value,
            $payment->reference
        );

        Log::info('Wallet Topped Up', [
            'wallet_id' => $wallet->id,
            'amount' => $payment->amount,
            'payment_reference' => $payment->reference,
        ]);
    }

    /**
     * Obtenir les méthodes de paiement disponibles
     */
    public function getAvailableMethods(): array
    {
        return collect(JekoPaymentMethod::cases())->map(fn($method) => [
            'value' => $method->value,
            'label' => $method->label(),
            'icon' => $method->icon(),
        ])->toArray();
    }

    /**
     * Vérifier si on est en mode sandbox
     * 
     * SECURITY H-2: Uniquement via config explicite ou clés absentes.
     * Ne JAMAIS deviner le mode sandbox par le contenu des clés.
     */
    private function isSandboxMode(): bool
    {
        // Mode sandbox explicitement activé dans la config (.env: JEKO_SANDBOX_MODE=true)
        if (config('services.jeko.sandbox_mode', false)) {
            return true;
        }
        
        // Sandbox si Jeko n'est pas correctement configuré (clés absentes ou URL invalide)
        return !$this->isConfigured;
    }

    /**
     * Gérer un paiement en mode sandbox (développement)
     * Simule un paiement réussi et crédite directement le wallet
     */
    private function handleSandboxPayment(JekoPayment $payment, Model $payable): JekoPayment
    {
        Log::info('JEKO SANDBOX MODE: Simulation de paiement', [
            'reference' => $payment->reference,
            'amount' => $payment->amount,
            'payable_type' => get_class($payable),
        ]);

        // Simuler un ID JEKO
        $fakeJekoId = 'SANDBOX-' . uniqid();
        
        // URL de redirection fictive qui redirige vers success callback
        $sandboxRedirectUrl = config('app.url') . '/api/payments/sandbox/confirm?reference=' . $payment->reference;

        // Mettre à jour le paiement
        $payment->update([
            'jeko_payment_request_id' => $fakeJekoId,
            'redirect_url' => $sandboxRedirectUrl,
            'status' => JekoPaymentStatus::PROCESSING,
        ]);

        return $payment->fresh();
    }

    /**
     * Confirmer un paiement sandbox (appelé depuis l'écran de confirmation)
     */
    public function confirmSandboxPayment(string $reference): JekoPayment
    {
        $payment = JekoPayment::byReference($reference)->first();
        
        if (!$payment) {
            throw new \Exception('Paiement non trouvé');
        }

        if ($payment->isFinal()) {
            return $payment;
        }

        // Marquer comme succès
        $payment->update([
            'status' => JekoPaymentStatus::SUCCESS,
            'completed_at' => now(),
            'webhook_processed' => true,
            'webhook_received_at' => now(),
        ]);

        // Exécuter la logique métier (crédit wallet, etc.)
        $this->handleSuccessfulPayment($payment);

        Log::info('JEKO SANDBOX: Paiement confirmé', [
            'reference' => $payment->reference,
            'amount' => $payment->amount,
        ]);

        return $payment->fresh();
    }

    /**
     * ======================================================================
     * PAYOUT / TRANSFER - Décaissement vers Mobile Money
     * ======================================================================
     * 
     * FLUX JEKO:
     * 1. Créer un contact: POST /partner_api/contacts
     * 2. Faire le transfert: POST /partner_api/transfers avec le contactId
     */

    /**
     * Créer ou récupérer un contact Jeko pour le payout
     *
     * @param string $phone Numéro de téléphone
     * @param string $name Nom du bénéficiaire
     * @param JekoPaymentMethod $method Méthode de paiement
     * @return string Contact UUID
     */
    private function getOrCreateJekoContact(
        string $phone,
        string $name,
        JekoPaymentMethod $method
    ): string {
        $response = Http::withHeaders([
            'X-API-KEY' => $this->apiKey,
            'X-API-KEY-ID' => $this->apiKeyId,
            'Content-Type' => 'application/json',
        ])->post("{$this->apiUrl}/partner_api/contacts", [
            'storeId' => $this->storeId,
            'name' => $name,
            'paymentMethod' => $method->value,
            'identifier' => [
                'number' => $phone,
            ],
        ]);

        if (!$response->successful()) {
            $errorBody = $response->json();
            Log::error('JEKO Contact Creation Error', [
                'phone' => $phone,
                'status' => $response->status(),
                'body' => $errorBody,
            ]);
            throw new \Exception($errorBody['message'] ?? 'Erreur lors de la création du contact JEKO');
        }

        $data = $response->json();
        return $data['id'];
    }

    /**
     * Créer une demande de décaissement (payout) via JEKO
     *
     * @param Model $payable Entité source (Wallet, WithdrawalRequest, etc.)
     * @param int $amountCents Montant en centimes
     * @param string $recipientPhone Numéro de téléphone du bénéficiaire (Mobile Money)
     * @param JekoPaymentMethod $method Méthode de paiement (WAVE, MTN, ORANGE, etc.)
     * @param User|null $user Utilisateur bénéficiaire
     * @param string|null $description Description du décaissement
     * @return JekoPayment
     * @throws \Exception
     */
    public function createPayout(
        Model $payable,
        int $amountCents,
        string $recipientPhone,
        JekoPaymentMethod $method,
        ?User $user = null,
        ?string $description = null
    ): JekoPayment {
        // Validation du montant minimum (500 centimes = 5 XOF pour Jeko transfers)
        if ($amountCents < 500) {
            throw new \InvalidArgumentException('Le montant minimum est de 500 centimes (5 XOF)');
        }

        // Nettoyer le numéro de téléphone
        $recipientPhone = $this->normalizePhoneNumber($recipientPhone);

        // Créer l'enregistrement local
        $payment = JekoPayment::create([
            'payable_type' => get_class($payable),
            'payable_id' => $payable->id,
            'user_id' => $user?->id,
            'amount_cents' => $amountCents,
            'currency' => 'XOF',
            'payment_method' => $method,
            'status' => JekoPaymentStatus::PENDING,
            'is_payout' => true,
            'recipient_phone' => $recipientPhone,
            'description' => $description ?? 'Retrait DR-PHARMA',
            'initiated_at' => now(),
        ]);

        // MODE SANDBOX: Simuler le décaissement
        if ($this->isSandboxMode()) {
            return $this->handleSandboxPayout($payment);
        }

        try {
            // Étape 1: Créer ou récupérer le contact Jeko
            $beneficiaryName = $user?->name ?? 'Client DR-PHARMA';
            $contactId = $this->getOrCreateJekoContact($recipientPhone, $beneficiaryName, $method);

            Log::info('JEKO Contact created/retrieved', [
                'contact_id' => $contactId,
                'phone' => $recipientPhone,
            ]);

            // Étape 2: Effectuer le transfert
            $response = Http::withHeaders([
                'X-API-KEY' => $this->apiKey,
                'X-API-KEY-ID' => $this->apiKeyId,
                'Content-Type' => 'application/json',
            ])->post("{$this->apiUrl}/partner_api/transfers", [
                'storeId' => $this->storeId,
                'contactId' => $contactId,
                'amountCents' => $amountCents,
                'currency' => 'XOF',
            ]);

            if (!$response->successful()) {
                $errorBody = $response->json();
                Log::error('JEKO Transfer API Error', [
                    'reference' => $payment->reference,
                    'status' => $response->status(),
                    'body' => $errorBody,
                ]);

                $payment->markAsFailed($errorBody['message'] ?? 'Erreur API JEKO Transfer');
                throw new \Exception($errorBody['message'] ?? 'Erreur lors du transfert JEKO');
            }

            $data = $response->json();

            // Mettre à jour avec les données JEKO
            $payment->update([
                'jeko_payment_request_id' => $data['id'] ?? null,
                'status' => JekoPaymentStatus::PROCESSING,
                'metadata' => [
                    'jeko_contact_id' => $contactId,
                    'jeko_transfer_id' => $data['id'] ?? null,
                    'jeko_status' => $data['status'] ?? 'pending',
                    'jeko_fees' => $data['fees']['amount'] ?? null,
                ],
            ]);

            Log::info('JEKO Transfer Created', [
                'reference' => $payment->reference,
                'jeko_transfer_id' => $data['id'] ?? null,
                'amount' => $amountCents / 100,
                'fees' => ($data['fees']['amount'] ?? 0) / 100,
                'recipient' => $recipientPhone,
                'status' => $data['status'] ?? 'pending',
            ]);

            return $payment->fresh();

        } catch (\Illuminate\Http\Client\RequestException $e) {
            Log::error('JEKO Transfer API Request Exception', [
                'reference' => $payment->reference,
                'message' => $e->getMessage(),
            ]);

            $payment->markAsFailed('Erreur de connexion à JEKO: ' . $e->getMessage());
            throw new \Exception('Impossible de contacter le service de paiement');
        }
    }

    /**
     * Créer un décaissement vers un compte bancaire
     *
     * @param Model $payable Entité source
     * @param int $amountCents Montant en centimes
     * @param array $bankDetails Détails bancaires (bank_code, account_number, holder_name)
     * @param User|null $user Utilisateur bénéficiaire
     * @param string|null $description Description
     * @return JekoPayment
     */
    public function createBankPayout(
        Model $payable,
        int $amountCents,
        array $bankDetails,
        ?User $user = null,
        ?string $description = null
    ): JekoPayment {
        // NOTE: L'API Jeko ne supporte pas encore les virements bancaires directs
        // On pourrait utiliser le même flux contact+transfer avec paymentMethod approprié
        // Pour l'instant, on refuse les virements bancaires
        
        Log::warning('Bank payout requested but not supported by Jeko API', [
            'user_id' => $user?->id,
            'amount' => $amountCents / 100,
        ]);
        
        throw new \Exception('Les virements bancaires ne sont pas encore disponibles. Veuillez utiliser Mobile Money (Wave, Orange Money, MTN, Moov).');
    }

    /**
     * Gérer un décaissement en mode sandbox
     */
    private function handleSandboxPayout(JekoPayment $payment): JekoPayment
    {
        Log::info('JEKO SANDBOX: Simulation décaissement', [
            'reference' => $payment->reference,
            'amount' => $payment->amount,
            'recipient' => $payment->recipient_phone ?? 'bank',
        ]);

        // Simuler un ID de transaction
        $fakeId = 'SANDBOX_PAYOUT_' . strtoupper(\Illuminate\Support\Str::random(8));

        $payment->update([
            'jeko_payment_request_id' => $fakeId,
            'status' => JekoPaymentStatus::PROCESSING,
        ]);

        // En sandbox, on peut auto-confirmer après un court délai
        // ou laisser en processing pour simulation manuelle
        
        return $payment->fresh();
    }

    /**
     * Confirmer un décaissement sandbox
     */
    public function confirmSandboxPayout(string $reference): JekoPayment
    {
        $payment = JekoPayment::byReference($reference)->first();
        
        if (!$payment) {
            throw new \Exception('Décaissement non trouvé');
        }

        if (!$payment->is_payout) {
            throw new \Exception('Ce paiement n\'est pas un décaissement');
        }

        if ($payment->isFinal()) {
            return $payment;
        }

        // Marquer comme succès
        $payment->update([
            'status' => JekoPaymentStatus::SUCCESS,
            'completed_at' => now(),
            'webhook_processed' => true,
            'webhook_received_at' => now(),
        ]);

        // Exécuter la logique métier
        $this->handleSuccessfulPayout($payment);

        Log::info('JEKO SANDBOX: Décaissement confirmé', [
            'reference' => $payment->reference,
            'amount' => $payment->amount,
        ]);

        return $payment->fresh();
    }

    /**
     * Traiter un décaissement réussi
     */
    protected function handleSuccessfulPayout(JekoPayment $payment): void
    {
        $payable = $payment->payable;

        if (!$payable) {
            Log::warning('Payout success but no payable found', ['reference' => $payment->reference]);
            return;
        }

        // Si c'est un WithdrawalRequest, marquer comme complété
        if ($payable instanceof \App\Models\WithdrawalRequest) {
            $payable->update([
                'status' => 'completed',
                'completed_at' => now(),
                'jeko_reference' => $payment->reference,
            ]);

            // NE PAS débiter ici - le wallet a déjà été débité lors de l'initiation du retrait
            // dans WalletController::withdraw()

            Log::info('Withdrawal completed via Jeko', [
                'withdrawal_id' => $payable->id,
                'amount' => $payable->amount,
                'reference' => $payment->reference,
            ]);
        }

        // Notifier l'utilisateur
        if ($payment->user) {
            try {
                $payment->user->notify(
                    new \App\Notifications\PayoutCompletedNotification(
                        $payment->amount,
                        $payment->reference,
                    )
                );
            } catch (\Exception $e) {
                Log::warning('Failed to send payout notification', [
                    'user_id' => $payment->user_id,
                    'error' => $e->getMessage(),
                ]);
            }
        }
    }

    /**
     * Vérifier le statut d'un décaissement (transfer)
     */
    public function checkPayoutStatus(JekoPayment $payment): JekoPayment
    {
        if (!$payment->is_payout || !$payment->jeko_payment_request_id) {
            return $payment;
        }

        if ($payment->isFinal()) {
            return $payment;
        }

        try {
            $response = Http::withHeaders([
                'X-API-KEY' => $this->apiKey,
                'X-API-KEY-ID' => $this->apiKeyId,
            ])->get("{$this->apiUrl}/partner_api/transfers/{$payment->jeko_payment_request_id}");

            if (!$response->successful()) {
                return $payment;
            }

            $data = $response->json();
            $status = strtoupper($data['status'] ?? '');

            if ($status === 'SUCCESS' || $status === 'COMPLETED' || $status === 'SENT') {
                $payment->update([
                    'status' => JekoPaymentStatus::SUCCESS,
                    'completed_at' => now(),
                ]);
                $this->handleSuccessfulPayout($payment);
            } elseif ($status === 'FAILED' || $status === 'REJECTED' || $status === 'CANCELLED') {
                $payment->markAsFailed($data['message'] ?? 'Transfert échoué');
            }

            return $payment->fresh();

        } catch (\Exception $e) {
            Log::error('JEKO Payout Status Check Error', [
                'reference' => $payment->reference,
                'message' => $e->getMessage(),
            ]);
            return $payment;
        }
    }

    /**
     * Normaliser un numéro de téléphone pour JEKO
     */
    private function normalizePhoneNumber(string $phone): string
    {
        // Supprimer les espaces et caractères spéciaux
        $phone = preg_replace('/[^0-9+]/', '', $phone);
        
        // Si le numéro commence par 0, ajouter l'indicatif Bénin
        if (str_starts_with($phone, '0')) {
            $phone = '+229' . substr($phone, 1);
        }
        
        // S'assurer qu'il commence par +
        if (!str_starts_with($phone, '+')) {
            $phone = '+' . $phone;
        }
        
        return $phone;
    }
}
