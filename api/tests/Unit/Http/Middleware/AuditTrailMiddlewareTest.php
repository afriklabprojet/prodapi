<?php

namespace Tests\Unit\Http\Middleware;

use App\Http\Middleware\AuditTrailMiddleware;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class AuditTrailMiddlewareTest extends TestCase
{
    use RefreshDatabase;

    protected AuditTrailMiddleware $middleware;

    protected function setUp(): void
    {
        parent::setUp();
        $this->middleware = new AuditTrailMiddleware();
    }

    #[Test]
    public function it_passes_through_request(): void
    {
        $request = Request::create('/api/admin/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(200, $response->getStatusCode());
    }

    #[Test]
    public function it_does_not_log_get_requests(): void
    {
        $user = User::factory()->create(['role' => 'admin']);
        $request = Request::create('/api/admin/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(0, DB::table('admin_audit_logs')->count());
    }

    #[Test]
    public function it_does_not_log_when_no_authenticated_user(): void
    {
        $request = Request::create('/api/admin/test', 'POST', ['data' => 'test']);

        $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true], 201);
        });

        $this->assertEquals(0, DB::table('admin_audit_logs')->count());
    }

    #[Test]
    public function it_logs_post_requests_from_authenticated_users(): void
    {
        $user = User::factory()->create(['role' => 'admin', 'name' => 'Jean Admin']);
        $request = Request::create('/api/admin/users', 'POST', ['name' => 'New User']);
        $request->setUserResolver(fn() => $user);

        $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true], 201);
        });

        $this->assertEquals(1, DB::table('admin_audit_logs')->count());

        $log = DB::table('admin_audit_logs')->first();
        $this->assertEquals($user->id, $log->user_id);
        $this->assertEquals('POST', $log->action);
        $this->assertEquals('api/admin/users', $log->url);
        $this->assertEquals(201, $log->response_status);
    }

    #[Test]
    public function it_logs_put_requests(): void
    {
        $user = User::factory()->create(['role' => 'admin']);
        $request = Request::create('/api/admin/users/1', 'PUT', ['name' => 'Updated']);
        $request->setUserResolver(fn() => $user);

        $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(1, DB::table('admin_audit_logs')->count());
        $log = DB::table('admin_audit_logs')->first();
        $this->assertEquals('PUT', $log->action);
    }

    #[Test]
    public function it_logs_delete_requests(): void
    {
        $user = User::factory()->create(['role' => 'admin']);
        $request = Request::create('/api/admin/users/1', 'DELETE');
        $request->setUserResolver(fn() => $user);

        $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(1, DB::table('admin_audit_logs')->count());
        $log = DB::table('admin_audit_logs')->first();
        $this->assertEquals('DELETE', $log->action);
    }

    #[Test]
    public function it_does_not_log_failed_requests(): void
    {
        $user = User::factory()->create(['role' => 'admin']);
        $request = Request::create('/api/admin/test', 'POST', ['data' => 'test']);
        $request->setUserResolver(fn() => $user);

        $this->middleware->handle($request, function ($req) {
            return response()->json(['error' => 'Not found'], 404);
        });

        $this->assertEquals(0, DB::table('admin_audit_logs')->count());
    }

    #[Test]
    public function it_strips_sensitive_fields_from_logged_data(): void
    {
        $user = User::factory()->create(['role' => 'admin']);
        $request = Request::create('/api/admin/test', 'POST', [
            'name' => 'Test',
            'password' => 'secret123',
            'token' => 'abc-token',
        ]);
        $request->setUserResolver(fn() => $user);

        $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true], 201);
        });

        $log = DB::table('admin_audit_logs')->first();
        $requestData = json_decode($log->request_data, true);

        $this->assertArrayHasKey('name', $requestData);
        $this->assertArrayNotHasKey('password', $requestData);
        $this->assertArrayNotHasKey('token', $requestData);
    }
}
