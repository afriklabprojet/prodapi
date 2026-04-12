<?php

namespace Tests\Unit\Providers;

use App\Providers\AppServiceProvider;
use Tests\TestCase;

class AppServiceProviderTest extends TestCase
{
    public function test_it_can_be_instantiated(): void
    {
        $provider = new AppServiceProvider($this->app);
        $this->assertInstanceOf(AppServiceProvider::class, $provider);
    }

    public function test_rate_limiter_api_is_configured(): void
    {
        $limiter = app(\Illuminate\Cache\RateLimiting\Limit::class ?? null);
        // Just verify the rate limiter for 'api' exists
        $this->assertTrue(
            \Illuminate\Support\Facades\RateLimiter::limiter('api') !== null
        );
    }

    public function test_rate_limiter_auth_is_configured(): void
    {
        $this->assertNotNull(\Illuminate\Support\Facades\RateLimiter::limiter('auth'));
    }

    public function test_rate_limiter_otp_is_configured(): void
    {
        $this->assertNotNull(\Illuminate\Support\Facades\RateLimiter::limiter('otp'));
    }

    public function test_rate_limiter_payment_is_configured(): void
    {
        $this->assertNotNull(\Illuminate\Support\Facades\RateLimiter::limiter('payment'));
    }

    public function test_rate_limiter_orders_is_configured(): void
    {
        $this->assertNotNull(\Illuminate\Support\Facades\RateLimiter::limiter('orders'));
    }

    public function test_rate_limiter_search_is_configured(): void
    {
        $this->assertNotNull(\Illuminate\Support\Facades\RateLimiter::limiter('search'));
    }

    public function test_rate_limiter_uploads_is_configured(): void
    {
        $this->assertNotNull(\Illuminate\Support\Facades\RateLimiter::limiter('uploads'));
    }

    public function test_rate_limiter_webhook_is_configured(): void
    {
        $this->assertNotNull(\Illuminate\Support\Facades\RateLimiter::limiter('webhook'));
    }

    public function test_rate_limiter_location_is_configured(): void
    {
        $this->assertNotNull(\Illuminate\Support\Facades\RateLimiter::limiter('location'));
    }

    public function test_rate_limiter_notifications_is_configured(): void
    {
        $this->assertNotNull(\Illuminate\Support\Facades\RateLimiter::limiter('notifications'));
    }

    public function test_rate_limiter_public_is_configured(): void
    {
        $this->assertNotNull(\Illuminate\Support\Facades\RateLimiter::limiter('public'));
    }

    public function test_rate_limiter_liveness_is_configured(): void
    {
        $this->assertNotNull(\Illuminate\Support\Facades\RateLimiter::limiter('liveness'));
    }

    public function test_rate_limiter_otp_send_is_configured(): void
    {
        $this->assertNotNull(\Illuminate\Support\Facades\RateLimiter::limiter('otp-send'));
    }

    public function test_rate_limiter_password_reset_is_configured(): void
    {
        $this->assertNotNull(\Illuminate\Support\Facades\RateLimiter::limiter('password-reset'));
    }
}
