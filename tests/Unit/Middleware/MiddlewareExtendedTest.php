<?php

namespace Tests\Unit\Middleware;

use App\Http\Middleware\CheckRole;
use App\Http\Middleware\ContentSecurityPolicy;
use App\Http\Middleware\EnsurePasswordChanged;
use App\Http\Middleware\EnsurePhoneIsVerified;
use App\Http\Middleware\EnsureProductionSafe;
use App\Http\Middleware\EnsureUserIsAdmin;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Tests\TestCase;

class MiddlewareExtendedTest extends TestCase
{
    // --- CheckRole ---

    public function test_check_role_returns_401_when_unauthenticated(): void
    {
        $middleware = new CheckRole();
        $request = Request::create('/api/test', 'GET');

        $response = $middleware->handle($request, fn() => new JsonResponse(['ok' => true]), 'admin');

        $this->assertSame(401, $response->getStatusCode());
        $data = json_decode($response->getContent(), true);
        $this->assertSame('UNAUTHENTICATED', $data['error_code']);
    }

    public function test_check_role_returns_403_when_wrong_role(): void
    {
        $middleware = new CheckRole();
        $user = new class { public string $role = 'customer'; };
        $request = Request::create('/api/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $middleware->handle($request, fn() => new JsonResponse(['ok' => true]), 'admin');

        $this->assertSame(403, $response->getStatusCode());
        $data = json_decode($response->getContent(), true);
        $this->assertSame('FORBIDDEN_ROLE', $data['error_code']);
    }

    public function test_check_role_passes_with_correct_role(): void
    {
        $middleware = new CheckRole();
        $user = new class { public string $role = 'admin'; };
        $request = Request::create('/api/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $middleware->handle($request, fn() => new JsonResponse(['ok' => true]), 'admin');

        $this->assertSame(200, $response->getStatusCode());
    }

    public function test_check_role_passes_with_multiple_roles(): void
    {
        $middleware = new CheckRole();
        $user = new class { public string $role = 'pharmacy'; };
        $request = Request::create('/api/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $middleware->handle($request, fn() => new JsonResponse(['ok' => true]), 'admin', 'pharmacy');

        $this->assertSame(200, $response->getStatusCode());
    }

    // --- EnsurePhoneIsVerified ---

    public function test_phone_verified_returns_401_when_unauthenticated(): void
    {
        $middleware = new EnsurePhoneIsVerified();
        $request = Request::create('/api/test', 'GET');

        $response = $middleware->handle($request, fn() => new JsonResponse(['ok' => true]));

        $this->assertSame(401, $response->getStatusCode());
    }

    public function test_phone_verified_returns_403_when_not_verified(): void
    {
        $middleware = new EnsurePhoneIsVerified();
        $user = new class { public ?string $phone_verified_at = null; };
        $request = Request::create('/api/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $middleware->handle($request, fn() => new JsonResponse(['ok' => true]));

        $this->assertSame(403, $response->getStatusCode());
        $data = json_decode($response->getContent(), true);
        $this->assertSame('PHONE_NOT_VERIFIED', $data['error_code']);
    }

    public function test_phone_verified_passes_when_verified(): void
    {
        $middleware = new EnsurePhoneIsVerified();
        $user = new class { public ?string $phone_verified_at = '2024-01-01 00:00:00'; };
        $request = Request::create('/api/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $middleware->handle($request, fn() => new JsonResponse(['ok' => true]));

        $this->assertSame(200, $response->getStatusCode());
    }

    // --- EnsureUserIsAdmin ---

    public function test_admin_check_returns_403_when_unauthenticated(): void
    {
        $middleware = new EnsureUserIsAdmin();
        $request = Request::create('/api/test', 'GET');

        $response = $middleware->handle($request, fn() => new JsonResponse(['ok' => true]));

        $this->assertSame(403, $response->getStatusCode());
        $data = json_decode($response->getContent(), true);
        $this->assertSame('FORBIDDEN_ADMIN', $data['error_code']);
    }

    public function test_admin_check_returns_403_for_non_admin(): void
    {
        $middleware = new EnsureUserIsAdmin();
        $user = new class { public function isAdmin(): bool { return false; } };
        $request = Request::create('/api/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $middleware->handle($request, fn() => new JsonResponse(['ok' => true]));

        $this->assertSame(403, $response->getStatusCode());
    }

    public function test_admin_check_passes_for_admin(): void
    {
        $middleware = new EnsureUserIsAdmin();
        $user = new class { public function isAdmin(): bool { return true; } };
        $request = Request::create('/api/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $middleware->handle($request, fn() => new JsonResponse(['ok' => true]));

        $this->assertSame(200, $response->getStatusCode());
    }

    // --- ContentSecurityPolicy ---

    public function test_csp_headers_are_added(): void
    {
        $middleware = new ContentSecurityPolicy();
        $request = Request::create('/test', 'GET');

        $response = $middleware->handle($request, function () {
            return new JsonResponse(['ok' => true]);
        });

        $this->assertNotNull($response->headers->get('Content-Security-Policy'));
        $this->assertSame('nosniff', $response->headers->get('X-Content-Type-Options'));
        $this->assertSame('SAMEORIGIN', $response->headers->get('X-Frame-Options'));
    }

    // --- EnsurePasswordChanged ---

    public function test_password_changed_passes_when_no_user(): void
    {
        $middleware = new EnsurePasswordChanged();
        $request = Request::create('/api/test', 'GET');

        $response = $middleware->handle($request, fn() => new JsonResponse(['ok' => true]));

        $this->assertSame(200, $response->getStatusCode());
    }

    public function test_password_changed_passes_when_user_not_forced(): void
    {
        $middleware = new EnsurePasswordChanged();
        $user = new class { public bool $must_change_password = false; };
        $request = Request::create('/api/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $middleware->handle($request, fn() => new JsonResponse(['ok' => true]));

        $this->assertSame(200, $response->getStatusCode());
    }

    public function test_password_changed_blocks_when_forced(): void
    {
        $middleware = new EnsurePasswordChanged();
        $user = new class { public bool $must_change_password = true; };
        $request = Request::create('/api/other', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $middleware->handle($request, fn() => new JsonResponse(['ok' => true]));

        $this->assertSame(403, $response->getStatusCode());
        $data = json_decode($response->getContent(), true);
        $this->assertSame('PASSWORD_CHANGE_REQUIRED', $data['error_code']);
    }

    public function test_password_changed_allows_change_password_route(): void
    {
        $middleware = new EnsurePasswordChanged();
        $user = new class { public bool $must_change_password = true; };
        $request = Request::create('/api/auth/change-password', 'POST');
        $request->setUserResolver(fn() => $user);

        $response = $middleware->handle($request, fn() => new JsonResponse(['ok' => true]));

        $this->assertSame(200, $response->getStatusCode());
    }

    public function test_password_changed_allows_logout_route(): void
    {
        $middleware = new EnsurePasswordChanged();
        $user = new class { public bool $must_change_password = true; };
        $request = Request::create('/api/auth/logout', 'POST');
        $request->setUserResolver(fn() => $user);

        $response = $middleware->handle($request, fn() => new JsonResponse(['ok' => true]));

        $this->assertSame(200, $response->getStatusCode());
    }

    // --- EnsureProductionSafe ---

    public function test_production_safe_passes_in_testing(): void
    {
        $middleware = new EnsureProductionSafe();
        $request = Request::create('/api/test', 'GET');

        $response = $middleware->handle($request, fn() => new JsonResponse(['ok' => true]));

        $this->assertSame(200, $response->getStatusCode());
    }
}
