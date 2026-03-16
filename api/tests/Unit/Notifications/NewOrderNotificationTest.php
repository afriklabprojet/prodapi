<?php

namespace Tests\Unit\Notifications;

use App\Models\Order;
use App\Models\User;
use App\Models\Pharmacy;
use App\Models\Customer;
use App\Notifications\NewOrderNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class NewOrderNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected $order;
    protected $pharmacy;
    protected $pharmacyUser;

    protected function setUp(): void
    {
        parent::setUp();

        $this->pharmacyUser = User::factory()->create([
            'role' => 'pharmacy',
            'email' => 'pharmacy@test.com',
            'fcm_token' => 'test-fcm-token',
        ]);

        $this->pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->pharmacy->users()->attach($this->pharmacyUser->id);

        $customer = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $customer->id]);

        $this->order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $customer->id,
            'reference' => 'DR-TEST123',
            'total_amount' => 5000,
        ]);
    }

    /** @test */
    public function it_can_be_constructed_with_order()
    {
        $notification = new NewOrderNotification($this->order);

        $this->assertInstanceOf(NewOrderNotification::class, $notification);
        $this->assertEquals($this->order->id, $notification->order->id);
    }

    /** @test */
    public function it_uses_database_channel()
    {
        $notification = new NewOrderNotification($this->order);
        $channels = $notification->via($this->pharmacyUser);

        $this->assertContains('database', $channels);
    }

    /** @test */
    public function it_uses_mail_channel_when_email_exists()
    {
        $notification = new NewOrderNotification($this->order);
        $channels = $notification->via($this->pharmacyUser);

        $this->assertContains('mail', $channels);
    }

    /** @test */
    public function it_uses_fcm_channel_when_token_exists()
    {
        $notification = new NewOrderNotification($this->order);
        $channels = $notification->via($this->pharmacyUser);

        $this->assertContains(\App\Channels\FcmChannel::class, $channels);
    }

    /** @test */
    public function it_skips_mail_when_no_email()
    {
        $userNoEmail = User::factory()->create([
            'email' => null,
            'fcm_token' => null,
        ]);

        $notification = new NewOrderNotification($this->order);
        $channels = $notification->via($userNoEmail);

        $this->assertNotContains('mail', $channels);
    }

    /** @test */
    public function to_fcm_returns_correct_structure()
    {
        $notification = new NewOrderNotification($this->order);
        $fcm = $notification->toFcm($this->pharmacyUser);

        $this->assertArrayHasKey('title', $fcm);
        $this->assertArrayHasKey('body', $fcm);
        $this->assertArrayHasKey('data', $fcm);
        $this->assertEquals('new_order', $fcm['data']['type']);
        $this->assertEquals((string)$this->order->id, $fcm['data']['order_id']);
    }

    /** @test */
    public function to_mail_returns_mail_message()
    {
        $notification = new NewOrderNotification($this->order);
        $mail = $notification->toMail($this->pharmacyUser);

        $this->assertInstanceOf(\Illuminate\Notifications\Messages\MailMessage::class, $mail);
    }

    /** @test */
    public function to_array_returns_database_data()
    {
        $notification = new NewOrderNotification($this->order);
        $array = $notification->toArray($this->pharmacyUser);

        $this->assertIsArray($array);
        $this->assertArrayHasKey('order_id', $array);
        $this->assertEquals($this->order->id, $array['order_id']);
    }

    /** @test */
    public function notification_can_be_sent()
    {
        Notification::fake();

        $this->pharmacyUser->notify(new NewOrderNotification($this->order));

        Notification::assertSentTo(
            $this->pharmacyUser,
            NewOrderNotification::class,
            function ($notification, $channels) {
                return $notification->order->id === $this->order->id;
            }
        );
    }

    /** @test */
    public function fcm_title_contains_emoji()
    {
        $notification = new NewOrderNotification($this->order);
        $fcm = $notification->toFcm($this->pharmacyUser);

        $this->assertStringContainsString('🛒', $fcm['title']);
    }

    /** @test */
    public function fcm_body_contains_order_reference()
    {
        $notification = new NewOrderNotification($this->order);
        $fcm = $notification->toFcm($this->pharmacyUser);

        $this->assertStringContainsString($this->order->reference, $fcm['body']);
    }

    /** @test */
    public function fcm_body_contains_total_amount()
    {
        $notification = new NewOrderNotification($this->order);
        $fcm = $notification->toFcm($this->pharmacyUser);

        $this->assertStringContainsString((string)$this->order->total_amount, $fcm['body']);
    }
}
