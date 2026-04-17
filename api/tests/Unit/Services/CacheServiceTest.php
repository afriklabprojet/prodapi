<?php

namespace Tests\Unit\Services;

use App\Services\CacheService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class CacheServiceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Cache::flush();
    }

    public function test_cache_and_get_product(): void
    {
        $product = (object) ['id' => 1, 'name' => 'Paracetamol'];
        CacheService::cacheProduct($product);

        $cached = CacheService::getProduct(1);
        $this->assertSame('Paracetamol', $cached->name);
    }

    public function test_get_product_returns_null_when_not_cached(): void
    {
        $this->assertNull(CacheService::getProduct(999));
    }

    public function test_forget_product_removes_cache(): void
    {
        $product = (object) ['id' => 2, 'name' => 'Aspirin'];
        CacheService::cacheProduct($product);
        CacheService::forgetProduct(2);

        $this->assertNull(CacheService::getProduct(2));
    }

    public function test_cache_and_get_pharmacy(): void
    {
        $pharmacy = (object) ['id' => 10, 'name' => 'Pharmacie Test'];
        CacheService::cachePharmacy($pharmacy);

        $cached = CacheService::getPharmacy(10);
        $this->assertSame('Pharmacie Test', $cached->name);
    }

    public function test_get_pharmacy_returns_null_when_not_cached(): void
    {
        $this->assertNull(CacheService::getPharmacy(999));
    }

    public function test_cache_and_get_available_couriers(): void
    {
        $couriers = [(object) ['id' => 1, 'name' => 'Yao']];
        CacheService::cacheAvailableCouriers($couriers);

        $cached = CacheService::getAvailableCouriers();
        $this->assertCount(1, $cached);
    }

    public function test_forget_couriers_removes_cache(): void
    {
        CacheService::cacheAvailableCouriers([(object) ['id' => 1]]);
        CacheService::forgetCouriers();

        $this->assertNull(CacheService::getAvailableCouriers());
    }

    public function test_cache_and_get_user(): void
    {
        $user = (object) ['id' => 5, 'name' => 'Jean'];
        CacheService::cacheUser($user);

        $cached = CacheService::getUser(5);
        $this->assertSame('Jean', $cached->name);
    }

    public function test_forget_user_removes_cache(): void
    {
        $user = (object) ['id' => 6, 'name' => 'Pierre'];
        CacheService::cacheUser($user);
        CacheService::forgetUser(6);

        $this->assertNull(CacheService::getUser(6));
    }

    public function test_cache_and_get_order(): void
    {
        $order = (object) ['id' => 100, 'reference' => 'ORD-100'];
        CacheService::cacheOrder($order);

        $cached = CacheService::getOrder(100);
        $this->assertSame('ORD-100', $cached->reference);
    }

    public function test_forget_order_removes_cache(): void
    {
        $order = (object) ['id' => 101, 'reference' => 'ORD-101'];
        CacheService::cacheOrder($order);
        CacheService::forgetOrder(101);

        $this->assertNull(CacheService::getOrder(101));
    }

    public function test_cache_product_list(): void
    {
        $products = [(object) ['id' => 1], (object) ['id' => 2]];
        CacheService::cacheProductList('products:search:test', $products);

        $cached = Cache::get('products:search:test');
        $this->assertCount(2, $cached);
    }

    public function test_cache_product_list_with_custom_ttl(): void
    {
        $products = [(object) ['id' => 1]];
        CacheService::cacheProductList('products:custom', $products, 120);

        $cached = Cache::get('products:custom');
        $this->assertCount(1, $cached);
    }

    public function test_clear_all_flushes_cache(): void
    {
        Cache::put('test_key', 'value', 60);
        CacheService::clearAll();

        $this->assertNull(Cache::get('test_key'));
    }

    public function test_ttl_constants_are_reasonable(): void
    {
        $this->assertSame(3600, CacheService::TTL_PRODUCTS);
        $this->assertSame(600, CacheService::TTL_PRODUCT_LIST);
        $this->assertSame(1800, CacheService::TTL_PHARMACIES);
        $this->assertSame(3600, CacheService::TTL_PHARMACY);
        $this->assertSame(300, CacheService::TTL_COURIERS);
        $this->assertSame(3600, CacheService::TTL_USER);
        $this->assertSame(600, CacheService::TTL_ORDER);
    }

    public function test_forget_product_list_does_not_throw(): void
    {
        // With array driver, tags are not supported, should not throw
        CacheService::forgetProductList();
        $this->assertTrue(true);
    }
}
