<?php

namespace Tests\Unit\Middleware;

use App\Http\Middleware\ApiSecurityHeaders;
use App\Http\Middleware\ApiVersionMiddleware;
use App\Http\Middleware\IdempotencyMiddleware;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class MiddlewareTest extends TestCase
{
    // --- ApiSecurityHeaders ---

    public function test_security_headers_are_added(): void
    {
        $middleware = new ApiSecurityHeaders();
        $request = Request::create('/api/test', 'GET');

        $response = $middleware->handle($request, function () {
            return new JsonResponse(['ok' => true]);
        });

        $this->assertSame('nosniff', $response->headers->get('X-Content-Type-Options'));
        $this->assertSame('DENY', $response->headers->get('X-Frame-Options'));
        $this->assertStringContainsString('max-age=', $response->headers->get('Strict-Transport-Security'));
        $this->assertSame('strict-origin-when-cross-origin', $response->headers->get('Referrer-Policy'));
    }

    // --- ApiVersionMiddleware ---

    public function test_version_headers_are_added(): void
    {
        $middleware = new ApiVersionMiddleware();
        $request = Request::create('/api/test', 'GET');

        $response = $middleware->handle($request, function () {
            return new JsonResponse(['ok' => true]);
        });

        $this->assertSame('v1', $response->headers->get('X-API-Version'));
        $this->assertSame('v1', $response->headers->get('X-API-Min-Version'));
    }

    public function test_version_middleware_no_deprecation_for_current(): void
    {
        $middleware = new ApiVersionMiddleware();
        $request = Request::create('/api/test', 'GET');
        $request->headers->set('X-API-Version', 'v1');

        $response = $middleware->handle($request, function () {
            return new JsonResponse(['ok' => true]);
        });

        $this->assertNull($response->headers->get('X-API-Deprecated'));
    }

    // --- IdempotencyMiddleware ---

    public function test_idempotency_passes_through_get_requests(): void
    {
        $middleware = new IdempotencyMiddleware();
        $request = Request::create('/api/orders', 'GET');

        $response = $middleware->handle($request, function () {
            return new JsonResponse(['data' => 'result']);
        });

        $this->assertSame(200, $response->getStatusCode());
    }

    public function test_idempotency_passes_through_post_without_key(): void
    {
        $middleware = new IdempotencyMiddleware();
        $request = Request::create('/api/orders', 'POST');

        $response = $middleware->handle($request, function () {
            return new JsonResponse(['created' => true], 201);
        });

        $this->assertSame(201, $response->getStatusCode());
    }

    public function test_idempotency_caches_successful_response(): void
    {
        Cache::flush();
        $middleware = new IdempotencyMiddleware();

        $key = 'test-unique-key-' . uniqid();
        $request = Request::create('/api/orders', 'POST');
        $request->headers->set('Idempotency-Key', $key);

        // First call
        $response = $middleware->handle($request, function () {
            return new JsonResponse(['created' => true], 201);
        });

        $this->assertSame(201, $response->getStatusCode());
    }

    public function test_idempotency_replays_cached_response(): void
    {
        Cache::flush();
        $middleware = new IdempotencyMiddleware();
        $key = 'replay-key-' . uniqid();

        $request1 = Request::create('/api/orders', 'POST');
        $request1->headers->set('Idempotency-Key', $key);

        // First call
        $middleware->handle($request1, function () {
            return new JsonResponse(['created' => true], 201);
        });

        // Second call with same key
        $request2 = Request::create('/api/orders', 'POST');
        $request2->headers->set('Idempotency-Key', $key);

        $response2 = $middleware->handle($request2, function () {
            return new JsonResponse(['should_not_reach' => true], 200);
        });

        $this->assertSame('true', $response2->headers->get('X-Idempotent-Replay'));
    }

    public function test_idempotency_does_not_cache_error_responses(): void
    {
        Cache::flush();
        $middleware = new IdempotencyMiddleware();
        $key = 'error-key-' . uniqid();

        $request = Request::create('/api/orders', 'POST');
        $request->headers->set('Idempotency-Key', $key);

        // First call returns error
        $middleware->handle($request, function () {
            return new JsonResponse(['error' => true], 400);
        });

        // Second call should go through handler again (not cached)
        $request2 = Request::create('/api/orders', 'POST');
        $request2->headers->set('Idempotency-Key', $key);

        $callCount = 0;
        $response2 = $middleware->handle($request2, function () use (&$callCount) {
            $callCount++;
            return new JsonResponse(['retry' => true], 200);
        });

        $this->assertSame(1, $callCount);
    }

    public function test_idempotency_works_with_x_idempotency_key_header(): void
    {
        Cache::flush();
        $middleware = new IdempotencyMiddleware();

        $key = 'x-test-key-' . uniqid();
        $request = Request::create('/api/orders', 'POST');
        $request->headers->set('X-Idempotency-Key', $key);

        $response = $middleware->handle($request, function () {
            return new JsonResponse(['ok' => true], 200);
        });

        $this->assertSame(200, $response->getStatusCode());
    }
}
