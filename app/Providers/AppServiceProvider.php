<?php

namespace App\Providers;

use App\Models\Delivery;
use App\Models\Order;
use App\Models\Product;
use App\Observers\DeliveryObserver;
use App\Observers\OrderObserver;
use App\Observers\ProductObserver;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use App\Events\PaymentConfirmed;
use App\Listeners\DistributeCommissions;
use Illuminate\Support\Facades\Event;
use Illuminate\Database\Eloquent\Model;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        // Charger Telescope uniquement en environnement local (et seulement s'il est installé)
        if ($this->app->environment('local') && class_exists(\Laravel\Telescope\TelescopeServiceProvider::class)) {
            $this->app->register(\Laravel\Telescope\TelescopeServiceProvider::class);
            $this->app->register(TelescopeServiceProvider::class);
        }
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Security: Prevent lazy loading in development to catch N+1 queries
        Model::preventLazyLoading(!app()->isProduction());
        
        // Security: Prevent silently discarding attributes
        Model::preventSilentlyDiscardingAttributes(!app()->isProduction());

        // I-05: Forcer HTTPS en production
        if (app()->isProduction()) {
            \Illuminate\Support\Facades\URL::forceScheme('https');
        }
        
        // Register Observers
        Order::observe(OrderObserver::class);
        Product::observe(ProductObserver::class);
        Delivery::observe(DeliveryObserver::class); // Auto-assignation automatique

        // Register Event Listeners
        Event::listen(
            PaymentConfirmed::class,
            DistributeCommissions::class,
        );

        // Configure Rate Limiters
        $this->configureRateLimiting();
    }

    /**
     * Configure the rate limiters for the application.
     * 
     * Security Audit Week 3 - Rate Limiting granulaire
     */
    protected function configureRateLimiting(): void
    {
        // Default API rate limit (60 req/min pour utilisateurs authentifiés)
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip())
                ->response(function () {
                    return response()->json([
                        'success' => false,
                        'message' => 'Trop de requêtes. Veuillez réessayer dans quelques instants.',
                    ], 429);
                });
        });

        // Authentication endpoints - Rate limiting (anti brute-force)
        // Beta: 20/min — Production recommandé: 5/min
        RateLimiter::for('auth', function (Request $request) {
            return Limit::perMinute(20)->by($request->ip())
                ->response(function () {
                    return response()->json([
                        'success' => false,
                        'message' => 'Trop de tentatives de connexion. Veuillez réessayer dans 1 minute.',
                    ], 429);
                });
        });

        // OTP verification - Rate limiting (anti brute-force OTP)
        // Beta: 15/min — Production recommandé: 3/min
        RateLimiter::for('otp', function (Request $request) {
            return Limit::perMinute(15)->by($request->ip())
                ->response(function () {
                    return response()->json([
                        'success' => false,
                        'message' => 'Trop de tentatives de vérification OTP. Veuillez réessayer dans 1 minute.',
                    ], 429);
                });
        });

        // OTP sending - Limité pour éviter le spam SMS
        // Beta: 10/min — Production recommandé: 2/min
        RateLimiter::for('otp-send', function (Request $request) {
            return Limit::perMinute(10)->by($request->ip())
                ->response(function () {
                    return response()->json([
                        'success' => false,
                        'message' => 'Trop de demandes d\'OTP. Veuillez attendre 1 minute.',
                    ], 429);
                });
        });

        // Password reset
        // Beta: 10/min — Production recommandé: 3/min
        RateLimiter::for('password-reset', function (Request $request) {
            return Limit::perMinute(10)->by($request->ip())
                ->response(function () {
                    return response()->json([
                        'success' => false,
                        'message' => 'Trop de demandes de réinitialisation. Veuillez réessayer dans 1 minute.',
                    ], 429);
                });
        });

        // Payment endpoints - TRÈS STRICT (prévention fraude)
        RateLimiter::for('payment', function (Request $request) {
            return Limit::perMinute(10)->by($request->user()?->id ?: $request->ip())
                ->response(function () {
                    return response()->json([
                        'success' => false,
                        'message' => 'Trop de tentatives de paiement. Veuillez réessayer dans quelques instants.',
                    ], 429);
                });
        });

        // Order creation - Modéré
        RateLimiter::for('orders', function (Request $request) {
            return Limit::perMinute(10)->by($request->user()?->id ?: $request->ip())
                ->response(function () {
                    return response()->json([
                        'success' => false,
                        'message' => 'Trop de commandes créées. Veuillez réessayer dans quelques instants.',
                    ], 429);
                });
        });

        // Search endpoints - Plus permissif
        RateLimiter::for('search', function (Request $request) {
            return Limit::perMinute(30)->by($request->user()?->id ?: $request->ip())
                ->response(function () {
                    return response()->json([
                        'success' => false,
                        'message' => 'Trop de recherches. Veuillez réessayer dans quelques instants.',
                    ], 429);
                });
        });

        // Uploads (prescriptions, images) - Strict
        RateLimiter::for('uploads', function (Request $request) {
            return Limit::perMinute(5)->by($request->user()?->id ?: $request->ip())
                ->response(function () {
                    return response()->json([
                        'success' => false,
                        'message' => 'Trop de fichiers uploadés. Veuillez réessayer dans quelques instants.',
                    ], 429);
                });
        });

        // Webhook endpoints - Limité par IP source
        RateLimiter::for('webhook', function (Request $request) {
            return Limit::perMinute(100)->by($request->ip())
                ->response(function () {
                    return response()->json([
                        'success' => false,
                        'message' => 'Rate limit exceeded for webhooks.',
                    ], 429);
                });
        });

        // Courier location updates - Fréquent mais limité
        RateLimiter::for('location', function (Request $request) {
            return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip())
                ->response(function () {
                    return response()->json([
                        'success' => false,
                        'message' => 'Trop de mises à jour de position.',
                    ], 429);
                });
        });

        // Notifications - Limité
        RateLimiter::for('notifications', function (Request $request) {
            return Limit::perMinute(30)->by($request->user()?->id ?: $request->ip());
        });

        // Public endpoints (sans auth) - Plus strict
        RateLimiter::for('public', function (Request $request) {
            return Limit::perMinute(20)->by($request->ip())
                ->response(function () {
                    return response()->json([
                        'success' => false,
                        'message' => 'Trop de requêtes. Veuillez réessayer dans quelques instants.',
                    ], 429);
                });
        });

        // Liveness detection - Limité pour éviter les abus
        // 10 validations par minute (plusieurs captures par challenge)
        RateLimiter::for('liveness', function (Request $request) {
            return Limit::perMinute(10)->by($request->user()?->id ?: $request->ip())
                ->response(function () {
                    return response()->json([
                        'success' => false,
                        'message' => 'Trop de tentatives. Veuillez patienter avant de réessayer.',
                    ], 429);
                });
        });
    }
}
