<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Gate;

class TelescopeServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        if (!$this->telescopeInstalled()) {
            return;
        }

        $this->app->register(\Laravel\Telescope\TelescopeServiceProvider::class);

        \Laravel\Telescope\Telescope::night();

        $this->hideSensitiveRequestDetails();

        $isLocal = $this->app->environment('local');

        \Laravel\Telescope\Telescope::filter(function (\Laravel\Telescope\IncomingEntry $entry) use ($isLocal) {
            if ($isLocal) {
                return true;
            }

            return $entry->isReportableException() ||
                   $entry->isFailedRequest() ||
                   $entry->isFailedJob() ||
                   $entry->isScheduledTask() ||
                   $entry->hasMonitoredTag();
        });

        \Laravel\Telescope\Telescope::tag(function (\Laravel\Telescope\IncomingEntry $entry) {
            if ($entry->type === 'request') {
                if (str_starts_with($entry->content['uri'] ?? '', '/api/')) {
                    return ['api'];
                }
            }
            return [];
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        if (!$this->telescopeInstalled()) {
            return;
        }

        Gate::define('viewTelescope', function ($user) {
            return in_array($user->email, [
                'admin@drlpharma.com',
                'dev@drlpharma.com',
            ]);
        });
    }

    /**
     * Check if Telescope is installed.
     */
    private function telescopeInstalled(): bool
    {
        return class_exists(\Laravel\Telescope\Telescope::class);
    }

    /**
     * Prevent sensitive request details from being logged by Telescope.
     */
    protected function hideSensitiveRequestDetails(): void
    {
        if ($this->app->environment('local')) {
            return;
        }

        \Laravel\Telescope\Telescope::hideRequestParameters([
            '_token',
            'password',
            'password_confirmation',
            'current_password',
            'new_password',
        ]);

        \Laravel\Telescope\Telescope::hideRequestHeaders([
            'cookie',
            'x-csrf-token',
            'x-xsrf-token',
            'authorization',
        ]);
    }
}
