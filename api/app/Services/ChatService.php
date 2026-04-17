<?php

namespace App\Services;

use App\Enums\MessageType;
use App\Events\NewChatMessage;
use App\Jobs\SendChatNotification;
use App\Models\Courier;
use App\Models\Delivery;
use App\Models\DeliveryMessage;
use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

final class ChatService
{
    private const CACHE_TTL_UNREAD = 300; // 5 minutes
    private const MAX_MESSAGE_LENGTH = 2000;
    private const DEFAULT_PER_PAGE = 50;
    private const MAX_PER_PAGE = 100;

    /**
     * Participant types valides
     */
    private const VALID_PARTICIPANT_TYPES = ['courier', 'pharmacy', 'client'];

    /**
     * Identifier l'utilisateur courant et son type de participant
     */
    public function resolveCurrentUser(User $user): array
    {
        // Priorité: courier > pharmacy > client
        if ($user->courier) {
            return [
                'type' => 'courier',
                'id' => (int) $user->courier->id,
                'name' => $user->name,
                'entity' => $user->courier,
            ];
        }

        // HasOneThrough peut retourner null si le pivot n'est pas chargé;
        // fallback sur la relation BelongsToMany directe.
        $pharmacy = $user->pharmacy ?? $user->pharmacies()->first();
        if ($pharmacy) {
            return [
                'type' => 'pharmacy',
                'id' => (int) $pharmacy->id,
                'name' => $pharmacy->name ?? $user->name,
                'entity' => $pharmacy,
            ];
        }

        return [
            'type' => 'client',
            'id' => (int) $user->id,
            'name' => $user->name,
            'entity' => $user,
        ];
    }

    /**
     * SECURITY: Vérifier que l'utilisateur est participant de la livraison
     * 
     * @throws AccessDeniedHttpException Si l'utilisateur n'est pas autorisé
     */
    public function assertIsDeliveryParticipant(Delivery $delivery, array $currentUser): void
    {
        if (!$this->isDeliveryParticipant($delivery, $currentUser)) {
            throw new AccessDeniedHttpException('Accès interdit à cette conversation');
        }
    }

    /**
     * Vérifier si l'utilisateur est un participant de la livraison
     */
    public function isDeliveryParticipant(Delivery $delivery, array $currentUser): bool
    {
        // Charger la commande si nécessaire (évite N+1)
        $order = $delivery->relationLoaded('order') 
            ? $delivery->order 
            : $delivery->load('order')->order;
        
        if (!$order) {
            return false;
        }

        return match ($currentUser['type']) {
            'courier' => (int) $delivery->courier_id === (int) $currentUser['id'],
            'pharmacy' => (int) $order->pharmacy_id === (int) $currentUser['id'],
            'client' => (int) $order->customer_id === (int) $currentUser['id'],
            default => false,
        };
    }

    /**
     * SECURITY: Vérifier que l'utilisateur est participant d'une session de chat persistante
     */
    public function isChatSessionParticipant(\App\Models\ChatSession $session, array $currentUser): bool
    {
        return $session->isParticipant($currentUser);
    }

    /**
     * SECURITY: Vérifier que le destinataire est un participant valide de la livraison
     */
    public function isValidReceiver(Delivery $delivery, string $receiverType, int $receiverId): bool
    {
        if (!in_array($receiverType, self::VALID_PARTICIPANT_TYPES, true)) {
            return false;
        }

        $order = $delivery->relationLoaded('order') 
            ? $delivery->order 
            : $delivery->load('order')->order;

        if (!$order) {
            return false;
        }

        return match ($receiverType) {
            'courier' => $delivery->courier_id === $receiverId,
            'pharmacy' => $order->pharmacy_id === $receiverId,
            'client' => $order->customer_id === $receiverId,
            default => false,
        };
    }

    /**
     * Récupérer les messages paginés avec cursor-based pagination
     * (Optimisé pour infinite scroll)
     */
    public function getMessages(
        Delivery $delivery,
        array $currentUser,
        ?int $beforeId = null,
        int $perPage = self::DEFAULT_PER_PAGE
    ): LengthAwarePaginator {
        $perPage = min($perPage, self::MAX_PER_PAGE);

        $query = DeliveryMessage::where('delivery_id', $delivery->id)
            ->orderByDesc('created_at')
            ->orderByDesc('id');

        // Cursor-based: messages avant un ID spécifique (pour infinite scroll)
        if ($beforeId !== null) {
            $query->where('id', '<', $beforeId);
        }

        return $query->paginate($perPage);
    }

    /**
     * Récupérer les messages d'une conversation spécifique
     */
    public function getConversationMessages(
        Delivery $delivery,
        array $currentUser,
        string $participantType,
        int $participantId,
        ?int $beforeId = null,
        int $perPage = self::DEFAULT_PER_PAGE
    ): LengthAwarePaginator {
        // Valider le type de participant
        if (!in_array($participantType, self::VALID_PARTICIPANT_TYPES, true)) {
            throw new \InvalidArgumentException('Type de participant invalide');
        }

        $perPage = min($perPage, self::MAX_PER_PAGE);

        $query = DeliveryMessage::forConversation(
            $delivery->id,
            $currentUser['type'],
            $currentUser['id'],
            $participantType,
            $participantId
        )->orderByDesc('created_at')->orderByDesc('id');

        if ($beforeId !== null) {
            $query->where('id', '<', $beforeId);
        }

        return $query->paginate($perPage);
    }

    /**
     * Envoyer un message
     */
    public function sendMessage(
        Delivery $delivery,
        array $currentUser,
        string $receiverType,
        int $receiverId,
        string $content,
        MessageType $type = MessageType::TEXT,
        ?array $metadata = null
    ): DeliveryMessage {
        // SECURITY: Valider que le destinataire est un participant
        if (!$this->isValidReceiver($delivery, $receiverType, $receiverId)) {
            throw new AccessDeniedHttpException('Destinataire invalide pour cette livraison');
        }

        // SECURITY: On ne peut pas s'envoyer de message à soi-même
        if ($currentUser['type'] === $receiverType && $currentUser['id'] === $receiverId) {
            throw new \InvalidArgumentException('Impossible de s\'envoyer un message à soi-même');
        }

        // Valider et nettoyer le contenu
        $content = $this->sanitizeContent($content, $type);

        // Créer le message dans une transaction
        $message = DB::transaction(function () use ($delivery, $currentUser, $receiverType, $receiverId, $content, $type, $metadata) {
            return DeliveryMessage::create([
                'delivery_id' => $delivery->id,
                'sender_type' => $currentUser['type'],
                'sender_id' => $currentUser['id'],
                'receiver_type' => $receiverType,
                'receiver_id' => $receiverId,
                'message' => $content,
                'type' => $type->value,
                'metadata' => $metadata,
            ]);
        });

        // Invalider le cache des messages non lus
        $this->invalidateUnreadCache($receiverType, $receiverId, $delivery->id);

        // Dispatcher la notification en async (Job)
        SendChatNotification::dispatch($message, $currentUser);

        // Broadcaster pour WebSocket (temps réel)
        event(new NewChatMessage($message, $currentUser));

        return $message;
    }

    /**
     * Envoyer un message système (automatique)
     */
    public function sendSystemMessage(Delivery $delivery, string $content): DeliveryMessage
    {
        $order = $delivery->load('order')->order;
        
        // Le message système est envoyé à tous les participants
        // On utilise le client comme destinataire principal
        return DeliveryMessage::create([
            'delivery_id' => $delivery->id,
            'sender_type' => 'system',
            'sender_id' => 0,
            'receiver_type' => 'client',
            'receiver_id' => $order->customer_id,
            'message' => $content,
            'type' => MessageType::SYSTEM->value,
        ]);
    }

    /**
     * Marquer les messages comme lus
     */
    public function markAsRead(
        Delivery $delivery,
        array $currentUser,
        string $senderType,
        int $senderId
    ): int {
        $count = DeliveryMessage::where('delivery_id', $delivery->id)
            ->where('receiver_type', $currentUser['type'])
            ->where('receiver_id', $currentUser['id'])
            ->where('sender_type', $senderType)
            ->where('sender_id', $senderId)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        // Invalider le cache
        $this->invalidateUnreadCache($currentUser['type'], $currentUser['id'], $delivery->id);

        return $count;
    }

    /**
     * Marquer tous les messages d'une livraison comme lus
     */
    public function markAllAsRead(Delivery $delivery, array $currentUser): int
    {
        $count = DeliveryMessage::where('delivery_id', $delivery->id)
            ->where('receiver_type', $currentUser['type'])
            ->where('receiver_id', $currentUser['id'])
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        $this->invalidateUnreadCache($currentUser['type'], $currentUser['id'], $delivery->id);

        return $count;
    }

    /**
     * Compter les messages non lus (avec cache)
     */
    public function getUnreadCount(Delivery $delivery, array $currentUser): int
    {
        $cacheKey = $this->getUnreadCacheKey($currentUser['type'], $currentUser['id'], $delivery->id);

        return Cache::remember($cacheKey, self::CACHE_TTL_UNREAD, function () use ($delivery, $currentUser) {
            return DeliveryMessage::where('delivery_id', $delivery->id)
                ->where('receiver_type', $currentUser['type'])
                ->where('receiver_id', $currentUser['id'])
                ->whereNull('read_at')
                ->count();
        });
    }

    /**
     * Compter le total de messages non lus pour un utilisateur (toutes livraisons)
     */
    public function getTotalUnreadCount(array $currentUser): int
    {
        return DeliveryMessage::where('receiver_type', $currentUser['type'])
            ->where('receiver_id', $currentUser['id'])
            ->whereNull('read_at')
            ->count();
    }

    /**
     * Supprimer un message (soft delete)
     */
    public function deleteMessage(DeliveryMessage $message, array $currentUser): bool
    {
        // SECURITY: Seul l'expéditeur peut supprimer son message
        if ($message->sender_type !== $currentUser['type'] || $message->sender_id !== $currentUser['id']) {
            throw new AccessDeniedHttpException('Vous ne pouvez supprimer que vos propres messages');
        }

        // Délai maximum pour supprimer (ex: 15 minutes)
        $maxDeleteDelay = now()->subMinutes(15);
        if ($message->created_at < $maxDeleteDelay) {
            throw new \InvalidArgumentException('Ce message ne peut plus être supprimé');
        }

        return $message->delete();
    }

    /**
     * Récupérer les participants d'une livraison
     */
    public function getParticipants(Delivery $delivery): array
    {
        $order = $delivery->load(['order.customer', 'courier'])->order;
        
        $participants = [];

        // Client
        if ($order->customer) {
            $participants[] = [
                'type' => 'client',
                'id' => $order->customer->id,
                'name' => $order->customer->name,
                'avatar' => $order->customer->avatar_url ?? null,
            ];
        }

        // Pharmacie
        if ($order->pharmacy) {
            $pharmacy = Pharmacy::find($order->pharmacy_id);
            if ($pharmacy) {
                $participants[] = [
                    'type' => 'pharmacy',
                    'id' => $pharmacy->id,
                    'name' => $pharmacy->name,
                    'avatar' => $pharmacy->logo_url ?? null,
                ];
            }
        }

        // Livreur
        if ($delivery->courier) {
            $participants[] = [
                'type' => 'courier',
                'id' => $delivery->courier->id,
                'name' => $delivery->courier->user->name ?? 'Livreur',
                'avatar' => $delivery->courier->user->avatar_url ?? null,
            ];
        }

        return $participants;
    }

    /**
     * Nettoyer et valider le contenu du message
     */
    private function sanitizeContent(string $content, MessageType $type): string
    {
        // Trim et limite de longueur
        $content = trim($content);
        
        if (mb_strlen($content) > self::MAX_MESSAGE_LENGTH) {
            $content = mb_substr($content, 0, self::MAX_MESSAGE_LENGTH);
        }

        // Pour les messages texte, supprimer les tags HTML dangereux
        if ($type === MessageType::TEXT) {
            $content = strip_tags($content);
        }

        return $content;
    }

    /**
     * Clé de cache pour les messages non lus
     */
    private function getUnreadCacheKey(string $type, int $id, int $deliveryId): string
    {
        return "chat:unread:{$type}:{$id}:delivery:{$deliveryId}";
    }

    /**
     * Invalider le cache des messages non lus
     */
    private function invalidateUnreadCache(string $type, int $id, int $deliveryId): void
    {
        Cache::forget($this->getUnreadCacheKey($type, $id, $deliveryId));
    }
}
