<?php

namespace App\Http\Middleware;

use Closure;
use Filament\Facades\Filament;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Force la 2FA pour le panel admin :
 *  - Si l'utilisateur n'a pas encore activé la 2FA → redirige vers /admin/two-factor/setup
 *  - Si activée mais session non challenge → redirige vers /admin/two-factor/challenge
 *
 * Le toggle est piloté par config('features.admin_2fa_required', true).
 */
class EnsureTwoFactorChallenge
{
    public function handle(Request $request, Closure $next): Response
    {
        if (! config('features.admin_2fa_required', true)) {
            return $next($request);
        }

        $user = $request->user();
        if (! $user) {
            return $next($request);
        }

        $panelId = Filament::getCurrentPanel()?->getId();
        if ($panelId !== 'admin') {
            return $next($request);
        }

        $setupUrl = url('/admin/two-factor/setup');
        $challengeUrl = url('/admin/two-factor/challenge');
        $allowed = [$setupUrl, $challengeUrl, url('/admin/logout')];

        // Routes toujours autorisées
        foreach ($allowed as $u) {
            if ($request->is(parse_url($u, PHP_URL_PATH).'*') || $request->fullUrlIs($u.'*')) {
                return $next($request);
            }
        }

        if (! $user->hasTwoFactorEnabled()) {
            return redirect($setupUrl);
        }

        if (! $request->session()->get('two_factor_passed')) {
            return redirect($challengeUrl);
        }

        return $next($request);
    }
}
