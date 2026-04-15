<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class Product extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'pharmacy_id',
        'category_id', // Add category_id
        'name',
        'slug',
        'description',
        'category', // Keep for backward compatibility (or to remove later)
        'brand',
        'price',
        'discount_price',
        'promotion_end_date',
        'stock_quantity',
        'low_stock_threshold',
        'sku',
        'barcode',
        'image',
        'images',
        'requires_prescription',
        'is_available',
        'delivery_option',
        'is_featured',
        'unit',
        'units_per_pack',
        'expiry_date',
        'manufacturer',
        'active_ingredient',
        'usage_instructions',
        'side_effects',
        'tags',
        'views_count',
        'sales_count',
        'average_rating',
        'reviews_count',
    ];

    protected $casts = [
        'price' => 'float',
        'discount_price' => 'float',
        'promotion_end_date' => 'date',
        'requires_prescription' => 'boolean',
        'is_available' => 'boolean',
        'is_featured' => 'boolean',
        'expiry_date' => 'date',
        'images' => 'array',
        'tags' => 'array',
        'average_rating' => 'float',
    ];

    protected $appends = [
        'final_price',
        'discount_percentage',
        'is_low_stock',
        'is_out_of_stock',
        'is_expired',
        'category_name',
    ];

    /**
     * Get the product's image full URL.
     *
     * @param  string  $value
     * @return string|null
     */
    public function getImageAttribute($value)
    {
        if (!$value) {
            return null;
        }
        
        if (Str::startsWith($value, ['http://', 'https://'])) {
            return $value;
        }

        // Use direct storage URL - symlink serves static files via Nginx
        return url('/storage/' . $value);
    }

    /**
     * Boot method
     */
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($product) {
            if (empty($product->slug)) {
                $product->slug = Str::slug($product->name) . '-' . $product->pharmacy_id;
            }
        });

        static::updating(function ($product) {
            if ($product->isDirty('name') || $product->isDirty('pharmacy_id')) {
                $product->slug = Str::slug($product->name) . '-' . $product->pharmacy_id;
            }
        });
    }

    /**
     * Pharmacy relationship
     */
    public function pharmacy(): BelongsTo
    {
        return $this->belongsTo(Pharmacy::class);
    }

    /**
     * Order items relationship
     */
    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    /**
     * Category relationship
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }
    
    // Accessor renamed to avoid conflict with category() BelongsTo
    public function getCategoryNameAttribute(): string
    {
        if ($this->category_id && !$this->relationLoaded('category')) {
             $this->load('category');
        }
        
        return $this->getRelation('category')?->name ?? 'Non classé';
    }

    /**
     * Get final price (with discount if applicable)
     */
    public function getFinalPriceAttribute(): float
    {
        return $this->discount_price ?? $this->price;
    }

    /**
     * Get the current price (alias for final_price).
     */
    public function getCurrentPrice(): float
    {
        return $this->final_price;
    }

    /**
     * Get discount percentage
     */
    public function getDiscountPercentageAttribute(): ?int
    {
        if ($this->discount_price && $this->discount_price < $this->price) {
            return (int) round((($this->price - $this->discount_price) / $this->price) * 100);
        }
        return null;
    }

    /**
     * Check if product is low stock
     */
    public function getIsLowStockAttribute(): bool
    {
        return $this->stock_quantity > 0 && $this->stock_quantity <= $this->low_stock_threshold;
    }

    /**
     * Check if product is out of stock
     */
    public function getIsOutOfStockAttribute(): bool
    {
        return $this->stock_quantity <= 0;
    }

    /**
     * Check if product is expired
     */
    public function getIsExpiredAttribute(): bool
    {
        if (!$this->expiry_date) {
            return false;
        }
        return $this->expiry_date->isPast();
    }

    /**
     * Scope: Available products
     */
    public function scopeAvailable($query)
    {
        return $query->where('is_available', true)
            ->where('stock_quantity', '>', 0)
            ->where(function ($q) {
                $q->whereNull('expiry_date')
                    ->orWhere('expiry_date', '>', now());
            });
    }

    /**
     * Scope: Featured products
     */
    public function scopeFeatured($query)
    {
        return $query->where('is_featured', true);
    }

    /**
     * Scope: By pharmacy
     */
    public function scopeForPharmacy($query, int $pharmacyId)
    {
        return $query->where('pharmacy_id', $pharmacyId);
    }

    /**
     * Scope: By category
     */
    public function scopeInCategory($query, string $category)
    {
        return $query->where('category', $category);
    }

    /**
     * Scope: Search by name or description
     */
    public function scopeSearch($query, string $search)
    {
        return $query->where(function ($q) use ($search) {
            $q->where('name', 'like', "%{$search}%")
                ->orWhere('description', 'like', "%{$search}%")
                ->orWhere('active_ingredient', 'like', "%{$search}%")
                ->orWhere('brand', 'like', "%{$search}%");
        });
    }

    /**
     * Scope: Low stock products
     */
    public function scopeLowStock($query)
    {
        return $query->whereColumn('stock_quantity', '<=', 'low_stock_threshold')
            ->where('stock_quantity', '>', 0);
    }

    /**
     * Scope: Out of stock products
     */
    public function scopeOutOfStock($query)
    {
        return $query->where('stock_quantity', '<=', 0);
    }

    /**
     * Increment view count
     */
    public function incrementViews(): void
    {
        $this->increment('views_count');
    }

    /**
     * Increment sales count
     */
    public function incrementSales(int $quantity = 1): void
    {
        $this->increment('sales_count', $quantity);
    }

    /**
     * Decrease stock quantity
     */
    public function decreaseStock(int $quantity): bool
    {
        if ($this->stock_quantity < $quantity) {
            return false;
        }

        $this->decrement('stock_quantity', $quantity);
        return true;
    }

    /**
     * Increase stock quantity
     */
    public function increaseStock(int $quantity): void
    {
        $this->increment('stock_quantity', $quantity);
    }
}
