<?php

namespace Tests\Unit\Http\Middleware;

use App\Http\Middleware\EnsurePasswordChanged;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class EnsurePasswordChangedTest extends TestCase
{
    use RefreshDatabase;

    protected EnsurePasswordChanged $middleware;

    protected function setUp(): void
    {
        parent::setUp();
        $this->middleware = new EnsurePasswordChanged();
    }

    #[Test]
    public function it_passes_through_for_guest()
    {
        $request = Request::create('/api/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(200, $response->getStatusCode());
    }

    #[Test]
    public function it_passes_through_when_password_change_not_required()
    {
        $user = User::factory()->create(['must_change_password' => false]);

        $request = Request::create('/api/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(200, $response->getStatusCode());
    }

    #[Test]
    public function it_blocks_when_password_change_required()
    {
        $user = User::factory()->create(['must_change_password' => true]);

        $request = Request::create('/api/protected', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(403, $response->getStatusCode());
        
        $body = json_decode($response->getContent(), true);
        $this->assertEquals('PASSWORD_CHANGE_REQUIRED', $body['error_code']);
        $this->assertTrue($body['must_change_password']);
    }

    #[Test]
    public function it_allows_change_password_route()
    {
        $user = User::factory()->create(['must_change_password' => true]);

        $request = Request::create('/api/auth/change-password', 'POST');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(200, $response->getStatusCode());
    }

    #[Test]
    public function it_allows_logout_route()
    {
        $user = User::factory()->create(['must_change_password' => true]);

        $request = Request::create('/api/auth/logout', 'POST');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(200, $response->getStatusCode());
    }

    #[Test]
    public function it_allows_v1_change_password_route()
    {
        $user = User::factory()->create(['must_change_password' => true]);

        $request = Request::create('/api/v1/auth/change-password', 'POST');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(200, $response->getStatusCode());
    }

    #[Test]
    public function it_allows_v1_logout_route()
    {
        $user = User::factory()->create(['must_change_password' => true]);

        $request = Request::create('/api/v1/auth/logout', 'POST');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(200, $response->getStatusCode());
    }
}
