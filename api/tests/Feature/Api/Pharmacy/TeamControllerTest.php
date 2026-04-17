<?php

namespace Tests\Feature\Api\Pharmacy;

use App\Enums\PharmacyRole;
use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class TeamControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Pharmacy $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->pharmacy->users()->attach($this->user->id, ['role' => 'titulaire']);
    }

    public function test_pharmacy_can_list_team_members(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/team');

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_pharmacy_can_list_available_roles(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/team/roles');

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_pharmacy_can_invite_by_email(): void
    {
        Notification::fake();

        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/team/invite', [
            'email' => 'pharmacien@example.com',
            'role' => PharmacyRole::ADJOINT->value,
        ]);

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_pharmacy_can_invite_by_phone(): void
    {
        Notification::fake();

        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/team/invite', [
            'phone' => '+2250700000001',
            'role' => PharmacyRole::PREPARATEUR->value,
        ]);

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_invite_requires_email_or_phone(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/team/invite', [
            'role' => PharmacyRole::ADJOINT->value,
        ]);

        $response->assertStatus(422);
    }

    public function test_invite_requires_role(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/team/invite', [
            'email' => 'pharmacien@example.com',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('role');
    }

    public function test_pharmacy_can_list_pending_invitations(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/team/invitations');

        $response->assertOk()->assertJsonPath('success', true);
    }

    public function test_accept_invitation_requires_token(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/team/invitations/accept', []);

        $response->assertStatus(422)->assertJsonValidationErrors('token');
    }

    public function test_accept_invitation_with_invalid_token(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/team/invitations/accept', [
            'token' => 'invalid-token',
        ]);

        $response->assertStatus(404);
    }

    public function test_unauthenticated_cannot_access_team(): void
    {
        $response = $this->getJson('/api/pharmacy/team');

        $response->assertStatus(401);
    }
}
