<?php

namespace App\Traits;

use Illuminate\Support\Facades\Cache;

/**
 * Trait pour ajouter du caching automatique aux modèles Eloquent.
 * 
 * Usage:
 * - Ajouter `use CachesModel;` dans le modèle
 * - Définir optionnellement $cacheTtl, $cachePrefix
 */
trait CachesModel
{
    /**
     * Boot le trait
     */
    public static function bootCachesModel(): void
    {
        // Invalider le cache après save
        static::saved(function ($model) {
            $model->forgetCache();
        });

        // Invalider le cache après delete
        static::deleted(function ($model) {
            $model->forgetCache();
        });
    }

    /**
     * Récupérer depuis le cache ou la DB
     */
    public static function findCached(int $id): ?static
    {
        $key = self::getCacheKey($id);
        $ttl = self::getCacheTtl();

        return Cache::remember($key, $ttl, function () use ($id) {
            return static::find($id);
        });
    }

    /**
     * Récupérer depuis le cache ou la DB avec relations
     */
    public static function findCachedWith(int $id, array $relations): ?static
    {
        $key = self::getCacheKey($id) . ':with:' . implode('-', $relations);
        $ttl = self::getCacheTtl();

        return Cache::remember($key, $ttl, function () use ($id, $relations) {
            return static::with($relations)->find($id);
        });
    }

    /**
     * Invalider le cache du modèle
     */
    public function forgetCache(): void
    {
        $key = self::getCacheKey($this->id);
        Cache::forget($key);
        
        // Aussi invalider les variations avec relations
        $patterns = Cache::get(self::getCachePatternKey(), []);
        foreach ($patterns as $pattern) {
            Cache::forget($pattern);
        }
    }

    /**
     * Générer la clé de cache
     */
    protected static function getCacheKey(int $id): string
    {
        $prefix = self::getCachePrefix();
        return "{$prefix}:{$id}";
    }

    /**
     * Obtenir le préfixe de cache
     */
    protected static function getCachePrefix(): string
    {
        return property_exists(static::class, 'cachePrefix')
            ? static::$cachePrefix
            : strtolower(class_basename(static::class));
    }

    /**
     * Obtenir le TTL du cache
     */
    protected static function getCacheTtl(): int
    {
        return property_exists(static::class, 'cacheTtl')
            ? static::$cacheTtl
            : 3600; // 1 heure par défaut
    }

    /**
     * Clé pour stocker les patterns de cache
     */
    protected static function getCachePatternKey(): string
    {
        return self::getCachePrefix() . ':patterns';
    }
}
