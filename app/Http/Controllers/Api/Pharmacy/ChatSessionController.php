<?php

namespace App\Http\Controllers\Api\Pharmacy;

use App\Events\MessageRead;
use App\Events\NewChatMessage;
use App\Http\Controllers\Controller;
use App\Models\ChatSession;
use App\Models\ChatSessionMessage;
use App\Services\ChatService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Controller pour les sessions de chat persistantes pharmacie ↔ client.
 *
 * Endpoints :
 * - GET    /pharmacy/chat-sessions                → liste des sessions
 * - POST   /pharmacy/chat-sessions                → créer/retrouver une session
 * - GET    /pharmacy/chat-sessions/{session}/messages   → messages (pagination)
 * - POST   /pharmacy/chat-sessions/{session}/messages   → envoyer un message
 * - POST   /pharmacy/chat-sessions/{session}/read       → marquer comme lus
 * - GET    /pharmacy/chat-sessions/{session}/unread     → compteur non-lus
 * - PATCH  /pharmacy/chat-sessions/{session}/status     → fermer/archiver
 */
class ChatSessionController extends Controller
{
    public function __construct(
        private readonly ChatService $chatService,
    ) {}

    // ── Sessions ───────────────────────────────────────────────────────────

    /**
     * Liste les sessions de la pharmacie authentifiée.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $this->chatService->resolveCurrentUser($request->user());
        $pharmacyId = $user['pharmacy_id'] ?? $user['id'];

        $sessions = ChatSession::forPharmacy($pharmacyId)
            ->with(['messages' => fn ($q) => $q->latest()->limit(1)])
            ->orderByDesc('last_message_at')
            ->paginate($request->integer('per_page', 20));

        return response()->json([
            'success' => true,
            'data'    => $sessions,
        ]);
    }

    /**
     * Retrouver ou créer une session pour un couple (pharmacie, client).
     */
    public function getOrCreate(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'client_id'   => 'required|integer|min:1',
            'client_type' => 'sometimes|in:customer,pharmacy_user',
        ]);

        $user       = $this->chatService->resolveCurrentUser($request->user());
        $pharmacyId = $user['pharmacy_id'] ?? $user['id'];
        $clientType = $validated['client_type'] ?? 'customer';

        $session = ChatSession::firstOrCreate(
            [
                'pharmacy_id' => $pharmacyId,
                'client_type' => $clientType,
                'client_id'   => $validated['client_id'],
            ],
            ['status' => 'active']
        );

        return response()->json([
            'success' => true,
            'data'    => $session,
            'created' => $session->wasRecentlyCreated,
        ], $session->wasRecentlyCreated ? 201 : 200);
    }

    // ── Messages ───────────────────────────────────────────────────────────

    /**
     * Récupérer les messages d'une session (pagination curseur).
     */
    public function getMessages(Request $request, ChatSession $chatSession): JsonResponse
    {
        $user = $this->chatService->resolveCurrentUser($request->user());
        $this->assertParticipant($chatSession, $user);

        $beforeId = $request->integer('before', 0) ?: null;
        $limit    = min($request->integer('limit', 30), 100);

        $query = $chatSession->messages()->latest('id');

        if ($beforeId) {
            $query->where('id', '<', $beforeId);
        }

        $messages = $query->limit($limit)->get()->reverse()->values();

        return response()->json([
            'success'  => true,
            'data'     => $messages,
            'has_more' => $messages->count() === $limit,
        ]);
    }

    /**
     * Envoyer un message dans une session.
     */
    public function sendMessage(Request $request, ChatSession $chatSession): JsonResponse
    {
        $validated = $request->validate([
            'message' => 'required|string|max:2000',
            'type'    => 'sometimes|in:text,image,file,location',
            'metadata' => 'sometimes|array',
        ]);

        $user = $this->chatService->resolveCurrentUser($request->user());
        $this->assertParticipant($chatSession, $user);

        if (!$chatSession->isActive()) {
            return response()->json([
                'success' => false,
                'message' => 'Cette conversation est fermée.',
            ], 403);
        }

        $message = ChatSessionMessage::create([
            'session_id'  => $chatSession->id,
            'sender_type' => $user['type'],
            'sender_id'   => $user['id'],
            'message'     => $validated['message'],
            'type'        => $validated['type'] ?? 'text',
            'metadata'    => $validated['metadata'] ?? null,
        ]);

        // Mettre à jour le timestamp de la session
        $chatSession->update(['last_message_at' => now()]);

        // Broadcast en temps réel
        broadcast(new NewChatMessage($message, $user))->toOthers();

        return response()->json([
            'success' => true,
            'data'    => $message,
            'message' => 'Message envoyé.',
        ], 201);
    }

    /**
     * Marquer les messages comme lus jusqu'à un certain ID.
     */
    public function markAsRead(Request $request, ChatSession $chatSession): JsonResponse
    {
        $validated = $request->validate([
            // message_id optionnel : si absent, marque tous les messages comme lus
            'message_id' => 'sometimes|nullable|integer|min:1',
        ]);

        $user = $this->chatService->resolveCurrentUser($request->user());
        $this->assertParticipant($chatSession, $user);

        $query = ChatSessionMessage::where('session_id', $chatSession->id)
            ->where('sender_type', '!=', $user['type'])
            ->whereNull('read_at');

        // Si message_id fourni, marquer seulement jusqu'à cet ID
        if (!empty($validated['message_id'])) {
            $query->where('id', '<=', (int) $validated['message_id']);
        }

        $count = $query->update(['read_at' => now()]);

        // Broadcast accusé de réception (double-check ✔✔)
        if ($count > 0) {
            broadcast(new MessageRead(
                messageId: $validated['message_id'],
                deliveryId: null,
                sessionId: $chatSession->id,
                reader: $user,
                readAt: now()->toIso8601String(),
            ))->toOthers();
        }

        return response()->json([
            'success'      => true,
            'marked_count' => $count,
        ]);
    }

    /**
     * Nombre de messages non lus dans cette session.
     */
    public function unreadCount(ChatSession $chatSession, Request $request): JsonResponse
    {
        $user = $this->chatService->resolveCurrentUser($request->user());
        $this->assertParticipant($chatSession, $user);

        $count = ChatSessionMessage::where('session_id', $chatSession->id)
            ->where('sender_type', '!=', $user['type'])
            ->whereNull('read_at')
            ->count();

        return response()->json([
            'success'      => true,
            'unread_count' => $count,
        ]);
    }

    /**
     * Changer le statut d'une session (closed, archived, active).
     */
    public function updateStatus(Request $request, ChatSession $chatSession): JsonResponse
    {
        $validated = $request->validate([
            'status' => 'required|in:active,closed,archived',
        ]);

        $user = $this->chatService->resolveCurrentUser($request->user());
        $this->assertParticipant($chatSession, $user);

        $chatSession->update(['status' => $validated['status']]);

        return response()->json([
            'success' => true,
            'data'    => $chatSession,
        ]);
    }

    // ── Guards ─────────────────────────────────────────────────────────────

    private function assertParticipant(ChatSession $session, array $user): void
    {
        if (!$session->isParticipant($user)) {
            abort(403, 'Accès refusé à cette session de chat.');
        }
    }
}
