<?php

namespace Tests\Unit\Middleware;

use App\Http\Middleware\CheckRole;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Tests\TestCase;

/**
 * Tests unitaires pour CheckRole middleware
 * 
 * Security Audit Week 3 - Tests de sécurité
 */
class CheckRoleTest extends TestCase
{
    use RefreshDatabase;

    protected CheckRole $middleware;

    protected function setUp(): void
    {
        parent::setUp();
        $this->middleware = new CheckRole();
    }

    public function test_allows_user_with_matching_role(): void
    {
        $user = User::factory()->create(['role' => 'admin']);

        $request = Request::create('/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return new Response('OK');
        }, 'admin');

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertEquals('OK', $response->getContent());
    }

    public function test_blocks_user_with_non_matching_role(): void
    {
        $user = User::factory()->create(['role' => 'customer']);

        $request = Request::create('/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return new Response('OK');
        }, 'admin');

        $this->assertEquals(403, $response->getStatusCode());
        
        $data = json_decode($response->getContent(), true);
        $this->assertFalse($data['success']);
        $this->assertStringContainsString('admin', $data['message']);
    }

    public function test_allows_user_with_one_of_multiple_roles(): void
    {
        $user = User::factory()->create(['role' => 'pharmacy']);

        $request = Request::create('/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return new Response('OK');
        }, 'admin', 'pharmacy', 'courier');

        $this->assertEquals(200, $response->getStatusCode());
    }

    public function test_blocks_user_with_none_of_multiple_roles(): void
    {
        $user = User::factory()->create(['role' => 'customer']);

        $request = Request::create('/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return new Response('OK');
        }, 'admin', 'pharmacy');

        $this->assertEquals(403, $response->getStatusCode());
    }

    public function test_blocks_unauthenticated_request(): void
    {
        $request = Request::create('/test', 'GET');
        $request->setUserResolver(fn() => null);

        $response = $this->middleware->handle($request, function ($req) {
            return new Response('OK');
        }, 'admin');

        $this->assertEquals(401, $response->getStatusCode());
        
        $data = json_decode($response->getContent(), true);
        $this->assertFalse($data['success']);
    }

    public function test_admin_role_check(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $customer = User::factory()->create(['role' => 'customer']);

        $request1 = Request::create('/test', 'GET');
        $request1->setUserResolver(fn() => $admin);

        $request2 = Request::create('/test', 'GET');
        $request2->setUserResolver(fn() => $customer);

        $response1 = $this->middleware->handle($request1, fn() => new Response('OK'), 'admin');
        $response2 = $this->middleware->handle($request2, fn() => new Response('OK'), 'admin');

        $this->assertEquals(200, $response1->getStatusCode());
        $this->assertEquals(403, $response2->getStatusCode());
    }

    public function test_courier_role_check(): void
    {
        $courier = User::factory()->create(['role' => 'courier']);

        $request = Request::create('/test', 'GET');
        $request->setUserResolver(fn() => $courier);

        $response = $this->middleware->handle($request, fn() => new Response('OK'), 'courier');

        $this->assertEquals(200, $response->getStatusCode());
    }

    public function test_pharmacy_role_check(): void
    {
        $pharmacy = User::factory()->create(['role' => 'pharmacy']);

        $request = Request::create('/test', 'GET');
        $request->setUserResolver(fn() => $pharmacy);

        $response = $this->middleware->handle($request, fn() => new Response('OK'), 'pharmacy');

        $this->assertEquals(200, $response->getStatusCode());
    }

    public function test_returns_json_response(): void
    {
        $user = User::factory()->create(['role' => 'customer']);

        $request = Request::create('/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, fn() => new Response('OK'), 'admin');

        $this->assertJson($response->getContent());
    }
}
