<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class Order extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'reference',
        'pharmacy_id',
        'customer_id',
        'status',
        'payment_status',
        'delivery_code',
        'payment_mode',
        'subtotal',
        'delivery_fee',
        'service_fee',
        'payment_fee',
        'total_amount',
        'currency',
        'customer_notes',
        'pharmacy_notes',
        'prescription_image',
        'delivery_address',
        'delivery_city',
        'delivery_latitude',
        'delivery_longitude',
        'delivery_distance_km',
        'customer_phone',
        'promo_code_id',
        'promo_discount',
        'confirmed_at',
        'paid_at',
        'delivered_at',
        'cancelled_at',
        'cancellation_reason',
        'payment_reference',
    ];

    protected $casts = [
        'subtotal' => 'decimal:2',
        'delivery_fee' => 'decimal:2',
        'service_fee' => 'decimal:2',
        'payment_fee' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'delivery_latitude' => 'decimal:7',
        'delivery_longitude' => 'decimal:7',
        'delivery_distance_km' => 'decimal:2',
        'confirmed_at' => 'datetime',
        'paid_at' => 'datetime',
        'delivered_at' => 'datetime',
        'cancelled_at' => 'datetime',
    ];

    protected static function boot()
    {
        parent::boot();

        static::creating(function ($order) {
            if (empty($order->delivery_code)) {
                $order->delivery_code = str_pad(random_int(0, 9999), 4, '0', STR_PAD_LEFT);
            }
        });
    }

    /**
     * Pharmacie
     */
    public function pharmacy(): BelongsTo
    {
        return $this->belongsTo(Pharmacy::class);
    }

    /**
     * Client
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    /**
     * Alias for customer relationship (used by DeliveryController)
     */
    public function user(): BelongsTo
    {
        return $this->customer();
    }

    /**
     * Articles de la commande
     */
    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    /**
     * Marquer la commande comme payée
     */
    public function markAsPaid(string $paymentReference): self
    {
        $this->update([
            'payment_status' => 'paid',
            'paid_at' => now(),
        ]);
        return $this;
    }

    /**
     * Livraison
     */
    public function delivery(): HasOne
    {
        return $this->hasOne(Delivery::class);
    }

    /**
     * Intentions de paiement
     */
    public function paymentIntents(): HasMany
    {
        return $this->hasMany(PaymentIntent::class);
    }

    /**
     * Paiements confirmés
     */
    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    /**
     * Commission
     */
    public function commission(): HasOne
    {
        return $this->hasOne(Commission::class);
    }

    /**
     * Générer une référence unique
     */
    public static function generateReference(): string
    {
        return 'DR-' . strtoupper(uniqid());
    }

    /**
     * Scope: commandes payées (via paiement réel)
     */
    public function scopePaid($query)
    {
        return $query->whereIn('status', [
            'confirmed',
            'preparing',
            'ready_for_pickup',
            'on_the_way',
            'delivered',
        ]);
    }

    /**
     * Scope: commandes comptabilisables dans les statistiques pharmacie.
     * Exclut les commandes abandonnées / non terminées :
     *  - 'pending'   → panier non confirmé/payé, potentiellement annulé par le cron
     *  - 'cancelled' → annulée (manuellement ou par le sweeper automatique)
     * Seules les commandes réellement acceptées par la pharmacie sont comptées.
     */
    public function scopeForStats($query)
    {
        return $query->whereNotIn('status', ['pending', 'cancelled']);
    }

    /**
     * Scope: commandes d'une pharmacie
     */
    public function scopeForPharmacy($query, int $pharmacyId)
    {
        return $query->where('pharmacy_id', $pharmacyId);
    }

    /**
     * Vérifier si la commande est payée (basé sur le statut de paiement, pas le statut de commande)
     */
    public function isPaid(): bool
    {
        return $this->payment_status === 'paid'
            || $this->paid_at !== null
            || $this->payment_mode === 'cash';
    }

    /**
     * Notes/avis liés à cette commande
     */
    public function ratings(): HasMany
    {
        return $this->hasMany(Rating::class);
    }
}

