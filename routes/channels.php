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
