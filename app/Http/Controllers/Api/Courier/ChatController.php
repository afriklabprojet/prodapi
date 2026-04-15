<?php

namespace App\Http\Controllers\Api\Courier;

use App\Http\Controllers\Controller;
use App\Jobs\SendChatNotification;
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

        $query = DeliveryMessage::where('delivery_id', $delivery->id);

        // Filtre optionnel par target (pharmacy/customer)
        $target = $request->query('target');
        if ($target) {
            $normalizedTarget = $target === 'customer' ? 'client' : $target;
            $query->where(function ($q) use ($normalizedTarget, $courier) {
                $q->where(function ($q2) use ($normalizedTarget) {
                    $q2->where('sender_type', $normalizedTarget)
                        ->orWhere('receiver_type', $normalizedTarget);
                })->where(function ($q2) use ($courier) {
                    $q2->where('sender_type', 'courier')
                        ->where('sender_id', $courier->id)
                        ->orWhere(function ($q3) use ($courier) {
                            $q3->where('receiver_type', 'courier')
                               ->where('receiver_id', $courier->id);
                        });
                });
            });
        } else {
            $query->where(function ($q) use ($courier) {
                $q->where(function ($q2) use ($courier) {
                    $q2->where('sender_type', 'courier')
                        ->where('sender_id', $courier->id);
                })->orWhere(function ($q2) use ($courier) {
                    $q2->where('receiver_type', 'courier')
                        ->where('receiver_id', $courier->id);
                });
            });
        }

        $messages = $query->orderBy('created_at', 'asc')->get();

        // Marquer les messages reçus comme lus
        DeliveryMessage::where('delivery_id', $delivery->id)
            ->where('receiver_type', 'courier')
            ->where('receiver_id', $courier->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        // Transformer avec is_mine
        $data = $messages->map(function ($msg) use ($courier) {
            return [
                'id' => $msg->id,
                'delivery_id' => $msg->delivery_id,
                'message' => $msg->message,
                'sender' => [
                    'type' => $msg->sender_type,
                    'id' => $msg->sender_id,
                ],
                'receiver' => [
                    'type' => $msg->receiver_type,
                    'id' => $msg->receiver_id,
                ],
                'is_mine' => $msg->sender_type === 'courier' && $msg->sender_id === $courier->id,
                'is_read' => $msg->read_at !== null,
                'created_at' => $msg->created_at->toIso8601String(),
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    public function store(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'message' => 'required|string|max:1000',
            // Accepte target OU receiver_type+receiver_id
            'target' => 'sometimes|in:pharmacy,customer,client',
            'receiver_type' => 'sometimes|in:pharmacy,client,customer',
            'receiver_id' => 'sometimes|integer',
        ]);

        $courier = $request->user()->courier;
        $delivery = Delivery::where('courier_id', $courier->id)->findOrFail($id);

        // Résoudre receiver depuis target si receiver_type/receiver_id absents
        $receiverType = $request->receiver_type;
        $receiverId = $request->receiver_id;

        if (!$receiverType && $request->target) {
            $order = $delivery->order;
            $target = $request->target;
            if ($target === 'pharmacy') {
                $receiverType = 'pharmacy';
                $receiverId = $order->pharmacy_id;
            } elseif (in_array($target, ['customer', 'client'])) {
                $receiverType = 'client';
                $receiverId = $order->customer_id;
            }
        }

        if (!$receiverType || !$receiverId) {
            return response()->json(['success' => false, 'message' => 'Destinataire requis (target ou receiver_type+receiver_id)'], 422);
        }

        $message = DeliveryMessage::create([
            'delivery_id' => $delivery->id,
            'sender_type' => 'courier',
            'sender_id' => $courier->id,
            'receiver_type' => $receiverType,
            'receiver_id' => $receiverId,
            'message' => $request->message,
        ]);

        // Notify recipient via FCM
        SendChatNotification::dispatch($message, [
            'type' => 'courier',
            'id' => $courier->id,
            'name' => $request->user()->name,
        ]);

        return response()->json([
            'success' => true,
            'data' => $message,
        ], 201);
    }
}
