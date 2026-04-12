<?php

namespace Tests\Unit\Models;

use App\Enums\PharmacyRole;
use App\Models\Pharmacy;
use App\Models\TeamInvitation;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class TeamInvitationTest extends TestCase
{
    use RefreshDatabase;

    public function test_fillable_fields(): void
    {
        $model = new TeamInvitation();
        $fillable = $model->getFillable();
        $this->assertContains('pharmacy_id', $fillable);
        $this->assertContains('invited_by', $fillable);
        $this->assertContains('email', $fillable);
        $this->assertContains('role', $fillable);
        $this->assertContains('token', $fillable);
        $this->assertContains('status', $fillable);
    }

    public function test_casts(): void
    {
        $model = new TeamInvitation();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('expires_at', $casts);
        $this->assertArrayHasKey('accepted_at', $casts);
        $this->assertArrayHasKey('role', $casts);
    }

    public function test_has_pharmacy_relationship(): void
    {
        $model = new TeamInvitation();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->pharmacy());
    }

    public function test_has_invited_by_relationship(): void
    {
        $model = new TeamInvitation();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->invitedBy());
    }

    #[Test]
    public function it_returns_true_when_invitation_is_expired(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $user = User::factory()->create();
        
        $invitation = TeamInvitation::create([
            'pharmacy_id' => $pharmacy->id,
            'invited_by' => $user->id,
            'email' => 'test@example.com',
            'role' => PharmacyRole::PREPARATEUR,
            'token' => 'test-token-expired',
            'status' => 'pending',
            'expires_at' => now()->subDay(),
        ]);

        $this->assertTrue($invitation->isExpired());
    }

    #[Test]
    public function it_returns_false_when_invitation_is_not_expired(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $user = User::factory()->create();
        
        $invitation = TeamInvitation::create([
            'pharmacy_id' => $pharmacy->id,
            'invited_by' => $user->id,
            'email' => 'test@example.com',
            'role' => PharmacyRole::PREPARATEUR,
            'token' => 'test-token-valid',
            'status' => 'pending',
            'expires_at' => now()->addDay(),
        ]);

        $this->assertFalse($invitation->isExpired());
    }

    #[Test]
    public function it_returns_true_when_invitation_is_pending(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $user = User::factory()->create();
        
        $invitation = TeamInvitation::create([
            'pharmacy_id' => $pharmacy->id,
            'invited_by' => $user->id,
            'email' => 'test@example.com',
            'role' => PharmacyRole::PREPARATEUR,
            'token' => 'test-token-pending',
            'status' => 'pending',
            'expires_at' => now()->addDay(),
        ]);

        $this->assertTrue($invitation->isPending());
    }

    #[Test]
    public function it_returns_false_when_invitation_is_expired_pending(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $user = User::factory()->create();
        
        $invitation = TeamInvitation::create([
            'pharmacy_id' => $pharmacy->id,
            'invited_by' => $user->id,
            'email' => 'test@example.com',
            'role' => PharmacyRole::PREPARATEUR,
            'token' => 'test-token-exp-pend',
            'status' => 'pending',
            'expires_at' => now()->subDay(),
        ]);

        $this->assertFalse($invitation->isPending());
    }

    #[Test]
    public function it_returns_false_when_invitation_is_not_pending_status(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $user = User::factory()->create();
        
        $invitation = TeamInvitation::create([
            'pharmacy_id' => $pharmacy->id,
            'invited_by' => $user->id,
            'email' => 'test@example.com',
            'role' => PharmacyRole::PREPARATEUR,
            'token' => 'test-token-accepted',
            'status' => 'accepted',
            'expires_at' => now()->addDay(),
        ]);

        $this->assertFalse($invitation->isPending());
    }

    #[Test]
    public function it_generates_unique_token(): void
    {
        $token1 = TeamInvitation::generateToken();
        $token2 = TeamInvitation::generateToken();

        $this->assertEquals(32, strlen($token1));
        $this->assertEquals(32, strlen($token2));
        $this->assertNotEquals($token1, $token2);
    }

    #[Test]
    public function it_accepts_invitation_and_adds_user_to_pharmacy(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $inviter = User::factory()->create();
        $invitedUser = User::factory()->create();
        
        $invitation = TeamInvitation::create([
            'pharmacy_id' => $pharmacy->id,
            'invited_by' => $inviter->id,
            'email' => $invitedUser->email,
            'role' => PharmacyRole::PREPARATEUR,
            'token' => 'test-token-accept',
            'status' => 'pending',
            'expires_at' => now()->addDay(),
        ]);

        $this->assertEquals('pending', $invitation->status);
        $this->assertNull($invitation->accepted_at);

        $invitation->accept($invitedUser);

        $invitation->refresh();
        $this->assertEquals('accepted', $invitation->status);
        $this->assertNotNull($invitation->accepted_at);

        // Verify user was added to pharmacy
        $this->assertTrue($pharmacy->users()->where('user_id', $invitedUser->id)->exists());
    }

    #[Test]
    public function it_declines_invitation(): void
    {
        $pharmacy = Pharmacy::factory()->create();
        $user = User::factory()->create();
        
        $invitation = TeamInvitation::create([
            'pharmacy_id' => $pharmacy->id,
            'invited_by' => $user->id,
            'email' => 'test@example.com',
            'role' => PharmacyRole::PREPARATEUR,
            'token' => 'test-token-decline',
            'status' => 'pending',
            'expires_at' => now()->addDay(),
        ]);

        $this->assertEquals('pending', $invitation->status);

        $invitation->decline();

        $invitation->refresh();
        $this->assertEquals('declined', $invitation->status);
    }
}
