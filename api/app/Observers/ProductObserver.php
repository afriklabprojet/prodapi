<?php

namespace App\Observers;

use App\Models\Product;
use App\Services\CacheService;
use App\Services\FirestoreService;
use Illuminate\Support\Facades\Log;

class ProductObserver
{
    public function __construct(
        protected FirestoreService $firestoreService
    ) {}

    public function created(Product $product): void
    {
        Log::info('Product created', ['id' => $product->id, 'name' => $product->name]);

        $this->syncToFirestore($product);
    }

    public function updated(Product $product): void
    {
        Log::info('Product updated', ['id' => $product->id, 'name' => $product->name]);

        $this->syncToFirestore($product);
        CacheService::forgetProduct($product->id);
    }

    public function deleted(Product $product): void
    {
        Log::info('Product deleted', ['id' => $product->id]);

        CacheService::forgetProduct($product->id);
    }

    protected function syncToFirestore(Product $product): void
    {
        try {
            $this->firestoreService->syncProduct($product);
        } catch (\Throwable $e) {
            Log::error('Failed to sync product to Firestore', [
                'product_id' => $product->id,
                'error' => $e->getMessage(),
            ]);
        }
    }
}
