<?php

namespace Tests\Unit\Notifications;

use App\Models\Order;
use App\Models\User;
use App\Models\Pharmacy;
use App\Models\Customer;
use App\Notifications\OrderStatusNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class OrderStatusNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected $order;
    protected $customer;

    protected function setUp(): void
    {
        parent::setUp();

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);

        $this->customer = User::factory()->create([
            'role' => 'customer',
            'email' => 'customer@test.com',
            'phone' => '+2250707070707',
            'fcm_token' => 'test-fcm-token',
        ]);
        Customer::factory()->create(['user_id' => $this->customer->id]);

        $this->order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $this->customer->id,
            'reference' => 'DR-TEST123',
            'total_amount' => 5000,
        ]);
    }

    /** @test */
    public function it_can_be_constructed_with_order_and_status()
    {
        $notification = new OrderStatusNotification($this->order, 'confirmed');

        $this->assertInstanceOf(OrderStatusNotification::class, $notification);
        $this->assertEquals($this->order->id, $notification->order->id);
        $this->assertEquals('confirmed', $notification->status);
    }

    /** @test */
    public function it_accepts_additional_message()
    {
        $notification = new OrderStatusNotification(
            $this->order,
            'cancelled',
            'Produit non disponible'
        );

        $this->assertEquals('Produit non disponible', $notification->additionalMessage);
    }

    /** @test */
    public function it_uses_database_channel()
    {
        $notification = new OrderStatusNotification($this->order, 'confirmed');
        $channels = $notification->via($this->customer);

        $this->assertContains('database', $channels);
    }

    /** @test */
    public function it_uses_mail_channel_when_email_exists()
    {
        $notification = new OrderStatusNotification($this->order, 'confirmed');
        $channels = $notification->via($this->customer);

        $this->assertContains('mail', $channels);
    }

    /** @test */
    public function it_uses_sms_for_important_statuses()
    {
        $importantStatuses = ['confirmed', 'assigned', 'delivered'];

        foreach ($importantStatuses as $status) {
            $notification = new OrderStatusNotification($this->order, $status);
            $channels = $notification->via($this->customer);

            $this->assertContains(
                \App\Channels\SmsChannel::class,
                $channels,
                "SMS should be sent for status: $status"
            );
        }
    }

    /** @test */
    public function it_does_not_use_sms_for_minor_statuses()
    {
        $minorStatuses = ['preparing', 'ready_for_pickup'];

        foreach ($minorStatuses as $status) {
            $notification = new OrderStatusNotification($this->order, $status);
            $channels = $notification->via($this->customer);

            $this->assertNotContains(
                \App\Channels\SmsChannel::class,
                $channels,
                "SMS should NOT be sent for status: $status"
            );
        }
    }

    /** @test */
    public function it_uses_fcm_channel_when_token_exists()
    {
        $notification = new OrderStatusNotification($this->order, 'confirmed');
        $channels = $notification->via($this->customer);

        $this->assertContains(\App\Channels\FcmChannel::class, $channels);
    }

    /** @test */
    public function to_fcm_returns_correct_structure_for_confirmed()
    {
        $notification = new OrderStatusNotification($this->order, 'confirmed');
        $fcm = $notification->toFcm($this->customer);

        $this->assertArrayHasKey('title', $fcm);
        $this->assertArrayHasKey('body', $fcm);
        $this->assertArrayHasKey('data', $fcm);
        $this->assertStringContainsString('✅', $fcm['title']);
    }

    /** @test */
    public function to_fcm_returns_correct_title_for_each_status()
    {
        $statusEmojis = [
            'confirmed' => '✅',
            'preparing' => '💊',
            'ready_for_pickup' => '🛍️',
            'assigned' => '🛵',
            'on_the_way' => '🚚',
            'delivered' => '🎉',
            'cancelled' => '❌',
        ];

        foreach ($statusEmojis as $status => $emoji) {
            $notification = new OrderStatusNotification($this->order, $status);
            $fcm = $notification->toFcm($this->customer);

            $this->assertStringContainsString(
                $emoji,
                $fcm['title'],
                "Title should contain $emoji for status: $status"
            );
        }
    }

    /** @test */
    public function to_mail_returns_mail_message()
    {
        $notification = new OrderStatusNotification($this->order, 'confirmed');
        $mail = $notification->toMail($this->customer);

        $this->assertInstanceOf(\Illuminate\Notifications\Messages\MailMessage::class, $mail);
    }

    /** @test */
    public function to_array_returns_database_data()
    {
        $notification = new OrderStatusNotification($this->order, 'confirmed');
        $array = $notification->toArray($this->customer);

        $this->assertIsArray($array);
        $this->assertArrayHasKey('order_id', $array);
        $this->assertArrayHasKey('status', $array);
        $this->assertEquals($this->order->id, $array['order_id']);
        $this->assertEquals('confirmed', $array['status']);
    }

    /** @test */
    public function notification_can_be_sent()
    {
        Notification::fake();

        $this->customer->notify(new OrderStatusNotification($this->order, 'confirmed'));

        Notification::assertSentTo(
            $this->customer,
            OrderStatusNotification::class,
            function ($notification, $channels) {
                return $notification->order->id === $this->order->id
                    && $notification->status === 'confirmed';
            }
        );
    }

    /** @test */
    public function fcm_data_contains_order_id_and_status()
    {
        $notification = new OrderStatusNotification($this->order, 'delivered');
        $fcm = $notification->toFcm($this->customer);

        $this->assertEquals((string)$this->order->id, $fcm['data']['order_id']);
        $this->assertEquals('delivered', $fcm['data']['status']);
    }
}
