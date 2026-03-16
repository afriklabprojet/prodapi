<?php

namespace Tests\Unit\Channels;

use App\Channels\SmsChannel;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class SmsChannelTest extends TestCase
{
    use RefreshDatabase;

    protected SmsChannel $channel;

    protected function setUp(): void
    {
        parent::setUp();
        $this->channel = app(SmsChannel::class);
    }

    /** @test */
    public function it_does_not_send_if_notification_has_no_toSms_method()
    {
        $user = User::factory()->create(['phone' => '+1234567890']);
        $notification = new NotificationWithoutSms();

        Http::fake();

        $this->channel->send($user, $notification);

        Http::assertNothingSent();
    }

    /** @test */
    public function it_does_not_send_if_toSms_returns_null()
    {
        $user = User::factory()->create(['phone' => '+1234567890']);
        $notification = new TestSmsNotificationReturnsNull();

        Http::fake();

        $this->channel->send($user, $notification);

        Http::assertNothingSent();
    }

    /** @test */
    public function it_does_not_send_if_user_has_no_phone()
    {
        Log::shouldReceive('warning')
            ->once()
            ->with('No phone number found for SMS notification', \Mockery::any());

        $user = User::factory()->create([
            'phone' => null,
        ]);
        $notification = new TestSmsNotification();

        Http::fake();

        $this->channel->send($user, $notification);

        Http::assertNothingSent();
    }

    /** @test */
    public function it_gets_phone_from_phone_field()
    {
        // Mock SmsService to verify the phone is passed correctly
        $smsServiceMock = \Mockery::mock(\App\Services\SmsService::class);
        $smsServiceMock->shouldReceive('send')
            ->once()
            ->with('+1234567890', 'Test SMS Message', [])
            ->andReturn(true);

        $this->app->instance(\App\Services\SmsService::class, $smsServiceMock);
        $this->channel = app(SmsChannel::class);

        $user = User::factory()->create(['phone' => '+1234567890']);
        $notification = new TestSmsNotification();

        $this->channel->send($user, $notification);
    }

    /** @test */
    public function it_sends_via_sms_service_provider()
    {
        // Mock SmsService to verify it delegates correctly
        $smsServiceMock = \Mockery::mock(\App\Services\SmsService::class);
        $smsServiceMock->shouldReceive('send')
            ->once()
            ->with('+1234567890', 'Test SMS Message', [])
            ->andReturn(true);

        $this->app->instance(\App\Services\SmsService::class, $smsServiceMock);
        $this->channel = app(SmsChannel::class);

        $user = User::factory()->create(['phone' => '+1234567890']);
        $notification = new TestSmsNotification();

        $this->channel->send($user, $notification);
    }

    /** @test */
    public function it_logs_warning_when_sms_send_fails()
    {
        // Mock SmsService to return false (send failed)
        $smsServiceMock = \Mockery::mock(\App\Services\SmsService::class);
        $smsServiceMock->shouldReceive('send')
            ->once()
            ->andReturn(false);

        $this->app->instance(\App\Services\SmsService::class, $smsServiceMock);
        $this->channel = app(SmsChannel::class);

        Log::shouldReceive('warning')
            ->once()
            ->with('SMS notification failed to send', \Mockery::type('array'));

        $user = User::factory()->create(['phone' => '+1234567890']);
        $notification = new TestSmsNotification();

        $this->channel->send($user, $notification);
    }

    /** @test */
    public function it_sends_successfully_via_sms_service()
    {
        $smsServiceMock = \Mockery::mock(\App\Services\SmsService::class);
        $smsServiceMock->shouldReceive('send')
            ->once()
            ->andReturn(true);

        $this->app->instance(\App\Services\SmsService::class, $smsServiceMock);
        $this->channel = app(SmsChannel::class);

        $user = User::factory()->create(['phone' => '+1234567890']);
        $notification = new TestSmsNotification();

        $this->channel->send($user, $notification);
    }
}

// Test notification classes
class NotificationWithoutSms extends Notification
{
    public function via($notifiable)
    {
        return ['database'];
    }
}

class TestSmsNotification extends Notification
{
    public function via($notifiable)
    {
        return [\App\Channels\SmsChannel::class];
    }

    public function toSms($notifiable)
    {
        return 'Test SMS Message';
    }
}

class TestSmsNotificationReturnsNull extends Notification
{
    public function via($notifiable)
    {
        return [\App\Channels\SmsChannel::class];
    }

    public function toSms($notifiable)
    {
        return null;
    }
}
