<?php

namespace App\Models;

use App\Enums\JekoPaymentMethod;
use App\Enums\JekoPaymentStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class JekoPayment extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'uuid',
        'reference',
        'jeko_payment_request_id',
        'payable_type',
        'payable_id',
        'user_id',
        'amount_cents',
        'currency',
        'payment_method',
        'status',
        'redirect_url',
        'success_url',
        'error_url',
        'transaction_data',
        'error_message',
        'initiated_at',
        'completed_at',
        'webhook_received_at',
        'webhook_processed',
        'business_processed',
        'is_payout',
        'recipient_phone',
        'bank_details',
        'description',
        'metadata',
    ];

    protected $casts = [
        'amount_cents' => 'integer',
        'payment_method' => JekoPaymentMethod::class,
        'status' => JekoPaymentStatus::class,
        'transaction_data' => 'array',
        'bank_details' => 'array',
        'metadata' => 'array',
        'initiated_at' => 'datetime',
        'completed_at' => 'datetime',
        'webhook_received_at' => 'datetime',
        'webhook_processed' => 'boolean',
        'is_payout' => 'boolean',
    ];

    // ──────────────────────────────────────────
    // BOOT : auto-generate uuid + reference
    // ──────────────────────────────────────────

    protected static function booted(): void
    {
        static::creating(function (self $payment) {
            if (empty($payment->uuid)) {
                $payment->uuid = (string) Str::uuid();
            }
            if (empty($payment->reference)) {
                $payment->reference = 'PAY-' . strtoupper(Str::random(12));
            }
        });
    }

    // ──────────────────────────────────────────
    // RELATIONS
    // ──────────────────────────────────────────

    /**
     * Entité payable (Order, Wallet, etc.)
     */
    public function payable(): MorphTo
    {
        return $this->morphTo();
    }

    /**
     * Utilisateur qui a initié le paiement
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    // ──────────────────────────────────────────
    // ACCESSORS
    // ──────────────────────────────────────────

    /**
     * Alias amount → amount_cents (compatibilité avec le code existant)
     * Utilisé partout : $payment->amount, $payment->amount / 100
     */
    public function getAmountAttribute(): int
    {
        return $this->amount_cents;
    }

    // ──────────────────────────────────────────
    // SCOPES
    // ──────────────────────────────────────────

    /**
     * Trouver par référence
     * Utilisé par : JekoPaymentService, JekoPaymentController, cancel()
     */
    public function scopeByReference($query, string $reference)
    {
        return $query->where('reference', $reference);
    }

    /**
     * Trouver par ID Jeko
     * Utilisé par : JekoPaymentService::handleWebhook()
     */
    public function scopeByJekoId($query, ?string $jekoId)
    {
        if ($jekoId === null) {
            return $query->whereRaw('0 = 1'); // Return empty query
        }
        return $query->where('jeko_payment_request_id', $jekoId);
    }

    // ──────────────────────────────────────────
    // MÉTHODES MÉTIER
    // ──────────────────────────────────────────

    /**
     * Vérifie si le paiement est en statut final
     * Utilisé par : JekoPaymentService, JekoPaymentController
     */
    public function isFinal(): bool
    {
        return $this->status->isFinal();
    }

    /**
     * Vérifie si le paiement est un succès
     * Utilisé par : ProcessPaymentResultJob, JekoPaymentService
     */
    public function isSuccess(): bool
    {
        return $this->status === JekoPaymentStatus::SUCCESS;
    }

    /**
     * Marquer comme échoué
     * Utilisé par : JekoPaymentService (erreurs API, erreurs connexion, montant incohérent)
     */
    public function markAsFailed(string $errorMessage): void
    {
        $this->update([
            'status' => JekoPaymentStatus::FAILED,
            'error_message' => $errorMessage,
            'completed_at' => now(),
        ]);
    }
}
