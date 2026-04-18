<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Models\Rating;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProductReviewController extends Controller
{
    /**
     * Get reviews for a product (public).
     *
     * GET /api/products/{id}/reviews
     */
    public function index(int $id): JsonResponse
    {
        $product = Product::findOrFail($id);

        $reviews = Rating::where('rateable_type', Product::class)
            ->where('rateable_id', $id)
            ->with('user:id,name,avatar')
            ->latest()
            ->paginate(20);

        $stats = Rating::where('rateable_type', Product::class)
            ->where('rateable_id', $id)
            ->selectRaw('
                COUNT(*) as total,
                AVG(rating) as average,
                SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END) as five_star,
                SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END) as four_star,
                SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END) as three_star,
                SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END) as two_star,
                SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END) as one_star
            ')
            ->first();

        return response()->json([
            'success' => true,
            'data' => [
                'stats' => [
                    'average_rating' => round($stats->average ?? 0, 1),
                    'total_reviews' => (int) $stats->total,
                    'distribution' => [
                        5 => (int) $stats->five_star,
                        4 => (int) $stats->four_star,
                        3 => (int) $stats->three_star,
                        2 => (int) $stats->two_star,
                        1 => (int) $stats->one_star,
                    ],
                ],
                'reviews' => $reviews,
            ],
        ]);
    }

    /**
     * Submit a product review (authenticated, must have ordered the product).
     *
     * POST /api/products/{id}/reviews
     */
    public function store(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
            'tags' => 'nullable|array',
            'tags.*' => 'string|max:50',
            'order_id' => 'required|integer|exists:orders,id',
        ]);

        $user = $request->user();
        $product = Product::findOrFail($id);

        // Verify the user actually ordered this product and it was delivered
        $order = Order::where('id', $request->order_id)
            ->where('customer_id', $user->id)
            ->where('status', 'delivered')
            ->whereHas('items', function ($q) use ($id) {
                $q->where('product_id', $id);
            })
            ->first();

        if (!$order) {
            return response()->json([
                'success' => false,
                'message' => 'Vous devez avoir acheté ce produit pour le noter.',
            ], 403);
        }

        // Check if user already reviewed this product for this order
        $existing = Rating::where('user_id', $user->id)
            ->where('order_id', $request->order_id)
            ->where('rateable_type', Product::class)
            ->where('rateable_id', $id)
            ->exists();

        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'Vous avez déjà donné votre avis sur ce produit pour cette commande.',
            ], 422);
        }

        $review = DB::transaction(function () use ($request, $user, $product, $id) {
            $rating = Rating::create([
                'user_id' => $user->id,
                'order_id' => $request->order_id,
                'rateable_type' => Product::class,
                'rateable_id' => $id,
                'rating' => $request->rating,
                'comment' => $request->comment,
                'tags' => $request->tags,
            ]);

            // Update product average rating and review count
            $stats = Rating::where('rateable_type', Product::class)
                ->where('rateable_id', $id)
                ->selectRaw('AVG(rating) as avg_rating, COUNT(*) as count')
                ->first();

            $product->update([
                'average_rating' => round($stats->avg_rating, 2),
                'reviews_count' => $stats->count,
            ]);

            return $rating;
        });

        return response()->json([
            'success' => true,
            'message' => 'Merci pour votre avis !',
            'data' => $review->load('user:id,name,avatar'),
        ], 201);
    }
}
