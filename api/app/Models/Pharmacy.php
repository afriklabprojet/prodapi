<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\MorphOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class Pharmacy extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'name',
        'phone',
        'email',
        'address',
        'city',
        'region',
        'duty_zone_id',
        'latitude',
        'longitude',
        'status',
        'is_active',
        'is_featured',
        'commission_rate_platform',
        'commission_rate_pharmacy',
        'commission_rate_courier',
        'license_number',
        'license_document',
        'id_card_document',
        'owner_name',
        'rejection_reason',
        'approved_at',
        // Withdrawal settings
        'withdrawal_threshold',
        'auto_withdraw_enabled',
        'is_open',
    ];

    /**
     * SECURITY: withdrawal_pin ne doit JAMAIS être mass-assignable
     */
    protected $guarded = [
        'withdrawal_pin',
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
        'commission_rate_platform' => 'decimal:4',
        'commission_rate_pharmacy' => 'decimal:4',
        'commission_rate_courier' => 'decimal:4',
        'approved_at' => 'datetime',
        'is_active' => 'boolean',
        'is_featured' => 'boolean',
        'withdrawal_threshold' => 'integer',
        'auto_withdraw_enabled' => 'boolean',
        'is_open' => 'boolean',
    ];

    /**
     * Relation vers la zone de service
     */
    public function dutyZone(): BelongsTo
    {
        return $this->belongsTo(DutyZone::class);
    }

    /**
     * Portefeuille de la pharmacie
     */
    public function wallet(): MorphOne
    {
        return $this->morphOne(Wallet::class, 'walletable');
    }
    
    /**
     * Utilisateurs liés à cette pharmacie
     */
    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'pharmacy_user')
            ->withPivot('role')
            ->withTimestamps();
    }

    /**
     * Commandes de cette pharmacie
     */
    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    /**
     * Produits de cette pharmacie
     */
    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    /**
     * Zone de livraison de cette pharmacie
     */
    public function deliveryZone(): HasOne
    {
        return $this->hasOne(DeliveryZone::class);
    }

    /**
     * Vérifier si la pharmacie est approuvée
     */
    public function isApproved(): bool
    {
        return $this->status === 'approved';
    }

    /**
     * Scope: pharmacies approuvées
     */
    public function scopeApproved($query)
    {
        return $query->where('status', 'approved');
    }

    /**
     * Scope: pharmacies en attente
     */
    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    /**
     * Scope: pharmacies proches d'une position
     * Compatible SQLite et MySQL
     * 
     * SECURITY: Utilise des bindings paramétrés pour éviter les SQL injections
     */
    public function scopeNearLocation($query, $latitude, $longitude, $radiusKm = 10)
    {
        // SECURITY: Forcer le cast en float pour éviter toute injection SQL
        $lat = (float) $latitude;
        $lng = (float) $longitude;
        $radius = (float) $radiusKm;
        
        // Valider les coordonnées (latitude: -90 à 90, longitude: -180 à 180)
        if ($lat < -90 || $lat > 90 || $lng < -180 || $lng > 180) {
            // Coordonnées invalides - retourner une query vide
            return $query->whereRaw('1 = 0');
        }

        $earthRadius = 6371; // km

        // Formule de distance Haversine avec bindings paramétrés
        // Compatible SQLite et MySQL (sans LEAST/GREATEST pour SQLite)
        // Note: La formule Haversine standard produit des valeurs dans [-1, 1] pour des coordonnées valides
        $haversineSelect = "*, (
            {$earthRadius} * acos(
                MAX(-1.0, MIN(1.0,
                    cos(radians(?)) * cos(radians(latitude)) *
                    cos(radians(longitude) - radians(?)) +
                    sin(radians(?)) * sin(radians(latitude))
                ))
            )
        ) AS distance";

        $haversineWhere = "(
            {$earthRadius} * acos(
                MAX(-1.0, MIN(1.0,
                    cos(radians(?)) * cos(radians(latitude)) *
                    cos(radians(longitude) - radians(?)) +
                    sin(radians(?)) * sin(radians(latitude))
                ))
            )
        ) <= ?";

        $haversineOrder = "(
            {$earthRadius} * acos(
                MAX(-1.0, MIN(1.0,
                    cos(radians(?)) * cos(radians(latitude)) *
                    cos(radians(longitude) - radians(?)) +
                    sin(radians(?)) * sin(radians(latitude))
                ))
            )
        )";

        return $query->selectRaw($haversineSelect, [$lat, $lng, $lat])
            ->whereRaw("latitude IS NOT NULL AND longitude IS NOT NULL")
            ->whereRaw($haversineWhere, [$lat, $lng, $lat, $radius])
            ->orderByRaw($haversineOrder, [$lat, $lng, $lat]);
    }

    /**
     * Gardes de cette pharmacie
     */
    public function onCalls(): HasMany
    {
        return $this->hasMany(PharmacyOnCall::class);
    }

    /**
     * Scope: pharmacies de garde actuellement
     */
    public function scopeOnDuty($query)
    {
        return $query->whereHas('onCalls', function ($q) {
            $q->where('start_at', '<=', now())
              ->where('end_at', '>=', now())
              ->where('is_active', true);
        });
    }

    /**
     * Scope: pharmacies en vedette
     */
    public function scopeFeatured($query)
    {
        return $query->where('is_featured', true);
    }

    /**
     * Informations de paiement de la pharmacie
     */
    public function paymentInfo(): HasMany
    {
        return $this->hasMany(PaymentInfo::class);
    }

    /**
     * Demandes de retrait de la pharmacie
     */
    public function withdrawalRequests(): HasMany
    {
        return $this->hasMany(WithdrawalRequest::class);
    }

    /**
     * Préférences de relevés automatiques
     */
    public function statementPreference(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(PharmacyStatementPreference::class);
    }

    /**
     * Avis reçus par la pharmacie
     */
    public function ratings(): \Illuminate\Database\Eloquent\Relations\MorphMany
    {
        return $this->morphMany(Rating::class, 'rateable');
    }

    /**
     * Note moyenne
     */
    public function averageRating(): float
    {
        return (float) $this->ratings()->avg('rating') ?: 0;
    }

    // ========================================================================
    // PIN SECURITY METHODS
    // ========================================================================

    /**
     * Vérifie si un PIN de retrait est configuré
     */
    public function hasPinConfigured(): bool
    {
        return !empty($this->withdrawal_pin);
    }

    /**
     * Définir le PIN de retrait
     */
    public function setWithdrawalPin(string $pin): void
    {
        $this->update([
            'withdrawal_pin' => \Illuminate\Support\Facades\Hash::make($pin),
            'pin_set_at' => now(),
            'pin_attempts' => 0,
            'pin_locked_until' => null,
        ]);
    }

    /**
     * Vérifier le PIN de retrait
     */
    public function verifyWithdrawalPin(string $pin): bool
    {
        // Vérifier si le compte est verrouillé
        if ($this->isPinLocked()) {
            return false;
        }

        $isValid = \Illuminate\Support\Facades\Hash::check($pin, $this->withdrawal_pin);

        if (!$isValid) {
            $this->incrementPinAttempts();
        } else {
            $this->resetPinAttempts();
        }

        return $isValid;
    }

    /**
     * Vérifier si le PIN est verrouillé (trop de tentatives)
     */
    public function isPinLocked(): bool
    {
        if ($this->pin_locked_until && $this->pin_locked_until->isFuture()) {
            return true;
        }

        // Si le verrou a expiré, le réinitialiser
        if ($this->pin_locked_until && $this->pin_locked_until->isPast()) {
            $this->update([
                'pin_attempts' => 0,
                'pin_locked_until' => null,
            ]);
        }

        return false;
    }

    /**
     * Incrémenter les tentatives de PIN échouées
     */
    protected function incrementPinAttempts(): void
    {
        $attempts = $this->pin_attempts + 1;
        $data = ['pin_attempts' => $attempts];

        // Après 5 tentatives, verrouiller pendant 30 minutes
        if ($attempts >= 5) {
            $data['pin_locked_until'] = now()->addMinutes(30);
        }

        $this->update($data);
    }

    /**
     * Réinitialiser les tentatives de PIN
     */
    protected function resetPinAttempts(): void
    {
        if ($this->pin_attempts > 0) {
            $this->update([
                'pin_attempts' => 0,
                'pin_locked_until' => null,
            ]);
        }
    }

    /**
     * Temps restant avant déverrouillage du PIN
     */
    public function pinLockRemainingMinutes(): ?int
    {
        if (!$this->isPinLocked()) {
            return null;
        }

        return (int) now()->diffInMinutes($this->pin_locked_until, false);
    }
}

