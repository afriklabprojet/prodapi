<?php

namespace App\Http\Controllers\Api\Courier;

use App\Http\Controllers\Controller;
use App\Models\SupportTicket;
use App\Models\SupportMessage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SupportController extends Controller
{
    public function reportProblem(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'category' => 'required|in:delivery,payment,app_bug,account,other',
            'subject' => 'required|string|max:255',
            'description' => 'required|string|max:2000',
        ]);

        $user = $request->user();

        $ticket = SupportTicket::create([
            'user_id' => $user->id,
            'category' => $validated['category'],
            'subject' => $validated['subject'],
            'description' => $validated['description'],
            'priority' => 'medium',
            'status' => 'open',
        ]);

        SupportMessage::create([
            'support_ticket_id' => $ticket->id,
            'user_id' => $user->id,
            'message' => $validated['description'],
            'is_from_support' => false,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Problème signalé avec succès',
            'data' => [
                'ticket_id' => $ticket->id,
                'reference' => $ticket->reference,
            ],
        ], 201);
    }
}
