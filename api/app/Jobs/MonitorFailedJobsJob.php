<?php

namespace App\Jobs;

use App\Mail\AdminAlertMail;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\WithoutOverlapping;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

/**
 * Surveille la table failed_jobs et alerte l'admin
 * si des jobs ont échoué dans les dernières heures.
 *
 * Exécuté toutes les 2 heures.
 */
class MonitorFailedJobsJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 1;
    public int $timeout = 30;

    public function middleware(): array
    {
        return [new WithoutOverlapping('monitor-failed-jobs')];
    }

    public function handle(): void
    {
        $since = now()->subHours(2);

        $recentFailures = DB::table('failed_jobs')
            ->where('failed_at', '>=', $since)
            ->orderByDesc('failed_at')
            ->limit(50)
            ->get(['uuid', 'queue', 'payload', 'exception', 'failed_at']);

        if ($recentFailures->isEmpty()) {
            return;
        }

        $totalFailed = DB::table('failed_jobs')->count();

        $summary = $recentFailures->map(function ($job) {
            $payload = json_decode($job->payload, true);
            $jobClass = $payload['displayName'] ?? 'Unknown';
            $exceptionLines = explode("\n", $job->exception ?? '');

            return [
                'uuid' => $job->uuid,
                'job' => class_basename($jobClass),
                'queue' => $job->queue,
                'failed_at' => $job->failed_at,
                'error' => $exceptionLines[0] ?? 'Unknown error',
            ];
        })->toArray();

        // Grouper par type de job
        $grouped = [];
        foreach ($summary as $item) {
            $grouped[$item['job']] = ($grouped[$item['job']] ?? 0) + 1;
        }

        Log::warning('MonitorFailedJobs: failures detected', [
            'recent_count' => count($summary),
            'total_in_table' => $totalFailed,
            'by_job' => $grouped,
        ]);

        try {
            Mail::to(config('mail.admin_address', 'admin@drlpharma.com'))
                ->send(new AdminAlertMail('failed_jobs', [
                    'recent_count' => count($summary),
                    'total_count' => $totalFailed,
                    'by_job' => $grouped,
                    'details' => array_slice($summary, 0, 10),
                    'period' => $since->format('d/m/Y H:i') . ' → ' . now()->format('d/m/Y H:i'),
                ]));
        } catch (\Throwable $e) {
            Log::warning('MonitorFailedJobs: alert email failed', [
                'error' => $e->getMessage(),
            ]);
        }
    }
}
