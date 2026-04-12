<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class WithdrawalRequest extends Model
{
    protected $fillable = [
        'wallet_id',
        'requestable_type',
        'requestable_id',
        'pharmacy_id', // Kept for backward compatibility, will be deprecated
        'amount',
        'payment_method',
        'account_details',
        'reference',
        'status',
        'processed_at',
        'completed_at',
        'admin_notes',
        'error_message',
        'jeko_reference',
        'jeko_payment_id',
        'phone',
        'bank_details',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'account_details' => 'array',
        'bank_details' => 'array',
        'processed_at' => 'datetime',
        'completed_at' => 'datetime',
    ];

    /**
     * Wallet associé
     */
    public function wallet(): BelongsTo
    {
        return $this->belongsTo(Wallet::class);
    }

    /**
     * Entité ayant demandé le retrait (Pharmacy ou User/Customer)
     * Relation polymorphique
     */
    public function requestable(): MorphTo
    {
        return $this->morphTo();
    }

    /**
     * Pharmacie ayant demandé le retrait
     * @deprecated Use requestable() instead
     */
    public function pharmacy(): BelongsTo
    {
        return $this->belongsTo(Pharmacy::class);
    }

    /**
     * Vérifie si la demande est d'une pharmacie
     */
    public function isFromPharmacy(): bool
    {
        return $this->requestable_type === Pharmacy::class 
            || $this->requestable_type === 'App\\Models\\Pharmacy';
    }

    /**
     * Vérifie si la demande est d'un livreur
     */
    public function isFromCourier(): bool
    {
        return $this->requestable_type === Courier::class 
            || $this->requestable_type === 'App\\Models\\Courier';
    }

    /**
     * Scope: demandes de pharmacies
     */
    public function scopeFromPharmacies($query)
    {
        return $query->where('requestable_type', Pharmacy::class);
    }

    /**
     * Scope: demandes de livreurs
     */
    public function scopeFromCouriers($query)
    {
        return $query->where('requestable_type', Courier::class);
    }

    /**
     * Nom formaté du demandeur
     */
    public function getRequesterNameAttribute(): string
    {
        if ($this->requestable) {
            return $this->requestable->name ?? 'Inconnu';
        }
        
        // Fallback pour anciennes données avec pharmacy_id
        if ($this->pharmacy_id && $this->pharmacy) {
            return $this->pharmacy->name;
        }
        
        return 'Inconnu';
    }

    /**
     * Type formaté du demandeur
     */
    public function getRequesterTypeAttribute(): string
    {
        if ($this->isFromPharmacy()) {
            return 'Pharmacie';
        }
        if ($this->isFromCourier()) {
            return 'Livreur';
        }
        return 'Inconnu';
    }
}
