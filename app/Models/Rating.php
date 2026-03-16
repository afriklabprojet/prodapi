<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class Rating extends Model
{
    protected $fillable = [
        'user_id',
        'order_id',
        'rateable_type',
        'rateable_id',
        'rating',
        'comment',
        'tags',
    ];

    protected $casts = [
        'rating' => 'integer',
        'tags' => 'array',
    ];

    // ── Relations ────────────────────────────────────────────────

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function rateable(): MorphTo
    {
        return $this->morphTo();
    }

    // ── Scopes ───────────────────────────────────────────────────

    public function scopeForType($query, string $type)
    {
        return $query->where('rateable_type', $type);
    }

    public function scopeForRateable($query, string $type, int $id)
    {
        return $query->where('rateable_type', $type)->where('rateable_id', $id);
    }
}
