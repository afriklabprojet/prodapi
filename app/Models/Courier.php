<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\Relations\MorphOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class Courier extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'user_id',
        'name',
        'phone',
        'vehicle_type',
        'vehicle_number',
        'license_number',
        'latitude',
        'longitude',
        'status',
        'rating',
        'completed_deliveries',
        'last_location_update',
        'driving_license_front_document',
        'driving_license_back_document',
        'vehicle_registration_document',
        'id_card_front_document',
        'id_card_back_document',
        'selfie_document',
        'kyc_status',
        'kyc_rejection_reason',
        'kyc_verified_at',
        // Gamification
        'total_xp',
        'current_streak_days',
        'last_active_date',
        'badges',
        'tier',
        // Fiabilité
        'acceptance_rate',
        'completion_rate',
        'on_time_rate',
        'reliability_score',
        'avg_delivery_speed_factor',
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
        'rating' => 'decimal:1',
        'completed_deliveries' => 'integer',
        'last_location_update' => 'datetime',
        'kyc_verified_at' => 'datetime',
        // Gamification
        'total_xp' => 'integer',
        'current_streak_days' => 'integer',
        'last_active_date' => 'date',
        'badges' => 'array',
        // Fiabilité
        'acceptance_rate' => 'decimal:2',
        'completion_rate' => 'decimal:2',
        'on_time_rate' => 'decimal:2',
        'reliability_score' => 'decimal:2',
        'avg_delivery_speed_factor' => 'decimal:2',
    ];

    /**
     * SECURITY: Attributs sensibles masqués dans les réponses JSON
     * Les documents KYC contiennent des données personnelles protégées
     * 
     * @var array<string>
     */
    protected $hidden = [
        'driving_license_front_document',
        'driving_license_back_document',
        'vehicle_registration_document',
        'id_card_front_document',
        'id_card_back_document',
        'selfie_document',
        'kyc_rejection_reason',    // Info interne
    ];

    // ──────────────────────────────────────────
    // CONSTANTES TIER
    // ──────────────────────────────────────────

    const TIER_BRONZE = 'bronze';
    const TIER_SILVER = 'silver';
    const TIER_GOLD = 'gold';
    const TIER_PLATINUM = 'platinum';

    const TIER_XP_THRESHOLDS = [
        self::TIER_BRONZE => 0,
        self::TIER_SILVER => 1000,
        self::TIER_GOLD => 5000,
        self::TIER_PLATINUM => 15000,
    ];

    const TIER_BENEFITS = [
        self::TIER_BRONZE => ['priority_multiplier' => 1.0, 'bonus_percent' => 0],
        self::TIER_SILVER => ['priority_multiplier' => 1.2, 'bonus_percent' => 5],
        self::TIER_GOLD => ['priority_multiplier' => 1.5, 'bonus_percent' => 10],
        self::TIER_PLATINUM => ['priority_multiplier' => 2.0, 'bonus_percent' => 15],
    ];

    // ──────────────────────────────────────────
    // RELATIONS
    // ──────────────────────────────────────────

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function deliveries(): HasMany
    {
        return $this->hasMany(Delivery::class);
    }

    public function wallet(): MorphOne
    {
        return $this->morphOne(Wallet::class, 'walletable');
    }

    /**
     * Lignes de commission (polymorphique via actor_type/actor_id)
     */
    public function commissionLines(): MorphMany
    {
        return $this->morphMany(CommissionLine::class, 'actor');
    }

    /**
     * Demandes de retrait du livreur (polymorphique)
     */
    public function withdrawalRequests(): MorphMany
    {
        return $this->morphMany(WithdrawalRequest::class, 'requestable');
    }

    /**
     * Challenges auxquels le coursier participe
     */
    public function challenges(): BelongsToMany
    {
        return $this->belongsToMany(Challenge::class, 'courier_challenges')
            ->withPivot('current_progress', 'status', 'started_at', 'completed_at', 'rewarded_at')
            ->withTimestamps();
    }

    /**
     * Offres de livraison reçues (broadcast)
     */
    public function deliveryOffers(): BelongsToMany
    {
        return $this->belongsToMany(DeliveryOffer::class, 'delivery_offer_courier')
            ->withPivot(['status', 'notified_at', 'viewed_at', 'responded_at', 'rejection_reason'])
            ->withTimestamps();
    }

    /**
     * Offres acceptées par ce livreur
     */
    public function acceptedOffers(): HasMany
    {
        return $this->hasMany(DeliveryOffer::class, 'accepted_by_courier_id');
    }

    /**
     * Shifts planifiés
     */
    public function shifts(): HasMany
    {
        return $this->hasMany(CourierShift::class);
    }

    /**
     * Shift actif actuel
     */
    public function activeShift(): ?CourierShift
    {
        return $this->shifts()->active()->today()->first();
    }

    /**
     * Lots de commandes assignés
     */
    public function orderBatches(): HasMany
    {
        return $this->hasMany(OrderBatch::class);
    }

    /**
     * Progression des challenges journaliers
     */
    public function challengeProgress(): HasMany
    {
        return $this->hasMany(CourierChallengeProgress::class);
    }

    // ──────────────────────────────────────────
    // ACCESSORS
    // ──────────────────────────────────────────

    /**
     * Alias plate_number → vehicle_number (utilisé dans DeliveryController::profile)
     */
    public function getPlateNumberAttribute(): ?string
    {
        return $this->vehicle_number;
    }

    // ──────────────────────────────────────────
    // SCOPES
    // ──────────────────────────────────────────

    /**
     * Coursiers disponibles pour les livraisons
     * Utilisé par CourierAssignmentService::findNearestAvailableCourier()
     */
    public function scopeAvailable($query)
    {
        return $query->where('status', 'available');
    }

    /**
     * Scope: livreurs proches d'une position
     * Compatible SQLite et MySQL
     * Utilisé par CourierAssignmentService::getAvailableCouriersInRadius()
     * 
     * SECURITY: Utilise des bindings paramétrés pour éviter les SQL injections
     */
    public function scopeNearLocation($query, $latitude, $longitude, $radiusKm = 20)
    {
        // SECURITY: Forcer le cast en float pour éviter toute injection SQL
        $lat = (float) $latitude;
        $lng = (float) $longitude;
        
        // Valider les coordonnées (latitude: -90 à 90, longitude: -180 à 180)
        if ($lat < -90 || $lat > 90 || $lng < -180 || $lng > 180) {
            // Coordonnées invalides - retourner une query vide
            return $query->whereRaw('1 = 0');
        }

        $earthRadius = 6371; // km

        // Formule de distance Haversine avec bindings paramétrés
        // GREATEST/LEAST pour MySQL/MariaDB (clamp acos input to [-1, 1])
        $haversineSelect = "*, (
            {$earthRadius} * acos(
                GREATEST(-1.0, LEAST(1.0,
                    cos(radians(?)) * cos(radians(latitude)) *
                    cos(radians(longitude) - radians(?)) +
                    sin(radians(?)) * sin(radians(latitude))
                ))
            )
        ) AS distance";

        return $query->selectRaw($haversineSelect, [$lat, $lng, $lat])
            ->whereRaw("latitude IS NOT NULL AND longitude IS NOT NULL");
    }

    // ──────────────────────────────────────────
    // MÉTHODES
    // ──────────────────────────────────────────

    /**
     * Mettre à jour la position GPS du coursier
     * Appelé par DeliveryController::updateLocation()
     */
    public function updateLocation(float $latitude, float $longitude): void
    {
        $this->update([
            'latitude' => $latitude,
            'longitude' => $longitude,
            'last_location_update' => now(),
        ]);
    }

    // ──────────────────────────────────────────
    // GAMIFICATION
    // ──────────────────────────────────────────

    /**
     * Ajouter de l'XP et vérifier le tier-up
     */
    public function addXp(int $amount, string $reason = ''): void
    {
        $this->increment('total_xp', $amount);
        $this->checkTierUp();
    }

    /**
     * Vérifier si le livreur doit passer au tier supérieur
     */
    public function checkTierUp(): void
    {
        $newTier = self::TIER_BRONZE;
        
        foreach (self::TIER_XP_THRESHOLDS as $tier => $threshold) {
            if ($this->total_xp >= $threshold) {
                $newTier = $tier;
            }
        }

        if ($newTier !== $this->tier) {
            $this->update(['tier' => $newTier]);
        }
    }

    /**
     * Mettre à jour le streak journalier
     */
    public function updateStreak(): void
    {
        $today = today();
        
        if ($this->last_active_date?->isYesterday()) {
            // Continuer le streak
            $this->increment('current_streak_days');
        } elseif (!$this->last_active_date?->isToday()) {
            // Nouveau streak
            $this->update(['current_streak_days' => 1]);
        }

        $this->update(['last_active_date' => $today]);
    }

    /**
     * Ajouter un badge
     */
    public function addBadge(string $badge): void
    {
        $badges = $this->badges ?? [];
        
        if (!in_array($badge, $badges)) {
            $badges[] = $badge;
            $this->update(['badges' => $badges]);
        }
    }

    /**
     * Obtenir les bénéfices du tier actuel
     */
    public function getTierBenefitsAttribute(): array
    {
        return self::TIER_BENEFITS[$this->tier ?? self::TIER_BRONZE];
    }

    // ──────────────────────────────────────────
    // FIABILITÉ
    // ──────────────────────────────────────────

    /**
     * Recalculer le score de fiabilité
     */
    public function recalculateReliabilityScore(): void
    {
        // Score pondéré:
        // - Taux d'acceptation: 20%
        // - Taux de complétion: 40%
        // - Taux de ponctualité: 30%
        // - Note moyenne: 10%
        
        $score = 
            ($this->acceptance_rate ?? 0) * 0.20 +
            ($this->completion_rate ?? 0) * 0.40 +
            ($this->on_time_rate ?? 0) * 0.30 +
            (($this->rating ?? 0) / 5 * 100) * 0.10;

        $this->update(['reliability_score' => round($score, 2)]);
    }

    /**
     * Calculer le score de priorité pour l'assignation
     * Plus le score est élevé, plus le livreur est prioritaire
     */
    public function getPriorityScoreAttribute(): float
    {
        $baseScore = $this->reliability_score ?? 50;
        $tierMultiplier = $this->tier_benefits['priority_multiplier'] ?? 1.0;
        
        // Bonus pour streak actif
        $streakBonus = min($this->current_streak_days * 2, 20); // Max +20 points
        
        return ($baseScore + $streakBonus) * $tierMultiplier;
    }

    /**
     * Scope: Livreurs triés par score de priorité
     */
    public function scopeOrderByPriority($query)
    {
        // Approximation SQL du score de priorité
        return $query->orderByDesc('reliability_score')
            ->orderByDesc('tier')
            ->orderByDesc('current_streak_days')
            ->orderByDesc('rating');
    }

    /**
     * Scope: Livreurs avec un shift actif dans une zone
     */
    public function scopeWithActiveShiftInZone($query, string $zoneId)
    {
        return $query->whereHas('shifts', function ($q) use ($zoneId) {
            $q->active()->today()->where('zone_id', $zoneId);
        });
    }
}
