<?php

namespace Tests\Unit\Providers;

use App\Providers\TelescopeServiceProvider;
use Illuminate\Support\Facades\Gate;
use ReflectionClass;
use Tests\TestCase;

class TelescopeServiceProviderTest extends TestCase
{
    public function test_telescope_installed_check(): void
    {
        $provider = new TelescopeServiceProvider($this->app);
        $reflection = new ReflectionClass($provider);
        $method = $reflection->getMethod('telescopeInstalled');
        $method->setAccessible(true);

        $result = $method->invoke($provider);

        // Telescope may or may not be installed — just ensure we get a boolean
        $this->assertIsBool($result);
    }

    public function test_register_completes_without_error(): void
    {
        $provider = new TelescopeServiceProvider($this->app);

        // Should complete without error regardless of Telescope presence
        $provider->register();
        $this->assertTrue(true);
    }

    public function test_boot_completes_without_error(): void
    {
        $provider = new TelescopeServiceProvider($this->app);

        // Should complete without error regardless of Telescope presence
        $provider->boot();
        $this->assertTrue(true);
    }

    public function test_hide_sensitive_request_details_in_local(): void
    {
        $this->app['env'] = 'local';

        $provider = new TelescopeServiceProvider($this->app);
        $reflection = new ReflectionClass($provider);
        $method = $reflection->getMethod('hideSensitiveRequestDetails');
        $method->setAccessible(true);

        // In local env, method should return early without calling Telescope methods
        // If Telescope is not installed, this verifies the local check happens first
        $method->invoke($provider);
        $this->assertTrue(true);
    }

    public function test_provider_extends_service_provider(): void
    {
        $this->assertTrue(
            is_subclass_of(TelescopeServiceProvider::class, \Illuminate\Support\ServiceProvider::class)
        );
    }

    public function test_provider_has_required_methods(): void
    {
        $reflection = new ReflectionClass(TelescopeServiceProvider::class);

        $this->assertTrue($reflection->hasMethod('register'));
        $this->assertTrue($reflection->hasMethod('boot'));
        $this->assertTrue($reflection->hasMethod('telescopeInstalled'));
        $this->assertTrue($reflection->hasMethod('hideSensitiveRequestDetails'));
    }

    public function test_view_telescope_gate_when_telescope_installed(): void
    {
        // Skip if Telescope isn't actually installed
        if (!class_exists(\Laravel\Telescope\Telescope::class)) {
            $this->markTestSkipped('Telescope not installed');
        }

        $provider = new TelescopeServiceProvider($this->app);
        $provider->boot();

        // Verify the gate is defined
        $this->assertTrue(Gate::has('viewTelescope'));
    }
}
