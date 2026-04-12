<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureProductionSafe
{
    /**
     * Vérifier que la configuration production est correcte.
     */
    public function handle(Request $request, Closure $next): Response
    {
        if (app()->environment('production') && config('app.key') === 'base64:CHANGEME') {
            return response()->json([
                'success' => false,
                'message' => 'Configuration de production incomplète',
                'error_code' => 'PRODUCTION_UNSAFE',
            ], 503);
        }

        return $next($request);
    }
}
