<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckRole
{
    /**
     * Vérifier que l'utilisateur a le rôle requis.
     * Usage : role:customer  ou  role:admin,pharmacy
     */
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Non authentifié',
                'error_code' => 'UNAUTHENTICATED',
            ], 401);
        }

        if (!in_array($user->role, $roles, true)) {
            return response()->json([
                'success' => false,
                'message' => 'Accès non autorisé. Rôle requis : ' . implode(', ', $roles),
                'error_code' => 'FORBIDDEN_ROLE',
            ], 403);
        }

        return $next($request);
    }
}
