<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

/**
 * Handle Infobip WhatsApp delivery reports & incoming messages.
 *
 * Configure this webhook URL in your Infobip portal:
 * POST /api/webhooks/whatsapp
 */
class WhatsAppWebhookController extends Controller
{
    /**
     * Handle delivery report from Infobip.
     *
     * Infobip sends delivery reports to your notifyUrl or configured webhook.
     * Statuses: PENDING, DELIVERED, SEEN, FAILED, REJECTED, EXPIRED
     */
    public function deliveryReport(Request $request)
    {
        $results = $request->input('results', []);

        foreach ($results as $result) {
            $messageId = $result['messageId'] ?? null;
            $status = $result['status']['groupName'] ?? 'UNKNOWN';
            $to = $result['to'] ?? null;
            $sentAt = $result['sentAt'] ?? null;
            $doneAt = $result['doneAt'] ?? null;

            Log::info('WhatsApp delivery report', [
                'messageId' => $messageId,
                'to' => $to,
                'status' => $status,
                'sentAt' => $sentAt,
                'doneAt' => $doneAt,
                'error' => $result['error'] ?? null,
            ]);

            // Handle specific statuses
            match ($status) {
                'DELIVERED' => $this->handleDelivered($messageId, $to),
                'SEEN' => $this->handleSeen($messageId, $to),
                'FAILED', 'REJECTED', 'EXPIRED' => $this->handleFailed($messageId, $to, $status, $result),
                default => null,
            };
        }

        return response()->json(['status' => 'ok']);
    }

    /**
     * Handle incoming WhatsApp messages from users.
     *
     * This webhook receives messages when a customer sends a WhatsApp
     * message to your business number (opens the 24h messaging window).
     */
    public function incomingMessage(Request $request)
    {
        $results = $request->input('results', []);

        foreach ($results as $message) {
            $from = $message['from'] ?? null;
            $to = $message['to'] ?? null;
            $receivedAt = $message['receivedAt'] ?? null;
            $messageId = $message['messageId'] ?? null;
            $messageType = $message['message']['type'] ?? 'UNKNOWN';
            $text = $message['message']['text'] ?? null;

            Log::info('WhatsApp incoming message', [
                'from' => $from,
                'to' => $to,
                'messageId' => $messageId,
                'type' => $messageType,
                'text' => $text,
                'receivedAt' => $receivedAt,
            ]);

            // Auto-reply et routage vers le support
            if ($from && $text) {
                $this->handleIncomingText($from, $text);
            }
        }

        return response()->json(['status' => 'ok']);
    }

    /**
     * Handle delivered status
     */
    protected function handleDelivered(string $messageId, string $to): void
    {
        Log::info("WhatsApp message delivered", [
            'messageId' => $messageId,
            'to' => $to,
        ]);
    }

    /**
     * Handle seen status
     */
    protected function handleSeen(string $messageId, string $to): void
    {
        Log::info("WhatsApp message seen", [
            'messageId' => $messageId,
            'to' => $to,
        ]);
    }

    /**
     * Handle failed/rejected/expired status
     */
    protected function handleFailed(string $messageId, string $to, string $status, array $result): void
    {
        Log::warning("WhatsApp message {$status}", [
            'messageId' => $messageId,
            'to' => $to,
            'status' => $status,
            'error' => $result['error'] ?? null,
        ]);
    }

    /**
     * Handle incoming text message — auto-reply or route to support.
     */
    protected function handleIncomingText(string $from, string $text): void
    {
        $textUpper = strtoupper(trim($text));

        // Mot-clé: COMMANDE / ORDER → infos dernière commande
        if (in_array($textUpper, ['COMMANDE', 'ORDER', 'SUIVI'])) {
            $user = User::where('phone', $from)->first();
            if ($user) {
                $lastOrder = $user->orders()->latest()->first();
                if ($lastOrder) {
                    $statusLabels = [
                        'pending' => 'En attente',
                        'confirmed' => 'Confirmée',
                        'preparing' => 'En préparation',
                        'ready' => 'Prête',
                        'delivering' => 'En livraison',
                        'delivered' => 'Livrée',
                        'cancelled' => 'Annulée',
                    ];
                    $statusLabel = $statusLabels[$lastOrder->status] ?? $lastOrder->status;
                    Log::info("WhatsApp auto-reply: order status", ['from' => $from, 'orderId' => $lastOrder->id]);
                    // Note: WhatsApp reply would be sent via Infobip WhatsApp API
                    // For now, log the intended reply
                    Cache::put("wa_reply:{$from}", "Votre commande #{$lastOrder->id} est: {$statusLabel}. Total: {$lastOrder->total} FCFA.", now()->addMinutes(5));
                }
            }
            return;
        }

        // Mot-clé: STOP → opt-out
        if (in_array($textUpper, ['STOP', 'ARRET', 'DESABONNER'])) {
            Cache::put("wa_optout:{$from}", true, now()->addYears(5));
            Log::info("WhatsApp opt-out", ['from' => $from]);
            return;
        }

        // Mot-clé: AIDE / HELP → message d'aide
        if (in_array($textUpper, ['AIDE', 'HELP', 'BONJOUR', 'HELLO', 'SALUT'])) {
            Log::info("WhatsApp help request", ['from' => $from]);
            Cache::put("wa_reply:{$from}", "Bonjour ! 👋 DR-PHARMA à votre service.\n\n📦 Envoyez COMMANDE pour le suivi.\n📞 Support: +225 07 00 00 00 00\n📧 support@drlpharma.com\n🌐 https://drlpharma.com", now()->addMinutes(5));
            return;
        }

        // Message non reconnu → notifier les admins pour traitement manuel
        $admins = User::where('role', 'admin')->get();
        foreach ($admins as $admin) {
            $admin->notify(
                \Filament\Notifications\Notification::make()
                    ->title('Message WhatsApp reçu')
                    ->body("De: {$from}\nMessage: " . \Illuminate\Support\Str::limit($text, 100))
                    ->info()
                    ->toDatabase()
            );
        }
    }
}
