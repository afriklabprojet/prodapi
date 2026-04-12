<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Str;

class SupportTicket extends Model
{
    protected $fillable = [
        'user_id',
        'reference',
        'category',
        'subject',
        'description',
        'status',
        'priority',
        'metadata',
        'resolved_at',
    ];

    protected $casts = [
        'metadata' => 'array',
        'resolved_at' => 'datetime',
    ];

    protected static function booted(): void
    {
        static::creating(function (SupportTicket $ticket) {
            if (empty($ticket->reference)) {
                $ticket->reference = 'TK-' . strtoupper(Str::random(8));
            }
        });
    }

    /**
     * Utilisateur ayant ouvert le ticket
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Messages du ticket
     */
    public function messages(): HasMany
    {
        return $this->hasMany(SupportMessage::class);
    }

    /**
     * Dernier message
     */
    public function latestMessage(): HasOne
    {
        return $this->hasOne(SupportMessage::class)->latestOfMany();
    }

    /**
     * Scope: tickets d'un utilisateur
     */
    public function scopeForUser($query, int $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * Scope: tickets ouverts
     */
    public function scopeOpen($query)
    {
        return $query->where('status', 'open');
    }

    /**
     * Marquer comme résolu
     */
    public function markAsResolved(): void
    {
        $this->update([
            'status' => 'resolved',
            'resolved_at' => now(),
        ]);
    }

    /**
     * Réouvrir le ticket
     */
    public function reopen(): void
    {
        $this->update([
            'status' => 'open',
            'resolved_at' => null,
        ]);
    }
}
