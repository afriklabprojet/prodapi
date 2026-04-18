<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\Pivot;

class PharmacyUser extends Pivot
{
    protected $table = 'pharmacy_user';
}
