<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Middleware de versioning API.
 * 
 * Ajoute des headers de version sur chaque réponse:
 * - X-API-Version: version courante
 * - X-API-Min-Version: version minimum supportée
 * - X-API-Deprecated: true si la version utilisée est dépréciée
 *
 * Les clients envoient le header: X-API-Version ou ?api_version=
 */
class ApiVersionMiddleware
{
    private const CURRENT_VERSION = 'v1';
    private const MIN_VERSION = 'v1';
    private const DEPRECATED_VERSIONS = [];

    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        // Ajouter les headers de version
        $response->headers->set('X-API-Version', self::CURRENT_VERSION);
        $response->headers->set('X-API-Min-Version', self::MIN_VERSION);

        // Vérifier si le client utilise une version dépréciée
        $clientVersion = $request->header('X-API-Version', $request->query('api_version', self::CURRENT_VERSION));

        if (in_array($clientVersion, self::DEPRECATED_VERSIONS)) {
            $response->headers->set('X-API-Deprecated', 'true');
            $response->headers->set('X-API-Sunset', 'Cette version sera désactivée prochainement. Mettez à jour votre application.');
        }

        return $response;
    }
}
