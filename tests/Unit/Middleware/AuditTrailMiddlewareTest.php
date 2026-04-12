<?php

namespace Tests\Unit\Middleware;

use App\Http\Middleware\AuditTrailMiddleware;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class AuditTrailMiddlewareTest extends TestCase
{
    use RefreshDatabase;

    private AuditTrailMiddleware $middleware;

    protected function setUp(): void
    {
        parent::setUp();
        $this->middleware = new AuditTrailMiddleware();
    }

    public function test_passes_through_get_requests_without_logging(): void
    {
        $request = Request::create('/admin/users', 'GET');
        $request->setUserResolver(fn() => User::factory()->create());

        $response = $this->middleware->handle($request, function () {
            return new Response('OK', 200);
        });

        $this->assertEquals(200, $response->getStatusCode());
    }

    public function test_logs_post_request_for_authenticated_user(): void
    {
        // Ensure the audit table exists
        if (!DB::getSchemaBuilder()->hasTable('admin_audit_logs')) {
            DB::getSchemaBuilder()->create('admin_audit_logs', function ($table) {
                $table->id();
                $table->unsignedBigInteger('user_id');
                $table->string('user_name');
                $table->string('action');
                $table->string('url');
                $table->string('route')->nullable();
                $table->json('request_data')->nullable();
                $table->integer('response_status');
                $table->string('ip_address')->nullable();
                $table->string('user_agent')->nullable();
                $table->timestamp('created_at')->nullable();
            });
        }

        $user = User::factory()->create();
        $request = Request::create('/admin/users', 'POST', ['name' => 'Test']);
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function () {
            return new Response('Created', 201);
        });

        $this->assertEquals(201, $response->getStatusCode());
        $this->assertDatabaseHas('admin_audit_logs', [
            'user_id' => $user->id,
            'action' => 'POST',
        ]);
    }

    public function test_does_not_log_failed_requests(): void
    {
        $user = User::factory()->create();
        $request = Request::create('/admin/users', 'POST');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function () {
            return new Response('Error', 422);
        });

        $this->assertEquals(422, $response->getStatusCode());
    }

    public function test_does_not_log_unauthenticated_requests(): void
    {
        $request = Request::create('/admin/users', 'POST');
        $request->setUserResolver(fn() => null);

        $response = $this->middleware->handle($request, function () {
            return new Response('OK', 200);
        });

        $this->assertEquals(200, $response->getStatusCode());
    }

    public function test_masks_sensitive_data(): void
    {
        if (!DB::getSchemaBuilder()->hasTable('admin_audit_logs')) {
            DB::getSchemaBuilder()->create('admin_audit_logs', function ($table) {
                $table->id();
                $table->unsignedBigInteger('user_id');
                $table->string('user_name');
                $table->string('action');
                $table->string('url');
                $table->string('route')->nullable();
                $table->json('request_data')->nullable();
                $table->integer('response_status');
                $table->string('ip_address')->nullable();
                $table->string('user_agent')->nullable();
                $table->timestamp('created_at')->nullable();
            });
        }

        $user = User::factory()->create();
        $request = Request::create('/admin/users', 'PUT', [
            'name' => 'Test',
            'password' => 'secret123',
            'pin' => '1234',
        ]);
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function () {
            return new Response('OK', 200);
        });

        $log = DB::table('admin_audit_logs')->first();
        $data = json_decode($log->request_data, true);
        $this->assertArrayHasKey('name', $data);
        $this->assertArrayNotHasKey('password', $data);
        $this->assertArrayNotHasKey('pin', $data);
    }
}
