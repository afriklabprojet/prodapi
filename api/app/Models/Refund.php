<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Refund extends Model
{
    use HasFactory;

    public const STATUS_PENDING = 'pending';
    public const STATUS_APPROVED = 'approved';
    public const STATUS_REJECTED = 'rejected';
    public const STATUS_PROCESSED = 'processed';

    public const TYPE_FULL = 'full';
    public const TYPE_PARTIAL = 'partial';

    public const METHOD_WALLET = 'wallet';
    public const METHOD_PAYOUT = 'payout';
    public const METHOD_MANUAL = 'manual';

    public const SOURCE_CUSTOMER = 'customer_request';
    public const SOURCE_AUTO_PHARMACIST_REJECT = 'auto_pharmacist_reject';
    public const SOURCE_AUTO_DELIVERY_FAILED = 'auto_delivery_failed';
    public const SOURCE_ADMIN = 'admin';

    protected $fillable = [
        'user_id',
        'order_id',
        'amount',
        'reason',
        'type',
        'method',
        'source',
        'status',
        'admin_note',
        'processed_by',
        'processed_at',
        'wallet_transaction_id',
        'payout_reference',
        'decided_by',
        'decided_at',
        'notified_at',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'processed_at' => 'datetime',
        'decided_at' => 'datetime',
        'notified_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function decider(): BelongsTo
    {
        return $this->belongsTo(User::class, 'decided_by');
    }

    public function processor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'processed_by');
    }

    public function walletTransaction(): BelongsTo
    {
        return $this->belongsTo(WalletTransaction::class, 'wallet_transaction_id');
    }

    public function isPending(): bool
    {
        return $this->status === self::STATUS_PENDING;
    }

    public function isFinal(): bool
    {
        return in_array($this->status, [self::STATUS_REJECTED, self::STATUS_PROCESSED], true);
    }
}
