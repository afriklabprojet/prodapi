<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Casts\Attribute;

class Prescription extends Model
{
    use HasFactory;

    protected $fillable = [
        'customer_id',
        'pharmacy_id',
        'order_id',
        'images',
        'notes',
        'status',
        'source',
        'admin_notes',
        'validated_at',
        'validated_by',
        'quote_amount',
        'pharmacy_notes',
        // OCR fields
        'extracted_medications',
        'matched_products',
        'unmatched_medications',
        'ocr_confidence',
        'analyzed_at',
        'analysis_status',
        'analysis_error',
        'ocr_raw_text',
        // Dispensing fields
        'fulfillment_status',
        'dispensing_count',
        'first_dispensed_at',
        'image_hash',
        'image_phash',
        'image_ahash',
        'image_shash',
        'content_hash',
    ];

    protected $casts = [
        'validated_at' => 'datetime',
        'analyzed_at' => 'datetime',
        'first_dispensed_at' => 'datetime',
        'extracted_medications' => 'array',
        'matched_products' => 'array',
        'unmatched_medications' => 'array',
        'ocr_confidence' => 'decimal:2',
    ];

    /**
     * Get the images attribute with absolute URLs.
     * Converts relative paths to full URLs via secure document endpoint.
     */
    protected function images(): Attribute
    {
        return Attribute::make(
            get: function ($value) {
                $images = is_string($value) ? json_decode($value, true) : $value;
                
                if (empty($images) || !is_array($images)) {
                    return [];
                }

                return array_map(function ($path) {
                    if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
                        return $path;
                    }

                    return url('/api/documents/' . $path);
                }, $images);
            },
            set: function ($value) {
                return is_array($value) ? json_encode($value) : $value;
            }
        );
    }

    /**
     * Get raw images paths without URL transformation (for internal use).
     */
    public function getRawImages(): array
    {
        $value = $this->attributes['images'] ?? null;
        $images = is_string($value) ? json_decode($value, true) : $value;
        return is_array($images) ? $images : [];
    }

    /**
     * Prescription statuses
     */
    const STATUS_PENDING = 'pending';
    const STATUS_VALIDATED = 'validated';
    const STATUS_REJECTED = 'rejected';
    const STATUS_COMPLETED = 'completed'; // Quand la commande associée est livrée

    /**
     * Prescription sources
     */
    const SOURCE_UPLOAD = 'upload';       // Uploadée via "Mes Ordonnances"
    const SOURCE_CHECKOUT = 'checkout';   // Uploadée lors du checkout

    /**
     * Get the customer that owns the prescription
     */
    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    /**
     * Get the order associated with this prescription
     */
    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    /**
     * Get the admin who validated the prescription
     */
    public function validator()
    {
        return $this->belongsTo(User::class, 'validated_by');
    }

    /**
     * Check if prescription is from checkout
     */
    public function isFromCheckout(): bool
    {
        return $this->source === self::SOURCE_CHECKOUT;
    }

    /**
     * Check if prescription has an associated order
     */
    public function hasOrder(): bool
    {
        return $this->order_id !== null;
    }

    /**
     * Scope for pending prescriptions
     */
    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    /**
     * Scope for validated prescriptions
     */
    public function scopeValidated($query)
    {
        return $query->where('status', self::STATUS_VALIDATED);
    }

    /**
     * Scope for prescriptions from checkout
     */
    public function scopeFromCheckout($query)
    {
        return $query->where('source', self::SOURCE_CHECKOUT);
    }

    /**
     * Check if prescription is pending
     */
    public function isPending(): bool
    {
        return $this->status === self::STATUS_PENDING;
    }

    /**
     * Check if prescription is validated
     */
    public function isValidated(): bool
    {
        return $this->status === self::STATUS_VALIDATED;
    }

    /**
     * Get all dispensings for this prescription
     */
    public function dispensings()
    {
        return $this->hasMany(PrescriptionDispensing::class);
    }

    /**
     * Check if prescription is fully dispensed
     */
    public function isFullyDispensed(): bool
    {
        return $this->fulfillment_status === 'full';
    }

    /**
     * Check if prescription is partially dispensed
     */
    public function isPartiallyDispensed(): bool
    {
        return $this->fulfillment_status === 'partial';
    }

    /**
     * Recalculate fulfillment status based on dispensings
     */
    public function recalculateFulfillment(): void
    {
        $dispensings = $this->dispensings()->get();
        $this->dispensing_count = $dispensings->count();

        if ($dispensings->isEmpty()) {
            $this->fulfillment_status = 'none';
        } else {
            // Check if all prescribed medications have been fully dispensed
            $medications = $this->extracted_medications ?? [];
            if (empty($medications)) {
                // No OCR data — any dispensing means at least partial
                $this->fulfillment_status = 'partial';
            } else {
                $totalPrescribed = count($medications);
                $dispensedMeds = $dispensings->pluck('medication_name')->unique()->count();
                $this->fulfillment_status = $dispensedMeds >= $totalPrescribed ? 'full' : 'partial';
            }

            if (!$this->first_dispensed_at) {
                $this->first_dispensed_at = $dispensings->min('dispensed_at');
            }
        }

        $this->save();
    }
}
