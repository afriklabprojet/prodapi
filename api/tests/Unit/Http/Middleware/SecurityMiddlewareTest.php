<?php

namespace Tests\Unit\Http\Middleware;

use App\Http\Middleware\EnsurePhoneIsVerified;
use App\Http\Middleware\EnsureUserIsAdmin;
use App\Http\Middleware\EnsureProductionSafe;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class SecurityMiddlewareTest extends TestCase
{
    use RefreshDatabase;

    // ================================================================
    // EnsurePhoneIsVerified
    // ================================================================

    #[Test]
    public function phone_verified_middleware_returns_401_for_guest(): void
    {
        $middleware = new EnsurePhoneIsVerified();
        $request = Request::create('/api/test', 'GET');

        $response = $middleware->handle($request, fn($req) => response()->json(['ok' => true]));

        $this->assertEquals(401, $response->getStatusCode());
        $body = json_decode($response->getContent(), true);
        $this->assertEquals('UNAUTHENTICATED', $body['error_code']);
    }

    #[Test]
    public function phone_verified_middleware_returns_403_when_phone_not_verified(): void
    {
        $middleware = new EnsurePhoneIsVerified();
        $user = User::factory()->create(['phone_verified_at' => null]);
        $request = Request::create('/api/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $middleware->handle($request, fn($req) => response()->json(['ok' => true]));

        $this->assertEquals(403, $response->getStatusCode());
        $body = json_decode($response->getContent(), true);
        $this->assertEquals('PHONE_NOT_VERIFIED', $body['error_code']);
        $this->assertTrue($body['requires_verification']);
    }

    #[Test]
    public function phone_verified_middleware_passes_when_phone_is_verified(): void
    {
        $middleware = new EnsurePhoneIsVerified();
        $user = User::factory()->create(['phone_verified_at' => now()]);
        $request = Request::create('/api/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $middleware->handle($request, fn($req) => response()->json(['ok' => true]));

        $this->assertEquals(200, $response->getStatusCode());
    }

    // ================================================================
    // EnsureUserIsAdmin
    // ================================================================

    #[Test]
    public function admin_middleware_returns_403_for_non_admin(): void
    {
        $middleware = new EnsureUserIsAdmin();
        $user = User::factory()->create(['role' => 'customer']);
        $request = Request::create('/api/admin/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $middleware->handle($request, fn($req) => response()->json(['ok' => true]));

        $this->assertEquals(403, $response->getStatusCode());
        $body = json_decode($response->getContent(), true);
        $this->assertEquals('FORBIDDEN_ADMIN', $body['error_code']);
    }

    #[Test]
    public function admin_middleware_returns_403_for_guest(): void
    {
        $middleware = new EnsureUserIsAdmin();
        $request = Request::create('/api/admin/test', 'GET');

        $response = $middleware->handle($request, fn($req) => response()->json(['ok' => true]));

        $this->assertEquals(403, $response->getStatusCode());
    }

    #[Test]
    public function admin_middleware_passes_for_admin_user(): void
    {
        $middleware = new EnsureUserIsAdmin();
        $user = User::factory()->create(['role' => 'admin']);
        $request = Request::create('/api/admin/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $middleware->handle($request, fn($req) => response()->json(['ok' => true]));

        $this->assertEquals(200, $response->getStatusCode());
    }

    // ================================================================
    // EnsureProductionSafe
    // ================================================================

    #[Test]
    public function production_safe_middleware_passes_in_testing_env(): void
    {
        $middleware = new EnsureProductionSafe();
        $request = Request::create('/api/test', 'GET');

        // In testing environment, should always pass through
        $response = $middleware->handle($request, fn($req) => response()->json(['ok' => true]));

        $this->assertEquals(200, $response->getStatusCode());
    }

    #[Test]
    public function production_safe_middleware_blocks_with_default_key_in_production(): void
    {
        $middleware = new EnsureProductionSafe();
        $request = Request::create('/api/test', 'GET');

        // Simulate production with default key
        app()->detectEnvironment(fn() => 'production');
        config(['app.key' => 'base64:CHANGEME']);

        $response = $middleware->handle($request, fn($req) => response()->json(['ok' => true]));

        // Restore environment
        app()->detectEnvironment(fn() => 'testing');
        config(['app.key' => 'base64:' . base64_encode(random_bytes(32))]);

        $this->assertEquals(503, $response->getStatusCode());
        $body = json_decode($response->getContent(), true);
        $this->assertEquals('PRODUCTION_UNSAFE', $body['error_code']);
    }
}
