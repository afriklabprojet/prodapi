<?php

namespace Tests\Unit\Jobs;

use App\Jobs\SendNotificationJob;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Notification as NotificationFacade;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class SendNotificationJobTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Log::spy();
    }

    #[Test]
    public function it_sends_notification_to_user()
    {
        NotificationFacade::fake();

        $user = User::factory()->create();
        $notification = new TestNotification('Hello');

        $job = new SendNotificationJob($user, $notification);
        $job->handle();

        NotificationFacade::assertSentTo($user, TestNotification::class);
    }

    #[Test]
    public function it_logs_successful_notification()
    {
        NotificationFacade::fake();

        $user = User::factory()->create();
        $notification = new TestNotification('Test');

        $job = new SendNotificationJob($user, $notification, ['order_id' => 123]);
        $job->handle();

        Log::shouldHaveReceived('info')->once();
    }

    #[Test]
    public function it_includes_context_in_logs()
    {
        NotificationFacade::fake();

        $user = User::factory()->create();
        $notification = new TestNotification('Test');
        $context = ['order_id' => 456, 'pharmacy_id' => 789];

        $job = new SendNotificationJob($user, $notification, $context);
        $job->handle();

        Log::shouldHaveReceived('info')->once();
    }

    #[Test]
    public function it_has_correct_retry_configuration()
    {
        $user = User::factory()->make();
        $notification = new TestNotification('Test');

        $job = new SendNotificationJob($user, $notification);

        $this->assertEquals(3, $job->tries);
        $this->assertEquals([10, 30, 60], $job->backoff);
        $this->assertEquals(30, $job->timeout);
    }

    #[Test]
    public function it_logs_failure_on_exception()
    {
        $user = User::factory()->create();
        $notification = new FailingNotification();

        $job = new SendNotificationJob($user, $notification);
        $exception = new \Exception('Test failure');
        
        $job->failed($exception);

        Log::shouldHaveReceived('error')->once();
    }

    #[Test]
    public function it_rethrows_exception_for_retry()
    {
        $this->expectException(\Exception::class);

        $user = User::factory()->create();
        $notification = new FailingNotification();

        // Mock the notify method to throw
        $mockUser = $this->createPartialMock(User::class, ['notify']);
        $mockUser->method('notify')->willThrowException(new \Exception('Notification failed'));
        $mockUser->id = $user->id;

        $job = new SendNotificationJob($mockUser, $notification);
        $job->handle();
    }
}

/**
 * Test notification class
 */
class TestNotification extends Notification
{
    public function __construct(private string $message) {}

    public function via($notifiable): array
    {
        return ['database'];
    }

    public function toDatabase($notifiable): array
    {
        return ['message' => $this->message];
    }
}

/**
 * Notification that always fails
 */
class FailingNotification extends Notification
{
    public function via($notifiable): array
    {
        return ['database'];
    }

    public function toDatabase($notifiable): array
    {
        throw new \Exception('Notification failed');
    }
}
