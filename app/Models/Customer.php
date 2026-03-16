<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Customer extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
    ];

    /**
     * L'utilisateur associé au profil client
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
