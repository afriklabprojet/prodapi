<?php

use App\Models\Delivery;
use App\Services\ChatService;
use Illuminate\Support\Facades\Broadcast;

/*
|--------------------------------------------------------------------------
| Broadcast Channels
|--------------------------------------------------------------------------
|
| Canaux de diffusion WebSocket pour le chat en temps réel.
| Chaque canal privé nécessite une autorisation.
|
*/

/**
 * Canal de chat pour une livraison spécifique
 * Accessible uniquement par les participants (client, pharmacie, livreur)
 */
Broadcast::channel('delivery.{deliveryId}.chat', function ($user, int $deliveryId) {
    $chatService = app(ChatService::class);
    $currentUser = $chatService->resolveCurrentUser($user);
    
    $delivery = Delivery::find($deliveryId);
    
    if (!$delivery) {
        return false;
    }
    
    return $chatService->isDeliveryParticipant($delivery, $currentUser);
});

/**
 * Canal de chat personnel pour un utilisateur
 * Reçoit tous les nouveaux messages destinés à cet utilisateur
 */
Broadcast::channel('chat.{type}.{id}', function ($user, string $type, int $id) {
    $chatService = app(ChatService::class);
    $currentUser = $chatService->resolveCurrentUser($user);
    
    // L'utilisateur ne peut écouter que son propre canal
    return $currentUser['type'] === $type && $currentUser['id'] === $id;
});

/**
 * Canal de chat pour une session persistante (pharmacie ↔ client)
 * Accessible uniquement par les participants de la session.
 */
Broadcast::channel('chat-session.{sessionId}', function ($user, int $sessionId) {
    $chatService = app(ChatService::class);
    $currentUser = $chatService->resolveCurrentUser($user);

    // Cherche la session et vérifie que l'utilisateur en est participant.
    $session = \App\Models\ChatSession::find($sessionId);

    if (!$session) {
        return false;
    }

    return $chatService->isChatSessionParticipant($session, $currentUser);
});

/**
 * Canal de présence pour une livraison (voir qui est en ligne)
 */
Broadcast::channel('delivery.{deliveryId}.presence', function ($user, int $deliveryId) {
    $chatService = app(ChatService::class);
    $currentUser = $chatService->resolveCurrentUser($user);
    
    $delivery = Delivery::find($deliveryId);
    
    if (!$delivery || !$chatService->isDeliveryParticipant($delivery, $currentUser)) {
        return false;
    }
    
    // Retourner les informations de présence
    return [
        'id' => $currentUser['id'],
        'type' => $currentUser['type'],
        'name' => $currentUser['name'],
    ];
});

/**
 * Canal privé du coursier — reçoit offres prises, nouvelles livraisons, etc.
 * Accessible uniquement par le coursier lui-même.
 */
Broadcast::channel('courier.{courierId}', function ($user, int $courierId) {
    if (!$user) {
        return false;
    }
    $courier = \App\Models\Courier::where('user_id', $user->id)->first();
    return $courier && $courier->id === $courierId;
});

/**
 * Canal privé de la commande — reçoit les mises à jour de position du coursier,
 * les changements de statut de livraison, et les ETA.
 * Accessible par le client propriétaire de la commande.
 */
Broadcast::channel('order.{orderId}', function ($user, int $orderId) {
    if (!$user) {
        return false;
    }
    return \App\Models\Order::where('id', $orderId)
        ->where('customer_id', $user->id)
        ->exists();
});
