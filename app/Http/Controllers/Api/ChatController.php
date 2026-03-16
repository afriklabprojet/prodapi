<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Delivery;
use App\Models\DeliveryMessage;
use App\Notifications\NewChatMessageNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ChatController extends Controller
{
    /**
     * Récupérer les messages d'une conversation
     */
    public function getMessages(Request $request, Delivery $delivery): JsonResponse
    {
        $request->validate([
            'participant_type' => 'required|in:courier,pharmacy,client',
            'participant_id' => 'required|integer',
        ]);

        // Déterminer l'utilisateur courant
        $currentUser = $this->getCurrentUser($request);
        if (!$currentUser) {
            return response()->json(['error' => 'Non autorisé'], 401);
        }

        $participantType = $request->participant_type;
        $participantId = $request->participant_id;

        // Récupérer les messages de la conversation
        $messages = DeliveryMessage::forConversation(
            $delivery->id,
            $currentUser['type'],
            $currentUser['id'],
            $participantType,
            $participantId
        )
        ->orderBy('created_at', 'asc')
        ->get()
        ->map(function ($message) use ($currentUser) {
            return [
                'id' => $message->id,
                'message' => $message->message,
                'sender_type' => $message->sender_type,
                'sender_id' => $message->sender_id,
                'is_mine' => $message->sender_type === $currentUser['type'] && $message->sender_id === $currentUser['id'],
                'read_at' => $message->read_at?->toIso8601String(),
                'created_at' => $message->created_at->toIso8601String(),
            ];
        });

        // Marquer les messages reçus comme lus
        DeliveryMessage::where('delivery_id', $delivery->id)
            ->where('receiver_type', $currentUser['type'])
            ->where('receiver_id', $currentUser['id'])
            ->where('sender_type', $participantType)
            ->where('sender_id', $participantId)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json([
            'success' => true,
            'messages' => $messages,
            'delivery' => [
                'id' => $delivery->id,
                'status' => $delivery->status,
            ],
        ]);
    }

    /**
     * Envoyer un message
     */
    public function sendMessage(Request $request, Delivery $delivery): JsonResponse
    {
        $request->validate([
            'receiver_type' => 'required|in:courier,pharmacy,client',
            'receiver_id' => 'required|integer',
            'message' => 'required|string|max:1000',
        ]);

        // Déterminer l'utilisateur courant
        $currentUser = $this->getCurrentUser($request);
        if (!$currentUser) {
            return response()->json(['error' => 'Non autorisé'], 401);
        }

        // Créer le message
        $message = DeliveryMessage::create([
            'delivery_id' => $delivery->id,
            'sender_type' => $currentUser['type'],
            'sender_id' => $currentUser['id'],
            'receiver_type' => $request->receiver_type,
            'receiver_id' => $request->receiver_id,
            'message' => $request->message,
        ]);

        // Envoyer notification push au destinataire
        $this->notifyReceiver($message, $currentUser);

        return response()->json([
            'success' => true,
            'message' => [
                'id' => $message->id,
                'message' => $message->message,
                'sender_type' => $message->sender_type,
                'sender_id' => $message->sender_id,
                'is_mine' => true,
                'read_at' => null,
                'created_at' => $message->created_at->toIso8601String(),
            ],
        ]);
    }

    /**
     * Récupérer le nombre de messages non lus
     */
    public function getUnreadCount(Request $request, Delivery $delivery): JsonResponse
    {
        $currentUser = $this->getCurrentUser($request);
        if (!$currentUser) {
            return response()->json(['error' => 'Non autorisé'], 401);
        }

        $count = DeliveryMessage::where('delivery_id', $delivery->id)
            ->where('receiver_type', $currentUser['type'])
            ->where('receiver_id', $currentUser['id'])
            ->whereNull('read_at')
            ->count();

        return response()->json([
            'success' => true,
            'unread_count' => $count,
        ]);
    }

    /**
     * Marquer tous les messages comme lus
     */
    public function markAllAsRead(Request $request, Delivery $delivery): JsonResponse
    {
        $request->validate([
            'sender_type' => 'required|in:courier,pharmacy,client',
            'sender_id' => 'required|integer',
        ]);

        $currentUser = $this->getCurrentUser($request);
        if (!$currentUser) {
            return response()->json(['error' => 'Non autorisé'], 401);
        }
        // SECURITY: Vérifier que l'utilisateur est un participant de cette livraison
        if (!$this->isDeliveryParticipant($delivery, $currentUser)) {
            return response()->json(['error' => 'Accès interdit à cette conversation'], 403);
        }
        DeliveryMessage::where('delivery_id', $delivery->id)
            ->where('receiver_type', $currentUser['type'])
            ->where('receiver_id', $currentUser['id'])
            ->where('sender_type', $request->sender_type)
            ->where('sender_id', $request->sender_id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['success' => true]);
    }

    /**
     * Déterminer l'utilisateur courant basé sur le token
     */
    private function getCurrentUser(Request $request): ?array
    {
        $user = $request->user();
        
        if (!$user) {
            return null;
        }

        // Vérifier si c'est un coursier
        if ($user->courier) {
            return [
                'type' => 'courier',
                'id' => $user->courier->id,
                'name' => $user->name,
            ];
        }

        // Vérifier si c'est une pharmacie
        if ($user->pharmacy) {
            return [
                'type' => 'pharmacy',
                'id' => $user->pharmacy->id,
                'name' => $user->pharmacy->name ?? $user->name,
            ];
        }

        // C'est un client
        return [
            'type' => 'client',
            'id' => $user->id,
            'name' => $user->name,
        ];
    }

    /**
     * SECURITY: Vérifier que l'utilisateur courant est un participant de la livraison
     */
    private function isDeliveryParticipant(Delivery $delivery, array $currentUser): bool
    {
        $order = $delivery->order;
        if (!$order) return false;

        return match($currentUser['type']) {
            'courier' => $delivery->courier_id === $currentUser['id'],
            'pharmacy' => $order->pharmacy_id === $currentUser['id'],
            'client' => $order->customer_id === $currentUser['id'],
            default => false,
        };
    }

    /**
     * Notifier le destinataire d'un nouveau message
     */
    private function notifyReceiver(DeliveryMessage $message, array $sender): void
    {
        $receiver = $message->receiver();
        
        if (!$receiver) {
            return;
        }

        // Récupérer l'utilisateur associé au destinataire
        $user = match($message->receiver_type) {
            'courier' => $receiver->user ?? null,
            'pharmacy' => $receiver->user ?? null,
            'client' => $receiver,
            default => null,
        };

        if ($user && method_exists($user, 'notify')) {
            try {
                $user->notify(new NewChatMessageNotification(
                    $message->delivery,
                    $sender['name'],
                    $sender['type'],
                    $message->message
                ));
            } catch (\Exception $e) {
                // Log l'erreur mais ne pas bloquer l'envoi du message
                \Log::warning("Erreur notification chat: " . $e->getMessage());
            }
        }
    }
}
