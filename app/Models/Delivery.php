<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Delivery extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'order_id',
        'courier_id',
        'status',
        'pickup_address',
        'pickup_latitude',
        'pickup_longitude',
        'delivery_address',
        'delivery_latitude',
        'delivery_longitude',
        'delivery_fee',
        'dropoff_latitude',
        'dropoff_longitude',
        'estimated_distance',
        'estimated_duration',
        'assigned_at',
        'accepted_at',
        'picked_up_at',
        'delivered_at',
        'delivery_notes',
        'delivery_proof_image',
        'failure_reason',
        // Champs minuterie d'attente
        'waiting_started_at',
        'waiting_ended_at',
        'waiting_fee',
        'auto_cancelled_at',
        'cancellation_reason',
        'customer_rating',
        'customer_rating_comment',
        'customer_rating_tags',
        'customer_rated_at',
        'metadata',
        'location_history',
    ];

    protected $casts = [
        'pickup_latitude' => 'decimal:7',
        'pickup_longitude' => 'decimal:7',
        'delivery_latitude' => 'decimal:7',
        'delivery_longitude' => 'decimal:7',
        'dropoff_latitude' => 'decimal:7',
        'dropoff_longitude' => 'decimal:7',
        'delivery_fee' => 'decimal:2',
        'estimated_distance' => 'decimal:2',
        'estimated_duration' => 'integer',
        'assigned_at' => 'datetime',
        'accepted_at' => 'datetime',
        'picked_up_at' => 'datetime',
        'delivered_at' => 'datetime',
        'waiting_started_at' => 'datetime',
        'waiting_ended_at' => 'datetime',
        'auto_cancelled_at' => 'datetime',
        'waiting_fee' => 'integer',
        'metadata' => 'array',
        'location_history' => 'array',
        'customer_rated_at' => 'datetime',
    ];

    /**
     * Commande
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * Livreur
     */
    public function courier(): BelongsTo
    {
        return $this->belongsTo(Courier::class);
    }

    /**
     * Livreurs ayant refusé cette livraison
     */
    public function rejectedCouriers(): \Illuminate\Database\Eloquent\Relations\BelongsToMany
    {
        return $this->belongsToMany(Courier::class, 'delivery_rejections')
            ->withPivot('reason', 'rejected_at');
    }

    /**
     * Points de tracking GPS
     */
    public function trackingPoints(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(DeliveryTrackingPoint::class);
    }

    /**
     * Scope: livraisons en cours
     */
    public function scopeInProgress($query)
    {
        return $query->whereIn('status', ['assigned', 'accepted', 'picked_up', 'in_transit']);
    }

    /**
     * Scope: livraisons d'un livreur
     */
    public function scopeForCourier($query, int $courierId)
    {
        return $query->where('courier_id', $courierId);
    }

    /**
     * Scope: livraisons en attente (minuterie active)
     */
    public function scopeWaiting($query)
    {
        return $query->whereNotNull('waiting_started_at')
            ->whereNull('waiting_ended_at')
            ->whereNull('auto_cancelled_at');
    }

    /**
     * Vérifier si la livraison est en attente
     */
    public function isWaiting(): bool
    {
        return $this->waiting_started_at !== null 
            && $this->waiting_ended_at === null 
            && $this->auto_cancelled_at === null;
    }

    /**
     * Vérifier si la livraison a été annulée par timeout
     */
    public function wasAutoCancelled(): bool
    {
        return $this->auto_cancelled_at !== null;
    }
}