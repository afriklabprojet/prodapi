<?php

namespace Tests\Unit\Observers;

use App\Models\Product;
use App\Observers\ProductObserver;
use App\Services\CacheService;
use App\Services\FirestoreService;
use Illuminate\Support\Facades\Log;
use Mockery;
use Tests\TestCase;

class ProductObserverTest extends TestCase
{
    private ProductObserver $observer;
    private $firestoreService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->firestoreService = Mockery::mock(FirestoreService::class);
        $this->observer = new ProductObserver($this->firestoreService);
    }

    public function test_created_logs_and_syncs(): void
    {
        $product = new Product();
        $product->id = 1;
        $product->name = 'Paracetamol';

        Log::shouldReceive('info')
            ->once()
            ->withArgs(fn($msg) => str_contains($msg, 'Product created'));

        $this->firestoreService->shouldReceive('syncProduct')
            ->once()
            ->with($product);

        $this->observer->created($product);
    }

    public function test_updated_logs_syncs_and_invalidates_cache(): void
    {
        $product = new Product();
        $product->id = 42;
        $product->name = 'Ibuprofène';

        Log::shouldReceive('info')
            ->once()
            ->withArgs(fn($msg) => str_contains($msg, 'Product updated'));

        $this->firestoreService->shouldReceive('syncProduct')
            ->once()
            ->with($product);

        $this->observer->updated($product);
    }

    public function test_deleted_logs_event(): void
    {
        $product = new Product();
        $product->id = 3;

        Log::shouldReceive('info')
            ->once()
            ->withArgs(fn($msg) => str_contains($msg, 'Product deleted'));

        $this->observer->deleted($product);
    }

    public function test_firestore_sync_failure_is_caught(): void
    {
        $product = new Product();
        $product->id = 5;
        $product->name = 'Test';

        Log::shouldReceive('info')->once();

        $this->firestoreService->shouldReceive('syncProduct')
            ->once()
            ->andThrow(new \RuntimeException('Firestore unavailable'));

        Log::shouldReceive('error')
            ->once()
            ->withArgs(fn($msg) => str_contains($msg, 'Failed to sync product'));

        $this->observer->created($product);
    }
}
