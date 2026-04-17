<?php

namespace Tests\Unit\Http\Middleware;

use App\Http\Middleware\EnsureCourierProfile;
use App\Models\Courier;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class EnsureCourierProfileTest extends TestCase
{
    use RefreshDatabase;

    protected EnsureCourierProfile $middleware;

    protected function setUp(): void
    {
        parent::setUp();
        $this->middleware = new EnsureCourierProfile();
    }

    #[Test]
    public function it_returns_401_for_unauthenticated_users()
    {
        $request = Request::create('/api/courier/test', 'GET');

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(401, $response->getStatusCode());
        $body = json_decode($response->getContent(), true);
        $this->assertEquals('UNAUTHENTICATED', $body['error_code']);
    }

    #[Test]
    public function it_returns_403_for_non_courier_users()
    {
        $user = User::factory()->create(['role' => 'customer']);

        $request = Request::create('/api/courier/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(403, $response->getStatusCode());
        $body = json_decode($response->getContent(), true);
        $this->assertEquals('FORBIDDEN_COURIER', $body['error_code']);
    }

    #[Test]
    public function it_returns_403_when_courier_profile_missing()
    {
        $user = User::factory()->create(['role' => 'courier']);
        // Note: No Courier record created

        $request = Request::create('/api/courier/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(403, $response->getStatusCode());
        $body = json_decode($response->getContent(), true);
        $this->assertEquals('COURIER_PROFILE_MISSING', $body['error_code']);
    }

    #[Test]
    public function it_returns_403_for_incomplete_kyc()
    {
        $user = User::factory()->create(['role' => 'courier']);
        Courier::factory()->create([
            'user_id' => $user->id,
            'kyc_status' => 'incomplete',
            'kyc_rejection_reason' => 'Veuillez soumettre votre CNI',
            'status' => 'active',
        ]);

        $request = Request::create('/api/courier/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(403, $response->getStatusCode());
        $body = json_decode($response->getContent(), true);
        $this->assertEquals('INCOMPLETE_KYC', $body['error_code']);
        $this->assertStringContains('CNI', $body['message']);
    }

    #[Test]
    public function it_returns_403_for_pending_approval()
    {
        $user = User::factory()->create(['role' => 'courier']);
        Courier::factory()->create([
            'user_id' => $user->id,
            'kyc_status' => 'approved',
            'status' => 'pending_approval',
        ]);

        $request = Request::create('/api/courier/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(403, $response->getStatusCode());
        $body = json_decode($response->getContent(), true);
        $this->assertEquals('PENDING_APPROVAL', $body['error_code']);
    }

    #[Test]
    public function it_returns_403_for_suspended_courier()
    {
        $user = User::factory()->create(['role' => 'courier']);
        Courier::factory()->create([
            'user_id' => $user->id,
            'kyc_status' => 'approved',
            'status' => 'suspended',
        ]);

        $request = Request::create('/api/courier/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(403, $response->getStatusCode());
        $body = json_decode($response->getContent(), true);
        $this->assertEquals('SUSPENDED', $body['error_code']);
    }

    #[Test]
    public function it_returns_403_for_rejected_courier()
    {
        $user = User::factory()->create(['role' => 'courier']);
        Courier::factory()->create([
            'user_id' => $user->id,
            'kyc_status' => 'approved',
            'status' => 'rejected',
        ]);

        $request = Request::create('/api/courier/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(403, $response->getStatusCode());
        $body = json_decode($response->getContent(), true);
        $this->assertEquals('REJECTED', $body['error_code']);
    }

    #[Test]
    public function it_passes_through_for_active_courier()
    {
        $user = User::factory()->create(['role' => 'courier']);
        Courier::factory()->create([
            'user_id' => $user->id,
            'kyc_status' => 'approved',
            'status' => 'active',
        ]);

        $request = Request::create('/api/courier/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(200, $response->getStatusCode());
    }

    #[Test]
    public function it_uses_default_kyc_message_when_no_reason()
    {
        $user = User::factory()->create(['role' => 'courier']);
        Courier::factory()->create([
            'user_id' => $user->id,
            'kyc_status' => 'incomplete',
            'kyc_rejection_reason' => null,
            'status' => 'active',
        ]);

        $request = Request::create('/api/courier/test', 'GET');
        $request->setUserResolver(fn() => $user);

        $response = $this->middleware->handle($request, function ($req) {
            return response()->json(['success' => true]);
        });

        $this->assertEquals(403, $response->getStatusCode());
        $body = json_decode($response->getContent(), true);
        $this->assertStringContains('KYC', $body['message']);
    }

    protected function assertStringContains(string $needle, string $haystack): void
    {
        $this->assertTrue(
            str_contains($haystack, $needle),
            "Failed asserting that '$haystack' contains '$needle'"
        );
    }
}
