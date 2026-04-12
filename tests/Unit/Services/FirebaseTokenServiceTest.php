<?php

namespace Tests\Unit\Services;

use App\Services\FirebaseTokenService;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Contract\Auth as FirebaseAuth;
use Lcobucci\JWT\UnencryptedToken;
use Mockery;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class FirebaseTokenServiceTest extends TestCase
{
    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }

    #[Test]
    public function it_generates_custom_token_successfully(): void
    {
        $mockToken = Mockery::mock(UnencryptedToken::class);
        $mockToken->shouldReceive('toString')->andReturn('firebase-custom-token-abc123');

        $mockAuth = Mockery::mock(FirebaseAuth::class);
        $mockAuth->shouldReceive('createCustomToken')
            ->once()
            ->withArgs(function ($uid, $claims) {
                return $uid === 'user_42'
                    && $claims['role'] === 'customer'
                    && $claims['user_id'] === 42;
            })
            ->andReturn($mockToken);

        $service = new FirebaseTokenService($mockAuth);
        $token = $service->generateCustomToken(42, 'customer');

        $this->assertEquals('firebase-custom-token-abc123', $token);
    }

    #[Test]
    public function it_includes_additional_claims_in_token(): void
    {
        $mockToken = Mockery::mock(UnencryptedToken::class);
        $mockToken->shouldReceive('toString')->andReturn('token-xyz');

        $mockAuth = Mockery::mock(FirebaseAuth::class);
        $mockAuth->shouldReceive('createCustomToken')
            ->once()
            ->withArgs(function ($uid, $claims) {
                return $uid === 'user_10'
                    && $claims['role'] === 'courier'
                    && $claims['user_id'] === 10
                    && $claims['courier_id'] === 5;
            })
            ->andReturn($mockToken);

        $service = new FirebaseTokenService($mockAuth);
        $token = $service->generateCustomToken(10, 'courier', ['courier_id' => 5]);

        $this->assertEquals('token-xyz', $token);
    }

    #[Test]
    public function it_returns_null_when_firebase_throws_exception(): void
    {
        Log::spy();

        $mockAuth = Mockery::mock(FirebaseAuth::class);
        $mockAuth->shouldReceive('createCustomToken')
            ->once()
            ->andThrow(new \Exception('Firebase not available'));

        $service = new FirebaseTokenService($mockAuth);
        $token = $service->generateCustomToken(1, 'customer');

        $this->assertNull($token);
        Log::shouldHaveReceived('error')->once();
    }

    #[Test]
    public function it_uses_user_prefix_in_uid(): void
    {
        $mockToken = Mockery::mock(UnencryptedToken::class);
        $mockToken->shouldReceive('toString')->andReturn('token');

        $mockAuth = Mockery::mock(FirebaseAuth::class);
        $mockAuth->shouldReceive('createCustomToken')
            ->once()
            ->withArgs(function ($uid, $claims) {
                return $uid === 'user_99';
            })
            ->andReturn($mockToken);

        $service = new FirebaseTokenService($mockAuth);
        $token = $service->generateCustomToken(99, 'pharmacy');

        $this->assertEquals('token', $token);
    }

    #[Test]
    public function it_supports_all_user_roles(): void
    {
        $roles = ['customer', 'courier', 'pharmacy', 'admin'];

        foreach ($roles as $role) {
            $mockToken = Mockery::mock(UnencryptedToken::class);
            $mockToken->shouldReceive('toString')->andReturn('token');

            $mockAuth = Mockery::mock(FirebaseAuth::class);
            $mockAuth->shouldReceive('createCustomToken')
                ->once()
                ->withArgs(function ($uid, $claims) use ($role) {
                    return $claims['role'] === $role;
                })
                ->andReturn($mockToken);

            $service = new FirebaseTokenService($mockAuth);
            $token = $service->generateCustomToken(1, $role);

            $this->assertNotNull($token, "Token should not be null for role: {$role}");
        }
    }
}
