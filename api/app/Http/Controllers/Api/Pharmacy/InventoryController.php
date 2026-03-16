<?php

namespace App\Http\Controllers\Api\Pharmacy;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class InventoryController extends Controller
{
    private function getPharmacy($user)
    {
        // Only allow approved pharmacies to access inventory
        return $user->pharmacies()->where('status', 'approved')->first();
    }

    /**
     * List all products for the authenticated pharmacy
     */
    public function index(Request $request)
    {
        $pharmacy = $this->getPharmacy($request->user());

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune pharmacie approuvée associée.',
            ], 403);
        }

        $perPage = min((int) $request->get('per_page', 50), 100);
        $search = $request->get('search');

        $query = Product::where('pharmacy_id', $pharmacy->id)
            ->with(['category']);

        if ($search) {
            $query->where('name', 'like', '%' . $search . '%');
        }

        $products = $query->orderBy('name')->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $products->items(),
            'meta' => [
                'current_page' => $products->currentPage(),
                'last_page' => $products->lastPage(),
                'per_page' => $products->perPage(),
                'total' => $products->total(),
            ],
        ]);
    }

    /**
     * Create a new product
     */
    public function store(Request $request)
    {
        $pharmacy = $this->getPharmacy($request->user());

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune pharmacie approuvée associée.',
            ], 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'required|string',
            'price' => 'required|numeric|min:0',
            'stock_quantity' => 'required|integer|min:0',
            'category_id' => 'required|exists:categories,id',
            'barcode' => 'nullable|string|max:255',
            'requires_prescription' => 'boolean',
            'is_available' => 'boolean',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:5120', 
            
            // New fields to match Filament
            'brand' => 'nullable|string|max:255',
            'manufacturer' => 'nullable|string|max:255',
            'active_ingredient' => 'nullable|string|max:255',
            'unit' => 'nullable|string|max:50',
            'expiry_date' => 'nullable|date',
            'usage_instructions' => 'nullable|string',
            'side_effects' => 'nullable|string',
        ]);

        // Handle image separately
        $productData = Arr::except($validated, ['image']);
        
        $product = new Product($productData);
        $product->pharmacy_id = $pharmacy->id;
        $product->slug = Str::slug($validated['name']) . '-' . Str::random(6);
        $product->requires_prescription = $request->boolean('requires_prescription', false); 
        $product->is_available = $request->boolean('is_available', true);
        
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('products', 'public');
            $product->image = 'storage/' . $path;
        }

        $product->save();
        
        // Eager load category to ensure full object is returned
        $product->load('category');

        return response()->json([
            'success' => true,
            'message' => 'Produit ajouté avec succès.',
            'data' => $product
        ], 201);
    }

    /**
     * Update stock quantity
     */
    public function updateStock(Request $request, $id)
    {
        $pharmacy = $this->getPharmacy($request->user());

        if (!$pharmacy) {
            return response()->json(['success' => false, 'message' => 'Non autorisé.'], 403);
        }

        $product = Product::where('pharmacy_id', $pharmacy->id)->where('id', $id)->first();

        if (!$product) {
            return response()->json(['success' => false, 'message' => 'Produit non trouvé.'], 404);
        }

        $validated = $request->validate([
            'quantity' => 'required|integer|min:0'
        ]);

        $product->stock_quantity = $validated['quantity'];
        $product->save();

        return response()->json([
            'success' => true,
            'message' => 'Stock mis à jour.',
            'data' => $product
        ]);
    }
    
    /**
     * Update price
     */
    public function updatePrice(Request $request, $id)
    {
        $pharmacy = $this->getPharmacy($request->user());

        if (!$pharmacy) {
            return response()->json(['success' => false, 'message' => 'Non autorisé.'], 403);
        }

        $product = Product::where('pharmacy_id', $pharmacy->id)->where('id', $id)->first();

        if (!$product) {
            return response()->json(['success' => false, 'message' => 'Produit non trouvé.'], 404);
        }

        $validated = $request->validate([
            'price' => 'required|numeric|min:0'
        ]);

        $product->price = $validated['price'];
        $product->save();

        return response()->json([
            'success' => true,
            'message' => 'Prix mis à jour.',
            'data' => $product
        ]);
    }

    /**
     * Toggle availability status
     */
    public function toggleStatus(Request $request, $id)
    {
        $pharmacy = $this->getPharmacy($request->user());

        if (!$pharmacy) {
            return response()->json(['success' => false, 'message' => 'Non autorisé.'], 403);
        }

        $product = Product::where('pharmacy_id', $pharmacy->id)->where('id', $id)->first();

        if (!$product) {
            return response()->json(['success' => false, 'message' => 'Produit non trouvé.'], 404);
        }

        $product->is_available = !$product->is_available;
        $product->save();

        return response()->json([
            'success' => true,
            'message' => 'Statut mis à jour.',
            'data' => $product
        ]);
    }

    /**
     * Get list of official categories
     */
    public function categories()
    {
        $categories = \App\Models\Category::where('is_active', true)->orderBy('name')->get();

        return response()->json([
            'success' => true,
            'data' => $categories
        ]);
    }

    /**
     * Store a new category
     */
    public function storeCategory(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255|unique:categories,name',
            'description' => 'nullable|string',
        ]);

        $category = new \App\Models\Category();
        $category->name = $validated['name'];
        $category->slug = \Illuminate\Support\Str::slug($validated['name']);
        $category->description = $validated['description'] ?? null;
        $category->is_active = true;
        $category->save();

        return response()->json([
            'success' => true,
            'message' => 'Catégorie créée avec succès.',
            'data' => $category
        ], 201);
    }

    /**
     * Update a category
     */
    public function updateCategory(Request $request, $id)
    {
        $category = \App\Models\Category::find($id);

        if (!$category) {
            return response()->json(['success' => false, 'message' => 'Catégorie non trouvée.'], 404);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255|unique:categories,name,' . $id,
            'description' => 'nullable|string',
        ]);

        $category->name = $validated['name'];
        $category->slug = \Illuminate\Support\Str::slug($validated['name']);
        $category->description = $validated['description'] ?? null;
        $category->save();

        return response()->json([
            'success' => true,
            'message' => 'Catégorie mise à jour avec succès.',
            'data' => $category
        ]);
    }

    /**
     * Delete a category
     */
    public function deleteCategory(Request $request, $id)
    {
        $category = \App\Models\Category::find($id);

        if (!$category) {
            return response()->json(['success' => false, 'message' => 'Catégorie non trouvée.'], 404);
        }

        // Check if category has products
        if ($category->products()->count() > 0) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer cette catégorie car elle contient des produits.'
            ], 422);
        }

        $category->delete();

        return response()->json([
            'success' => true,
            'message' => 'Catégorie supprimée avec succès.'
        ]);
    }

    /**
     * Update product details
     */
    public function update(Request $request, $id)
    {
        $pharmacy = $this->getPharmacy($request->user());

        if (!$pharmacy) {
            return response()->json(['success' => false, 'message' => 'Non autorisé.'], 403);
        }

        $product = Product::where('pharmacy_id', $pharmacy->id)->where('id', $id)->first();

        if (!$product) {
            return response()->json(['success' => false, 'message' => 'Produit non trouvé.'], 404);
        }

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'description' => 'sometimes|string',
            'price' => 'sometimes|numeric|min:0',
            'stock_quantity' => 'sometimes|integer|min:0',
            'category_id' => 'sometimes|exists:categories,id',
            'barcode' => 'nullable|string|max:255',
            'requires_prescription' => 'boolean',
            'is_available' => 'boolean',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:5120',

            // New fields update
            'brand' => 'nullable|string|max:255',
            'manufacturer' => 'nullable|string|max:255',
            'active_ingredient' => 'nullable|string|max:255',
            'unit' => 'nullable|string|max:50',
            'expiry_date' => 'nullable|date',
            'usage_instructions' => 'nullable|string',
            'side_effects' => 'nullable|string',
        ]);

        // Handle image
        if ($request->hasFile('image')) {
            // Delete old image if exists
            if ($product->image && Storage::disk('public')->exists(str_replace('storage/', '', $product->image))) {
                Storage::disk('public')->delete(str_replace('storage/', '', $product->image));
            }
            $path = $request->file('image')->store('products', 'public');
            $product->image = 'storage/' . $path;
        }

        // Fill other fields
        $product->fill(Arr::except($validated, ['image']));
        
        // Handle booleans explicitly if needed (Laravel handles boolean validation but sometimes casting is tricky with form-data)
        if ($request->has('requires_prescription')) {
            $product->requires_prescription = $request->boolean('requires_prescription');
        }
        if ($request->has('is_available')) {
            $product->is_available = $request->boolean('is_available');
        }

        $product->save();
        $product->load('category');

        return response()->json([
            'success' => true,
            'message' => 'Produit mis à jour avec succès.',
            'data' => $product
        ]);
    }

    /**
     * Delete a product
     */
    public function destroy(Request $request, $id)
    {
        $pharmacy = $this->getPharmacy($request->user());

        if (!$pharmacy) {
            return response()->json(['success' => false, 'message' => 'Non autorisé.'], 403);
        }

        $product = Product::where('pharmacy_id', $pharmacy->id)->where('id', $id)->first();

        if (!$product) {
            return response()->json(['success' => false, 'message' => 'Produit non trouvé.'], 404);
        }

        $product->delete(); // Soft delete allowed by model

        return response()->json([
            'success' => true,
            'message' => 'Produit supprimé avec succès.'
        ]);
    }

    /**
     * Apply promotion/discount to a product
     */
    public function applyPromotion(Request $request, $id)
    {
        $pharmacy = $this->getPharmacy($request->user());

        if (!$pharmacy) {
            return response()->json(['success' => false, 'message' => 'Non autorisé.'], 403);
        }

        $product = Product::where('pharmacy_id', $pharmacy->id)->where('id', $id)->first();

        if (!$product) {
            return response()->json(['success' => false, 'message' => 'Produit non trouvé.'], 404);
        }

        $validated = $request->validate([
            'discount_percentage' => 'required|numeric|min:1|max:99',
            'end_date' => 'nullable|date|after:today',
        ]);

        // Calculate discount price from percentage
        $discountPrice = $product->price * (1 - ($validated['discount_percentage'] / 100));
        $product->discount_price = round($discountPrice, 2);
        
        if (isset($validated['end_date'])) {
            $product->promotion_end_date = $validated['end_date'];
        }
        
        $product->save();
        $product->load('category');

        return response()->json([
            'success' => true,
            'message' => 'Promotion appliquée avec succès.',
            'data' => $product
        ]);
    }

    /**
     * Remove promotion/discount from a product
     */
    public function removePromotion(Request $request, $id)
    {
        $pharmacy = $this->getPharmacy($request->user());

        if (!$pharmacy) {
            return response()->json(['success' => false, 'message' => 'Non autorisé.'], 403);
        }

        $product = Product::where('pharmacy_id', $pharmacy->id)->where('id', $id)->first();

        if (!$product) {
            return response()->json(['success' => false, 'message' => 'Produit non trouvé.'], 404);
        }

        $product->discount_price = null;
        $product->promotion_end_date = null;
        $product->save();
        $product->load('category');

        return response()->json([
            'success' => true,
            'message' => 'Promotion supprimée.',
            'data' => $product
        ]);
    }

    /**
     * Mark product stock as loss (damaged, expired, etc.)
     */
    public function markAsLoss(Request $request, $id)
    {
        $pharmacy = $this->getPharmacy($request->user());

        if (!$pharmacy) {
            return response()->json(['success' => false, 'message' => 'Non autorisé.'], 403);
        }

        $product = Product::where('pharmacy_id', $pharmacy->id)->where('id', $id)->first();

        if (!$product) {
            return response()->json(['success' => false, 'message' => 'Produit non trouvé.'], 404);
        }

        $validated = $request->validate([
            'quantity' => 'required|integer|min:1',
            'reason' => 'required|string|max:500',
        ]);

        if ($validated['quantity'] > $product->stock_quantity) {
            return response()->json([
                'success' => false,
                'message' => 'La quantité à déclarer dépasse le stock disponible.'
            ], 422);
        }

        // Decrease stock
        $product->stock_quantity -= $validated['quantity'];
        $product->save();
        
        // Log the loss (could be enhanced with a dedicated stock_movements table)
        \Log::info("Stock loss recorded", [
            'product_id' => $product->id,
            'pharmacy_id' => $pharmacy->id,
            'quantity' => $validated['quantity'],
            'reason' => $validated['reason'],
            'remaining_stock' => $product->stock_quantity,
        ]);

        $product->load('category');

        return response()->json([
            'success' => true,
            'message' => 'Perte enregistrée. Stock mis à jour.',
            'data' => $product
        ]);
    }
}
