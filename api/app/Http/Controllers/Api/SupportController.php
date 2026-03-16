<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SupportTicket;
use App\Models\SupportMessage;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class SupportController extends Controller
{
    /**
     * Liste des tickets de l'utilisateur connecté
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        
        $tickets = SupportTicket::forUser($user->id)
            ->with(['latestMessage', 'messages' => function ($query) {
                $query->latest()->limit(1);
            }])
            ->withCount(['messages', 'messages as unread_count' => function ($query) use ($user) {
                $query->where('is_from_support', true)->whereNull('read_at');
            }])
            ->orderBy('updated_at', 'desc')
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $tickets,
        ]);
    }

    /**
     * Créer un nouveau ticket
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'subject' => 'required|string|max:255',
            'description' => 'required|string|max:2000',
            'category' => ['required', Rule::in(['order', 'delivery', 'payment', 'account', 'app_bug', 'other'])],
            'priority' => ['nullable', Rule::in(['low', 'medium', 'high'])],
        ]);

        $user = $request->user();

        $ticket = SupportTicket::create([
            'user_id' => $user->id,
            'subject' => $validated['subject'],
            'description' => $validated['description'],
            'category' => $validated['category'],
            'priority' => $validated['priority'] ?? 'medium',
            'status' => 'open',
        ]);

        // Créer le premier message automatiquement
        SupportMessage::create([
            'support_ticket_id' => $ticket->id,
            'user_id' => $user->id,
            'message' => $validated['description'],
            'is_from_support' => false,
        ]);

        $ticket->load('messages');

        return response()->json([
            'success' => true,
            'message' => 'Ticket créé avec succès',
            'data' => $ticket,
        ], 201);
    }

    /**
     * Afficher un ticket spécifique avec ses messages
     */
    public function show(Request $request, SupportTicket $ticket): JsonResponse
    {
        $user = $request->user();

        // Vérifier que le ticket appartient à l'utilisateur
        if ($ticket->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Ticket non trouvé',
            ], 404);
        }

        // Marquer les messages du support comme lus
        $ticket->messages()
            ->where('is_from_support', true)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        $ticket->load(['messages.user:id,name', 'user:id,name,email']);

        return response()->json([
            'success' => true,
            'data' => $ticket,
        ]);
    }

    /**
     * Envoyer un message dans un ticket
     */
    public function sendMessage(Request $request, SupportTicket $ticket): JsonResponse
    {
        $user = $request->user();

        // Vérifier que le ticket appartient à l'utilisateur
        if ($ticket->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Ticket non trouvé',
            ], 404);
        }

        // Vérifier que le ticket n'est pas fermé
        if ($ticket->status === 'closed') {
            return response()->json([
                'success' => false,
                'message' => 'Ce ticket est fermé. Veuillez créer un nouveau ticket.',
            ], 400);
        }

        $validated = $request->validate([
            'message' => 'required|string|max:2000',
            'attachment' => 'nullable|file|max:5120|mimes:jpg,jpeg,png,pdf,doc,docx',
        ]);

        $attachmentPath = null;
        if ($request->hasFile('attachment')) {
            $attachmentPath = $request->file('attachment')->store('support/attachments', 'private');
        }

        $message = SupportMessage::create([
            'support_ticket_id' => $ticket->id,
            'user_id' => $user->id,
            'message' => $validated['message'],
            'attachment' => $attachmentPath,
            'is_from_support' => false,
        ]);

        // Si le ticket était résolu, le réouvrir
        if ($ticket->status === 'resolved') {
            $ticket->reopen();
        }

        // Mettre à jour le timestamp du ticket
        $ticket->touch();

        $message->load('user:id,name');

        return response()->json([
            'success' => true,
            'message' => 'Message envoyé',
            'data' => $message,
        ], 201);
    }

    /**
     * Marquer un ticket comme résolu
     */
    public function resolve(Request $request, SupportTicket $ticket): JsonResponse
    {
        $user = $request->user();

        // Vérifier que le ticket appartient à l'utilisateur
        if ($ticket->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Ticket non trouvé',
            ], 404);
        }

        $ticket->markAsResolved();

        return response()->json([
            'success' => true,
            'message' => 'Ticket marqué comme résolu',
            'data' => $ticket,
        ]);
    }

    /**
     * Fermer définitivement un ticket
     */
    public function close(Request $request, SupportTicket $ticket): JsonResponse
    {
        $user = $request->user();

        // Vérifier que le ticket appartient à l'utilisateur
        if ($ticket->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Ticket non trouvé',
            ], 404);
        }

        $ticket->update(['status' => 'closed']);

        return response()->json([
            'success' => true,
            'message' => 'Ticket fermé',
            'data' => $ticket,
        ]);
    }

    /**
     * Statistiques des tickets (pour le profil)
     */
    public function stats(Request $request): JsonResponse
    {
        $user = $request->user();

        $stats = [
            'total' => SupportTicket::forUser($user->id)->count(),
            'open' => SupportTicket::forUser($user->id)->open()->count(),
            'resolved' => SupportTicket::forUser($user->id)->where('status', 'resolved')->count(),
            'closed' => SupportTicket::forUser($user->id)->where('status', 'closed')->count(),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats,
        ]);
    }
}
