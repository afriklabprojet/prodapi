<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Force admin users to change their password on first login.
 * 
 * If the authenticated user has `must_change_password = true`,
 * redirect them to the password change page.
 */
class ForcePasswordChange
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && $user->must_change_password) {
            // Allow access to the change-password page itself, logout, and assets
            $allowedPaths = [
                'admin/force-change-password',
                'admin/logout',
                'livewire',
            ];

            $currentPath = $request->path();

            foreach ($allowedPaths as $path) {
                if (str_starts_with($currentPath, $path)) {
                    return $next($request);
                }
            }

            return redirect()->to('/admin/force-change-password');
        }

        return $next($request);
    }
}
