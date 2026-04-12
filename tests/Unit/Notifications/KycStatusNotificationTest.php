<?php

namespace Tests\Unit\Notifications;

use App\Notifications\KycStatusNotification;
use App\Models\User;
use App\Channels\FcmChannel;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class KycStatusNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create([
            'role' => 'courier',
            'fcm_token' => 'test_fcm_token',
        ]);
    }

    #[Test]
    public function via_includes_database()
    {
        $notification = new KycStatusNotification('approved');
        $channels = $notification->via($this->user);

        $this->assertContains('database', $channels);
    }

    #[Test]
    public function via_includes_fcm_when_user_has_token()
    {
        $notification = new KycStatusNotification('approved');
        $channels = $notification->via($this->user);

        $this->assertContains(FcmChannel::class, $channels);
    }

    #[Test]
    public function via_excludes_fcm_when_no_token()
    {
        $userNoFcm = User::factory()->create(['fcm_token' => null]);
        $notification = new KycStatusNotification('approved');
        $channels = $notification->via($userNoFcm);

        $this->assertNotContains(FcmChannel::class, $channels);
    }

    #[Test]
    public function to_fcm_approved_status()
    {
        $notification = new KycStatusNotification('approved');
        $fcm = $notification->toFcm($this->user);

        $this->assertArrayHasKey('title', $fcm);
        $this->assertArrayHasKey('body', $fcm);
        $this->assertArrayHasKey('data', $fcm);
        $this->assertEquals('kyc_status_update', $fcm['data']['type']);
        $this->assertEquals('approved', $fcm['data']['kyc_status']);
        $this->assertStringContainsString('approuvée', $fcm['title']);
    }

    #[Test]
    public function to_fcm_rejected_status()
    {
        $notification = new KycStatusNotification('rejected', 'Documents illisibles');
        $fcm = $notification->toFcm($this->user);

        $this->assertEquals('rejected', $fcm['data']['kyc_status']);
        $this->assertStringContainsString('rejetée', $fcm['title']);
    }

    #[Test]
    public function to_fcm_incomplete_status()
    {
        $notification = new KycStatusNotification('incomplete', 'Photo floue');
        $fcm = $notification->toFcm($this->user);

        $this->assertEquals('incomplete', $fcm['data']['kyc_status']);
        $this->assertStringContainsString('resoumettre', $fcm['title']);
    }

    #[Test]
    public function to_array_returns_correct_structure()
    {
        $notification = new KycStatusNotification('approved');
        $array = $notification->toArray($this->user);

        $this->assertEquals('kyc_status_update', $array['type']);
        $this->assertEquals('approved', $array['kyc_status']);
        $this->assertArrayHasKey('title', $array);
        $this->assertArrayHasKey('body', $array);
    }

    #[Test]
    public function to_array_includes_reason_when_rejected()
    {
        $notification = new KycStatusNotification('rejected', 'Documents expirés');
        $array = $notification->toArray($this->user);

        $this->assertEquals('Documents expirés', $array['reason']);
    }

    #[Test]
    public function notification_can_be_sent()
    {
        Notification::fake();

        $this->user->notify(new KycStatusNotification('approved'));

        Notification::assertSentTo($this->user, KycStatusNotification::class);
    }
}
