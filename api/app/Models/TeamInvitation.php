<?php

namespace App\Models;

use App\Enums\PharmacyRole;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class TeamInvitation extends Model
{
    use HasFactory;

    protected $fillable = [
        'pharmacy_id',
        'invited_by',
        'email',
        'phone',
        'role',
        'token',
        'status',
        'expires_at',
        'accepted_at',
    ];

    protected function casts(): array
    {
        return [
            'role' => PharmacyRole::class,
            'expires_at' => 'datetime',
            'accepted_at' => 'datetime',
        ];
    }

    public function pharmacy(): BelongsTo
    {
        return $this->belongsTo(Pharmacy::class);
    }

    public function invitedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'invited_by');
    }

    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }

    public function isPending(): bool
    {
        return $this->status === 'pending' && !$this->isExpired();
    }

    /**
     * Génère un token unique pour l'invitation
     */
    public static function generateToken(): string
    {
        do {
            $token = Str::random(32);
        } while (self::where('token', $token)->exists());

        return $token;
    }

    /**
     * Marque l'invitation comme acceptée et ajoute l'utilisateur à la pharmacie
     */
    public function accept(User $user): void
    {
        $this->update([
            'status' => 'accepted',
            'accepted_at' => now(),
        ]);

        // Ajouter l'utilisateur à la pharmacie avec le rôle spécifié
        $this->pharmacy->users()->syncWithoutDetaching([
            $user->id => ['role' => $this->role->value],
        ]);
    }

    public function decline(): void
    {
        $this->update(['status' => 'declined']);
    }
}
