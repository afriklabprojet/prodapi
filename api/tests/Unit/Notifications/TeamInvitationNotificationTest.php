<?php

namespace Tests\Unit\Notifications;

use App\Channels\FcmChannel;
use App\Channels\SmsChannel;
use App\Enums\PharmacyRole;
use App\Models\Pharmacy;
use App\Models\TeamInvitation;
use App\Models\User;
use App\Notifications\TeamInvitationNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TeamInvitationNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected TeamInvitation $invitation;
    protected User $inviter;
    protected Pharmacy $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();

        $this->inviter = User::factory()->create(['role' => 'pharmacy', 'name' => 'Admin Pharmacie']);
        $this->pharmacy = Pharmacy::factory()->create(['name' => 'Pharmacie Centrale', 'status' => 'approved']);

        $this->invitation = TeamInvitation::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'invited_by' => $this->inviter->id,
            'email' => 'invite@test.com',
            'phone' => '+213600000010',
            'role' => PharmacyRole::ADJOINT,
            'token' => 'test-invite-token-123',
            'status' => 'pending',
            'expires_at' => now()->addDays(7),
        ]);
    }

    public function test_can_be_constructed(): void
    {
        $notification = new TeamInvitationNotification($this->invitation);
        $this->assertInstanceOf(TeamInvitationNotification::class, $notification);
        $this->assertEquals($this->invitation->id, $notification->invitation->id);
    }

    public function test_via_includes_database(): void
    {
        $user = User::factory()->create();
        $notification = new TeamInvitationNotification($this->invitation);
        $channels = $notification->via($user);
        $this->assertContains('database', $channels);
    }

    public function test_via_includes_mail(): void
    {
        $user = User::factory()->create();
        $notification = new TeamInvitationNotification($this->invitation);
        $channels = $notification->via($user);
        $this->assertContains('mail', $channels);
    }

    public function test_via_includes_fcm_when_token_present(): void
    {
        $user = User::factory()->create(['fcm_token' => 'test-fcm-token']);
        $notification = new TeamInvitationNotification($this->invitation);
        $channels = $notification->via($user);
        $this->assertContains(FcmChannel::class, $channels);
    }

    public function test_via_excludes_fcm_when_no_token(): void
    {
        $user = User::factory()->create(['fcm_token' => null]);
        $notification = new TeamInvitationNotification($this->invitation);
        $channels = $notification->via($user);
        $this->assertNotContains(FcmChannel::class, $channels);
    }

    public function test_via_includes_sms_when_invitation_has_phone(): void
    {
        $user = User::factory()->create(['phone' => null]);
        $notification = new TeamInvitationNotification($this->invitation); // invitation has phone
        $channels = $notification->via($user);
        $this->assertContains(SmsChannel::class, $channels);
    }

    public function test_to_database_returns_array(): void
    {
        $user = User::factory()->create();
        $notification = new TeamInvitationNotification($this->invitation);
        $data = $notification->toDatabase($user);

        $this->assertIsArray($data);
        $this->assertEquals('team_invitation', $data['type']);
    }

    public function test_to_database_contains_invitation_token(): void
    {
        $user = User::factory()->create();
        $notification = new TeamInvitationNotification($this->invitation);
        $data = $notification->toDatabase($user);

        $this->assertEquals('test-invite-token-123', $data['invitation_token']);
    }

    public function test_to_database_contains_pharmacy_id(): void
    {
        $user = User::factory()->create();
        $notification = new TeamInvitationNotification($this->invitation);
        $data = $notification->toDatabase($user);

        $this->assertEquals($this->pharmacy->id, $data['pharmacy_id']);
    }

    public function test_to_database_contains_role(): void
    {
        $user = User::factory()->create();
        $notification = new TeamInvitationNotification($this->invitation);
        $data = $notification->toDatabase($user);

        $this->assertNotNull($data['role']);
    }

    public function test_to_database_contains_expires_at(): void
    {
        $user = User::factory()->create();
        $notification = new TeamInvitationNotification($this->invitation);
        $data = $notification->toDatabase($user);

        $this->assertArrayHasKey('expires_at', $data);
    }

    public function test_to_mail_returns_mail_message(): void
    {
        $user = User::factory()->create(['name' => 'Invited User']);
        $notification = new TeamInvitationNotification($this->invitation);
        $mail = $notification->toMail($user);

        $this->assertInstanceOf(\Illuminate\Notifications\Messages\MailMessage::class, $mail);
    }

    public function test_to_fcm_returns_array_with_type(): void
    {
        $user = User::factory()->create(['fcm_token' => 'test-token']);
        $notification = new TeamInvitationNotification($this->invitation);
        $data = $notification->toFcm($user);

        $this->assertIsArray($data);
        $this->assertArrayHasKey('title', $data);
        $this->assertArrayHasKey('body', $data);
        $this->assertEquals('team_invitation', $data['data']['type']);
    }

    public function test_to_sms_returns_string(): void
    {
        $user = User::factory()->create();
        $notification = new TeamInvitationNotification($this->invitation);
        $sms = $notification->toSms($user);

        $this->assertIsString($sms);
        $this->assertStringContainsString('DR PHARMA', $sms);
    }
}
