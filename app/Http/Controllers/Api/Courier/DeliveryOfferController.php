<?php

namespace App\Http\Controllers\Api\Courier;

use App\Http\Controllers\Controller;
use App\Models\DeliveryOffer;
use App\Services\BroadcastDispatchService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DeliveryOfferController extends Controller
{
    public function __construct(
        private BroadcastDispatchService $dispatchService
    ) {}

    /**
     * Liste les offres de livraison pour le livreur
     * 
     * GET /api/courier/offers
     */
    public function index(Request $request)
    {
        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur non trouvé',
            ], 403);
        }

        // Offres actives pour ce livreur
        $offers = $courier->deliveryOffers()
            ->where('status', DeliveryOffer::STATUS_PENDING)
            ->where('expires_at', '>', now())
            ->with(['order.pharmacy'])
            ->orderBy('expires_at')
            ->get();

        $formattedOffers = $offers->map(function ($offer) {
            $order = $offer->order;
            $pharmacy = $order->pharmacy ?? null;

            return [
                'id' => $offer->id,
                'order_id' => $offer->order_id,
                'expires_at' => $offer->expires_at?->toIso8601String(),
                'seconds_remaining' => max(0, $offer->expires_at?->diffInSeconds(now(), false) * -1),
                'broadcast_level' => $offer->broadcast_level,
                'pickup' => [
                    'name' => $pharmacy?->name ?? 'Pharmacie',
                    'address' => $pharmacy?->address,
                    'latitude' => (float) ($pharmacy?->latitude ?? 0),
                    'longitude' => (float) ($pharmacy?->longitude ?? 0),
                ],
                'dropoff' => [
                    'address' => $order->delivery_address,
                    'latitude' => (float) $order->delivery_latitude,
                    'longitude' => (float) $order->delivery_longitude,
                ],
                'estimated_distance_km' => $offer->estimated_distance ?? null,
                'estimated_earnings' => $order->delivery_fee ?? 0,
                'items_count' => $order->items?->count() ?? 0,
                'surge_multiplier' => $offer->surge_multiplier ?? 1.0,
                'created_at' => $offer->created_at->toIso8601String(),
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $formattedOffers,
        ]);
    }

    /**
     * Accepter une offre de livraison
     * 
     * POST /api/courier/offers/{id}/accept
     */
    public function accept(Request $request, $id)
    {
        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur non trouvé',
            ], 403);
        }

        $offer = DeliveryOffer::findOrFail($id);

        // Vérifier que le livreur fait partie des destinataires
        $pivotData = $offer->couriers()->where('courier_id', $courier->id)->first();
        if (!$pivotData) {
            return response()->json([
                'success' => false,
                'message' => 'Cette offre ne vous est pas destinée',
            ], 403);
        }

        // Tenter d'accepter
        $result = $this->dispatchService->acceptOffer($offer, $courier);

        if (!$result['success']) {
            return response()->json($result, 400);
        }

        Log::info("DeliveryOffer: Courier {$courier->id} accepted offer {$offer->id}");

        return response()->json([
            'success' => true,
            'message' => $result['message'],
            'data' => [
                'delivery_id' => $result['delivery']->id,
                'order_id' => $result['delivery']->order_id,
            ],
        ]);
    }

    /**
     * Rejeter une offre de livraison
     * 
     * POST /api/courier/offers/{id}/reject
     */
    public function reject(Request $request, $id)
    {
        $request->validate([
            'reason' => 'nullable|string|max:200',
        ]);

        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur non trouvé',
            ], 403);
        }

        $offer = DeliveryOffer::findOrFail($id);

        // Vérifier que le livreur fait partie des destinataires
        $pivotData = $offer->couriers()->where('courier_id', $courier->id)->first();
        if (!$pivotData) {
            return response()->json([
                'success' => false,
                'message' => 'Cette offre ne vous est pas destinée',
            ], 403);
        }

        $this->dispatchService->rejectOffer($offer, $courier, $request->reason);

        Log::info("DeliveryOffer: Courier {$courier->id} rejected offer {$offer->id}", [
            'reason' => $request->reason,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Offre refusée avec succès',
        ]);
    }

    /**
     * Obtenir les détails d'une offre
     * 
     * GET /api/courier/offers/{id}
     */
    public function show(Request $request, $id)
    {
        $courier = $request->user()->courier;

        if (!$courier) {
            return response()->json([
                'success' => false,
                'message' => 'Profil livreur non trouvé',
            ], 403);
        }

        $offer = DeliveryOffer::with(['order.pharmacy', 'order.items'])
            ->findOrFail($id);

        // Vérifier que le livreur fait partie des destinataires
        $pivotData = $offer->couriers()->where('courier_id', $courier->id)->first();
        if (!$pivotData) {
            return response()->json([
                'success' => false,
                'message' => 'Cette offre ne vous est pas destinée',
            ], 403);
        }

        $order = $offer->order;
        $pharmacy = $order->pharmacy ?? null;

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $offer->id,
                'order_id' => $offer->order_id,
                'status' => $offer->status,
                'expires_at' => $offer->expires_at?->toIso8601String(),
                'seconds_remaining' => max(0, $offer->expires_at?->diffInSeconds(now(), false) * -1),
                'broadcast_level' => $offer->broadcast_level,
                'pickup' => [
                    'name' => $pharmacy?->name ?? 'Pharmacie',
                    'address' => $pharmacy?->address,
                    'phone' => $pharmacy?->phone,
                    'latitude' => (float) ($pharmacy?->latitude ?? 0),
                    'longitude' => (float) ($pharmacy?->longitude ?? 0),
                ],
                'dropoff' => [
                    'address' => $order->delivery_address,
                    'latitude' => (float) $order->delivery_latitude,
                    'longitude' => (float) $order->delivery_longitude,
                    'notes' => $order->delivery_notes ?? null,
                ],
                'order' => [
                    'reference' => $order->reference,
                    'total_amount' => (float) $order->total_amount,
                    'payment_mode' => $order->payment_mode,
                    'items_count' => $order->items?->count() ?? 0,
                    'items' => $order->items?->map(fn($item) => [
                        'name' => $item->product_name ?? $item->product?->name,
                        'quantity' => $item->quantity,
                    ]),
                ],
                'estimated_distance_km' => $offer->estimated_distance ?? null,
                'estimated_earnings' => $order->delivery_fee ?? 0,
                'surge_multiplier' => $offer->surge_multiplier ?? 1.0,
                'created_at' => $offer->created_at->toIso8601String(),
            ],
        ]);
    }
}
