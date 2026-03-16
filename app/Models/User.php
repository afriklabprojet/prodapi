<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;

class User extends Authenticatable implements FilamentUser
{
    use HasFactory, Notifiable, HasApiTokens;
    
    public function canAccessPanel(Panel $panel): bool
    {
        return $this->role === 'admin';
    }

    protected $fillable = [
        'name',
        'email',
        'password',
        'phone',
        'role',
        'avatar',
        'phone_verified_at',
        'fcm_token',
        'firebase_uid',
        'last_notification_read_at',
        'must_change_password',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'phone_verified_at' => 'datetime',
            'password' => 'hashed',
            'must_change_password' => 'boolean',
        ];
    }

    /**
     * Pharmacies associées à cet utilisateur
     */
    public function pharmacies(): BelongsToMany
    {
        return $this->belongsToMany(Pharmacy::class, 'pharmacy_user')
            ->withPivot('role')
            ->withTimestamps();
    }

    /**
     * Profil livreur si l'utilisateur est un livreur
     */
    public function courier(): HasOne
    {
        return $this->hasOne(Courier::class);
    }

    /**
     * Commandes passées par ce client
     */
    public function orders(): HasMany
    {
        return $this->hasMany(Order::class, 'customer_id');
    }

    /**
     * Ordonnances envoyées par ce client
     */
    public function prescriptions(): HasMany
    {
        return $this->hasMany(Prescription::class, 'customer_id');
    }

    /**
     * Adresses de livraison du client
     */
    public function addresses(): HasMany
    {
        return $this->hasMany(CustomerAddress::class);
    }

    /**
     * Adresse par défaut du client
     */
    public function defaultAddress(): HasOne
    {
        return $this->hasOne(CustomerAddress::class)->where('is_default', true);
    }

    /**
     * Vérifier si l'utilisateur est admin
     */
    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    /**
     * Vérifier si l'utilisateur est pharmacien
     */
    public function isPharmacy(): bool
    {
        return $this->role === 'pharmacy';
    }

    /**
     * Vérifier si l'utilisateur est livreur
     */
    public function isCourier(): bool
    {
        return $this->role === 'courier';
    }

    /**
     * Vérifier si l'utilisateur est client
     */
    public function isCustomer(): bool
    {
        return $this->role === 'customer';
    }
}

