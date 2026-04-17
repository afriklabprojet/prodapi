<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsurePhoneIsVerified
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Non authentifié',
                'error_code' => 'UNAUTHENTICATED',
            ], 401);
        }

        if (!$user->phone_verified_at) {
            return response()->json([
                'success' => false,
                'message' => 'Veuillez vérifier votre numéro de téléphone d\'abord',
                'error_code' => 'PHONE_NOT_VERIFIED',
                'requires_verification' => true,
            ], 403);
        }

        return $next($request);
    }
}
