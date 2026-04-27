<?php

namespace App\Providers;

use Illuminate\Support\Facades\Gate;
use Laravel\Horizon\Horizon;
use Laravel\Horizon\HorizonApplicationServiceProvider;

class HorizonServiceProvider extends HorizonApplicationServiceProvider
{
    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        parent::boot();

        // Horizon::routeSmsNotificationsTo('15556667777');
        // Horizon::routeMailNotificationsTo('example@example.com');
        // Horizon::routeSlackNotificationsTo('slack-webhook-url', '#channel');
    }

    /**
     * Register the Horizon gate.
     *
     * Acc\u00e8s restreint aux admins (emails whitelistes via env HORIZON_ADMINS,
     * separes par des virgules). Fallback : refuse en non-local.
     */
    protected function gate(): void
    {
        Gate::define('viewHorizon', function ($user = null) {
            if (! $user) {
                return false;
            }

            $admins = collect(explode(',', (string) env('HORIZON_ADMINS', '')))
                ->map(fn ($e) => strtolower(trim($e)))
                ->filter()
                ->all();

            return in_array(strtolower((string) $user->email), $admins, true);
        });
    }
}
