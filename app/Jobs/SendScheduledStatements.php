<?php

namespace App\Jobs;

use App\Mail\PharmacyStatementMail;
use App\Models\PharmacyStatementPreference;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class SendScheduledStatements implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * Le nombre de tentatives
     */
    public $tries = 3;

    /**
     * Le délai avant retry (secondes)
     */
    public $backoff = 60;

    /**
     * Le timeout du job (5 minutes pour traiter de nombreux relevés)
     */
    public $timeout = 300;

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        Log::info('SendScheduledStatements: Début de la vérification des relevés programmés');

        $preferences = PharmacyStatementPreference::with(['pharmacy.wallet', 'pharmacy.user'])
            ->dueForSending()
            ->get();

        Log::info("SendScheduledStatements: {$preferences->count()} relevés à envoyer");

        foreach ($preferences as $preference) {
            try {
                $this->sendStatement($preference);
            } catch (\Exception $e) {
                Log::error("SendScheduledStatements: Erreur pour pharmacie {$preference->pharmacy_id}", [
                    'error' => $e->getMessage(),
                ]);
            }
        }

        Log::info('SendScheduledStatements: Terminé');
    }

    /**
     * Envoyer le relevé pour une préférence donnée
     */
    protected function sendStatement(PharmacyStatementPreference $preference): void
    {
        $pharmacy = $preference->pharmacy;
        $email = $preference->effective_email;

        if (!$email) {
            Log::warning("SendScheduledStatements: Pas d'email pour pharmacie {$pharmacy->id}");
            return;
        }

        // Récupérer la période
        $period = $preference->getStatementPeriod();

        // Récupérer les transactions de la période
        $wallet = $pharmacy->wallet;
        
        if (!$wallet) {
            Log::warning("SendScheduledStatements: Pas de wallet pour pharmacie {$pharmacy->id}");
            return;
        }

        $transactions = $wallet->transactions()
            ->whereBetween('created_at', [$period['start'], $period['end']])
            ->orderBy('created_at', 'desc')
            ->get();

        // Calculer les totaux
        $totalCredits = $transactions->where('type', 'credit')->sum('amount');
        $totalDebits = $transactions->where('type', 'debit')->sum('amount');

        $statementData = [
            'pharmacy' => $pharmacy,
            'transactions' => $transactions,
            'period_start' => $period['start'],
            'period_end' => $period['end'],
            'total_credits' => $totalCredits,
            'total_debits' => $totalDebits,
            'balance' => $wallet->balance,
            'format' => $preference->format,
            'frequency_label' => $preference->frequency_label,
        ];

        // Envoyer l'email avec le relevé
        Mail::to($email)->send(new PharmacyStatementMail($statementData));

        // Programmer le prochain envoi
        $preference->scheduleNextSend();

        Log::info("SendScheduledStatements: Relevé envoyé à {$email} pour pharmacie {$pharmacy->name}");
    }
}
