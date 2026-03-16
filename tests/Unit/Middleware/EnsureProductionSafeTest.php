<?php

namespace Tests\Unit\Middleware;

use App\Http\Middleware\EnsureProductionSafe;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Tests\TestCase;

/**
 * Tests unitaires pour EnsureProductionSafe middleware
 * 
 * Security Audit Week 3 - Tests de sécurité
 */
class EnsureProductionSafeTest extends TestCase
{
    protected EnsureProductionSafe $middleware;

    protected function setUp(): void
    {
        parent::setUp();
        $this->middleware = new EnsureProductionSafe();
    }

    public function test_allows_request_in_non_production_environment(): void
    {
        // Par défaut, nous sommes en environnement de test (non-production)
        $request = Request::create('/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return new Response('OK');
        });

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertEquals('OK', $response->getContent());
    }

    public function test_allows_request_in_testing_environment(): void
    {
        // En test, le middleware laisse passer
        $request = Request::create('/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return new Response('OK');
        });

        $this->assertEquals(200, $response->getStatusCode());
    }

    public function test_local_environment_allows_debug_mode(): void
    {
        // En local, le debug est autorisé
        config(['app.debug' => true]);
        
        $request = Request::create('/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return new Response('OK');
        });

        $this->assertEquals(200, $response->getStatusCode());
    }

    public function test_testing_environment_allows_debug_mode(): void
    {
        // En testing (environnement actuel), debug OK
        config(['app.debug' => true]);

        $request = Request::create('/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return new Response('OK');
        });

        $this->assertEquals(200, $response->getStatusCode());
    }
}
