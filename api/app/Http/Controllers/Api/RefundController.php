<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Gère les remboursements pour les commandes annulées ou les problèmes de livraison.
 */
class RefundController extends Controller
{
    /**
     * Liste les remboursements du client authentifié.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $refunds = DB::table('refunds')
            ->where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->paginate(min($request->input('per_page', 15), 50));

        return response()->json([
            'success' => true,
            'data' => $refunds,
        ]);
    }

    /**
     * Détail d'un remboursement.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();

        $refund = DB::table('refunds')
            ->where('id', $id)
            ->where('user_id', $user->id)
            ->first();

        if (!$refund) {
            return response()->json([
                'success' => false,
                'message' => 'Remboursement non trouvé.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $refund,
        ]);
    }

    /**
     * Demander un remboursement pour une commande.
     *
     * POST /api/customer/refunds
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'order_id' => 'required|exists:orders,id',
            'reason' => 'required|string|max:500',
            'type' => 'required|in:full,partial',
            'amount' => 'required_if:type,partial|nullable|numeric|min:1',
        ]);

        $user = $request->user();
        $orderId = $request->input('order_id');

        // Vérifier que la commande appartient au client
        $order = DB::table('orders')
            ->where('id', $orderId)
            ->where('customer_id', $user->id)
            ->first();

        if (!$order) {
            return response()->json([
                'success' => false,
                'message' => 'Commande non trouvée.',
            ], 404);
        }

        // Vérifier qu'il n'y a pas déjà une demande en cours
        $existingRefund = DB::table('refunds')
            ->where('order_id', $orderId)
            ->whereIn('status', ['pending', 'approved'])
            ->first();

        if ($existingRefund) {
            return response()->json([
                'success' => false,
                'message' => 'Une demande de remboursement est déjà en cours pour cette commande.',
            ], 422);
        }

        $amount = $request->input('type') === 'full'
            ? $order->total_amount
            : min($request->input('amount'), $order->total_amount);

        $refundId = DB::table('refunds')->insertGetId([
            'user_id' => $user->id,
            'order_id' => $orderId,
            'amount' => $amount,
            'reason' => $request->input('reason'),
            'type' => $request->input('type'),
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $refund = DB::table('refunds')->where('id', $refundId)->first();

        return response()->json([
            'success' => true,
            'message' => 'Demande de remboursement soumise. Vous serez notifié de la décision.',
            'data' => $refund,
        ], 201);
    }
}
