<?php

namespace Tests\Unit\Http\Middleware;

use App\Http\Middleware\CheckRole;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class CheckRoleTest extends TestCase
{
    use RefreshDatabase;

    protected CheckRole $middleware;

    protected function setUp(): void
    {
        parent::setUp();
        $this->middleware = new CheckRole();
    }

    #[Test]
    public function it_returns_401_for_unauthenticated_user(): void
    {
        $request = Request::create('/api/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        }, 'admin');

        $this->assertEquals(401, $response->getStatusCode());
        $body = json_decode($response->getContent(), true);
        $this->assertFalse($body['success']);
        $this->assertEquals('UNAUTHENTICATED', $body['error_code']);
    }

    #[Test]
    public function it_returns_403_when_role_does_not_match(): void
    {
        $user = User::factory()->create(['role' => 'customer']);

        $request = Request::create('/api/admin/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        }, 'admin');

        $this->assertEquals(403, $response->getStatusCode());
        $body = json_decode($response->getContent(), true);
        $this->assertFalse($body['success']);
        $this->assertEquals('FORBIDDEN_ROLE', $body['error_code']);
        $this->assertStringContainsString('admin', $body['message']);
    }

    #[Test]
    public function it_passes_through_when_role_matches(): void
    {
        $user = User::factory()->create(['role' => 'admin']);

        $request = Request::create('/api/admin/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        }, 'admin');

        $this->assertEquals(200, $response->getStatusCode());
        $body = json_decode($response->getContent(), true);
        $this->assertTrue($body['success']);
    }

    #[Test]
    public function it_passes_through_when_one_of_multiple_roles_matches(): void
    {
        $user = User::factory()->create(['role' => 'pharmacy']);

        $request = Request::create('/api/pharmacy/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        }, 'admin', 'pharmacy');

        $this->assertEquals(200, $response->getStatusCode());
    }

    #[Test]
    public function it_blocks_when_none_of_multiple_roles_match(): void
    {
        $user = User::factory()->create(['role' => 'customer']);

        $request = Request::create('/api/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        }, 'admin', 'pharmacy');

        $this->assertEquals(403, $response->getStatusCode());
        $body = json_decode($response->getContent(), true);
        $this->assertStringContainsString('admin', $body['message']);
        $this->assertStringContainsString('pharmacy', $body['message']);
    }

    #[Test]
    public function it_passes_for_courier_role(): void
    {
        $user = User::factory()->create(['role' => 'courier']);

        $request = Request::create('/api/courier/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        }, 'courier');

        $this->assertEquals(200, $response->getStatusCode());
    }
}
