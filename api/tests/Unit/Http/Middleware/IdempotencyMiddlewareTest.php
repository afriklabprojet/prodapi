<?php

namespace Tests\Unit\Http\Middleware;

use App\Http\Middleware\IdempotencyMiddleware;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class IdempotencyMiddlewareTest extends TestCase
{
    use RefreshDatabase;

    protected IdempotencyMiddleware $middleware;

    protected function setUp(): void
    {
        parent::setUp();
        $this->middleware = new IdempotencyMiddleware();
        Cache::flush();
    }

    #[Test]
    public function it_passes_through_get_requests()
    {
        $request = Request::create('/api/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['data' => 'test']);
        });

        $this->assertEquals(200, $response->getStatusCode());
        $this->assertEquals(['data' => 'test'], $response->original);
    }

    #[Test]
    public function it_passes_through_post_without_idempotency_key()
    {
        $request = Request::create('/api/test', 'POST', ['name' => 'test']);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['created' => true], 201);
        });

        $this->assertEquals(201, $response->getStatusCode());
    }

    #[Test]
    public function it_caches_successful_post_response()
    {
        $idempotencyKey = 'unique-key-123';
        $request = Request::create('/api/test', 'POST', ['name' => 'test']);
        $request->headers->set('Idempotency-Key', $idempotencyKey);

        // First request
        $callCount = 0;
        $handler = function ($req) use (&$callCount) {
            $callCount++;
            return response()->json(['created' => true, 'id' => 42], 201);
        };

        $response1 = $this->middleware->handle($request, $handler);
        $this->assertEquals(201, $response1->getStatusCode());
        $this->assertEquals(1, $callCount);

        // Second request with same key should return cached response
        $response2 = $this->middleware->handle($request, $handler);
        $this->assertEquals(201, $response2->getStatusCode());
        $this->assertEquals(1, $callCount); // Handler not called again
        $this->assertEquals('true', $response2->headers->get('X-Idempotent-Replay'));
    }

    #[Test]
    public function it_uses_x_idempotency_key_header()
    {
        $idempotencyKey = 'x-header-key-456';
        $request = Request::create('/api/test', 'POST');
        $request->headers->set('X-Idempotency-Key', $idempotencyKey);

        $callCount = 0;
        $handler = function ($req) use (&$callCount) {
            $callCount++;
            return response()->json(['success' => true], 200);
        };

        // First call
        $this->middleware->handle($request, $handler);
        $this->assertEquals(1, $callCount);

        // Second call with same key
        $this->middleware->handle($request, $handler);
        $this->assertEquals(1, $callCount);
    }

    #[Test]
    public function it_does_not_cache_failed_responses()
    {
        $idempotencyKey = 'error-key-789';
        $request = Request::create('/api/test', 'POST');
        $request->headers->set('Idempotency-Key', $idempotencyKey);

        $callCount = 0;
        $handler = function ($req) use (&$callCount) {
            $callCount++;
            return response()->json(['error' => 'Bad request'], 400);
        };

        // First request fails
        $this->middleware->handle($request, $handler);
        $this->assertEquals(1, $callCount);

        // Second request should also execute because errors are not cached
        $this->middleware->handle($request, $handler);
        $this->assertEquals(2, $callCount);
    }

    #[Test]
    public function it_handles_put_requests()
    {
        $idempotencyKey = 'put-key-111';
        $request = Request::create('/api/test/1', 'PUT', ['name' => 'updated']);
        $request->headers->set('Idempotency-Key', $idempotencyKey);

        $callCount = 0;
        $handler = function ($req) use (&$callCount) {
            $callCount++;
            return response()->json(['updated' => true], 200);
        };

        $this->middleware->handle($request, $handler);
        $this->assertEquals(1, $callCount);

        // Replay
        $this->middleware->handle($request, $handler);
        $this->assertEquals(1, $callCount);
    }

    #[Test]
    public function it_handles_patch_requests()
    {
        $idempotencyKey = 'patch-key-222';
        $request = Request::create('/api/test/1', 'PATCH', ['name' => 'patched']);
        $request->headers->set('Idempotency-Key', $idempotencyKey);

        $callCount = 0;
        $handler = function ($req) use (&$callCount) {
            $callCount++;
            return response()->json(['patched' => true], 200);
        };

        $this->middleware->handle($request, $handler);
        $this->assertEquals(1, $callCount);

        // Replay
        $this->middleware->handle($request, $handler);
        $this->assertEquals(1, $callCount);
    }

    #[Test]
    public function it_handles_delete_requests()
    {
        $idempotencyKey = 'delete-key-333';
        $request = Request::create('/api/test/1', 'DELETE');
        $request->headers->set('Idempotency-Key', $idempotencyKey);

        $callCount = 0;
        $handler = function ($req) use (&$callCount) {
            $callCount++;
            return response()->json(['deleted' => true], 200);
        };

        $this->middleware->handle($request, $handler);
        $this->assertEquals(1, $callCount);

        // Replay
        $this->middleware->handle($request, $handler);
        $this->assertEquals(1, $callCount);
    }

    #[Test]
    public function it_scopes_keys_by_user()
    {
        $idempotencyKey = 'user-scoped-key';

        // First user
        $user1 = \App\Models\User::factory()->create();
        $request1 = Request::create('/api/test', 'POST');
        $request1->headers->set('Idempotency-Key', $idempotencyKey);
        $request1->setUserResolver(fn() => $user1);

        $callCount = 0;
        $handler = function ($req) use (&$callCount) {
            $callCount++;
            return response()->json(['result' => $callCount], 200);
        };

        $this->middleware->handle($request1, $handler);
        $this->assertEquals(1, $callCount);

        // Different user with same key should not be cached
        $user2 = \App\Models\User::factory()->create();
        $request2 = Request::create('/api/test', 'POST');
        $request2->headers->set('Idempotency-Key', $idempotencyKey);
        $request2->setUserResolver(fn() => $user2);

        $this->middleware->handle($request2, $handler);
        $this->assertEquals(2, $callCount);
    }

    #[Test]
    public function it_returns_conflict_on_concurrent_requests()
    {
        $idempotencyKey = 'concurrent-key';
        $cacheKey = 'idempotency:' . md5($idempotencyKey . ':');

        // Simulate a lock already held
        $lock = Cache::lock($cacheKey . ':lock', 30);
        $lock->get();

        $request = Request::create('/api/test', 'POST');
        $request->headers->set('Idempotency-Key', $idempotencyKey);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['created' => true], 201);
        });

        $this->assertEquals(409, $response->getStatusCode());
        $this->assertStringContains('en cours de traitement', $response->getContent());

        $lock->release();
    }

    protected function assertStringContains(string $needle, string $haystack): void
    {
        $this->assertTrue(
            str_contains($haystack, $needle),
            "Failed asserting that '$haystack' contains '$needle'"
        );
    }
}
