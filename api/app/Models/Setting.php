<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class Setting extends Model
{
    protected $fillable = ['key', 'value', 'type'];

    public $timestamps = true;

    private const CACHE_PREFIX = 'setting:';
    private const CACHE_TTL = 600; // 10 min

    /**
     * Récupérer une valeur de setting avec cache
     */
    public static function get(string $key, mixed $default = null): mixed
    {
        $cacheKey = self::CACHE_PREFIX . $key;

        return Cache::remember($cacheKey, self::CACHE_TTL, function () use ($key, $default) {
            $setting = static::where('key', $key)->first();

            if (!$setting) {
                return $default;
            }

            return self::castValue($setting->value, $setting->type ?? 'string');
        });
    }

    /**
     * Définir une valeur de setting (invalide le cache)
     */
    public static function set(string $key, mixed $value, string $type = 'string'): void
    {
        static::updateOrCreate(
            ['key' => $key],
            ['value' => (string) $value, 'type' => $type]
        );

        Cache::forget(self::CACHE_PREFIX . $key);
        Cache::forget('settings:all');
    }

    /**
     * Récupérer tous les settings avec cache
     */
    public static function allCached(): array
    {
        return Cache::remember('settings:all', self::CACHE_TTL, function () {
            return static::pluck('value', 'key')->toArray();
        });
    }

    /**
     * Invalider tout le cache settings
     */
    public static function clearCache(): void
    {
        $settings = static::pluck('key');
        foreach ($settings as $key) {
            Cache::forget(self::CACHE_PREFIX . $key);
        }
        Cache::forget('settings:all');
    }

    /**
     * Caster la valeur selon le type
     */
    private static function castValue(string $value, string $type): mixed
    {
        return match ($type) {
            'integer', 'int' => (int) $value,
            'float', 'double' => (float) $value,
            'boolean', 'bool' => filter_var($value, FILTER_VALIDATE_BOOLEAN),
            'json', 'array' => json_decode($value, true) ?? [],
            default => $value,
        };
    }

    /**
     * Boot: clear cache on save/update/delete
     */
    protected static function boot()
    {
        parent::boot();

        static::saved(function (Setting $setting) {
            Cache::forget(self::CACHE_PREFIX . $setting->key);
            Cache::forget('settings:all');
        });

        static::deleted(function (Setting $setting) {
            Cache::forget(self::CACHE_PREFIX . $setting->key);
            Cache::forget('settings:all');
        });
    }
}
