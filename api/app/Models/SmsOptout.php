<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SmsOptout extends Model
{
    protected $fillable = ['phone', 'reason', 'opted_out_at'];

    protected $casts = [
        'opted_out_at' => 'datetime',
    ];
}
