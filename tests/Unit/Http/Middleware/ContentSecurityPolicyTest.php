<?php

namespace Tests\Unit\Http\Middleware;

use App\Http\Middleware\ContentSecurityPolicy;
use Illuminate\Http\Request;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class ContentSecurityPolicyTest extends TestCase
{
    protected ContentSecurityPolicy $middleware;

    protected function setUp(): void
    {
        parent::setUp();
        $this->middleware = new ContentSecurityPolicy();
    }

    #[Test]
    public function it_adds_content_security_policy_header(): void
    {
        $request = Request::create('/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $csp = $response->headers->get('Content-Security-Policy');
        $this->assertNotNull($csp);
        $this->assertStringContainsString("default-src 'self'", $csp);
    }

    #[Test]
    public function it_adds_x_content_type_options_header(): void
    {
        $request = Request::create('/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals('nosniff', $response->headers->get('X-Content-Type-Options'));
    }

    #[Test]
    public function it_adds_x_frame_options_header(): void
    {
        $request = Request::create('/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals('SAMEORIGIN', $response->headers->get('X-Frame-Options'));
    }

    #[Test]
    public function it_adds_referrer_policy_header(): void
    {
        $request = Request::create('/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(
            'strict-origin-when-cross-origin',
            $response->headers->get('Referrer-Policy')
        );
    }

    #[Test]
    public function it_passes_request_through(): void
    {
        $request = Request::create('/test', 'GET');

        $calledWith = null;
        $response = $this->middleware->handle($request, function ($req) use (&$calledWith) {
            $calledWith = $req;
            return response()->json(['data' => 'test'], 200);
        });

        $this->assertSame($request, $calledWith);
        $this->assertEquals(200, $response->getStatusCode());
    }

    #[Test]
    public function csp_header_includes_script_src(): void
    {
        $request = Request::create('/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $csp = $response->headers->get('Content-Security-Policy');
        $this->assertStringContainsString('script-src', $csp);
    }

    #[Test]
    public function csp_header_includes_style_src(): void
    {
        $request = Request::create('/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $csp = $response->headers->get('Content-Security-Policy');
        $this->assertStringContainsString('style-src', $csp);
    }

    #[Test]
    public function csp_header_includes_frame_ancestors(): void
    {
        $request = Request::create('/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $csp = $response->headers->get('Content-Security-Policy');
        $this->assertStringContainsString('frame-ancestors', $csp);
    }
}
