<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class FraudEvent extends Model
{
    public const SEVERITY_LOW = 'low';
    public const SEVERITY_MEDIUM = 'medium';
    public const SEVERITY_HIGH = 'high';
    public const SEVERITY_CRITICAL = 'critical';

    public const TYPE_PRESCRIPTION_REUSE = 'prescription_reuse';
    public const TYPE_PRESCRIPTION_REJECTED = 'prescription_rejected';
    public const TYPE_PAYMENT_REPLAY = 'payment_replay';
    public const TYPE_RAPID_ORDER_BURST = 'rapid_order_burst';
    public const TYPE_MULTI_ACCOUNT_DEVICE = 'multi_account_device';
    public const TYPE_VELOCITY_ABUSE = 'velocity_abuse';

    protected $fillable = [
        'type',
        'severity',
        'score',
        'user_id',
        'subject_type',
        'subject_id',
        'ip',
        'user_agent',
        'payload',
        'reviewed',
    ];

    protected $casts = [
        'payload' => 'array',
        'reviewed' => 'boolean',
        'score' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function subject(): MorphTo
    {
        return $this->morphTo();
    }
}
