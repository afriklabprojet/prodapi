<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Applique les headers de securite sur toutes les reponses API.
 * Objectif: defense en profondeur cote navigateur / WebView mobile.
 */
class ApiSecurityHeaders
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        // Anti-sniffing / framing / mixed content
        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-Frame-Options', 'DENY');
        $response->headers->set('X-Permitted-Cross-Domain-Policies', 'none');

        // HSTS: 2 ans + sous-domaines + preload (prerequis preload list)
        $response->headers->set(
            'Strict-Transport-Security',
            'max-age=63072000; includeSubDomains; preload'
        );

        // Fuite d'origine minimale
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');

        // Isolation cross-origin (WebViews / navigateurs)
        $response->headers->set('Cross-Origin-Opener-Policy', 'same-origin');
        $response->headers->set('Cross-Origin-Resource-Policy', 'same-site');

        // Desactiver toutes les API navigateur sensibles par defaut (API JSON n'en a pas besoin)
        $response->headers->set(
            'Permissions-Policy',
            'accelerometer=(), ambient-light-sensor=(), autoplay=(), battery=(), '
            . 'camera=(), cross-origin-isolated=(), display-capture=(), '
            . 'document-domain=(), encrypted-media=(), fullscreen=(), '
            . 'geolocation=(), gyroscope=(), keyboard-map=(), magnetometer=(), '
            . 'microphone=(), midi=(), payment=(), picture-in-picture=(), '
            . 'publickey-credentials-get=(), screen-wake-lock=(), sync-xhr=(), '
            . 'usb=(), xr-spatial-tracking=()'
        );

        // Retirer les headers qui fingerprint la stack
        $response->headers->remove('X-Powered-By');
        $response->headers->remove('Server');

        return $response;
    }
}
