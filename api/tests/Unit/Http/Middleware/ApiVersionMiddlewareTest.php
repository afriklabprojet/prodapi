<?php

namespace Tests\Unit\Http\Middleware;

use App\Http\Middleware\ApiVersionMiddleware;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Tests\TestCase;

class ApiVersionMiddlewareTest extends TestCase
{
    private function runMiddleware(Request $request): Response
    {
        $middleware = new ApiVersionMiddleware();
        $response = new Response('OK', 200);

        return $middleware->handle($request, fn() => $response);
    }

    public function test_adds_x_api_version_header(): void
    {
        $request = Request::create('/api/test', 'GET');
        $response = $this->runMiddleware($request);

        $this->assertTrue($response->headers->has('X-API-Version'));
        $this->assertNotEmpty($response->headers->get('X-API-Version'));
    }

    public function test_adds_x_api_min_version_header(): void
    {
        $request = Request::create('/api/test', 'GET');
        $response = $this->runMiddleware($request);

        $this->assertTrue($response->headers->has('X-API-Min-Version'));
        $this->assertNotEmpty($response->headers->get('X-API-Min-Version'));
    }

    public function test_current_version_is_v1(): void
    {
        $request = Request::create('/api/test', 'GET');
        $response = $this->runMiddleware($request);

        $this->assertEquals('v1', $response->headers->get('X-API-Version'));
    }

    public function test_min_version_is_v1(): void
    {
        $request = Request::create('/api/test', 'GET');
        $response = $this->runMiddleware($request);

        $this->assertEquals('v1', $response->headers->get('X-API-Min-Version'));
    }

    public function test_does_not_add_deprecated_header_for_current_version(): void
    {
        $request = Request::create('/api/test', 'GET');
        $request->headers->set('X-API-Version', 'v1');
        $response = $this->runMiddleware($request);

        $this->assertFalse($response->headers->has('X-API-Deprecated'));
    }

    public function test_passes_through_response_unchanged(): void
    {
        $request = Request::create('/api/test', 'GET');
        $response = $this->runMiddleware($request);

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertEquals('OK', $response->getContent());
    }

    public function test_reads_version_from_query_string(): void
    {
        $request = Request::create('/api/test?api_version=v1', 'GET');
        $response = $this->runMiddleware($request);

        // Non-deprecated version: no deprecated header
        $this->assertFalse($response->headers->has('X-API-Deprecated'));
    }

    public function test_works_on_post_requests(): void
    {
        $request = Request::create('/api/orders', 'POST');
        $response = $this->runMiddleware($request);

        $this->assertTrue($response->headers->has('X-API-Version'));
        $this->assertTrue($response->headers->has('X-API-Min-Version'));
    }
}
