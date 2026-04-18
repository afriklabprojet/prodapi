<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Refund;
use App\Services\RefundService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Gestion admin des demandes de remboursement.
 */
class RefundAdminController extends Controller
{
    public function __construct(private RefundService $refunds)
    {
    }

    public function index(Request $request): JsonResponse
    {
        $query = Refund::query()->with(['user:id,name,phone,email', 'order:id,reference,total_amount']);

        if ($status = $request->input('status')) {
            $query->where('status', $status);
        }

        $items = $query->orderByDesc('created_at')
            ->paginate(min((int) $request->input('per_page', 20), 100));

        return response()->json(['success' => true, 'data' => $items]);
    }

    public function approve(Request $request, int $id): JsonResponse
    {
        $request->validate(['note' => 'nullable|string|max:500']);
        $refund = Refund::findOrFail($id);

        try {
            $refund = $this->refunds->approve($refund, $request->user(), $request->input('note'));
        } catch (\RuntimeException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 422);
        }

        return response()->json(['success' => true, 'data' => $refund]);
    }

    public function reject(Request $request, int $id): JsonResponse
    {
        $request->validate(['note' => 'required|string|min:5|max:500']);
        $refund = Refund::findOrFail($id);

        try {
            $refund = $this->refunds->reject($refund, $request->user(), $request->string('note'));
        } catch (\RuntimeException $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 422);
        }

        return response()->json(['success' => true, 'data' => $refund]);
    }

    public function process(Request $request, int $id): JsonResponse
    {
        $refund = Refund::findOrFail($id);

        try {
            $refund = $this->refunds->process($refund, $request->user());
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 422);
        }

        return response()->json(['success' => true, 'data' => $refund]);
    }
}
