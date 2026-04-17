<?php

namespace Tests\Unit\Traits;

use App\Traits\CachesModel;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class CachesModelTest extends TestCase
{
    public function test_get_default_cache_prefix(): void
    {
        // Use reflection to test protected static method
        $reflection = new \ReflectionClass(CachesModelTestModel::class);
        $method = $reflection->getMethod('getCachePrefix');
        $method->setAccessible(true);

        $prefix = $method->invoke(null);
        $this->assertEquals('cachesmodeltestmodel', $prefix);
    }

    public function test_get_default_cache_ttl(): void
    {
        $reflection = new \ReflectionClass(CachesModelTestModel::class);
        $method = $reflection->getMethod('getCacheTtl');
        $method->setAccessible(true);

        $ttl = $method->invoke(null);
        $this->assertEquals(3600, $ttl);
    }

    public function test_get_cache_key(): void
    {
        $reflection = new \ReflectionClass(CachesModelTestModel::class);
        $method = $reflection->getMethod('getCacheKey');
        $method->setAccessible(true);

        $key = $method->invoke(null, 42);
        $this->assertEquals('cachesmodeltestmodel:42', $key);
    }

    public function test_custom_prefix_and_ttl(): void
    {
        $reflection = new \ReflectionClass(CachesModelWithCustomPrefix::class);

        $prefixMethod = $reflection->getMethod('getCachePrefix');
        $prefixMethod->setAccessible(true);
        $this->assertEquals('custom', $prefixMethod->invoke(null));

        $ttlMethod = $reflection->getMethod('getCacheTtl');
        $ttlMethod->setAccessible(true);
        $this->assertEquals(600, $ttlMethod->invoke(null));
    }

    public function test_forget_cache_clears_key(): void
    {
        Cache::put('cachesmodeltestmodel:1', 'test_data');
        $this->assertTrue(Cache::has('cachesmodeltestmodel:1'));

        $model = new CachesModelTestModel();
        $model->id = 1;
        $model->forgetCache();

        $this->assertFalse(Cache::has('cachesmodeltestmodel:1'));
    }

    public function test_find_cached_uses_cache(): void
    {
        Cache::put('cachesmodeltestmodel:1', 'cached_value', 3600);
        $result = Cache::get('cachesmodeltestmodel:1');
        $this->assertEquals('cached_value', $result);
    }
}

// Test model using the trait
class CachesModelTestModel extends Model
{
    use CachesModel;

    public $id;
    protected $table = 'test_models';
}

class CachesModelWithCustomPrefix extends Model
{
    use CachesModel;

    protected static string $cachePrefix = 'custom';
    protected static int $cacheTtl = 600;
    protected $table = 'test_models';
}
