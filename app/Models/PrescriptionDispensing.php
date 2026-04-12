<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PrescriptionDispensing extends Model
{
    protected $fillable = [
        'prescription_id',
        'pharmacy_id',
        'order_id',
        'medication_name',
        'product_id',
        'quantity_prescribed',
        'quantity_dispensed',
        'dispensed_at',
        'dispensed_by',
    ];

    protected $casts = [
        'dispensed_at' => 'datetime',
        'quantity_prescribed' => 'integer',
        'quantity_dispensed' => 'integer',
    ];

    public function prescription(): BelongsTo
    {
        return $this->belongsTo(Prescription::class);
    }

    public function pharmacy(): BelongsTo
    {
        return $this->belongsTo(Pharmacy::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function dispensedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'dispensed_by');
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }
}
