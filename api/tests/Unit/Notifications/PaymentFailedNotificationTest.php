<?php

namespace Tests\Unit\Notifications;

use App\Notifications\PaymentFailedNotification;
use App\Models\User;
use App\Models\Order;
use App\Models\Customer;
use App\Models\Pharmacy;
use App\Channels\FcmChannel;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class PaymentFailedNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Order $order;

    protected function setUp(): void
    {
        parent::setUp();

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->user = User::factory()->create([
            'role' => 'customer',
            'email' => 'client@test.com',
            'fcm_token' => 'test_fcm_token',
        ]);
        Customer::factory()->create(['user_id' => $this->user->id]);

        $this->order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $this->user->id,
            'reference' => 'CMD-PAY-001',
            'total_amount' => 5000,
        ]);
    }

    #[Test]
    public function via_includes_database()
    {
        $notification = new PaymentFailedNotification($this->order);
        $channels = $notification->via($this->user);

        $this->assertContains('database', $channels);
    }

    #[Test]
    public function via_includes_fcm_when_user_has_token()
    {
        $notification = new PaymentFailedNotification($this->order);
        $channels = $notification->via($this->user);

        $this->assertContains(FcmChannel::class, $channels);
    }

    #[Test]
    public function via_includes_mail_when_user_has_email()
    {
        $notification = new PaymentFailedNotification($this->order);
        $channels = $notification->via($this->user);

        $this->assertContains('mail', $channels);
    }

    #[Test]
    public function via_excludes_mail_when_no_email()
    {
        $userNoEmail = User::factory()->create(['email' => null, 'fcm_token' => null]);
        $notification = new PaymentFailedNotification($this->order);
        $channels = $notification->via($userNoEmail);

        $this->assertNotContains('mail', $channels);
    }

    #[Test]
    public function to_fcm_returns_correct_structure()
    {
        $notification = new PaymentFailedNotification($this->order, 'Solde insuffisant');
        $fcm = $notification->toFcm($this->user);

        $this->assertArrayHasKey('title', $fcm);
        $this->assertArrayHasKey('body', $fcm);
        $this->assertArrayHasKey('data', $fcm);
        $this->assertEquals('payment_failed', $fcm['data']['type']);
        $this->assertEquals((string) $this->order->id, $fcm['data']['order_id']);
        $this->assertStringContainsString('CMD-PAY-001', $fcm['body']);
    }

    #[Test]
    public function to_mail_returns_mail_message()
    {
        $notification = new PaymentFailedNotification($this->order);
        $mail = $notification->toMail($this->user);

        $this->assertInstanceOf(MailMessage::class, $mail);
    }

    #[Test]
    public function to_array_returns_correct_structure()
    {
        $notification = new PaymentFailedNotification($this->order, 'Timeout');
        $array = $notification->toArray($this->user);

        $this->assertEquals($this->order->id, $array['order_id']);
        $this->assertEquals('CMD-PAY-001', $array['order_reference']);
        $this->assertEquals('payment_failed', $array['type']);
        $this->assertEquals('Timeout', $array['reason']);
        $this->assertEquals($this->order->total_amount, $array['amount']);
    }

    #[Test]
    public function notification_can_be_sent()
    {
        Notification::fake();

        $this->user->notify(new PaymentFailedNotification($this->order));

        Notification::assertSentTo($this->user, PaymentFailedNotification::class);
    }
}
