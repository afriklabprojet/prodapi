<?php

namespace Tests\Unit\Http\Middleware;

use App\Http\Middleware\ApiSecurityHeaders;
use Illuminate\Http\Request;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class ApiSecurityHeadersTest extends TestCase
{
    protected ApiSecurityHeaders $middleware;

    protected function setUp(): void
    {
        parent::setUp();
        $this->middleware = new ApiSecurityHeaders();
    }

    #[Test]
    public function it_adds_x_content_type_options_header(): void
    {
        $request = Request::create('/api/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals('nosniff', $response->headers->get('X-Content-Type-Options'));
    }

    #[Test]
    public function it_adds_x_frame_options_header(): void
    {
        $request = Request::create('/api/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals('DENY', $response->headers->get('X-Frame-Options'));
    }

    #[Test]
    public function it_adds_strict_transport_security_header(): void
    {
        $request = Request::create('/api/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $sts = $response->headers->get('Strict-Transport-Security');
        $this->assertStringContainsString('max-age=31536000', $sts);
        $this->assertStringContainsString('includeSubDomains', $sts);
    }

    #[Test]
    public function it_adds_referrer_policy_header(): void
    {
        $request = Request::create('/api/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(
            'strict-origin-when-cross-origin',
            $response->headers->get('Referrer-Policy')
        );
    }

    #[Test]
    public function it_passes_request_through_to_next(): void
    {
        $request = Request::create('/api/test', 'GET');

        $wasCalled = false;
        $response = $this->middleware->handle($request, function ($req) use (&$wasCalled) {
            $wasCalled = true;
            return response()->json(['data' => 'test'], 200);
        });

        $this->assertTrue($wasCalled);
        $this->assertEquals(200, $response->getStatusCode());
    }

    #[Test]
    public function it_does_not_modify_response_body(): void
    {
        $request = Request::create('/api/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['key' => 'value']);
        });

        $body = json_decode($response->getContent(), true);
        $this->assertEquals(['key' => 'value'], $body);
    }
}
