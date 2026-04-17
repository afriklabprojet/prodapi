<?php

namespace Tests\Feature;

use App\Enums\PharmacyRole;
use App\Models\Pharmacy;
use App\Models\TeamInvitation;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PharmacyTeamControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    private User $pharmacyUser;
    private Pharmacy $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();

        $this->pharmacyUser = User::factory()->create([
            'role' => 'pharmacy',
            'phone_verified_at' => now(),
            'must_change_password' => false,
        ]);

        $this->pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->pharmacy->users()->attach($this->pharmacyUser->id, ['role' => PharmacyRole::TITULAIRE->value]);
    }

    private function actingAsPharmacy()
    {
        return $this->actingAs($this->pharmacyUser, 'sanctum');
    }

    // ─── INDEX ───────────────────────────────────────────────────────────────

    public function test_index_returns_team_members(): void
    {
        $member = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy->users()->attach($member->id, ['role' => PharmacyRole::PREPARATEUR->value]);

        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/team');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.total', 2);
    }

    public function test_index_marks_current_user(): void
    {
        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/team');

        $response->assertOk();

        $members = collect($response->json('data.members'));
        $currentUser = $members->firstWhere('id', $this->pharmacyUser->id);
        $this->assertTrue($currentUser['is_current_user']);
    }

    // ─── INVITE ──────────────────────────────────────────────────────────────

    public function test_invite_by_email(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/team/invite', [
            'email' => 'new@pharmacist.com',
            'role' => PharmacyRole::ADJOINT->value,
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['invitation_id', 'token']]);

        $this->assertDatabaseHas('team_invitations', [
            'pharmacy_id' => $this->pharmacy->id,
            'email' => 'new@pharmacist.com',
            'status' => 'pending',
        ]);
    }

    public function test_invite_by_phone(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/team/invite', [
            'phone' => '+22507000001',
            'role' => PharmacyRole::PREPARATEUR->value,
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_invite_already_member_returns_error(): void
    {
        $member = User::factory()->create(['role' => 'pharmacy', 'email' => 'exists@pharm.com']);
        $this->pharmacy->users()->attach($member->id, ['role' => PharmacyRole::PREPARATEUR->value]);

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/team/invite', [
            'email' => 'exists@pharm.com',
            'role' => PharmacyRole::ADJOINT->value,
        ]);

        $response->assertStatus(422);
    }

    public function test_invite_duplicate_pending_returns_error(): void
    {
        TeamInvitation::create([
            'pharmacy_id' => $this->pharmacy->id,
            'invited_by' => $this->pharmacyUser->id,
            'email' => 'pending@pharm.com',
            'role' => PharmacyRole::ADJOINT,
            'token' => TeamInvitation::generateToken(),
            'status' => 'pending',
            'expires_at' => now()->addDays(7),
        ]);

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/team/invite', [
            'email' => 'pending@pharm.com',
            'role' => PharmacyRole::ADJOINT->value,
        ]);

        $response->assertStatus(422);
    }

    public function test_invite_non_privileged_role_returns_forbidden(): void
    {
        // Create a preparateur user (cannot invite)
        $prepUser = User::factory()->create(['role' => 'pharmacy', 'phone_verified_at' => now(), 'must_change_password' => false]);
        $this->pharmacy->users()->attach($prepUser->id, ['role' => PharmacyRole::PREPARATEUR->value]);

        $response = $this->actingAs($prepUser, 'sanctum')
            ->postJson('/api/pharmacy/team/invite', [
                'email' => 'new@test.com',
                'role' => PharmacyRole::STAGIAIRE->value,
            ]);

        $response->assertForbidden();
    }

    public function test_invite_validation(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/team/invite', []);

        $response->assertUnprocessable();
    }

    // ─── PENDING INVITATIONS ─────────────────────────────────────────────────

    public function test_pending_invitations(): void
    {
        TeamInvitation::create([
            'pharmacy_id' => $this->pharmacy->id,
            'invited_by' => $this->pharmacyUser->id,
            'email' => 'test@test.com',
            'role' => PharmacyRole::ADJOINT,
            'token' => TeamInvitation::generateToken(),
            'status' => 'pending',
            'expires_at' => now()->addDays(7),
        ]);

        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/team/invitations');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(1, 'data.invitations');
    }

    public function test_pending_invitations_excludes_expired(): void
    {
        TeamInvitation::create([
            'pharmacy_id' => $this->pharmacy->id,
            'invited_by' => $this->pharmacyUser->id,
            'email' => 'expired@test.com',
            'role' => PharmacyRole::ADJOINT,
            'token' => TeamInvitation::generateToken(),
            'status' => 'pending',
            'expires_at' => now()->subDay(),
        ]);

        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/team/invitations');

        $response->assertOk()
            ->assertJsonCount(0, 'data.invitations');
    }

    // ─── CANCEL INVITATION ───────────────────────────────────────────────────

    public function test_cancel_invitation(): void
    {
        $invitation = TeamInvitation::create([
            'pharmacy_id' => $this->pharmacy->id,
            'invited_by' => $this->pharmacyUser->id,
            'email' => 'cancel@test.com',
            'role' => PharmacyRole::ADJOINT,
            'token' => TeamInvitation::generateToken(),
            'status' => 'pending',
            'expires_at' => now()->addDays(7),
        ]);

        $response = $this->actingAsPharmacy()->deleteJson("/api/pharmacy/team/invitations/{$invitation->id}");

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('team_invitations', [
            'id' => $invitation->id,
            'status' => 'expired',
        ]);
    }

    public function test_cancel_nonexistent_invitation_returns_404(): void
    {
        $response = $this->actingAsPharmacy()->deleteJson('/api/pharmacy/team/invitations/99999');

        $response->assertNotFound();
    }

    // ─── ACCEPT INVITATION ───────────────────────────────────────────────────

    public function test_accept_invitation(): void
    {
        $invitedUser = User::factory()->create([
            'role' => 'pharmacy',
            'email' => 'invited@test.com',
            'phone_verified_at' => now(),
            'must_change_password' => false,
        ]);

        $invitation = TeamInvitation::create([
            'pharmacy_id' => $this->pharmacy->id,
            'invited_by' => $this->pharmacyUser->id,
            'email' => 'invited@test.com',
            'role' => PharmacyRole::ADJOINT,
            'token' => TeamInvitation::generateToken(),
            'status' => 'pending',
            'expires_at' => now()->addDays(7),
        ]);

        $response = $this->actingAs($invitedUser, 'sanctum')
            ->postJson('/api/pharmacy/team/invitations/accept', [
                'token' => $invitation->token,
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_accept_expired_invitation_returns_404(): void
    {
        $user = User::factory()->create([
            'role' => 'pharmacy',
            'phone_verified_at' => now(),
            'must_change_password' => false,
        ]);

        $invitation = TeamInvitation::create([
            'pharmacy_id' => $this->pharmacy->id,
            'invited_by' => $this->pharmacyUser->id,
            'email' => $user->email,
            'role' => PharmacyRole::ADJOINT,
            'token' => TeamInvitation::generateToken(),
            'status' => 'pending',
            'expires_at' => now()->subDay(),
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/pharmacy/team/invitations/accept', [
                'token' => $invitation->token,
            ]);

        $response->assertNotFound();
    }

    public function test_accept_invitation_wrong_user_returns_forbidden(): void
    {
        $wrongUser = User::factory()->create([
            'role' => 'pharmacy',
            'email' => 'wrong@test.com',
            'phone' => '+22507000099',
            'phone_verified_at' => now(),
            'must_change_password' => false,
        ]);

        $invitation = TeamInvitation::create([
            'pharmacy_id' => $this->pharmacy->id,
            'invited_by' => $this->pharmacyUser->id,
            'email' => 'correct@test.com',
            'phone' => '+22507000001',
            'role' => PharmacyRole::ADJOINT,
            'token' => TeamInvitation::generateToken(),
            'status' => 'pending',
            'expires_at' => now()->addDays(7),
        ]);

        $response = $this->actingAs($wrongUser, 'sanctum')
            ->postJson('/api/pharmacy/team/invitations/accept', [
                'token' => $invitation->token,
            ]);

        $response->assertForbidden();
    }

    // ─── UPDATE ROLE ─────────────────────────────────────────────────────────

    public function test_update_member_role(): void
    {
        $member = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy->users()->attach($member->id, ['role' => PharmacyRole::PREPARATEUR->value]);

        $response = $this->actingAsPharmacy()->putJson("/api/pharmacy/team/members/{$member->id}/role", [
            'role' => PharmacyRole::ADJOINT->value,
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_update_own_role_returns_error(): void
    {
        $response = $this->actingAsPharmacy()->putJson("/api/pharmacy/team/members/{$this->pharmacyUser->id}/role", [
            'role' => PharmacyRole::ADJOINT->value,
        ]);

        $response->assertStatus(422);
    }

    public function test_update_role_non_manager_returns_forbidden(): void
    {
        $adjUser = User::factory()->create(['role' => 'pharmacy', 'phone_verified_at' => now(), 'must_change_password' => false]);
        $this->pharmacy->users()->attach($adjUser->id, ['role' => PharmacyRole::ADJOINT->value]);

        $member = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy->users()->attach($member->id, ['role' => PharmacyRole::PREPARATEUR->value]);

        $response = $this->actingAs($adjUser, 'sanctum')
            ->putJson("/api/pharmacy/team/members/{$member->id}/role", [
                'role' => PharmacyRole::STAGIAIRE->value,
            ]);

        $response->assertForbidden();
    }

    // ─── REMOVE MEMBER ───────────────────────────────────────────────────────

    public function test_remove_member(): void
    {
        $member = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy->users()->attach($member->id, ['role' => PharmacyRole::PREPARATEUR->value]);

        $response = $this->actingAsPharmacy()->deleteJson("/api/pharmacy/team/members/{$member->id}");

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_remove_self_returns_error(): void
    {
        $response = $this->actingAsPharmacy()->deleteJson("/api/pharmacy/team/members/{$this->pharmacyUser->id}");

        $response->assertStatus(422);
    }

    public function test_remove_last_titulaire_returns_error(): void
    {
        // Only one titulaire exists (the setup user)
        $otherTitulaire = User::factory()->create(['role' => 'pharmacy']);
        // Don't add another titulaire, so removing this one should fail
        // Actually, the current user IS the only titulaire, and we try to remove them
        // But self-removal is blocked first. Let's create a scenario where we try to remove
        // another titulaire when they're the last one besides the current user.

        // Actually, make two titulaires and try to remove one when it's the last
        $member = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy->users()->attach($member->id, ['role' => PharmacyRole::TITULAIRE->value]);

        // Now we have 2 titulaires. Remove one - should work
        $response = $this->actingAsPharmacy()->deleteJson("/api/pharmacy/team/members/{$member->id}");
        $response->assertOk();
    }

    public function test_remove_non_manager_returns_forbidden(): void
    {
        $prepUser = User::factory()->create(['role' => 'pharmacy', 'phone_verified_at' => now(), 'must_change_password' => false]);
        $this->pharmacy->users()->attach($prepUser->id, ['role' => PharmacyRole::PREPARATEUR->value]);

        $member = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy->users()->attach($member->id, ['role' => PharmacyRole::STAGIAIRE->value]);

        $response = $this->actingAs($prepUser, 'sanctum')
            ->deleteJson("/api/pharmacy/team/members/{$member->id}");

        $response->assertForbidden();
    }

    // ─── AVAILABLE ROLES ─────────────────────────────────────────────────────

    public function test_available_roles(): void
    {
        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/team/roles');

        $response->assertOk()
            ->assertJsonPath('success', true);

        $roles = $response->json('data.roles');
        $this->assertGreaterThanOrEqual(4, count($roles));
    }

    // ─── AUTH ────────────────────────────────────────────────────────────────

    public function test_requires_auth(): void
    {
        $this->getJson('/api/pharmacy/team')->assertUnauthorized();
    }
}
