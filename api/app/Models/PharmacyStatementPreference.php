<?php

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PharmacyStatementPreference extends Model
{
    protected $fillable = [
        'pharmacy_id',
        'frequency',
        'format',
        'auto_send',
        'email',
        'next_send_at',
        'last_sent_at',
    ];

    protected $casts = [
        'auto_send' => 'boolean',
        'next_send_at' => 'datetime',
        'last_sent_at' => 'datetime',
    ];

    /**
     * Pharmacie associée
     */
    public function pharmacy(): BelongsTo
    {
        return $this->belongsTo(Pharmacy::class);
    }

    /**
     * Email effectif (préférence ou premier utilisateur de la pharmacie)
     */
    public function getEffectiveEmailAttribute(): ?string
    {
        return $this->email ?? $this->pharmacy?->users?->first()?->email;
    }

    /**
     * Libellé de la fréquence
     */
    public function getFrequencyLabelAttribute(): string
    {
        return match ($this->frequency) {
            'weekly' => 'Hebdomadaire',
            'quarterly' => 'Trimestriel',
            default => 'Mensuel',
        };
    }

    /**
     * Programmer le prochain envoi selon la fréquence
     */
    public function scheduleNextSend(): void
    {
        $this->update([
            'last_sent_at' => now(),
            'next_send_at' => match ($this->frequency) {
                'weekly' => now()->addWeek(),
                'quarterly' => now()->addQuarter(),
                default => now()->addMonth(),
            },
        ]);
    }

    /**
     * Scope: préférences dues pour envoi
     */
    public function scopeDueForSending($query)
    {
        return $query->where('auto_send', true)
            ->where('next_send_at', '<=', now());
    }

    /**
     * Calculer la période du relevé selon la fréquence
     */
    public function getStatementPeriod(): array
    {
        $now = Carbon::now();

        return match ($this->frequency) {
            'weekly' => [
                'start' => $now->copy()->subWeek()->startOfWeek(),
                'end' => $now->copy()->subWeek()->endOfWeek(),
            ],
            'quarterly' => [
                'start' => $now->copy()->subQuarter()->startOfQuarter(),
                'end' => $now->copy()->subQuarter()->endOfQuarter(),
            ],
            default => [ // monthly
                'start' => $now->copy()->subMonth()->startOfMonth(),
                'end' => $now->copy()->subMonth()->endOfMonth(),
            ],
        };
    }
}
