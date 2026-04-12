<?php

namespace App\Jobs;

use App\Models\DeliveryRejection;
use App\Models\WebhookLog;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

/**
 * Nettoyage périodique des données anciennes.
 *
 * - Delivery rejections > 6 mois
 * - Webhook logs > 60 jours
 * - Payment intents expirés > 90 jours
 * - Notifications lues > 90 jours
 * - Fichiers logs Laravel > 30 jours
 *
 * Exécuté chaque dimanche à 3h du matin.
 */
class CleanupOldDataJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public int $timeout = 300;

    public function middleware(): array
    {
        return [new WithoutOverlapping('cleanup-old-data')];
    }

    public function handle(): void
    {
        $stats = [];

        // 1. Delivery rejections > 6 mois
        $stats['delivery_rejections'] = DB::table('delivery_rejections')
            ->where('rejected_at', '<', now()->subMonths(6))
            ->delete();

        // 2. Webhook logs > 60 jours
        if (Schema::hasTable('webhook_logs')) {
            $stats['webhook_logs'] = WebhookLog::where('created_at', '<', now()->subDays(60))->delete();
        }

        // 3. Payment intents expirés > 90 jours
        if (Schema::hasTable('payment_intents')) {
            $stats['payment_intents'] = DB::table('payment_intents')
                ->whereIn('status', ['cancelled', 'expired', 'failed'])
                ->where('created_at', '<', now()->subDays(90))
                ->delete();
        }

        // 4. Notifications lues > 90 jours
        $stats['notifications'] = DB::table('notifications')
            ->whereNotNull('read_at')
            ->where('read_at', '<', now()->subDays(90))
            ->delete();

        // 5. Nettoyer les anciens fichiers logs
        $stats['log_files'] = $this->cleanupLogFiles();

        $totalCleaned = array_sum($stats);

        if ($totalCleaned > 0) {
            Log::info('CleanupOldData: complete', $stats);
        }
    }

    private function cleanupLogFiles(): int
    {
        $logPath = storage_path('logs');
        $deleted = 0;

        if (!is_dir($logPath)) {
            return 0;
        }

        $files = glob($logPath . '/laravel-*.log');
        $threshold = now()->subDays(30)->timestamp;

        foreach ($files as $file) {
            if (is_file($file) && filemtime($file) < $threshold) {
                if (unlink($file)) {
                    $deleted++;
                }
            }
        }

        return $deleted;
    }

    public function failed(\Throwable $exception): void
    {
        Log::error('CleanupOldDataJob failed', [
            'error' => $exception->getMessage(),
        ]);
    }
}
