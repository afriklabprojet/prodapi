<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

/*
|--------------------------------------------------------------------------
| Console Routes / Scheduler
|--------------------------------------------------------------------------
*/

// Vérifier les paiements en attente toutes les 2 minutes
Schedule::job(new \App\Jobs\CheckPendingPaymentsJob)->everyTwoMinutes()
    ->withoutOverlapping()
    ->onOneServer();

// Expirer les paiements wallet abandonnés après 10 minutes (toutes les 2 min)
// Wave/JEKO peuvent mettre 1-3 min pour que l'utilisateur confirme + 10-60s de webhook
Schedule::call(function () {
    $expired = \App\Models\JekoPayment::whereIn('status', ['pending', 'processing'])
        ->where('payable_type', 'App\\Models\\Wallet')
        ->where('created_at', '<', now()->subMinutes(10))
        ->update([
            'status' => 'expired',
            'error_message' => 'Auto-expired: session abandonnée (>10min)',
            'completed_at' => now(),
        ]);
    if ($expired > 0) {
        \Illuminate\Support\Facades\Log::info("Scheduler: {$expired} rechargement(s) wallet expirés (>10min)");
    }
})->everyTwoMinutes()->name('expire-stale-wallet-payments')->withoutOverlapping()->onOneServer();

// Annuler les commandes non payées après 30 minutes (toutes les 2 min)
// Balayage fréquent pour nettoyer rapidement les commandes abandonnées (non terminées)
Schedule::job(new \App\Jobs\CancelStaleOrdersJob)->everyTwoMinutes()
    ->withoutOverlapping()
    ->onOneServer();

// Vérifier les timeouts livraisons en attente (toutes les minutes)
Schedule::job(new \App\Jobs\CheckWaitingDeliveryTimeouts)->everyMinute()
    ->withoutOverlapping()
    ->onOneServer();

// Envoyer les relevés de compte programmés (quotidien 8h)
Schedule::job(new \App\Jobs\SendScheduledStatements)->dailyAt('08:00')
    ->withoutOverlapping()
    ->onOneServer();

// Nettoyer les paiements expirés (toutes les heures)
Schedule::call(function () {
    $expired = \App\Models\JekoPayment::whereIn('status', ['pending', 'processing'])
        ->where('created_at', '<', now()->subHours(4))
        ->update([
            'status' => 'expired',
            'error_message' => 'Auto-expired: timeout 4h (scheduler)',
            'completed_at' => now(),
        ]);

    if ($expired > 0) {
        \Illuminate\Support\Facades\Log::info("Scheduler: {$expired} paiements expirés nettoyés");
    }
})->hourly()->name('cleanup-expired-payments')->onOneServer();

// Nettoyer les tokens Sanctum expirés (quotidien 3h)
Schedule::command('sanctum:prune-expired --hours=48')->dailyAt('03:00')->onOneServer();

// Nettoyer le cache des webhook logs > 30 jours
Schedule::call(function () {
    if (\Illuminate\Support\Facades\Schema::hasTable('webhook_logs')) {
        \App\Models\WebhookLog::where('created_at', '<', now()->subDays(30))->delete();
    }
})->weekly()->name('cleanup-old-webhook-logs')->onOneServer();

// ============================================
// JOBS DE MAINTENANCE & MONITORING
// ============================================

// Audit quotidien des soldes wallets (2h du matin)
Schedule::job(new \App\Jobs\ReconcileWalletBalancesJob)->dailyAt('02:00')
    ->withoutOverlapping()
    ->onOneServer();

// Détecter les livraisons bloquées (toutes les 30 min)
Schedule::job(new \App\Jobs\CheckStuckDeliveriesJob)->everyThirtyMinutes()
    ->withoutOverlapping()
    ->onOneServer();

// Commissions manquantes sur commandes livrées (4h du matin)
Schedule::job(new \App\Jobs\ProcessMissingCommissionsJob)->dailyAt('04:00')
    ->withoutOverlapping()
    ->onOneServer();

// Nettoyage données anciennes (dimanche 3h du matin)
Schedule::job(new \App\Jobs\CleanupOldDataJob)->weeklyOn(0, '03:00')
    ->withoutOverlapping()
    ->onOneServer();

// Health check livreurs (1h du matin)
Schedule::job(new \App\Jobs\CourierActivityHealthCheckJob)->dailyAt('01:00')
    ->withoutOverlapping()
    ->onOneServer();

// Rapport quotidien admin (6h du matin)
Schedule::job(new \App\Jobs\DailyAdminDigestJob)->dailyAt('06:00')
    ->withoutOverlapping()
    ->onOneServer();

// Escalade tickets support (8h30)
Schedule::job(new \App\Jobs\SupportTicketEscalationJob)->dailyAt('08:30')
    ->withoutOverlapping()
    ->onOneServer();

// Surveillance des failed_jobs (toutes les 2 heures)
Schedule::job(new \App\Jobs\MonitorFailedJobsJob)->everyTwoHours()
    ->withoutOverlapping()
    ->onOneServer();

// ============================================
// NETTOYAGE & INTÉGRITÉ DES DONNÉES
// ============================================

// Nettoyer les tokens FCM invalides des users inactifs >60 jours (hebdomadaire)
// Évite d'envoyer des notifications à des tokens expirés (économise les quotas FCM)
Schedule::call(function () {
    $cleaned = \App\Models\User::whereNotNull('fcm_token')
        ->where('updated_at', '<', now()->subDays(60))
        ->update(['fcm_token' => null]);
    if ($cleaned > 0) {
        \Illuminate\Support\Facades\Log::info("Scheduler: {$cleaned} token(s) FCM nettoyé(s) (inactifs >60j)");
    }
})->weekly()->name('cleanup-stale-fcm-tokens')->onOneServer();

// Désactiver les pharmacies de garde dont la période est terminée (toutes les 6h)
Schedule::call(function () {
    $deactivated = \App\Models\PharmacyOnCall::where('is_active', true)
        ->where('end_at', '<', now())
        ->update(['is_active' => false]);
    if ($deactivated > 0) {
        \Illuminate\Support\Facades\Log::info("Scheduler: {$deactivated} pharmacie(s) de garde désactivée(s)");
    }
})->everySixHours()->name('deactivate-expired-oncall-pharmacies')->onOneServer();

// Auto-échouer les demandes de retrait bloquées en "processing" depuis >48h
Schedule::call(function () {
    $stuck = \App\Models\WithdrawalRequest::where('status', 'processing')
        ->where('updated_at', '<', now()->subHours(48))
        ->get();

    foreach ($stuck as $request) {
        $request->update([
            'status' => 'failed',
        ]);
        \Illuminate\Support\Facades\Log::warning("Scheduler: Retrait #{$request->id} auto-échoué (stuck >48h)");
    }

    if ($stuck->count() > 0) {
        try {
            \Illuminate\Support\Facades\Mail::to(config('mail.admin_address', 'admin@drlpharma.com'))
                ->send(new \App\Mail\AdminAlertMail('withdrawal_timeout', [
                    'count' => $stuck->count(),
                    'ids' => $stuck->pluck('id')->toArray(),
                ]));
        } catch (\Throwable $e) {
            // Silently ignore email failures
        }
    }
})->everyFourHours()->name('timeout-stuck-withdrawal-requests')->withoutOverlapping()->onOneServer();

// Nettoyer la table job_batches (entrées terminées >30 jours)
Schedule::call(function () {
    $deleted = \Illuminate\Support\Facades\DB::table('job_batches')
        ->whereNotNull('finished_at')
        ->where('created_at', '<', now()->subDays(30)->timestamp)
        ->delete();
    if ($deleted > 0) {
        \Illuminate\Support\Facades\Log::info("Scheduler: {$deleted} job batch(es) nettoyé(s)");
    }
})->weekly()->name('cleanup-old-job-batches')->onOneServer();

// Auto-compléter les livraisons en attente (waiting) depuis >30 min
// Empêche les frais d'attente de grimper indéfiniment
Schedule::call(function () {
    $stuck = \App\Models\Delivery::whereNotNull('waiting_started_at')
        ->whereNull('waiting_ended_at')
        ->where('waiting_started_at', '<', now()->subMinutes(30))
        ->get();

    foreach ($stuck as $delivery) {
        $delivery->update([
            'waiting_ended_at' => now(),
        ]);
        \Illuminate\Support\Facades\Log::warning("Scheduler: Livraison #{$delivery->id} - attente auto-stoppée (>30min)");
    }
})->everyTenMinutes()->name('auto-stop-delivery-waiting-timeout')->withoutOverlapping()->onOneServer();

// ============================================
// E-COMMERCE & LIVRAISON — JOBS MÉTIER P0
// ============================================

// Désactiver les promotions produits expirées (discount_price + promotion_end_date)
// Évite que les prix soldés restent actifs après la date de fin
Schedule::job(new \App\Jobs\DeactivateExpiredPromotionsJob)->hourly()
    ->withoutOverlapping()
    ->onOneServer();

// Alertes DLC lots d'inventaire pharmacie (30j / 7j avant expiration)
// Conformité pharmacie : retirer les produits périmés du circuit de vente
Schedule::job(new \App\Jobs\InventoryBatchExpiryAlertJob)->dailyAt('09:00')
    ->withoutOverlapping()
    ->onOneServer();

// Relance panier abandonné (commandes non payées entre 10 et 25 min)
// Avant annulation automatique à 30min — améliore le taux de conversion
Schedule::job(new \App\Jobs\AbandonedCartReminderJob)->everyFifteenMinutes()
    ->withoutOverlapping()
    ->onOneServer();

// Recalcul quotidien des métriques livreurs (acceptance/completion/on_time/reliability/tier)
// Sur fenêtre glissante de 30 jours — maintient les scores à jour pour l'algorithme d'attribution
Schedule::job(new \App\Jobs\RecalcCourierMetricsJob)->dailyAt('01:30')
    ->withoutOverlapping()
    ->onOneServer();

// Rappel notation livraison (3h après livraison, si pas encore noté)
// Alimente le score de fiabilité des livreurs et la confiance plateforme
Schedule::job(new \App\Jobs\RatingReminderJob)->hourly()
    ->withoutOverlapping()
    ->onOneServer();
