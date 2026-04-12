<?php

namespace App\Jobs;

use App\Mail\AdminAlertMail;
use App\Models\SupportTicket;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

/**
 * Gère l'escalade et la fermeture automatique des tickets support.
 *
 * - Tickets ouverts >5 jours → escalade (priority high) + alerte admin
 * - Tickets ouverts >30 jours sans activité → fermeture automatique
 *
 * Exécuté tous les jours à 8h30.
 */
class SupportTicketEscalationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public int $timeout = 120;

    private const ESCALATION_DAYS = 5;
    private const AUTO_CLOSE_DAYS = 30;

    public function middleware(): array
    {
        return [new WithoutOverlapping('support-ticket-escalation')];
    }

    public function handle(): void
    {
        $stats = [
            'escalated' => 0,
            'auto_closed' => 0,
        ];

        // 1. Escalade : tickets ouverts > 5 jours, pas encore en haute priorité
        $ticketsToEscalate = SupportTicket::where('status', 'open')
            ->where('priority', '!=', 'high')
            ->where('created_at', '<', now()->subDays(self::ESCALATION_DAYS))
            ->limit(50)
            ->get();

        $escalatedTickets = [];

        foreach ($ticketsToEscalate as $ticket) {
            $ticket->update(['priority' => 'high']);
            $stats['escalated']++;

            $escalatedTickets[] = [
                'reference' => $ticket->reference,
                'subject' => $ticket->subject,
                'category' => $ticket->category,
                'age_days' => now()->diffInDays($ticket->created_at),
            ];
        }

        // Notifier admin des escalades
        if (count($escalatedTickets) > 0) {
            try {
                Mail::to(config('mail.admin_address', 'admin@drlpharma.com'))
                    ->send(new AdminAlertMail('ticket_escalation', [
                        'count' => count($escalatedTickets),
                        'tickets' => array_slice($escalatedTickets, 0, 20),
                    ]));
            } catch (\Throwable $e) {
                Log::debug('SupportTicketEscalation: email failed', [
                    'error' => $e->getMessage(),
                ]);
            }
        }

        // 2. Fermeture auto : tickets ouverts > 30 jours sans message récent
        $ticketsToClose = SupportTicket::where('status', 'open')
            ->where('created_at', '<', now()->subDays(self::AUTO_CLOSE_DAYS))
            ->whereDoesntHave('messages', function ($q) {
                $q->where('created_at', '>', now()->subDays(self::AUTO_CLOSE_DAYS));
            })
            ->limit(50)
            ->get();

        foreach ($ticketsToClose as $ticket) {
            $ticket->update([
                'status' => 'resolved',
                'resolved_at' => now(),
            ]);

            // Ajouter un message de fermeture automatique
            $ticket->messages()->create([
                'user_id' => null,
                'message' => "Ce ticket a été fermé automatiquement après " . self::AUTO_CLOSE_DAYS .
                    " jours sans activité. N'hésitez pas à en ouvrir un nouveau si le problème persiste.",
            ]);

            $stats['auto_closed']++;
        }

        if (array_sum($stats) > 0) {
            Log::info('SupportTicketEscalation: complete', $stats);
        }
    }

    public function failed(\Throwable $exception): void
    {
        Log::error('SupportTicketEscalationJob failed', [
            'error' => $exception->getMessage(),
        ]);
    }
}
