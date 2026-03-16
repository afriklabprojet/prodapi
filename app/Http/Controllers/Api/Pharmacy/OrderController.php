<?php

namespace App\Http\Controllers\Api\Pharmacy;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Services\WaitingFeeService;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    public function __construct(
        protected WaitingFeeService $waitingFeeService
    ) {}

    /**
     * Get pharmacy orders
     */
    public function index(Request $request)
    {
        // Get user's pharmacy
        $pharmacy = $request->user()->pharmacies()->approved()->first();

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune pharmacie approuvée trouvée pour cet utilisateur',
            ], 403);
        }

        $status = $request->query('status');

        $query = $pharmacy->orders()->with(['customer:id,name,phone', 'items']);

        if ($status) {
            $query->where('status', $status);
        }

        $orders = $query->latest()->get()->map(function ($order) {
            return [
                'id' => (int) $order->id,
                'reference' => $order->reference,
                'customer' => [
                    'id' => $order->customer?->id,
                    'name' => $order->customer->name ?? 'Client supprimé',
                    'phone' => $order->customer->phone ?? '',
                ],
                'status' => $order->status,
                'payment_status' => $order->payment_status ?? 'pending',
                'payment_mode' => $order->payment_mode,
                'paid_at' => $order->paid_at,
                'total_amount' => (float) $order->total_amount,
                'items_count' => (int) $order->items->count(),
                'delivery_address' => $order->delivery_address,
                'customer_notes' => $order->customer_notes,
                'created_at' => $order->created_at,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $orders,
        ]);
    }

    /**
     * Get order details
     */
    public function show(Request $request, $id)
    {
        $pharmacy = $request->user()->pharmacies()->approved()->first();

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune pharmacie approuvée trouvée',
            ], 403);
        }

        $order = $pharmacy->orders()->with(['customer', 'items', 'delivery.courier'])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => (int) $order->id,
                'reference' => $order->reference,
                'status' => $order->status,
                'payment_status' => $order->payment_status ?? 'pending',
                'customer' => [
                    'id' => $order->customer?->id,
                    'name' => $order->customer->name ?? 'Client supprimé',
                    'phone' => $order->customer->phone ?? '',
                ],
                'items' => $order->items->map(fn($item) => [
                    'name' => $item->product_name ?? $item->name ?? 'Produit',
                    'quantity' => (int) $item->quantity,
                    'unit_price' => (float) $item->unit_price,
                    'total_price' => (float) $item->total_price,
                ])->values(),
                'subtotal' => (float) $order->subtotal,
                'delivery_fee' => (float) ($order->delivery_fee ?? 0),
                'total_amount' => (float) $order->total_amount,
                'payment_mode' => $order->payment_mode,
                'delivery_address' => $order->delivery_address,
                'customer_phone' => $order->customer_phone,
                'customer_notes' => $order->customer_notes,
                'pharmacy_notes' => $order->pharmacy_notes,
                'prescription_image' => $order->prescription_image,
                'delivery' => $order->delivery ? [
                    'id' => $order->delivery->id,
                    'status' => $order->delivery->status,
                    'courier' => $order->delivery->courier ? [
                        'id' => $order->delivery->courier->id,
                        'name' => $order->delivery->courier->name,
                        'phone' => $order->delivery->courier->phone,
                    ] : null,
                ] : null,
                'created_at' => $order->created_at,
                'paid_at' => $order->paid_at,
                'cancelled_at' => $order->cancelled_at,
                'cancellation_reason' => $order->cancellation_reason,
            ],
        ]);
    }

    /**
     * Confirm order (pharmacy accepts)
     */
    public function confirm(Request $request, $id)
    {
        $pharmacy = $request->user()->pharmacies()->approved()->first();

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune pharmacie approuvée trouvée',
            ], 403);
        }

        $order = $pharmacy->orders()->findOrFail($id);

        if ($order->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Cette commande ne peut pas être confirmée',
            ], 400);
        }

        // Block confirmation if payment has not been completed
        $isPaid = $order->paid_at !== null
            || ($order->payment_status ?? 'pending') === 'paid'
            || $order->payment_mode === 'cash'; // Cash orders are paid on delivery

        if (!$isPaid) {
            return response()->json([
                'success' => false,
                'message' => 'Le paiement de cette commande n\'a pas encore été validé. Impossible de confirmer.',
            ], 422);
        }

        $order->update([
            'status' => 'confirmed',
            'confirmed_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Commande confirmée avec succès',
        ]);
    }

    /**
     * Mark order as ready for delivery
     */
    public function ready(Request $request, $id)
    {
        $pharmacy = $request->user()->pharmacies()->approved()->first();

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune pharmacie approuvée trouvée',
            ], 403);
        }

        $order = $pharmacy->orders()->findOrFail($id);

        if (!in_array($order->status, ['confirmed'])) {
            return response()->json([
                'success' => false,
                'message' => 'Cette commande ne peut pas être marquée comme prête',
            ], 400);
        }

        $order->update([
            'status' => 'ready',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Commande prête pour livraison',
        ]);
    }

    /**
     * Mark order as delivered (customer pickup at pharmacy)
     */
    public function delivered(Request $request, $id)
    {
        $pharmacy = $request->user()->pharmacies()->approved()->first();

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune pharmacie approuvée trouvée',
            ], 403);
        }

        $order = $pharmacy->orders()->findOrFail($id);

        if (!in_array($order->status, ['ready', 'ready_for_pickup'])) {
            return response()->json([
                'success' => false,
                'message' => 'Cette commande ne peut pas être marquée comme livrée',
            ], 400);
        }

        $order->update([
            'status' => 'delivered',
            'delivered_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Commande livrée avec succès',
        ]);
    }

    /**
     * Add notes to an order
     */
    public function addNotes(Request $request, $id)
    {
        $request->validate([
            'notes' => 'required|string',
        ]);

        $pharmacy = $request->user()->pharmacies()->approved()->first();

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune pharmacie approuvée trouvée',
            ], 403);
        }

        $order = $pharmacy->orders()->findOrFail($id);

        $order->update([
            'pharmacy_notes' => $request->notes,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Notes ajoutées avec succès',
            'data' => $order,
        ]);
    }

    /**
     * Get delivery waiting status for an order
     * Returns countdown timer info when courier is waiting at client location
     */
    public function deliveryWaitingStatus(Request $request, $id)
    {
        $pharmacy = $request->user()->pharmacies()->approved()->first();

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune pharmacie approuvée trouvée',
            ], 403);
        }

        $order = $pharmacy->orders()->with(['delivery'])->findOrFail($id);

        if (!$order->delivery) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune livraison associée à cette commande',
            ], 404);
        }

        $delivery = $order->delivery;

        // Get waiting info if delivery is in waiting status
        $waitingInfo = $this->waitingFeeService->getWaitingInfo($delivery);

        return response()->json([
            'success' => true,
            'data' => [
                'order_id' => $order->id,
                'order_reference' => $order->reference,
                'delivery_id' => $delivery->id,
                'delivery_status' => $delivery->status,
                'is_waiting' => $delivery->status === 'waiting_for_customer',
                'waiting_started_at' => $delivery->waiting_started_at,
                'waiting_info' => $waitingInfo,
                'settings' => $this->waitingFeeService->getWaitingSettings(),
            ],
        ]);
    }

    /**
     * Reject order
     */
    public function reject(Request $request, $id)
    {
        $request->validate([
            'reason' => 'nullable|string',
        ]);

        $pharmacy = $request->user()->pharmacies()->approved()->first();

        if (!$pharmacy) {
            return response()->json([
                'success' => false,
                'message' => 'Aucune pharmacie approuvée trouvée',
            ], 403);
        }

        $order = $pharmacy->orders()->findOrFail($id);

        if ($order->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Cette commande ne peut pas être rejetée',
            ], 400);
        }

        $order->update([
            'status' => 'cancelled',
            'cancellation_reason' => $request->reason,
            'cancelled_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Commande rejetée avec succès',
        ]);
    }
}

