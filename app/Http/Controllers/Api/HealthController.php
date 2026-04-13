<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Traits\ApiResponder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Storage;

/**
 * Health check public (pour monitoring + mobile startup)
 * GET /api/health
 * GET /api/health?deep=1 pour checks étendus (admin only)
 */
class HealthController extends Controller
{
    use ApiResponder;

    public function __invoke()
    {
        // DEBUG: Si audit=pharmacies, retourner les infos pharmacies
        if (request('audit') === 'pharmacies') {
            return $this->auditPharmacies();
        }

        $checks = [];
        $healthy = true;
        $warnings = [];

        // === CHECKS CRITIQUES (affectent le status) ===

        // Database check
        try {
            $dbStart = microtime(true);
            DB::connection()->getPdo();
            $dbLatency = round((microtime(true) - $dbStart) * 1000, 2);
            $checks['database'] = [
                'status' => 'ok',
                'latency_ms' => $dbLatency,
            ];
            if ($dbLatency > 100) {
                $warnings[] = "Database latency high: {$dbLatency}ms";
            }
        } catch (\Throwable $e) {
            $checks['database'] = ['status' => 'error', 'message' => 'Connection failed'];
            $healthy = false;
        }

        // Cache check
        try {
            $cacheStart = microtime(true);
            Cache::put('health_check', true, 10);
            $cacheOk = Cache::get('health_check') === true;
            $cacheLatency = round((microtime(true) - $cacheStart) * 1000, 2);
            $checks['cache'] = [
                'status' => $cacheOk ? 'ok' : 'error',
                'latency_ms' => $cacheLatency,
            ];
            if (!$cacheOk) $healthy = false;
        } catch (\Throwable $e) {
            $checks['cache'] = ['status' => 'error', 'message' => $e->getMessage()];
            $healthy = false;
        }

        // Redis check (si configuré)
        try {
            if (config('cache.default') === 'redis' || config('queue.default') === 'redis') {
                $redisStart = microtime(true);
                Redis::ping();
                $redisLatency = round((microtime(true) - $redisStart) * 1000, 2);
                $checks['redis'] = [
                    'status' => 'ok',
                    'latency_ms' => $redisLatency,
                ];
            }
        } catch (\Throwable $e) {
            $checks['redis'] = ['status' => 'error', 'message' => 'Redis unavailable'];
            // Redis down = warning, pas critical si fallback existe
            $warnings[] = 'Redis connection failed';
        }

        // === CHECKS NON-CRITIQUES ===

        // Queue check
        try {
            $pendingJobs = DB::table('jobs')->count();
            $failedJobs = DB::table('failed_jobs')->count();
            $checks['queue'] = [
                'status' => 'ok',
                'pending_jobs' => $pendingJobs,
                'failed_jobs' => $failedJobs,
            ];
            if ($failedJobs > 0) {
                $warnings[] = "{$failedJobs} failed jobs in queue";
            }
            if ($pendingJobs > 1000) {
                $warnings[] = "Queue backlog high: {$pendingJobs} jobs";
            }
        } catch (\Throwable $e) {
            $checks['queue'] = ['status' => 'unavailable'];
        }

        // Storage check
        try {
            $testFile = 'health_check_' . time() . '.tmp';
            Storage::disk('local')->put($testFile, 'test');
            Storage::disk('local')->delete($testFile);
            $checks['storage'] = ['status' => 'ok'];
        } catch (\Throwable $e) {
            $checks['storage'] = ['status' => 'error', 'message' => 'Storage not writable'];
            $warnings[] = 'Storage write failed';
        }

        // Deep checks (admin only)
        if (request('deep') === '1') {
            $checks = array_merge($checks, $this->deepChecks());
        }

        // Compute overall status
        $status = $healthy ? 200 : 503;
        $statusText = $healthy 
            ? (count($warnings) > 0 ? 'healthy_with_warnings' : 'healthy')
            : 'degraded';

        $response = [
            'success' => $healthy,
            'status' => $statusText,
            'version' => config('app.version', '1.0.0'),
            'environment' => app()->environment(),
            'checks' => $checks,
            'timestamp' => now()->toIso8601String(),
        ];

        if (count($warnings) > 0) {
            $response['warnings'] = $warnings;
        }

        return response()->json($response, $status);
    }

    /**
     * Checks approfondis pour monitoring interne.
     */
    protected function deepChecks(): array
    {
        $checks = [];

        // Circuit breaker status
        $circuits = ['eta-service', 'geo-zone', 'weather-api', 'traffic-api', 'whatsapp'];
        $circuitStatuses = [];
        foreach ($circuits as $circuit) {
            $isOpen = Cache::has("circuit:{$circuit}:open");
            $failureCount = (int) Cache::get("circuit:{$circuit}:failures", 0);
            $circuitStatuses[$circuit] = [
                'status' => $isOpen ? 'OPEN' : 'CLOSED',
                'failures' => $failureCount,
            ];
        }
        $checks['circuit_breakers'] = $circuitStatuses;

        // Database connection pool
        try {
            $dbStats = DB::select("SHOW STATUS LIKE 'Threads_connected'");
            $threadsConnected = $dbStats[0]->Value ?? 'unknown';
            $checks['db_connections'] = $threadsConnected;
        } catch (\Throwable $e) {
            $checks['db_connections'] = 'unavailable';
        }

        // Disk space
        try {
            $freeSpace = disk_free_space(storage_path());
            $totalSpace = disk_total_space(storage_path());
            $usedPercent = round((1 - $freeSpace / $totalSpace) * 100, 1);
            $checks['disk'] = [
                'free_gb' => round($freeSpace / 1024 / 1024 / 1024, 2),
                'used_percent' => $usedPercent,
            ];
        } catch (\Throwable $e) {
            $checks['disk'] = 'unavailable';
        }

        // Recent errors count
        try {
            $recentErrors = DB::table('failed_jobs')
                ->where('failed_at', '>=', now()->subHour())
                ->count();
            $checks['recent_errors_1h'] = $recentErrors;
        } catch (\Throwable $e) {
            $checks['recent_errors_1h'] = 'unavailable';
        }

        return $checks;
    }

    /**
     * Audit des pharmacies (debug).
     */
    protected function auditPharmacies()
    {
        $pharmacies = \App\Models\Pharmacy::withCount('products')
            ->withCount(['products as available_products_count' => function ($q) {
                $q->where('is_available', true);
            }])
            ->get(['id', 'name', 'status', 'is_active', 'is_open', 'created_at']);
        
        return response()->json([
            'success' => true,
            'total_pharmacies' => $pharmacies->count(),
            'approved_count' => $pharmacies->where('status', 'approved')->count(),
            'pending_count' => $pharmacies->where('status', 'pending')->count(),
            'rejected_count' => $pharmacies->where('status', 'rejected')->count(),
            'pharmacies' => $pharmacies->map(fn($p) => [
                'id' => $p->id,
                'name' => $p->name,
                'status' => $p->status,
                'is_active' => $p->is_active,
                'is_open' => $p->is_open,
                'total_products' => $p->products_count,
                'available_products' => $p->available_products_count,
                'created_at' => $p->created_at?->toDateTimeString(),
            ]),
        ]);
    }
}
