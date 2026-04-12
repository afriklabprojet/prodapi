<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $sortBy = $request->get('sort_by', 'created_at');
        $sortOrder = strtolower($request->get('sort_order', 'desc')) === 'asc' ? 'asc' : 'desc';
        $allowedSorts = ['created_at', 'price', 'name', 'sales_count'];

        $products = Product::query()
            ->where('is_available', true)
            ->when($request->pharmacy_id, fn ($q, $v) => $q->where('pharmacy_id', $v))
            ->when($request->filled('min_price'), fn ($q) => $q->where('price', '>=', (float) $request->min_price))
            ->when($request->filled('max_price'), fn ($q) => $q->where('price', '<=', (float) $request->max_price))
            ->when($request->has('requires_prescription'), function ($query) use ($request) {
                $value = filter_var($request->requires_prescription, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
                if ($value !== null) {
                    $query->where('requires_prescription', $value);
                }
            })
            ->with(['category', 'pharmacy'])
            ->when(
                in_array($sortBy, $allowedSorts, true),
                fn ($q) => $q->orderBy($sortBy, $sortOrder),
                fn ($q) => $q->orderByDesc('created_at')
            )
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => [
                'products' => $products->items(),
                'pagination' => [
                    'current_page' => $products->currentPage(),
                    'last_page' => $products->lastPage(),
                    'per_page' => $products->perPage(),
                    'total' => $products->total(),
                ],
            ],
        ]);
    }

    public function featured(Request $request): JsonResponse
    {
        $products = Product::where('is_available', true)
            ->where('is_featured', true)
            ->with(['category', 'pharmacy'])
            ->limit($request->get('limit', 10))
            ->get();

        return response()->json([
            'success' => true,
            'data' => $products,
        ]);
    }

    public function categories(): JsonResponse
    {
        $categories = Category::where('is_active', true)
            ->orderBy('order')
            ->orderBy('name')
            ->get(['id', 'name', 'slug', 'icon', 'image']);

        return response()->json([
            'success' => true,
            'data' => $categories,
        ]);
    }

    public function byCategory(string $category): JsonResponse
    {
        $cat = Category::where('slug', $category)
            ->orWhere('id', $category)
            ->first();

        $products = Product::query()
            ->where('is_available', true)
            ->when(
                $cat,
                fn ($q) => $q->where('category_id', $cat->id),
                fn ($q) => $q->where('category', $category)
            )
            ->with(['category', 'pharmacy'])
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => [
                'products' => $products->items(),
                'pagination' => [
                    'current_page' => $products->currentPage(),
                    'last_page' => $products->lastPage(),
                    'per_page' => $products->perPage(),
                    'total' => $products->total(),
                ],
            ],
        ]);
    }

    public function search(Request $request): JsonResponse
    {
        $request->validate(['q' => 'required|string|min:2|max:100']);

        $products = Product::where('is_available', true)
            ->where(function ($query) use ($request) {
                $searchTerm = $request->q;
                $query->where('name', 'like', "%{$searchTerm}%")
                    ->orWhere('description', 'like', "%{$searchTerm}%")
                    ->orWhere('manufacturer', 'like', "%{$searchTerm}%")
                    ->orWhere('active_ingredient', 'like', "%{$searchTerm}%");
            })
            ->with(['category', 'pharmacy'])
            ->orderByDesc('is_featured')
            ->orderByDesc('sales_count')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => [
                'products' => $products->items(),
                'pagination' => [
                    'current_page' => $products->currentPage(),
                    'last_page' => $products->lastPage(),
                    'per_page' => $products->perPage(),
                    'total' => $products->total(),
                ],
            ],
        ]);
    }

    public function show(int $id): JsonResponse
    {
        $product = Product::where('is_available', true)
            ->with(['category', 'pharmacy'])
            ->findOrFail($id);

        $product->incrementViews();
        $product->refresh();

        return response()->json([
            'success' => true,
            'data' => [
                'product' => $product,
            ],
        ]);
    }

    public function showBySlug(string $slug): JsonResponse
    {
        $product = Product::where('slug', $slug)
            ->where('is_available', true)
            ->with(['category', 'pharmacy'])
            ->firstOrFail();

        $product->incrementViews();
        $product->refresh();

        return response()->json([
            'success' => true,
            'data' => [
                'product' => $product,
            ],
        ]);
    }

    /**
     * Compare les prix du même produit (ou similaire) dans d'autres pharmacies
     */
    public function comparePrices(int $id): JsonResponse
    {
        $product = Product::with('pharmacy')->findOrFail($id);
        
        // Rechercher des produits similaires dans d'autres pharmacies
        // Critères: même nom OU même ingrédient actif OU même code DCI
        $alternatives = Product::where('id', '!=', $id)
            ->where('pharmacy_id', '!=', $product->pharmacy_id)
            ->where('is_available', true)
            ->where('stock_quantity', '>', 0)
            ->where(function ($query) use ($product) {
                // Match par nom exact (normalié)
                $normalizedName = strtolower(trim($product->name));
                $query->whereRaw('LOWER(name) = ?', [$normalizedName]);
                
                // OU par ingrédient actif si présent
                if ($product->active_ingredient) {
                    $query->orWhere('active_ingredient', $product->active_ingredient);
                }
                
                // OU par code DCI si présent
                if ($product->dci_code) {
                    $query->orWhere('dci_code', $product->dci_code);
                }
            })
            ->with(['pharmacy:id,name,address,latitude,longitude'])
            ->select([
                'id', 
                'name', 
                'price', 
                'promo_price', 
                'stock_quantity',
                'pharmacy_id',
                'image_url'
            ])
            ->orderBy('price')
            ->limit(5)
            ->get()
            ->map(function ($alt) {
                return [
                    'id' => $alt->id,
                    'name' => $alt->name,
                    'price' => $alt->getCurrentPrice(),
                    'original_price' => $alt->price,
                    'has_promo' => $alt->promo_price !== null && $alt->promo_price < $alt->price,
                    'stock' => $alt->stock_quantity,
                    'pharmacy' => [
                        'id' => $alt->pharmacy_id,
                        'name' => $alt->pharmacy->name ?? 'Pharmacie',
                        'address' => $alt->pharmacy->address ?? null,
                    ],
                ];
            });

        return response()->json([
            'success' => true,
            'data' => [
                'current' => [
                    'id' => $product->id,
                    'name' => $product->name,
                    'price' => $product->getCurrentPrice(),
                    'pharmacy' => [
                        'id' => $product->pharmacy_id,
                        'name' => $product->pharmacy->name ?? 'Pharmacie',
                    ],
                ],
                'alternatives' => $alternatives,
                'has_alternatives' => $alternatives->count() > 0,
            ],
        ]);
    }
}
