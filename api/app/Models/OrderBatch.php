<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class OrderBatch extends Model
{
    use HasFactory;

    protected $fillable = [
        'courier_id',
        'delivery_offer_id',
        'status',
        'total_orders',
        'total_fee',
        'batch_bonus',
        'optimized_route',
        'total_distance',
        'estimated_total_time',
    ];

    protected $casts = [
        'total_orders' => 'integer',
        'total_fee' => 'integer',
        'batch_bonus' => 'integer',
        'optimized_route' => 'array',
        'total_distance' => 'decimal:2',
        'estimated_total_time' => 'integer',
    ];

    // ──────────────────────────────────────────
    // CONSTANTES
    // ──────────────────────────────────────────

    const STATUS_PENDING = 'pending';
    const STATUS_ASSIGNED = 'assigned';
    const STATUS_IN_PROGRESS = 'in_progress';
    const STATUS_COMPLETED = 'completed';
    const STATUS_CANCELLED = 'cancelled';

    const MAX_ORDERS_PER_BATCH = 4;
    const MAX_DETOUR_PERCENT = 30;

    // ──────────────────────────────────────────
    // RELATIONS
    // ──────────────────────────────────────────

    /**
     * Livreur assigné
     */
    public function courier(): BelongsTo
    {
        return $this->belongsTo(Courier::class);
    }

    /**
     * Offre de livraison associée
     */
    public function deliveryOffer(): BelongsTo
    {
        return $this->belongsTo(DeliveryOffer::class);
    }

    /**
     * Commandes dans ce lot
     */
    public function orders(): BelongsToMany
    {
        return $this->belongsToMany(Order::class, 'order_batch_items')
            ->withPivot(['sequence', 'estimated_arrival', 'actual_arrival', 'status'])
            ->withTimestamps()
            ->orderByPivot('sequence');
    }

    /**
     * Livraisons associées à ce lot
     */
    public function deliveries(): HasMany
    {
        return $this->hasMany(Delivery::class);
    }

    // ──────────────────────────────────────────
    // ACCESSORS
    // ──────────────────────────────────────────

    /**
     * Nombre de commandes restantes à livrer
     */
    public function getRemainingOrdersAttribute(): int
    {
        return $this->orders()
            ->wherePivotIn('status', ['pending', 'picked_up'])
            ->count();
    }

    /**
     * Progression en pourcentage
     */
    public function getProgressPercentAttribute(): int
    {
        if ($this->total_orders === 0) return 0;
        
        $delivered = $this->orders()->wherePivot('status', 'delivered')->count();
        return (int) round(($delivered / $this->total_orders) * 100);
    }

    /**
     * Prochaine commande à livrer
     */
    public function getNextOrderAttribute(): ?Order
    {
        return $this->orders()
            ->wherePivotIn('status', ['pending', 'picked_up'])
            ->orderByPivot('sequence')
            ->first();
    }

    // ──────────────────────────────────────────
    // SCOPES
    // ──────────────────────────────────────────

    /**
     * Lots en cours
     */
    public function scopeInProgress($query)
    {
        return $query->whereIn('status', [self::STATUS_ASSIGNED, self::STATUS_IN_PROGRESS]);
    }

    /**
     * Lots pour un livreur
     */
    public function scopeForCourier($query, int $courierId)
    {
        return $query->where('courier_id', $courierId);
    }

    // ──────────────────────────────────────────
    // MÉTHODES
    // ──────────────────────────────────────────

    /**
     * Ajouter une commande au lot
     */
    public function addOrder(Order $order, int $sequence, ?\DateTime $estimatedArrival = null): void
    {
        $this->orders()->attach($order->id, [
            'sequence' => $sequence,
            'estimated_arrival' => $estimatedArrival,
            'status' => 'pending',
        ]);

        $this->increment('total_orders');
        $this->increment('total_fee', $order->delivery_fee);
    }

    /**
     * Marquer une commande comme récupérée
     */
    public function markOrderPickedUp(Order $order): void
    {
        $this->orders()->updateExistingPivot($order->id, [
            'status' => 'picked_up',
        ]);
    }

    /**
     * Marquer une commande comme livrée
     */
    public function markOrderDelivered(Order $order): void
    {
        $this->orders()->updateExistingPivot($order->id, [
            'status' => 'delivered',
            'actual_arrival' => now(),
        ]);

        // Vérifier si le lot est complet
        if ($this->remaining_orders === 0) {
            $this->update(['status' => self::STATUS_COMPLETED]);
        }
    }

    /**
     * Démarrer le lot
     */
    public function start(): void
    {
        $this->update(['status' => self::STATUS_IN_PROGRESS]);
    }

    /**
     * Calculer le bonus total
     */
    public function calculateBatchBonus(): int
    {
        // +150 FCFA par commande supplémentaire (au-delà de la première)
        $additionalOrders = max(0, $this->total_orders - 1);
        return $additionalOrders * 150;
    }
}
