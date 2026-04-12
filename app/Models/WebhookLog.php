<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WebhookLog extends Model
{
    protected $fillable = [
        'provider',
        'webhook_id',
        'event_type',
        'reference',
        'status',
        'payload',
        'ip_address',
        'processed',
        'error_message',
        'attempts',
    ];

    protected $casts = [
        'payload' => 'array',
        'processed' => 'boolean',
        'attempts' => 'integer',
    ];

    public function scopeUnprocessed($query)
    {
        return $query->where('processed', false);
    }

    public function scopeForProvider($query, string $provider)
    {
        return $query->where('provider', $provider);
    }

    public function markProcessed(): void
    {
        $this->update([
            'processed' => true,
            'attempts' => $this->attempts + 1,
        ]);
    }

    public function markFailed(string $error): void
    {
        $this->update([
            'error_message' => $error,
            'attempts' => $this->attempts + 1,
        ]);
    }
}
