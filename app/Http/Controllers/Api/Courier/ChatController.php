<?php

namespace App\Http\Controllers\Api\Courier;

use App\Http\Controllers\Controller;
use App\Models\Delivery;
use App\Models\DeliveryMessage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    public function index(Request $request, int $id): JsonResponse
    {
        $courier = $request->user()->courier;
        $delivery = Delivery::where('courier_id', $courier->id)->findOrFail($id);

        $messages = DeliveryMessage::where('delivery_id', $delivery->id)
            ->where(function ($q) use ($courier) {
                $q->where(function ($q2) use ($courier) {
                    $q2->where('sender_type', 'courier')
                        ->where('sender_id', $courier->id);
                })->orWhere(function ($q2) use ($courier) {
                    $q2->where('receiver_type', 'courier')
                        ->where('receiver_id', $courier->id);
                });
            })
            ->orderBy('created_at', 'asc')
            ->get();

        // Marquer les messages reçus comme lus
        DeliveryMessage::where('delivery_id', $delivery->id)
            ->where('receiver_type', 'courier')
            ->where('receiver_id', $courier->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json([
            'success' => true,
            'data' => $messages,
        ]);
    }

    public function store(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'receiver_type' => 'required|in:pharmacy,client',
            'receiver_id' => 'required|integer',
            'message' => 'required|string|max:1000',
        ]);

        $courier = $request->user()->courier;
        $delivery = Delivery::where('courier_id', $courier->id)->findOrFail($id);

        $message = DeliveryMessage::create([
            'delivery_id' => $delivery->id,
            'sender_type' => 'courier',
            'sender_id' => $courier->id,
            'receiver_type' => $request->receiver_type,
            'receiver_id' => $request->receiver_id,
            'message' => $request->message,
        ]);

        return response()->json([
            'success' => true,
            'data' => $message,
        ], 201);
    }
}
