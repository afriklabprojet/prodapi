<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Category extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'pharmacy_id',
        'name',
        'slug',
        'description',
        'image',
        'icon',
        'is_active',
        'order',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'order' => 'integer',
        'pharmacy_id' => 'integer',
    ];

    /**
     * Produits de cette catégorie
     */
    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    /**
     * Pharmacie propriétaire (NULL = catégorie globale)
     */
    public function pharmacy(): BelongsTo
    {
        return $this->belongsTo(Pharmacy::class);
    }

    /**
     * Scope : catégories globales (admin)
     */
    public function scopeGlobal(Builder $query): Builder
    {
        return $query->whereNull('pharmacy_id');
    }

    /**
     * Scope : catégories visibles par une pharmacie = globales + les siennes
     */
    public function scopeVisibleTo(Builder $query, int $pharmacyId): Builder
    {
        return $query->where(function ($q) use ($pharmacyId) {
            $q->whereNull('pharmacy_id')->orWhere('pharmacy_id', $pharmacyId);
        });
    }
}
