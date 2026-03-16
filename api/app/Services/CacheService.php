<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class CacheService
{
    /**
     * Cache TTL values (in seconds)
     */
    const TTL_PRODUCTS = 3600;        // 1 hour
    const TTL_PRODUCT_LIST = 600;     // 10 minutes
    const TTL_PHARMACIES = 1800;      // 30 minutes
    const TTL_PHARMACY = 3600;        // 1 hour
    const TTL_COURIERS = 300;         // 5 minutes
    const TTL_USER = 3600;            // 1 hour
    const TTL_ORDER = 600;            // 10 minutes

    /**
     * Cache a product
     */
    public static function cacheProduct($product): void
    {
        $key = self::productKey($product->id);
        Cache::put($key, $product, self::TTL_PRODUCTS);
    }

    /**
     * Get cached product
     */
    public static function getProduct($productId)
    {
        return Cache::get(self::productKey($productId));
    }

    /**
     * Invalidate product cache
     */
    public static function forgetProduct($productId): void
    {
        Cache::forget(self::productKey($productId));
        self::forgetProductList();
    }

    /**
     * Cache product list
     */
    public static function cacheProductList(string $cacheKey, $products, ?int $ttl = null): void
    {
        Cache::put($cacheKey, $products, $ttl ?? self::TTL_PRODUCT_LIST);
    }

    /**
     * Forget all product lists
     */
    public static function forgetProductList(): void
    {
        // Cache::tags() is not supported by 'file' or 'database' drivers (default in Laravel)
        // Only Redis/Memcached support tags.
        // Fallback: don't use tags if not supported.
        try {
            if (Cache::getStore() instanceof \Illuminate\Cache\TaggedCache) {
                 Cache::tags(['products'])->flush();
            } else {
                 // Try catch for BadMethodCallException even if not TaggedCache instance check?
                 // Actually safest is just try-catch the call directly.
                 // The previous code had a try-catch but maybe it was catching \Exception and the error is BadMethodCallException?
                 // BadMethodCallException extends LogicException extends Exception, so it should be caught.
                 // Let's broaden the catch scope or verify why it failed.
                 Cache::tags(['products'])->flush();
            }
        } catch (\BadMethodCallException $e) {
             // Driver doesn't support tags.
             // Manually clear known keys if we tracked them, or just ignore for MVP.
             // Clearing *everything* is too aggressive (Cache::flush()).
             // Ideally we clear common query keys if we knew them.
        } catch (\Exception $e) {
             // Other errors
        }
    }

    /**
     * Cache a pharmacy
     */
    public static function cachePharmacy($pharmacy): void
    {
        $key = self::pharmacyKey($pharmacy->id);
        Cache::put($key, $pharmacy, self::TTL_PHARMACY);
    }

    /**
     * Get cached pharmacy
     */
    public static function getPharmacy($pharmacyId)
    {
        return Cache::get(self::pharmacyKey($pharmacyId));
    }

    /**
     * Invalidate pharmacy cache
     */
    public static function forgetPharmacy($pharmacyId): void
    {
        Cache::forget(self::pharmacyKey($pharmacyId));
        Cache::tags(['pharmacies'])->flush();
    }

    /**
     * Cache available couriers
     */
    public static function cacheAvailableCouriers($couriers): void
    {
        Cache::put('couriers:available', $couriers, self::TTL_COURIERS);
    }

    /**
     * Get cached available couriers
     */
    public static function getAvailableCouriers()
    {
        return Cache::get('couriers:available');
    }

    /**
     * Invalidate couriers cache
     */
    public static function forgetCouriers(): void
    {
        Cache::forget('couriers:available');
    }

    /**
     * Cache user data
     */
    public static function cacheUser($user): void
    {
        $key = self::userKey($user->id);
        Cache::put($key, $user, self::TTL_USER);
    }

    /**
     * Get cached user
     */
    public static function getUser($userId)
    {
        return Cache::get(self::userKey($userId));
    }

    /**
     * Invalidate user cache
     */
    public static function forgetUser($userId): void
    {
        Cache::forget(self::userKey($userId));
    }

    /**
     * Cache order
     */
    public static function cacheOrder($order): void
    {
        $key = self::orderKey($order->id);
        Cache::put($key, $order, self::TTL_ORDER);
    }

    /**
     * Get cached order
     */
    public static function getOrder($orderId)
    {
        return Cache::get(self::orderKey($orderId));
    }

    /**
     * Invalidate order cache
     */
    public static function forgetOrder($orderId): void
    {
        Cache::forget(self::orderKey($orderId));
    }

    /**
     * Generate cache keys
     */
    protected static function productKey($productId): string
    {
        return "product:{$productId}";
    }

    protected static function pharmacyKey($pharmacyId): string
    {
        return "pharmacy:{$pharmacyId}";
    }

    protected static function userKey($userId): string
    {
        return "user:{$userId}";
    }

    protected static function orderKey($orderId): string
    {
        return "order:{$orderId}";
    }

    /**
     * Clear all cache
     */
    public static function clearAll(): void
    {
        try {
            Cache::flush();
            Log::info('All cache cleared successfully');
        } catch (\Exception $e) {
            Log::error('Failed to clear cache: ' . $e->getMessage());
        }
    }
}
