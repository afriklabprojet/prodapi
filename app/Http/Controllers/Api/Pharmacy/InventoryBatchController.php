<?php

namespace App\Http\Controllers\Api\Pharmacy;

use App\Http\Controllers\Controller;
use App\Models\InventoryBatch;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class InventoryBatchController extends Controller
{
    /** GET /pharmacy/inventory/batches */
    public function index(Request $request): JsonResponse
    {
        $pharmacy = Auth::user()->pharmacy;

        $query = InventoryBatch::where('pharmacy_id', $pharmacy->id)
            ->with('product:id,name')
            ->orderBy('expiry_date');

        if ($request->filled('product_id')) {
            $query->where('product_id', $request->integer('product_id'));
        }

        if ($request->boolean('expiring_soon')) {
            $query->where('expiry_date', '>=', now())
                  ->where('expiry_date', '<=', now()->addDays(30));
        }

        $batches = $query->get()->map(fn ($b) => $this->format($b));

        return response()->json(['success' => true, 'data' => $batches]);
    }

    /** POST /pharmacy/inventory/batches */
    public function store(Request $request): JsonResponse
    {
        $pharmacy = Auth::user()->pharmacy;

        $validated = $request->validate([
            'product_id'   => 'required|integer|exists:products,id',
            'batch_number' => 'required|string|max:100',
            'lot_number'   => 'nullable|string|max:100',
            'expiry_date'  => 'required|date|after:today',
            'quantity'     => 'required|integer|min:1',
            'received_at'  => 'nullable|date',
            'supplier'     => 'nullable|string|max:255',
        ]);

        $batch = InventoryBatch::create(array_merge($validated, [
            'pharmacy_id' => $pharmacy->id,
        ]));

        $batch->load('product:id,name');

        return response()->json([
            'success' => true,
            'message' => 'Lot créé avec succès',
            'data'    => $this->format($batch),
        ], 201);
    }

    /** DELETE /pharmacy/inventory/batches/{batchId} */
    public function destroy(int $batchId): JsonResponse
    {
        $pharmacy = Auth::user()->pharmacy;

        $batch = InventoryBatch::where('id', $batchId)
            ->where('pharmacy_id', $pharmacy->id)
            ->firstOrFail();

        $batch->delete();

        return response()->json(['success' => true, 'message' => 'Lot supprimé']);
    }

    private function format(InventoryBatch $b): array
    {
        return [
            'id'           => $b->id,
            'product_id'   => $b->product_id,
            'product_name' => $b->product?->name,
            'batch_number' => $b->batch_number,
            'lot_number'   => $b->lot_number,
            'expiry_date'  => $b->expiry_date?->toDateString(),
            'quantity'     => $b->quantity,
            'received_at'  => $b->received_at?->toDateString(),
            'supplier'     => $b->supplier,
        ];
    }
}
