<?php

namespace Tests\Unit\Notifications;

use App\Notifications\PayoutCompletedNotification;
use App\Models\User;
use App\Channels\FcmChannel;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class PayoutCompletedNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create([
            'fcm_token' => 'test_fcm_token',
        ]);
    }

    #[Test]
    public function via_includes_database()
    {
        $notification = new PayoutCompletedNotification(25000, 'PAY-REF-001');
        $channels = $notification->via($this->user);

        $this->assertContains('database', $channels);
    }

    #[Test]
    public function via_includes_fcm_when_user_has_token()
    {
        $notification = new PayoutCompletedNotification(25000, 'PAY-REF-001');
        $channels = $notification->via($this->user);

        $this->assertContains(FcmChannel::class, $channels);
    }

    #[Test]
    public function via_excludes_fcm_when_no_token()
    {
        $userNoFcm = User::factory()->create(['fcm_token' => null]);
        $notification = new PayoutCompletedNotification(25000, 'PAY-REF-001');
        $channels = $notification->via($userNoFcm);

        $this->assertNotContains(FcmChannel::class, $channels);
    }

    #[Test]
    public function to_array_returns_correct_structure()
    {
        $notification = new PayoutCompletedNotification(25000, 'PAY-REF-001');
        $array = $notification->toArray($this->user);

        $this->assertEquals('payout_completed', $array['type']);
        $this->assertEquals(25000, $array['amount']);
        $this->assertEquals('PAY-REF-001', $array['reference']);
        $this->assertStringContainsString('25 000', $array['body']);
        $this->assertStringContainsString('PAY-REF-001', $array['body']);
    }

    #[Test]
    public function to_fcm_returns_correct_structure()
    {
        $notification = new PayoutCompletedNotification(25000, 'PAY-REF-001');
        $fcm = $notification->toFcm($this->user);

        $this->assertArrayHasKey('title', $fcm);
        $this->assertArrayHasKey('body', $fcm);
        $this->assertArrayHasKey('data', $fcm);
        $this->assertEquals('payout_completed', $fcm['data']['type']);
        $this->assertEquals('PAY-REF-001', $fcm['data']['reference']);
        $this->assertStringContainsString('25 000', $fcm['body']);
    }

    #[Test]
    public function notification_can_be_sent()
    {
        Notification::fake();

        $this->user->notify(new PayoutCompletedNotification(25000, 'PAY-REF-001'));

        Notification::assertSentTo($this->user, PayoutCompletedNotification::class);
    }
}
