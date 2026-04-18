<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Models\Courier;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Rating;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RatingController extends Controller
{
    /**
     * Rate a delivered order (courier + pharmacy in one call).
     *
     * POST /api/customer/orders/{id}/rate
     */
    public function store(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'courier_rating' => 'nullable|integer|min:1|max:5',
            'courier_comment' => 'nullable|string|max:500',
            'courier_tags' => 'nullable|array',
            'courier_tags.*' => 'string|max:50',
            'pharmacy_rating' => 'nullable|integer|min:1|max:5',
            'pharmacy_comment' => 'nullable|string|max:500',
            'pharmacy_tags' => 'nullable|array',
            'pharmacy_tags.*' => 'string|max:50',
        ]);

        $user = $request->user();

        $order = Order::where('customer_id', $user->id)
            ->where('id', $id)
            ->where('status', 'delivered')
            ->with('delivery.courier')
            ->first();

        if (!$order) {
            return response()->json([
                'success' => false,
                'message' => 'Commande non trouvée ou non livrée.',
            ], 404);
        }

        // Check if already rated
        if ($order->ratings()->where('user_id', $user->id)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Vous avez déjà noté cette commande.',
            ], 422);
        }

        $ratings = [];

        DB::transaction(function () use ($request, $user, $order, &$ratings) {
            // Rate courier (via Delivery)
            if ($request->filled('courier_rating') && $order->delivery) {
                $rating = Rating::create([
                    'user_id' => $user->id,
                    'order_id' => $order->id,
                    'rateable_type' => Courier::class,
                    'rateable_id' => $order->delivery->courier_id,
                    'rating' => $request->courier_rating,
                    'comment' => $request->courier_comment,
                    'tags' => $request->courier_tags,
                ]);
                $ratings[] = $rating;

                // Update courier average rating
                if ($order->delivery->courier) {
                    $avg = Rating::where('rateable_type', Courier::class)
                        ->where('rateable_id', $order->delivery->courier_id)
                        ->avg('rating');
                    $order->delivery->courier->update(['rating' => round($avg, 2)]);
                }
            }

            // Rate pharmacy
            if ($request->filled('pharmacy_rating')) {
                $rating = Rating::create([
                    'user_id' => $user->id,
                    'order_id' => $order->id,
                    'rateable_type' => Pharmacy::class,
                    'rateable_id' => $order->pharmacy_id,
                    'rating' => $request->pharmacy_rating,
                    'comment' => $request->pharmacy_comment,
                    'tags' => $request->pharmacy_tags,
                ]);
                $ratings[] = $rating;
            }
        });

        return response()->json([
            'success' => true,
            'message' => 'Merci pour votre avis !',
            'data' => $ratings,
        ]);
    }

    /**
     * Get user's rating for a specific order.
     *
     * GET /api/customer/orders/{id}/rating
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();

        $ratings = Rating::where('user_id', $user->id)
            ->where('order_id', $id)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $ratings,
        ]);
    }

    /**
     * Get ratings for a pharmacy (public).
     *
     * GET /api/pharmacies/{id}/ratings
     */
    public function pharmacyRatings(int $id): JsonResponse
    {
        $pharmacy = Pharmacy::findOrFail($id);

        $ratings = Rating::where('rateable_type', Pharmacy::class)
            ->where('rateable_id', $id)
            ->with('user:id,name')
            ->latest()
            ->paginate(20);

        $average = Rating::where('rateable_type', Pharmacy::class)
            ->where('rateable_id', $id)
            ->avg('rating');

        $count = Rating::where('rateable_type', Pharmacy::class)
            ->where('rateable_id', $id)
            ->count();

        return response()->json([
            'success' => true,
            'data' => [
                'average_rating' => round($average ?? 0, 1),
                'total_ratings' => $count,
                'ratings' => $ratings,
            ],
        ]);
    }
}
