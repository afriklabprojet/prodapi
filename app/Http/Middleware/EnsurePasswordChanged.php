<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsurePasswordChanged
{
    /**
     * Forcer le changement de mot de passe au premier login admin.
     *
     * Les routes de changement de mot de passe et de déconnexion sont exemptées.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && $user->must_change_password) {
            // Permettre les routes de changement de mot de passe et de déconnexion
            $exemptRoutes = [
                'api/auth/change-password',
                'api/auth/logout',
                'api/v1/auth/change-password',
                'api/v1/auth/logout',
            ];

            if (!in_array($request->path(), $exemptRoutes)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Vous devez changer votre mot de passe avant de continuer.',
                    'error_code' => 'PASSWORD_CHANGE_REQUIRED',
                    'must_change_password' => true,
                ], 403);
            }
        }

        return $next($request);
    }
}
