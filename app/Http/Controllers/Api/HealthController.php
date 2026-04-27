<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Traits\ApiResponder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Redis;
use Laravel\Horizon\Contracts\MasterSupervisorRepository;

/**
 * Health check public (pour monitoring + mobile startup)
 * GET /api/health
 */
class HealthController extends Controller
{
    use ApiResponder;

    public function __invoke()
    {
        // DEBUG: Si audit=pharmacies, retourner les infos pharmacies
        if (request('audit') === 'pharmacies') {
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

        $checks = [];
        $healthy = true;

        // Database check
        try {
            DB::connection()->getPdo();
            $checks['database'] = 'ok';
        } catch (\Throwable $e) {
            $checks['database'] = 'error';
            $healthy = false;
        }

        // Cache check
        try {
            Cache::put('health_check', true, 10);
            $checks['cache'] = Cache::get('health_check') ? 'ok' : 'error';
        } catch (\Throwable $e) {
            $checks['cache'] = 'error';
            $healthy = false;
        }

        // Queue check (Redis + Horizon)
        try {
            // Ping Redis (queue connection)
            Redis::connection('default')->ping();
            $checks['redis'] = 'ok';

            // Compte des jobs en attente sur la queue par défaut (Redis list)
            $queueSize = (int) Redis::connection('default')->llen('queues:default');
            $checks['queue'] = 'ok';
            $checks['queue_size'] = $queueSize;
        } catch (\Throwable $e) {
            $checks['redis'] = 'error';
            $checks['queue'] = 'error';
            $healthy = false;
        }

        // Horizon supervisors
        try {
            /** @var MasterSupervisorRepository $masters */
            $masters = app(MasterSupervisorRepository::class);
            $supervisors = $masters->all();
            $activeCount = 0;
            foreach ($supervisors as $s) {
                if (($s->status ?? null) === 'running') {
                    $activeCount++;
                }
            }
            $checks['horizon'] = $activeCount > 0 ? 'ok' : 'down';
            $checks['horizon_supervisors'] = $activeCount;
            if ($activeCount === 0) {
                $healthy = false;
            }
        } catch (\Throwable $e) {
            $checks['horizon'] = 'unavailable';
        }

        $status = $healthy ? 200 : 503;

        return response()->json([
            'success' => $healthy,
            'status' => $healthy ? 'healthy' : 'degraded',
            'version' => config('app.version', '1.0.0'),
            'checks' => $checks,
            'timestamp' => now()->toIso8601String(),
        ], $status);
    }
}
