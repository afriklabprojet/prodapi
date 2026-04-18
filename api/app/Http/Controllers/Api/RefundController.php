<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Refund;
use App\Services\RefundService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Gère les remboursements côté client.
 */
class RefundController extends Controller
{
    public function __construct(private RefundService $refunds)
    {
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $items = Refund::where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->paginate(min((int) $request->input('per_page', 15), 50));

        return response()->json([
            'success' => true,
            'data' => $items,
        ]);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();

        $refund = Refund::where('id', $id)->where('user_id', $user->id)->first();

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

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'order_id' => 'required|exists:orders,id',
            'reason' => 'required|string|min:10|max:500',
            'type' => 'required|in:full,partial',
            'amount' => 'required_if:type,partial|nullable|numeric|min:1',
        ]);

        $user = $request->user();
        $order = Order::find($request->integer('order_id'));

        if (!$order) {
            return response()->json([
                'success' => false,
                'message' => 'Commande introuvable.',
            ], 404);
        }

        try {
            $refund = $this->refunds->requestRefund(
                order: $order,
                user: $user,
                type: (string) $request->string('type'),
                amount: $request->input('amount') !== null ? (float) $request->input('amount') : null,
                reason: (string) $request->string('reason'),
            );
        } catch (\InvalidArgumentException|\RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Demande de remboursement soumise. Vous serez notifié de la décision.',
            'data' => $refund,
        ], 201);
    }
}
