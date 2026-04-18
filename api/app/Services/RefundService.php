<?php

namespace App\Services;

use App\Models\Order;
use App\Models\Refund;
use App\Models\User;
use App\Notifications\RefundStatusNotification;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use InvalidArgumentException;
use RuntimeException;

/**
 * Orchestrateur du workflow de remboursement.
 *
 * Cycle de vie :
 *   pending → approved → processed   (chemin nominal)
 *   pending → rejected                (refusé par admin)
 *   pending → processed               (auto-process si méthode wallet)
 */
class RefundService
{
    /**
     * Fenêtre maximale (en jours) pour demander un remboursement après livraison.
     */
    public const REQUEST_WINDOW_DAYS = 7;

    public function __construct(private CustomerWalletService $wallet)
    {
    }

    /**
     * Crée une demande de remboursement déclenchée par le client.
     *
     * @throws InvalidArgumentException si la commande n'est pas remboursable
     */
    public function requestRefund(
        Order $order,
        User $user,
        string $type = Refund::TYPE_FULL,
        ?float $amount = null,
        string $reason = 'Demande client',
        string $source = Refund::SOURCE_CUSTOMER
    ): Refund {
        $this->assertOrderRefundable($order, $user, $source);

        $finalAmount = $type === Refund::TYPE_FULL
            ? (float) $order->total_amount
            : min((float) ($amount ?? 0), (float) $order->total_amount);

        if ($finalAmount <= 0) {
            throw new InvalidArgumentException('Le montant remboursé doit être positif.');
        }

        $existing = Refund::where('order_id', $order->id)
            ->whereIn('status', [Refund::STATUS_PENDING, Refund::STATUS_APPROVED])
            ->first();

        if ($existing) {
            throw new RuntimeException('Une demande de remboursement est déjà en cours pour cette commande.');
        }

        return Refund::create([
            'user_id' => $user->id,
            'order_id' => $order->id,
            'amount' => $finalAmount,
            'reason' => $reason,
            'type' => $type,
            'method' => Refund::METHOD_WALLET,
            'source' => $source,
            'status' => Refund::STATUS_PENDING,
        ]);
    }

    /**
     * Approuve une demande sans la traiter (workflow 2 étapes).
     */
    public function approve(Refund $refund, ?User $admin = null, ?string $note = null): Refund
    {
        if (!$refund->isPending()) {
            throw new RuntimeException('Seules les demandes pending peuvent être approuvées.');
        }

        $refund->update([
            'status' => Refund::STATUS_APPROVED,
            'admin_note' => $note ?? $refund->admin_note,
            'decided_by' => $admin?->id,
            'decided_at' => now(),
        ]);

        return $refund->fresh();
    }

    /**
     * Refuse définitivement une demande.
     */
    public function reject(Refund $refund, User $admin, string $note): Refund
    {
        if (!$refund->isPending()) {
            throw new RuntimeException('Seules les demandes pending peuvent être rejetées.');
        }

        $refund->update([
            'status' => Refund::STATUS_REJECTED,
            'admin_note' => $note,
            'decided_by' => $admin->id,
            'decided_at' => now(),
        ]);

        $this->notify($refund);

        return $refund->fresh();
    }

    /**
     * Effectue le remboursement effectif.
     * Méthode wallet : crédite le wallet client + lie la transaction.
     * Méthode payout/manual : marque comme traité (à compléter par opération externe).
     */
    public function process(Refund $refund, ?User $admin = null): Refund
    {
        if ($refund->status === Refund::STATUS_PROCESSED) {
            return $refund;
        }
        if (!in_array($refund->status, [Refund::STATUS_PENDING, Refund::STATUS_APPROVED], true)) {
            throw new RuntimeException("Refund #{$refund->id} ne peut pas être traité (statut: {$refund->status}).");
        }

        $order = $refund->order()->first();
        $user = $refund->user()->first();

        if (!$order || !$user) {
            throw new RuntimeException("Commande ou client introuvable pour refund #{$refund->id}.");
        }

        return DB::transaction(function () use ($refund, $order, $user, $admin) {
            $walletTransactionId = null;

            if ($refund->method === Refund::METHOD_WALLET) {
                $tx = $this->wallet->refund(
                    $user,
                    (float) $refund->amount,
                    $refund->reason,
                    $order->reference ?? "ORDER-{$order->id}"
                );
                $walletTransactionId = $tx->id;
            }

            $refund->update([
                'status' => Refund::STATUS_PROCESSED,
                'processed_by' => $admin?->id ?? $refund->processed_by,
                'processed_at' => now(),
                'wallet_transaction_id' => $walletTransactionId,
            ]);

            // Marquer la commande comme remboursée si refund full
            if ($refund->type === Refund::TYPE_FULL && $order->status !== Order::STATUS_REFUNDED) {
                $order->update(['status' => Order::STATUS_REFUNDED]);
            }

            $refund = $refund->fresh();
            $this->notify($refund);

            return $refund;
        });
    }

    /**
     * Helper : crée + auto-process en une seule étape.
     * Utilisé par le rejet pharmacien et autres workflows automatiques.
     */
    public function createAndAutoProcess(
        Order $order,
        ?float $amount = null,
        string $reason = 'Remboursement automatique',
        string $source = Refund::SOURCE_AUTO_PHARMACIST_REJECT
    ): ?Refund {
        try {
            // Court-circuiter validations métier (déclenché par système, pas client)
            if (!$order->customer_id) {
                return null;
            }

            // Évite doublons
            $existing = Refund::where('order_id', $order->id)
                ->whereIn('status', [Refund::STATUS_PENDING, Refund::STATUS_APPROVED, Refund::STATUS_PROCESSED])
                ->first();
            if ($existing) {
                return $existing;
            }

            $finalAmount = $amount !== null ? min($amount, (float) $order->total_amount) : (float) $order->total_amount;
            if ($finalAmount <= 0) {
                return null;
            }

            $refund = Refund::create([
                'user_id' => $order->customer_id,
                'order_id' => $order->id,
                'amount' => $finalAmount,
                'reason' => $reason,
                'type' => $finalAmount >= (float) $order->total_amount ? Refund::TYPE_FULL : Refund::TYPE_PARTIAL,
                'method' => Refund::METHOD_WALLET,
                'source' => $source,
                'status' => Refund::STATUS_APPROVED,
                'decided_at' => now(),
            ]);

            return $this->process($refund);
        } catch (\Throwable $e) {
            Log::error('RefundService::createAndAutoProcess failed', [
                'order_id' => $order->id,
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Validation métier : commande remboursable ?
     */
    private function assertOrderRefundable(Order $order, User $user, string $source): void
    {
        if ($order->customer_id !== $user->id && $source === Refund::SOURCE_CUSTOMER) {
            throw new InvalidArgumentException("Cette commande n'appartient pas au client.");
        }

        if ($order->payment_status !== 'paid' && $order->payment_mode !== 'cash') {
            throw new InvalidArgumentException("Cette commande n'a pas été payée.");
        }

        if ($source === Refund::SOURCE_CUSTOMER) {
            if ($order->status === Order::STATUS_REFUNDED) {
                throw new InvalidArgumentException('Cette commande est déjà remboursée.');
            }

            // Fenêtre 7 jours après livraison (ou après création si pas livrée)
            $reference = $order->delivered_at ?? $order->created_at;
            if ($reference && $reference->lt(now()->subDays(self::REQUEST_WINDOW_DAYS))) {
                throw new InvalidArgumentException(
                    sprintf('Le délai de %d jours pour demander un remboursement est dépassé.', self::REQUEST_WINDOW_DAYS)
                );
            }
        }
    }

    /**
     * Envoie la notification au client (best-effort).
     */
    private function notify(Refund $refund): void
    {
        try {
            $user = $refund->user;
            if ($user) {
                $user->notify(new RefundStatusNotification($refund));
                $refund->update(['notified_at' => now()]);
            }
        } catch (\Throwable $e) {
            Log::warning('RefundStatus notification failed', [
                'refund_id' => $refund->id,
                'error' => $e->getMessage(),
            ]);
        }
    }
}
