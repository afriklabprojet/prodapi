<?php

namespace App\Http\Controllers\Api;

use App\Enums\MessageType;
use App\Http\Controllers\Controller;
use App\Http\Resources\MessageCollection;
use App\Http\Resources\MessageResource;
use App\Models\Delivery;
use App\Models\DeliveryMessage;
use App\Services\ChatService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rules\Enum;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

/**
 * Chat Controller - Version Production SaaS
 * 
 * Sécurisé, optimisé et prêt pour le temps réel.
 * 
 * @security Toutes les méthodes vérifient que l'utilisateur est participant de la livraison
 * @performance Pagination, cache, eager loading
 * @realtime Events broadcast pour WebSocket
 */
class ChatController extends Controller
{
    public function __construct(
        private readonly ChatService $chatService
    ) {}

    /**
     * Récupérer les messages d'une conversation (avec pagination)
     * 
     * @queryParam participant_type string Type de l'autre participant. Exemple: courier
     * @queryParam participant_id int ID de l'autre participant. Exemple: 1
     * @queryParam before_id int Pour pagination cursor-based (infinite scroll)
     * @queryParam per_page int Messages par page (max 100). Exemple: 50
     */
    public function getMessages(Request $request, Delivery $delivery): JsonResponse
    {
        $validated = $request->validate([
            'participant_type' => 'sometimes|in:courier,pharmacy,client',
            'participant_id' => 'sometimes|integer',
            'before_id' => 'sometimes|integer|min:1',
            'per_page' => 'sometimes|integer|min:1|max:100',
        ]);

        // Ignorer participant_id <= 0 (fallback FCM sans données) au lieu de 422
        if (isset($validated['participant_id']) && $validated['participant_id'] <= 0) {
            unset($validated['participant_id']);
            unset($validated['participant_type']);
        }

        // Résoudre l'utilisateur courant
        $currentUser = $this->chatService->resolveCurrentUser($request->user());

        // SECURITY: Vérifier l'accès à cette livraison
        $this->chatService->assertIsDeliveryParticipant($delivery, $currentUser);

        $beforeId = $validated['before_id'] ?? null;
        $perPage = $validated['per_page'] ?? 50;

        // Récupérer les messages (avec ou sans filtre de conversation)
        if (isset($validated['participant_type'], $validated['participant_id'])) {
            $messages = $this->chatService->getConversationMessages(
                $delivery,
                $currentUser,
                $validated['participant_type'],
                (int) $validated['participant_id'],
                $beforeId,
                $perPage
            );
        } else {
            $messages = $this->chatService->getMessages(
                $delivery,
                $currentUser,
                $beforeId,
                $perPage
            );
        }

        // Marquer comme lus (optionnel, selon flag)
        if ($request->boolean('mark_read', false) && isset($validated['participant_type'])) {
            $this->chatService->markAsRead(
                $delivery,
                $currentUser,
                $validated['participant_type'],
                (int) $validated['participant_id']
            );
        }

        $collection = (new MessageCollection($messages))->setCurrentUser($currentUser);

        return response()->json([
            'success' => true,
            'data' => $collection,
            'meta' => [
                'current_page' => $messages->currentPage(),
                'last_page' => $messages->lastPage(),
                'per_page' => $messages->perPage(),
                'total' => $messages->total(),
                'has_more' => $messages->hasMorePages(),
            ],
            'delivery' => [
                'id' => $delivery->id,
                'status' => $delivery->status,
            ],
        ]);
    }

    /**
     * Envoyer un message
     * 
     * @bodyParam receiver_type string required Type du destinataire. Exemple: courier
     * @bodyParam receiver_id int required ID du destinataire. Exemple: 1
     * @bodyParam message string required Contenu du message (max 2000 caractères)
     * @bodyParam type string Type de message: text, image, file, location. Défaut: text
     * @bodyParam metadata object Métadonnées (URL fichier, coordonnées, etc.)
     */
    public function sendMessage(Request $request, Delivery $delivery): JsonResponse
    {
        $validated = $request->validate([
            'message' => 'required|string|max:2000',
            // Accepte target OU receiver_type+receiver_id
            'target' => 'sometimes|in:courier,pharmacy,client,customer',
            'receiver_type' => 'sometimes|in:courier,pharmacy,client',
            'receiver_id' => 'sometimes|integer|min:1',
            'type' => ['sometimes', new Enum(MessageType::class)],
            'metadata' => 'sometimes|array',
            'metadata.url' => 'sometimes|url|max:500',
            'metadata.filename' => 'sometimes|string|max:255',
            'metadata.latitude' => 'sometimes|numeric|between:-90,90',
            'metadata.longitude' => 'sometimes|numeric|between:-180,180',
        ]);

        // Résoudre l'utilisateur courant
        $currentUser = $this->chatService->resolveCurrentUser($request->user());

        // SECURITY: Vérifier l'accès à cette livraison
        $this->chatService->assertIsDeliveryParticipant($delivery, $currentUser);

        // Résoudre receiver depuis target si receiver_type/receiver_id absents
        $receiverType = $validated['receiver_type'] ?? null;
        $receiverId = $validated['receiver_id'] ?? null;

        if (!$receiverType && isset($validated['target'])) {
            $order = $delivery->order;
            $target = $validated['target'];
            if ($target === 'pharmacy') {
                $receiverType = 'pharmacy';
                $receiverId = $order->pharmacy_id;
            } elseif (in_array($target, ['customer', 'client'])) {
                $receiverType = 'client';
                $receiverId = $order->customer_id;
            } elseif ($target === 'courier') {
                $receiverType = 'courier';
                $receiverId = $delivery->courier_id;
            }
        }

        if (!$receiverType || !$receiverId) {
            return response()->json([
                'success' => false,
                'message' => 'Destinataire requis (target ou receiver_type+receiver_id)',
            ], 422);
        }

        $messageType = isset($validated['type']) 
            ? MessageType::from($validated['type']) 
            : MessageType::TEXT;

        // Envoyer le message
        $message = $this->chatService->sendMessage(
            $delivery,
            $currentUser,
            $receiverType,
            (int) $receiverId,
            $validated['message'],
            $messageType,
            $validated['metadata'] ?? null
        );

        $resource = (new MessageResource($message))->setCurrentUser($currentUser);

        return response()->json([
            'success' => true,
            'data' => $resource,
        ], 201);
    }

    /**
     * Récupérer le nombre de messages non lus (avec cache)
     */
    public function getUnreadCount(Request $request, Delivery $delivery): JsonResponse
    {
        $currentUser = $this->chatService->resolveCurrentUser($request->user());

        // SECURITY: Vérifier l'accès
        $this->chatService->assertIsDeliveryParticipant($delivery, $currentUser);

        $count = $this->chatService->getUnreadCount($delivery, $currentUser);

        return response()->json([
            'success' => true,
            'unread_count' => $count,
        ]);
    }

    /**
     * Marquer tous les messages comme lus
     * 
     * @bodyParam sender_type string Type de l'expéditeur à marquer comme lu
     * @bodyParam sender_id int ID de l'expéditeur
     */
    public function markAllAsRead(Request $request, Delivery $delivery): JsonResponse
    {
        $validated = $request->validate([
            'sender_type' => 'sometimes|in:courier,pharmacy,client',
            'sender_id' => 'sometimes|integer|min:1',
        ]);

        $currentUser = $this->chatService->resolveCurrentUser($request->user());

        // SECURITY: Vérifier l'accès
        $this->chatService->assertIsDeliveryParticipant($delivery, $currentUser);

        // Marquer comme lu (tous ou spécifique)
        if (isset($validated['sender_type'], $validated['sender_id'])) {
            $count = $this->chatService->markAsRead(
                $delivery,
                $currentUser,
                $validated['sender_type'],
                (int) $validated['sender_id']
            );
        } else {
            $count = $this->chatService->markAllAsRead($delivery, $currentUser);
        }

        return response()->json([
            'success' => true,
            'marked_count' => $count,
        ]);
    }

    /**
     * Récupérer les participants de la conversation
     */
    public function getParticipants(Request $request, Delivery $delivery): JsonResponse
    {
        $currentUser = $this->chatService->resolveCurrentUser($request->user());

        // SECURITY: Vérifier l'accès
        $this->chatService->assertIsDeliveryParticipant($delivery, $currentUser);

        $participants = $this->chatService->getParticipants($delivery);

        return response()->json([
            'success' => true,
            'participants' => $participants,
            'me' => [
                'type' => $currentUser['type'],
                'id' => $currentUser['id'],
                'name' => $currentUser['name'],
            ],
        ]);
    }

    /**
     * Supprimer un message (soft delete, expéditeur uniquement, max 15 min)
     */
    public function deleteMessage(Request $request, Delivery $delivery, DeliveryMessage $message): JsonResponse
    {
        $currentUser = $this->chatService->resolveCurrentUser($request->user());

        // SECURITY: Vérifier l'accès à la livraison
        $this->chatService->assertIsDeliveryParticipant($delivery, $currentUser);

        // Vérifier que le message appartient à cette livraison
        if ($message->delivery_id !== $delivery->id) {
            throw new AccessDeniedHttpException('Message introuvable dans cette conversation');
        }

        $this->chatService->deleteMessage($message, $currentUser);

        return response()->json([
            'success' => true,
            'message' => 'Message supprimé',
        ]);
    }

    /**
     * Résoudre ou créer la delivery d'une commande (helper)
     * 
     * Si la commande n'a pas de livraison, on en crée une automatiquement
     * pour permettre le chat pharmacie ↔ client avant l'assignation d'un livreur.
     */
    private function resolveDeliveryFromOrder(int $orderId): Delivery
    {
        $order = \App\Models\Order::findOrFail($orderId);
        $delivery = $order->delivery;

        if (!$delivery) {
            // Créer automatiquement une livraison pour permettre le chat
            $delivery = Delivery::create([
                'order_id' => $order->id,
                'pharmacy_id' => $order->pharmacy_id,
                'customer_id' => $order->user_id,
                'status' => 'pending',
                'pickup_address' => $order->pharmacy?->address ?? 'Pharmacie',
                'delivery_address' => $order->delivery_address ?? $order->user?->address ?? 'Client',
                'pickup_lat' => $order->pharmacy?->latitude,
                'pickup_lng' => $order->pharmacy?->longitude,
                'delivery_lat' => $order->delivery_lat,
                'delivery_lng' => $order->delivery_lng,
            ]);
            
            \Log::info("[Chat] Auto-created delivery #{$delivery->id} for order #{$orderId} to enable chat");
        }

        return $delivery;
    }

    /**
     * Récupérer les messages via order ID (résout la delivery automatiquement)
     */
    public function getMessagesByOrder(Request $request, int $order): JsonResponse
    {
        $delivery = $this->resolveDeliveryFromOrder($order);
        return $this->getMessages($request, $delivery);
    }

    /**
     * Envoyer un message via order ID (résout la delivery automatiquement)
     */
    public function sendMessageByOrder(Request $request, int $order): JsonResponse
    {
        $delivery = $this->resolveDeliveryFromOrder($order);
        return $this->sendMessage($request, $delivery);
    }
}
