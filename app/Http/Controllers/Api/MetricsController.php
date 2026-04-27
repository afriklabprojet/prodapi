<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Redis;
use Laravel\Horizon\Contracts\JobRepository;
use Laravel\Horizon\Contracts\MasterSupervisorRepository;
use Laravel\Horizon\Contracts\MetricsRepository;

/**
 * Metrics endpoint Prometheus-compatible.
 * GET /api/metrics
 *
 * Auth via header `X-Metrics-Token` (env: METRICS_TOKEN).
 * Sortie : text/plain (format expo Prometheus).
 *
 * Métriques exposées :
 *  - drpharma_horizon_master_status{name="..."}      (1 = running)
 *  - drpharma_horizon_jobs_recent_total              (jobs récents en mémoire Horizon)
 *  - drpharma_horizon_jobs_failed_total              (total échecs Horizon)
 *  - drpharma_queue_pending{queue="..."}             (Redis llen par queue)
 *  - drpharma_throughput_per_minute                  (throughput global)
 *  - drpharma_uptime_seconds                         (depuis APP_BOOT)
 */
class MetricsController extends Controller
{
    /** Queues à monitorer (alignées sur config/horizon.php). */
    private const MONITORED_QUEUES = [
        'default',
        'payments',
        'notifications',
        'broadcasts',
        'events',
    ];

    public function __invoke(
        Request $request,
        MasterSupervisorRepository $masters,
        JobRepository $jobs,
        MetricsRepository $metrics,
    ): Response {
        $expected = (string) config('drpharma.metrics_token', env('METRICS_TOKEN', ''));

        if ($expected === '') {
            return response('metrics endpoint disabled (set METRICS_TOKEN)', 503)
                ->header('Content-Type', 'text/plain');
        }

        $provided = (string) ($request->header('X-Metrics-Token') ?? $request->query('token', ''));

        if (! hash_equals($expected, $provided)) {
            return response('forbidden', 403)->header('Content-Type', 'text/plain');
        }

        $lines = [];

        // Horizon supervisors
        $lines[] = '# HELP drpharma_horizon_master_status Horizon master supervisor status (1 = running)';
        $lines[] = '# TYPE drpharma_horizon_master_status gauge';
        try {
            foreach ($masters->all() as $s) {
                $name = (string) ($s->name ?? 'unknown');
                $status = ($s->status ?? null) === 'running' ? 1 : 0;
                $lines[] = sprintf('drpharma_horizon_master_status{name="%s"} %d', $this->escape($name), $status);
            }
        } catch (\Throwable $e) {
            $lines[] = 'drpharma_horizon_master_status{name="error"} 0';
        }

        // Jobs counters
        try {
            $lines[] = '# HELP drpharma_horizon_jobs_recent_total Recent jobs tracked by Horizon';
            $lines[] = '# TYPE drpharma_horizon_jobs_recent_total gauge';
            $lines[] = 'drpharma_horizon_jobs_recent_total ' . (int) $jobs->totalRecent();

            $lines[] = '# HELP drpharma_horizon_jobs_failed_total Total failed jobs tracked by Horizon';
            $lines[] = '# TYPE drpharma_horizon_jobs_failed_total counter';
            $lines[] = 'drpharma_horizon_jobs_failed_total ' . (int) $jobs->totalFailed();
        } catch (\Throwable $e) {
            // Skip metrics if Horizon repo unavailable
        }

        // Queue depth (Redis lists)
        $lines[] = '# HELP drpharma_queue_pending Pending jobs per queue (Redis llen)';
        $lines[] = '# TYPE drpharma_queue_pending gauge';
        foreach (self::MONITORED_QUEUES as $queue) {
            try {
                $size = (int) Redis::connection('default')->llen('queues:' . $queue);
                $lines[] = sprintf('drpharma_queue_pending{queue="%s"} %d', $this->escape($queue), $size);
            } catch (\Throwable $e) {
                // Skip this queue
            }
        }

        // Throughput
        try {
            $lines[] = '# HELP drpharma_throughput_per_minute Throughput per minute (Horizon snapshots)';
            $lines[] = '# TYPE drpharma_throughput_per_minute gauge';
            $lines[] = 'drpharma_throughput_per_minute ' . (int) $metrics->jobsProcessedPerMinute();
        } catch (\Throwable $e) {
            // Skip
        }

        // Uptime (depuis le boot du process FPM)
        $lines[] = '# HELP drpharma_uptime_seconds Process uptime since request boot';
        $lines[] = '# TYPE drpharma_uptime_seconds gauge';
        $bootedAt = defined('LARAVEL_START') ? LARAVEL_START : microtime(true);
        $lines[] = 'drpharma_uptime_seconds ' . sprintf('%.3f', microtime(true) - $bootedAt);

        return response(implode("\n", $lines) . "\n", 200)
            ->header('Content-Type', 'text/plain; version=0.0.4');
    }

    private function escape(string $value): string
    {
        return str_replace(['\\', '"', "\n"], ['\\\\', '\\"', '\\n'], $value);
    }
}
