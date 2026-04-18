<?php

namespace App\Models;

use App\Enums\MessageType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * Message d'une session de chat persistante.
 *
 * Structure analogue à DeliveryMessage mais liée à ChatSession
 * plutôt qu'à une livraison.
 *
 * @property int              $id
 * @property int              $session_id
 * @property string           $sender_type   'pharmacy_user' | 'customer'
 * @property int              $sender_id
 * @property string           $message
 * @property \App\Enums\MessageType $type
 * @property array|null       $metadata
 * @property \Carbon\Carbon|null $read_at
 * @property \Carbon\Carbon   $created_at
 * @property \Carbon\Carbon   $updated_at
 */
class ChatSessionMessage extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'session_id',
        'sender_type',
        'sender_id',
        'message',
        'type',
        'metadata',
        'read_at',
    ];

    protected $casts = [
        'read_at'  => 'datetime',
        'metadata' => 'array',
        'type'     => MessageType::class,
    ];

    // ── Relations ──────────────────────────────────────────────────────────

    public function session(): BelongsTo
    {
        return $this->belongsTo(ChatSession::class, 'session_id');
    }
}
