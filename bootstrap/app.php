<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\Exceptions\ThrottleRequestsException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        apiPrefix: 'api',
        commands: __DIR__.'/../routes/console.php',
        channels: __DIR__.'/../routes/channels.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // R-003: CSP headers pour les routes web (Filament admin)
        $middleware->web(append: [
            \App\Http\Middleware\ContentSecurityPolicy::class,
        ]);
        
        $middleware->api(prepend: [
            \App\Http\Middleware\TrustProxies::class,
            \Illuminate\Http\Middleware\HandleCors::class,
            \App\Http\Middleware\EnsureProductionSafe::class, // SECURITY: Vérifier config production
            \App\Http\Middleware\ApiSecurityHeaders::class, // SECURITY: Headers sécurité API
        ]);
        
        // Configuration de la redirection pour les utilisateurs non authentifiés
        // Pour les requêtes API, retourne null pour déclencher une exception JSON
        // Pour les requêtes web, redirige vers la page de login Filament
        $middleware->redirectGuestsTo(function (\Illuminate\Http\Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return null; // Déclenche AuthenticationException -> JSON 401
            }
            return '/finance/login'; // Redirection vers Filament
        });
        
        // Remplacer le middleware Authenticate par notre version personnalisée
        // pour éviter l'erreur "Route [login] not defined" sur les requêtes API
        $middleware->alias([
            'auth' => \App\Http\Middleware\Authenticate::class,
            'role' => \App\Http\Middleware\CheckRole::class,
            'admin' => \App\Http\Middleware\EnsureUserIsAdmin::class,
            'production.safe' => \App\Http\Middleware\EnsureProductionSafe::class,
            'verified.phone' => \App\Http\Middleware\EnsurePhoneIsVerified::class,
            'csp' => \App\Http\Middleware\ContentSecurityPolicy::class, // R-003
            'courier' => \App\Http\Middleware\EnsureCourierProfile::class, // Vérifier profil coursier
            'password.changed' => \App\Http\Middleware\EnsurePasswordChanged::class, // I-02: Forcer changement mot de passe
            'idempotent' => \App\Http\Middleware\IdempotencyMiddleware::class, // Anti double-soumission
            'audit' => \App\Http\Middleware\AuditTrailMiddleware::class, // Admin audit trail
            'api.version' => \App\Http\Middleware\ApiVersionMiddleware::class, // API versioning headers
        ]);
        
        // Appliquer le rate limiting par défaut sur l'API
        $middleware->api(append: [
            \Illuminate\Routing\Middleware\ThrottleRequests::class.':api',
            \App\Http\Middleware\ApiVersionMiddleware::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Sentry — capture toutes les exceptions non gérées (no-op si SENTRY_LARAVEL_DSN vide)
        $exceptions->reportable(function (\Throwable $e) {
            if (app()->bound('sentry')) {
                \Sentry\Laravel\Integration::captureUnhandledException($e);
            }
        });

        // SECURITY LOGGING — accès refusés (auth/authz/rate-limit)
        // Aide à détecter brute-force, scan d'autorisation, scrapers.
        $exceptions->reportable(function (AuthenticationException $e) {
            $request = request();
            if ($request->is('api/*') || $request->expectsJson()) {
                Log::channel('security')->warning('[ACCESS_DENIED] unauthenticated', [
                    'ip' => $request->ip(),
                    'method' => $request->method(),
                    'path' => $request->path(),
                    'ua' => substr((string) $request->userAgent(), 0, 200),
                ]);
            }
        });

        $exceptions->reportable(function (AuthorizationException $e) {
            $request = request();
            if ($request->is('api/*') || $request->expectsJson()) {
                Log::channel('security')->warning('[ACCESS_DENIED] forbidden', [
                    'ip' => $request->ip(),
                    'user_id' => optional($request->user())->id,
                    'method' => $request->method(),
                    'path' => $request->path(),
                    'reason' => $e->getMessage(),
                ]);
            }
        });

        $exceptions->reportable(function (ThrottleRequestsException $e) {
            $request = request();
            Log::channel('security')->warning('[RATE_LIMIT] throttled', [
                'ip' => $request->ip(),
                'user_id' => optional($request->user())->id,
                'method' => $request->method(),
                'path' => $request->path(),
                'ua' => substr((string) $request->userAgent(), 0, 200),
            ]);
        });

        // Retourner JSON pour les modèles non trouvés (404) sur les requêtes API
        $exceptions->render(function (ModelNotFoundException $e, Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                $model = class_basename($e->getModel());
                return response()->json([
                    'success' => false,
                    'message' => "Ressource introuvable",
                    'error' => "La ressource demandée ({$model}) n'existe pas ou a été supprimée.",
                    'error_code' => 'RESOURCE_NOT_FOUND'
                ], 404);
            }
        });

        // Retourner JSON pour les requêtes API non authentifiées
        // au lieu de rediriger vers une route login
        $exceptions->render(function (AuthenticationException $e, Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Non authentifié',
                    'error' => 'Veuillez vous connecter pour accéder à cette ressource',
                    'error_code' => 'UNAUTHENTICATED'
                ], 401);
            }
        });
    })->create();
