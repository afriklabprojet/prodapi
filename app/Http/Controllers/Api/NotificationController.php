<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Notifications\DatabaseNotification;
use Illuminate\Support\Facades\Auth;

class NotificationController extends Controller
{
    /**
     * Get all notifications for authenticated user
     */
    public function index(Request $request): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        $notifications = $user->notifications()
            ->orderBy('created_at', 'desc')
            ->paginate(min((int) $request->input('per_page', 20), 100));

        return response()->json([
            'success' => true,
            'data' => [
                'notifications' => collect($notifications->items())->map(fn ($n) => $this->formatNotification($n))->values(),
                'unread_count' => $user->unreadNotifications()->count(),
                'pagination' => [
                    'current_page' => $notifications->currentPage(),
                    'last_page' => $notifications->lastPage(),
                    'per_page' => $notifications->perPage(),
                    'total' => $notifications->total(),
                ],
            ],
        ]);
    }

    /**
     * Get unread notifications only
     */
    public function unread(Request $request): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        $notifications = $user->unreadNotifications()
            ->paginate($request->input('per_page', 20));

        return response()->json([
            'success' => true,
            'data' => [
                'notifications' => collect($notifications->items())->map(fn ($n) => $this->formatNotification($n))->values(),
                'unread_count' => $user->unreadNotifications()->count(),
            ],
        ]);
    }

    /**
     * Mark notification as read
     */
    public function markAsRead(string $id): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        $notification = $user->notifications()->findOrFail($id);
        $notification->markAsRead();

        return response()->json([
            'success' => true,
            'message' => 'Notification marquée comme lue',
        ]);
    }

    /**
     * Mark all notifications as read
     */
    public function markAllAsRead(): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();
        $user->unreadNotifications->markAsRead();

        return response()->json([
            'success' => true,
            'message' => 'Toutes les notifications marquées comme lues',
        ]);
    }

    /**
     * Delete a notification
     */
    public function destroy(string $id): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        $notification = $user->notifications()->findOrFail($id);
        $notification->delete();

        return response()->json([
            'success' => true,
            'message' => 'Notification supprimée',
        ]);
    }

    /**
     * Update FCM token for push notifications
     */
    public function updateFcmToken(Request $request): JsonResponse
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        /** @var \App\Models\User $user */
        $user = Auth::user();
        $user->update([
            'fcm_token' => $request->fcm_token,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'FCM token mis à jour',
        ]);
    }

    /**
     * Remove FCM token (logout from push notifications)
     */
    public function removeFcmToken(): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();
        $user->update([
            'fcm_token' => null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'FCM token supprimé',
        ]);
    }

    /**
     * Get notification sound settings
     * Returns available sounds and current configuration for each notification type
     */
    public function getSoundSettings(): JsonResponse
    {
        $notificationSettings = app(\App\Services\NotificationSettingsService::class);
        
        // Define all notification types based on user role
        /** @var \App\Models\User $user */
        $user = Auth::user();
        
        $notificationTypes = [];
        
        // Common notification types
        $notificationTypes['delivery_timeout'] = [
            'label' => 'Annulation pour délai dépassé',
            'config' => $notificationSettings->getConfig('delivery_timeout'),
        ];
        
        // Role-specific notification types
        if ($user->role === 'client') {
            $notificationTypes['order_confirmed'] = [
                'label' => 'Commande confirmée',
                'config' => $notificationSettings->getConfig('order_confirmed'),
            ];
            $notificationTypes['courier_arrived'] = [
                'label' => 'Livreur arrivé',
                'config' => $notificationSettings->getConfig('courier_arrived'),
            ];
            $notificationTypes['delivery_completed'] = [
                'label' => 'Livraison terminée',
                'config' => $notificationSettings->getConfig('delivery_completed'),
            ];
        } elseif ($user->role === 'pharmacy') {
            $notificationTypes['new_order_received'] = [
                'label' => 'Nouvelle commande reçue',
                'config' => $notificationSettings->getConfig('new_order_received'),
            ];
            $notificationTypes['delivery_assigned'] = [
                'label' => 'Livreur assigné',
                'config' => $notificationSettings->getConfig('delivery_assigned'),
            ];
        } elseif ($user->role === 'courier') {
            $notificationTypes['delivery_assigned'] = [
                'label' => 'Nouvelle livraison assignée',
                'config' => $notificationSettings->getConfig('delivery_assigned'),
            ];
            $notificationTypes['courier_arrived'] = [
                'label' => 'Arrivée confirmée',
                'config' => $notificationSettings->getConfig('courier_arrived'),
            ];
        }
        
        return response()->json([
            'success' => true,
            'data' => [
                'available_sounds' => $notificationSettings->getAvailableSounds(),
                'notification_types' => $notificationTypes,
            ],
        ]);
    }

    /**
     * Normalize a notification into a consistent format.
     * Ensures every notification has guaranteed title, body, and type keys in data.
     */
    private function formatNotification(DatabaseNotification $notification): array
    {
        // $notification->data peut parfois revenir sous forme de string JSON
        // (anciennes notifications, accessor cassé, etc.) — on normalise en array.
        $rawData = $notification->data ?? [];
        if (is_string($rawData)) {
            $decoded = json_decode($rawData, true);
            $rawData = is_array($decoded) ? $decoded : [];
        }
        if (! is_array($rawData)) {
            $rawData = [];
        }
        $data = $rawData;
        $laravelType = $notification->type; // e.g. "App\Notifications\NewOrderNotification"

        // Resolve notification_type from data['type'] or infer from class name
        $typeRaw = $data['type'] ?? null;
        $type = is_string($typeRaw) && $typeRaw !== ''
            ? $typeRaw
            : $this->inferTypeFromClass($laravelType);

        // TOUJOURS reconstruire title et body propres à partir des données structurées
        // Ne JAMAIS utiliser les champs bruts title/message qui contiennent des références hex
        $title = $this->buildTitle($type, $data);
        $body = $this->buildBody($type, $data);

        // Merge normalized fields into data
        $normalizedData = array_merge($data, [
            'type' => $type,
            'title' => $title,
            'body' => $body,
        ]);

        return [
            'id' => $notification->id,
            'type' => $laravelType,
            'notifiable_type' => $notification->notifiable_type,
            'notifiable_id' => $notification->notifiable_id,
            'data' => $normalizedData,
            'read_at' => $notification->read_at?->toIso8601String(),
            'created_at' => $notification->created_at?->toIso8601String(),
            'updated_at' => $notification->updated_at?->toIso8601String(),
        ];
    }

    /**
     * Infer a short notification type from the full Laravel class name.
     */
    private function inferTypeFromClass(string $className): string
    {
        return match (class_basename($className)) {
            'NewOrderNotification' => 'new_order',
            'NewOrderReceivedNotification' => 'new_order_received',
            'OrderStatusNotification' => 'order_status',
            'DeliveryAssignedNotification' => 'delivery_assigned',
            'CourierArrivedNotification' => 'courier_arrived',
            'CourierArrivedAtClientNotification' => 'courier_arrived_at_client',
            'DeliveryTimeoutCancelledNotification' => 'delivery_timeout_cancelled',
            'OrderDeliveredToPharmacyNotification' => 'order_delivered',
            'PrescriptionStatusNotification' => 'prescription_status',
            'NewPrescriptionNotification' => 'new_prescription',
            'PayoutCompletedNotification' => 'payout_completed',
            'NewChatMessageNotification' => 'chat_message',
            'KycStatusNotification' => 'kyc_status_update',
            default => 'general',
        };
    }

    /**
     * Build a human-readable title from notification type and data.
     */
    /**
     * Raccourcit une référence de commande pour l'affichage.
     * "DR-69B6124EE359B" → "#...E359B"
     */
    private function shortRef(string $ref): string
    {
        if (empty($ref)) return '';
        if (strlen($ref) <= 8) return "#{$ref}";
        return '#...' . substr($ref, -5);
    }

    private function buildTitle(string $type, array $data): string
    {
        $customerName = $data['customer_name'] ?? $data['order_data']['customer_name'] ?? '';
        $itemsCount = $data['items_count'] ?? $data['order_data']['items_count'] ?? '';

        return match ($type) {
            'new_order', 'new_order_received' => $customerName
                ? "🛒 Commande de {$customerName}"
                : ($itemsCount ? "🛒 Nouvelle commande · {$itemsCount} article(s)" : '🛒 Nouvelle commande reçue'),
            'order_status' => $this->orderStatusTitle($data['status'] ?? ''),
            'delivery_assigned' => '🚴 Livreur assigné',
            'courier_arrived' => '📍 Livreur arrivé à la pharmacie',
            'courier_arrived_at_client' => '📍 Livreur arrivé chez le client',
            'delivery_timeout_cancelled' => '⏰ Livraison annulée (délai dépassé)',
            'order_delivered' => $customerName
                ? "🎉 Commande livrée à {$customerName}"
                : '🎉 Commande livrée avec succès',
            'prescription_status' => '📋 Mise à jour ordonnance',
            'new_prescription' => '📋 Nouvelle ordonnance reçue',
            'payout_completed' => isset($data['amount'])
                ? "💰 Paiement reçu · {$data['amount']} F CFA"
                : '💰 Paiement reçu',
            'chat_message' => isset($data['sender_name'])
                ? "💬 Message de {$data['sender_name']}"
                : '💬 Nouveau message',
            'kyc_status_update' => '🔐 Mise à jour vérification KYC',
            default => 'Notification',
        };
    }

    /**
     * Build a human-readable body from notification type and data.
     */
    private function buildBody(string $type, array $data): string
    {
        $ref = $data['order_reference'] ?? '';
        $shortRef = $this->shortRef($ref);

        return match ($type) {
            'new_order', 'new_order_received' => $this->orderBody($data),
            'order_status' => $this->orderStatusBody($data['status'] ?? '', $shortRef),
            'delivery_assigned' => $this->deliveryAssignedBody($data),
            'order_delivered' => $this->orderDeliveredBody($data),
            'courier_arrived' => $shortRef ? "Le livreur est arrivé pour la commande {$shortRef}" : 'Le livreur est arrivé',
            'courier_arrived_at_client' => $shortRef ? "Le livreur est arrivé chez le client {$shortRef}" : 'Le livreur est arrivé à destination',
            'delivery_timeout_cancelled' => $shortRef ? "La commande {$shortRef} a été annulée (délai dépassé)" : 'La commande a été annulée',
            'payout_completed' => isset($data['amount']) ? "Montant versé: {$data['amount']} F CFA" : 'Votre décaissement a été effectué',
            'chat_message' => $data['message_preview'] ?? 'Vous avez reçu un nouveau message',
            'new_prescription' => isset($data['customer_name']) ? "Ordonnance reçue de {$data['customer_name']}" : 'Une nouvelle ordonnance a été soumise',
            'low_stock' => isset($data['product_name']) ? "{$data['product_name']} — stock bas" : 'Un produit a atteint le seuil minimum',
            'kyc_status_update' => match ($data['status'] ?? '') {
                'approved' => 'Votre vérification KYC a été approuvée ✅',
                'rejected' => 'Votre vérification KYC a été refusée. Veuillez resoumettre.',
                default => 'Le statut de votre vérification a été mis à jour',
            },
            default => $data['body'] ?? $data['message'] ?? '',
        };
    }

    private function orderStatusTitle(string $status): string
    {
        return match ($status) {
            'confirmed' => '✅ Commande confirmée',
            'preparing' => '💊 Préparation en cours',
            'ready', 'ready_for_pickup' => '📦 Commande prête',
            'assigned' => '🚴 Livreur assigné',
            'on_the_way', 'picked_up' => '🚀 En livraison',
            'delivered' => '🎉 Commande livrée',
            'cancelled' => '❌ Commande annulée',
            default => '📱 Mise à jour commande',
        };
    }

    private function orderBody(array $data): string
    {
        $nested = $data['order_data'] ?? [];
        $parts = [];

        // Client (flat ou nested)
        $customerName = $data['customer_name'] ?? $nested['customer_name'] ?? '';
        if ($customerName) $parts[] = "Client: {$customerName}";

        // Articles
        $itemsCount = $data['items_count'] ?? $nested['items_count'] ?? '';
        if ($itemsCount) $parts[] = "{$itemsCount} article(s)";

        // Montant
        $totalAmount = $data['total_amount'] ?? $nested['total_amount'] ?? '';
        if ($totalAmount) {
            $currency = $data['currency'] ?? $nested['currency'] ?? 'FCFA';
            $parts[] = "{$totalAmount} {$currency}";
        }

        // Mode de paiement
        $paymentMode = $data['payment_mode'] ?? $nested['payment_mode'] ?? '';
        if ($paymentMode) {
            $label = match ($paymentMode) {
                'cash' => 'Espèces',
                'mobile_money' => 'Mobile Money',
                'card' => 'Carte',
                'wave' => 'Wave',
                'orange' => 'Orange Money',
                default => $paymentMode,
            };
            $parts[] = $label;
        }

        // Réf courte
        $ref = $data['order_reference'] ?? '';
        if ($ref) $parts[] = 'Réf: ' . $this->shortRef($ref);

        return !empty($parts) ? implode(' · ', $parts) : 'Nouvelle commande reçue';
    }

    private function orderStatusBody(string $status, string $shortRef = ''): string
    {
        $refStr = $shortRef ? " {$shortRef}" : '';
        return match ($status) {
            'confirmed' => "La commande{$refStr} a été confirmée.",
            'preparing' => "La commande{$refStr} est en cours de préparation.",
            'ready', 'ready_for_pickup' => "La commande{$refStr} est prête pour le ramassage.",
            'assigned' => "Un livreur a été assigné à la commande{$refStr}.",
            'on_the_way', 'picked_up' => "La commande{$refStr} est en cours de livraison.",
            'delivered' => "La commande{$refStr} a été livrée avec succès. 🎉",
            'cancelled' => "La commande{$refStr} a été annulée.",
            default => "Mise à jour de la commande{$refStr}.",
        };
    }

    private function deliveryAssignedBody(array $data): string
    {
        $parts = [];
        $courierName = $data['courier_name'] ?? $data['delivery_data']['courier_name'] ?? '';
        if ($courierName) $parts[] = "Livreur: {$courierName}";
        $pickupAddr = $data['delivery_data']['pickup_address'] ?? '';
        if ($pickupAddr) $parts[] = $pickupAddr;
        $ref = $data['order_reference'] ?? '';
        if ($ref) $parts[] = 'Réf: ' . $this->shortRef($ref);
        return !empty($parts) ? implode(' · ', $parts) : 'Un livreur a été assigné à votre commande';
    }

    private function orderDeliveredBody(array $data): string
    {
        $parts = [];
        $customer = $data['customer_name'] ?? '';
        if ($customer) $parts[] = "Client: {$customer}";
        $ref = $data['order_reference'] ?? '';
        if ($ref) $parts[] = 'Réf: ' . $this->shortRef($ref);
        return !empty($parts) ? implode(' · ', $parts) : 'La commande a été livrée avec succès';
    }

    /**
     * Get notification preferences for the authenticated user
     */
    public function getPreferences(): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();
        $defaults = [
            'order_updates' => true,
            'promotions' => true,
            'prescriptions' => true,
            'delivery_alerts' => true,
        ];

        return response()->json([
            'success' => true,
            'data' => array_merge($defaults, $user->notification_preferences ?? []),
        ]);
    }

    /**
     * Update notification preferences for the authenticated user
     */
    public function updatePreferences(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'order_updates' => 'sometimes|boolean',
            'promotions' => 'sometimes|boolean',
            'prescriptions' => 'sometimes|boolean',
            'delivery_alerts' => 'sometimes|boolean',
        ]);

        /** @var \App\Models\User $user */
        $user = Auth::user();
        $current = $user->notification_preferences ?? [];
        $user->notification_preferences = array_merge($current, $validated);
        $user->save();

        return response()->json([
            'success' => true,
            'data' => $user->notification_preferences,
            'message' => 'Préférences mises à jour',
        ]);
    }
}
