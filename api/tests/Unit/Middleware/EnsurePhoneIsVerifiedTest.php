<?php

namespace Tests\Unit\Middleware;

use App\Http\Middleware\EnsurePhoneIsVerified;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Tests\TestCase;

/**
 * Tests unitaires pour EnsurePhoneIsVerified middleware
 * 
 * Security Audit Week 3 - Tests de sécurité
 */
class EnsurePhoneIsVerifiedTest extends TestCase
{
    use RefreshDatabase;

    protected EnsurePhoneIsVerified $middleware;

    protected function setUp(): void
    {
        parent::setUp();
        $this->middleware = new EnsurePhoneIsVerified();
    }

    public function test_allows_users_with_verified_phone(): void
    {
        $user = User::factory()->create([
            'phone_verified_at' => now(),
        ]);

        $request = Request::create('/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return new Response('OK');
        });

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertEquals('OK', $response->getContent());
    }

    public function test_blocks_users_without_verified_phone(): void
    {
        $user = User::factory()->create([
            'phone_verified_at' => null,
        ]);

        $request = Request::create('/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return new Response('OK');
        });

        $this->assertEquals(403, $response->getStatusCode());
        
        $data = json_decode($response->getContent(), true);
        $this->assertFalse($data['success']);
        $this->assertTrue($data['requires_verification']);
    }

    public function test_blocks_unauthenticated_requests(): void
    {
        $request = Request::create('/test', 'GET');
        $request->setUserResolver(fn() => null);

        $response = $this->middleware->handle($request, function ($req) {
            return new Response('OK');
        });

        $this->assertEquals(401, $response->getStatusCode());
    }

    public function test_returns_json_response_with_correct_structure(): void
    {
        $user = User::factory()->create([
            'phone_verified_at' => null,
        ]);

        $request = Request::create('/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return new Response('OK');
        });

        $data = json_decode($response->getContent(), true);
        
        $this->assertArrayHasKey('success', $data);
        $this->assertArrayHasKey('message', $data);
        $this->assertArrayHasKey('requires_verification', $data);
    }
}
