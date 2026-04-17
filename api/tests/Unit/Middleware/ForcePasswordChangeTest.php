<?php

namespace Tests\Unit\Middleware;

use App\Http\Middleware\ForcePasswordChange;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Http\RedirectResponse;
use Tests\TestCase;

class ForcePasswordChangeTest extends TestCase
{
    private ForcePasswordChange $middleware;

    protected function setUp(): void
    {
        parent::setUp();
        $this->middleware = new ForcePasswordChange();
    }

    public function test_passes_through_for_guest(): void
    {
        $request = Request::create('/admin/dashboard', 'GET');
        $request->setUserResolver(fn() => null);

        $response = $this->middleware->handle($request, function () {
            return new Response('OK', 200);
        });

        $this->assertEquals(200, $response->getStatusCode());
    }

    public function test_passes_through_when_no_password_change_required(): void
    {
        $user = new User();
        $user->must_change_password = false;

        $request = Request::create('/admin/dashboard', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function () {
            return new Response('OK', 200);
        });

        $this->assertEquals(200, $response->getStatusCode());
    }

    public function test_redirects_when_password_change_required(): void
    {
        $user = new User();
        $user->must_change_password = true;

        $request = Request::create('/admin/dashboard', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function () {
            return new Response('OK', 200);
        });

        $this->assertInstanceOf(RedirectResponse::class, $response);
        $this->assertStringContains('/admin/force-change-password', $response->getTargetUrl());
    }

    public function test_allows_change_password_page(): void
    {
        $user = new User();
        $user->must_change_password = true;

        $request = Request::create('/admin/force-change-password', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function () {
            return new Response('OK', 200);
        });

        $this->assertEquals(200, $response->getStatusCode());
    }

    public function test_allows_logout_page(): void
    {
        $user = new User();
        $user->must_change_password = true;

        $request = Request::create('/admin/logout', 'POST');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function () {
            return new Response('OK', 200);
        });

        $this->assertEquals(200, $response->getStatusCode());
    }

    public function test_allows_livewire_requests(): void
    {
        $user = new User();
        $user->must_change_password = true;

        $request = Request::create('/livewire/update', 'POST');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function () {
            return new Response('OK', 200);
        });

        $this->assertEquals(200, $response->getStatusCode());
    }

    private function assertStringContains(string $needle, string $haystack): void
    {
        $this->assertTrue(
            str_contains($haystack, $needle),
            "Failed asserting that '$haystack' contains '$needle'"
        );
    }
}
