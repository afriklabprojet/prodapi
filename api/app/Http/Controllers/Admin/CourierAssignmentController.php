<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Courier;
use App\Models\Delivery;
use App\Models\Order;
use App\Services\CourierAssignmentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CourierAssignmentController extends Controller
{
    public function __construct(
        protected CourierAssignmentService $assignmentService,
    ) {}

    public function getAvailableCouriers(Order $order): JsonResponse
    {
        $couriers = $this->assignmentService->getAvailableCouriersInRadius(
            $order->pharmacy->latitude,
            $order->pharmacy->longitude,
        );

        return response()->json([
            'success' => true,
            'data' => $couriers,
        ]);
    }

    public function autoAssign(Order $order): JsonResponse
    {
        $delivery = $this->assignmentService->assignCourier($order);

        if (!$delivery) {
            return response()->json([
                'success' => false,
                'message' => 'Aucun livreur disponible',
            ], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Livreur assigné automatiquement',
            'data' => $delivery->load('courier:id,name,phone'),
        ]);
    }

    public function manualAssign(Request $request, Order $order): JsonResponse
    {
        $request->validate([
            'courier_id' => 'required|exists:couriers,id',
        ]);

        $courier = Courier::findOrFail($request->courier_id);
        $delivery = $this->assignmentService->assignSpecificCourier($order, $courier);

        if (!$delivery) {
            return response()->json([
                'success' => false,
                'message' => 'Impossible d\'assigner ce livreur',
            ], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Livreur assigné manuellement',
            'data' => $delivery->load('courier:id,name,phone'),
        ]);
    }

    public function reassign(Delivery $delivery): JsonResponse
    {
        $newCourier = $this->assignmentService->reassignDelivery($delivery);

        if (!$newCourier) {
            return response()->json([
                'success' => false,
                'message' => 'Aucun livreur disponible pour la réassignation',
            ], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Livraison réassignée',
            'data' => [
                'courier' => $newCourier->only('id', 'name', 'phone'),
            ],
        ]);
    }

    public function estimateDeliveryTime(Order $order): JsonResponse
    {
        $estimate = $this->assignmentService->estimateDeliveryTime(
            $order->pharmacy->latitude,
            $order->pharmacy->longitude,
            $order->delivery_latitude,
            $order->delivery_longitude,
        );

        return response()->json([
            'success' => true,
            'data' => $estimate,
        ]);
    }
}
