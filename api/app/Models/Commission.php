<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Commission extends Model
{
    use HasFactory;
    protected $fillable = [
        'order_id',
        'total_amount',
        'calculated_at',
    ];

    protected $casts = [
        'total_amount' => 'decimal:2',
        'calculated_at' => 'datetime',
    ];

    /**
     * Commande
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * Lignes de commission
     */
    public function lines(): HasMany
    {
        return $this->hasMany(CommissionLine::class);
    }

    /**
     * Récupérer la commission de la plateforme
     */
    public function getPlatformAmount(): float
    {
        return $this->lines()
            ->where('actor_type', 'platform')
            ->value('amount') ?? 0;
    }

    /**
     * Récupérer la commission de la pharmacie
     */
    public function getPharmacyAmount(): float
    {
        return $this->lines()
            ->where('actor_type', 'App\Models\Pharmacy')
            ->value('amount') ?? 0;
    }

    /**
     * Récupérer la commission du livreur
     */
    public function getCourierAmount(): float
    {
        return $this->lines()
            ->where('actor_type', 'App\Models\Courier')
            ->value('amount') ?? 0;
    }
}

