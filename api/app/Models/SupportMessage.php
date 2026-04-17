<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SupportMessage extends Model
{
    protected $fillable = [
        'support_ticket_id',
        'user_id',
        'message',
        'attachment',
        'is_from_support',
        'read_at',
    ];

    protected $casts = [
        'is_from_support' => 'boolean',
        'read_at' => 'datetime',
    ];

    /**
     * Ticket parent
     */
    public function supportTicket(): BelongsTo
    {
        return $this->belongsTo(SupportTicket::class);
    }

    /**
     * Auteur du message
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
