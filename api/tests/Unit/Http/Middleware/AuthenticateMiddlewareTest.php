<?php

namespace Tests\Unit\Http\Middleware;

use App\Http\Middleware\Authenticate;
use Illuminate\Http\Request;
use ReflectionClass;
use Tests\TestCase;

class AuthenticateMiddlewareTest extends TestCase
{
    private function callRedirectTo(Request $request): ?string
    {
        $middleware = new Authenticate($this->app['auth']);
        $reflection = new ReflectionClass($middleware);
        $method = $reflection->getMethod('redirectTo');
        $method->setAccessible(true);

        return $method->invoke($middleware, $request);
    }

    public function test_api_request_returns_null(): void
    {
        $request = Request::create('/api/v1/orders', 'GET');

        $this->assertNull($this->callRedirectTo($request));
    }

    public function test_json_request_returns_null(): void
    {
        $request = Request::create('/some-page', 'GET');
        $request->headers->set('Accept', 'application/json');

        $this->assertNull($this->callRedirectTo($request));
    }

    public function test_web_request_returns_finance_login(): void
    {
        $request = Request::create('/admin/dashboard', 'GET');
        $request->headers->set('Accept', 'text/html');

        $this->assertSame('/finance/login', $this->callRedirectTo($request));
    }

    public function test_api_prefix_variations(): void
    {
        $paths = ['/api/users', '/api/admin/orders', '/api/v1/health'];
        foreach ($paths as $path) {
            $request = Request::create($path, 'GET');
            $this->assertNull(
                $this->callRedirectTo($request),
                "Expected null for API path: {$path}"
            );
        }
    }

    public function test_web_routes_redirect_to_finance_login(): void
    {
        $paths = ['/dashboard', '/settings', '/admin'];
        foreach ($paths as $path) {
            $request = Request::create($path, 'GET');
            $request->headers->set('Accept', 'text/html');
            $this->assertSame(
                '/finance/login',
                $this->callRedirectTo($request),
                "Expected /finance/login for web path: {$path}"
            );
        }
    }
}
