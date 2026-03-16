<?php

namespace Tests\Unit\Channels;

use App\Channels\FcmChannel;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Messaging\CloudMessage;
use Mockery;
use Tests\TestCase;

class FcmChannelTest extends TestCase
{
    use RefreshDatabase;

    protected $messaging;
    protected $channel;

    protected function setUp(): void
    {
        parent::setUp();

        $this->messaging = Mockery::mock(Messaging::class);
        $this->channel = new FcmChannel($this->messaging);
    }

    protected function tearDown(): void
    {
        if ($container = Mockery::getContainer()) {
            $this->addToAssertionCount($container->mockery_getExpectationCount());
        }
        Mockery::close();
        parent::tearDown();
    }

    /** @test */
    public function it_does_not_send_if_notification_has_no_toFcm_method()
    {
        $user = User::factory()->create(['fcm_token' => 'test_token']);
        $notification = new NotificationWithoutFcm();

        $this->messaging->shouldNotReceive('send');

        $this->channel->send($user, $notification);
    }

    /** @test */
    public function it_does_not_send_if_user_has_no_fcm_token()
    {
        $user = User::factory()->create(['fcm_token' => null]);
        $notification = new TestFcmNotification();

        $this->messaging->shouldNotReceive('send');

        $this->channel->send($user, $notification);
    }

    /** @test */
    public function it_sends_notification_with_correct_data()
    {
        $user = User::factory()->create(['fcm_token' => 'valid_token']);
        $notification = new TestFcmNotification();

        $this->messaging->shouldReceive('send')
            ->once()
            ->with(Mockery::on(function ($message) {
                return $message instanceof CloudMessage;
            }));

        $this->channel->send($user, $notification);
    }

    /** @test */
    public function it_logs_successful_send()
    {
        Log::shouldReceive('info')
            ->once()
            ->with('FCM Notification sent', Mockery::any());

        $user = User::factory()->create(['fcm_token' => 'valid_token']);
        $notification = new TestFcmNotification();

        $this->messaging->shouldReceive('send')->once();

        $this->channel->send($user, $notification);
    }

    /** @test */
    public function it_handles_messaging_exception()
    {
        Log::shouldReceive('error')
            ->once()
            ->with(Mockery::pattern('/FCM Send Error:/'), Mockery::any());

        $user = User::factory()->create(['fcm_token' => 'invalid_token']);
        $notification = new TestFcmNotification();

        $this->messaging->shouldReceive('send')
            ->once()
            ->andThrow(new \Kreait\Firebase\Exception\Messaging\InvalidMessage('Invalid token'));

        // Should not throw
        $this->channel->send($user, $notification);
    }

    /** @test */
    public function it_handles_general_exception()
    {
        Log::shouldReceive('error')
            ->once()
            ->with(Mockery::pattern('/FCM Exception:/'), Mockery::any());

        $user = User::factory()->create(['fcm_token' => 'test_token']);
        $notification = new TestFcmNotification();

        $this->messaging->shouldReceive('send')
            ->once()
            ->andThrow(new \Exception('Connection error'));

        // Should not throw
        $this->channel->send($user, $notification);
    }

    /** @test */
    public function it_includes_android_config_when_provided()
    {
        $user = User::factory()->create(['fcm_token' => 'valid_token']);
        $notification = new TestFcmNotificationWithAndroid();

        $this->messaging->shouldReceive('send')
            ->once()
            ->with(Mockery::on(function ($message) {
                return $message instanceof CloudMessage;
            }));

        $this->channel->send($user, $notification);
    }

    /** @test */
    public function it_includes_apns_config_when_provided()
    {
        $user = User::factory()->create(['fcm_token' => 'valid_token']);
        $notification = new TestFcmNotificationWithApns();

        $this->messaging->shouldReceive('send')
            ->once()
            ->with(Mockery::on(function ($message) {
                return $message instanceof CloudMessage;
            }));

        $this->channel->send($user, $notification);
    }
}

// Test notification classes
class NotificationWithoutFcm extends Notification
{
    public function via($notifiable)
    {
        return ['database'];
    }
}

class TestFcmNotification extends Notification
{
    public function via($notifiable)
    {
        return [FcmChannel::class];
    }

    public function toFcm($notifiable)
    {
        return [
            'title' => 'Test Notification',
            'body' => 'This is a test',
            'data' => [
                'type' => 'test',
                'id' => '123',
            ],
        ];
    }
}

class TestFcmNotificationWithAndroid extends Notification
{
    public function via($notifiable)
    {
        return [FcmChannel::class];
    }

    public function toFcm($notifiable)
    {
        return [
            'title' => 'Test Notification',
            'body' => 'This is a test',
            'data' => [
                'type' => 'test',
                'android_channel_id' => 'high_priority',
                'sound' => 'notification.mp3',
            ],
            'android' => [
                'priority' => 'high',
                'notification' => [
                    'channel_id' => 'high_priority',
                ],
            ],
        ];
    }
}

class TestFcmNotificationWithApns extends Notification
{
    public function via($notifiable)
    {
        return [FcmChannel::class];
    }

    public function toFcm($notifiable)
    {
        return [
            'title' => 'Test Notification',
            'body' => 'This is a test',
            'data' => ['type' => 'test'],
            'apns' => [
                'headers' => [
                    'apns-priority' => '10',
                ],
                'payload' => [
                    'aps' => [
                        'sound' => 'default',
                    ],
                ],
            ],
        ];
    }
}
