<?php

namespace Tests\Unit\Notifications;

use App\Notifications\CourierCancelledDeliveryNotification;
use App\Models\User;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Courier;
use App\Models\Customer;
use App\Models\Pharmacy;
use App\Channels\FcmChannel;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class CourierCancelledDeliveryNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected User $customerUser;
    protected Delivery $delivery;
    protected Order $order;

    protected function setUp(): void
    {
        parent::setUp();

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->customerUser = User::factory()->create([
            'role' => 'customer',
            'fcm_token' => 'test_fcm_token',
        ]);
        Customer::factory()->create(['user_id' => $this->customerUser->id]);

        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);

        $this->order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $this->customerUser->id,
            'reference' => 'CMD-CANCEL-001',
        ]);

        $this->delivery = Delivery::factory()->create([
            'order_id' => $this->order->id,
            'courier_id' => $courier->id,
            'status' => 'cancelled',
        ]);
    }

    #[Test]
    public function via_includes_database()
    {
        $notification = new CourierCancelledDeliveryNotification($this->delivery);
        $channels = $notification->via($this->customerUser);

        $this->assertContains('database', $channels);
    }

    #[Test]
    public function via_includes_fcm_when_user_has_token()
    {
        $notification = new CourierCancelledDeliveryNotification($this->delivery);
        $channels = $notification->via($this->customerUser);

        $this->assertContains(FcmChannel::class, $channels);
    }

    #[Test]
    public function via_excludes_fcm_when_no_token()
    {
        $userNoFcm = User::factory()->create(['fcm_token' => null]);
        $notification = new CourierCancelledDeliveryNotification($this->delivery);
        $channels = $notification->via($userNoFcm);

        $this->assertNotContains(FcmChannel::class, $channels);
    }

    #[Test]
    public function to_fcm_returns_correct_structure()
    {
        $notification = new CourierCancelledDeliveryNotification($this->delivery);
        $fcm = $notification->toFcm($this->customerUser);

        $this->assertArrayHasKey('title', $fcm);
        $this->assertArrayHasKey('body', $fcm);
        $this->assertArrayHasKey('data', $fcm);
        $this->assertEquals('courier_cancelled', $fcm['data']['type']);
        $this->assertEquals((string) $this->order->id, $fcm['data']['order_id']);
        $this->assertStringContainsString('CMD-CANCEL-001', $fcm['body']);
    }

    #[Test]
    public function to_mail_returns_mail_message()
    {
        $notification = new CourierCancelledDeliveryNotification($this->delivery);
        $mail = $notification->toMail($this->customerUser);

        $this->assertInstanceOf(MailMessage::class, $mail);
    }

    #[Test]
    public function to_array_returns_correct_structure()
    {
        $notification = new CourierCancelledDeliveryNotification($this->delivery, 'Panne véhicule');
        $array = $notification->toArray($this->customerUser);

        $this->assertEquals($this->order->id, $array['order_id']);
        $this->assertEquals('CMD-CANCEL-001', $array['order_reference']);
        $this->assertEquals($this->delivery->id, $array['delivery_id']);
        $this->assertEquals('courier_cancelled', $array['type']);
        $this->assertEquals('Panne véhicule', $array['reason']);
        $this->assertArrayHasKey('message', $array);
    }

    #[Test]
    public function notification_can_be_sent()
    {
        Notification::fake();

        $this->customerUser->notify(new CourierCancelledDeliveryNotification($this->delivery));

        Notification::assertSentTo($this->customerUser, CourierCancelledDeliveryNotification::class);
    }
}
