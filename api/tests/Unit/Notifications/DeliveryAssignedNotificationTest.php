<?php

namespace Tests\Unit\Notifications;

use App\Notifications\DeliveryAssignedNotification;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use App\Models\Courier;
use App\Models\Customer;
use App\Channels\FcmChannel;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class DeliveryAssignedNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected $delivery;
    protected $order;
    protected $courier;
    protected $courierUser;

    protected function setUp(): void
    {
        parent::setUp();

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $customerUser = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $customerUser->id]);

        $this->courierUser = User::factory()->create([
            'role' => 'courier',
            'email' => 'courier@test.com',
            'fcm_token' => 'test_fcm_token',
        ]);

        $this->courier = Courier::factory()->create([
            'user_id' => $this->courierUser->id,
            'status' => 'available',
        ]);

        $this->order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $customerUser->id,
            'status' => 'confirmed',
            'total_amount' => 15000,
            'reference' => 'CMD-TEST-001',
        ]);

        $this->delivery = Delivery::factory()->create([
            'order_id' => $this->order->id,
            'courier_id' => $this->courier->id,
            'status' => 'assigned',
            'pickup_address' => '123 Pharmacy Street',
            'delivery_address' => '456 Customer Avenue',
            'delivery_fee' => 1500,
            'estimated_distance' => 5.5,
        ]);
    }

    /** @test */
    public function it_can_be_constructed_with_delivery()
    {
        $notification = new DeliveryAssignedNotification($this->delivery);

        $this->assertInstanceOf(DeliveryAssignedNotification::class, $notification);
        $this->assertEquals($this->delivery->id, $notification->delivery->id);
    }

    /** @test */
    public function via_returns_database_channel()
    {
        $notification = new DeliveryAssignedNotification($this->delivery);
        $channels = $notification->via($this->courierUser);

        $this->assertContains('database', $channels);
    }

    /** @test */
    public function via_includes_mail_when_user_has_email()
    {
        $notification = new DeliveryAssignedNotification($this->delivery);
        $channels = $notification->via($this->courierUser);

        $this->assertContains('mail', $channels);
    }

    /** @test */
    public function via_excludes_mail_when_user_has_no_email()
    {
        $userWithoutEmail = User::factory()->create([
            'email' => null,
            'fcm_token' => 'token',
        ]);

        $notification = new DeliveryAssignedNotification($this->delivery);
        $channels = $notification->via($userWithoutEmail);

        $this->assertNotContains('mail', $channels);
    }

    /** @test */
    public function via_includes_fcm_when_user_has_fcm_token()
    {
        $notification = new DeliveryAssignedNotification($this->delivery);
        $channels = $notification->via($this->courierUser);

        $this->assertContains(FcmChannel::class, $channels);
    }

    /** @test */
    public function via_excludes_fcm_when_user_has_no_fcm_token()
    {
        $userWithoutFcm = User::factory()->create([
            'email' => 'test@test.com',
            'fcm_token' => null,
        ]);

        $notification = new DeliveryAssignedNotification($this->delivery);
        $channels = $notification->via($userWithoutFcm);

        $this->assertNotContains(FcmChannel::class, $channels);
    }

    /** @test */
    public function to_fcm_returns_correct_structure()
    {
        $notification = new DeliveryAssignedNotification($this->delivery);
        $fcm = $notification->toFcm($this->courierUser);

        $this->assertArrayHasKey('title', $fcm);
        $this->assertArrayHasKey('body', $fcm);
        $this->assertArrayHasKey('data', $fcm);
        $this->assertStringContainsString('NOUVELLE LIVRAISON', $fcm['title']);
    }

    /** @test */
    public function to_fcm_contains_delivery_data()
    {
        $notification = new DeliveryAssignedNotification($this->delivery);
        $fcm = $notification->toFcm($this->courierUser);

        $this->assertEquals('delivery_assigned', $fcm['data']['type']);
        $this->assertEquals((string) $this->delivery->id, $fcm['data']['delivery_id']);
        $this->assertEquals((string) $this->order->id, $fcm['data']['order_id']);
        $this->assertEquals($this->delivery->pickup_address, $fcm['data']['pharmacy_address']);
        $this->assertEquals((string) $this->delivery->delivery_fee, $fcm['data']['delivery_fee']);
    }

    /** @test */
    public function to_mail_returns_mail_message()
    {
        $notification = new DeliveryAssignedNotification($this->delivery);
        $mail = $notification->toMail($this->courierUser);

        $this->assertInstanceOf(\Illuminate\Notifications\Messages\MailMessage::class, $mail);
    }

    /** @test */
    public function to_array_returns_correct_structure()
    {
        $notification = new DeliveryAssignedNotification($this->delivery);
        $array = $notification->toArray($this->courierUser);

        $this->assertEquals($this->delivery->id, $array['delivery_id']);
        $this->assertEquals($this->order->id, $array['order_id']);
        $this->assertEquals('delivery_assigned', $array['type']);
        $this->assertEquals('accept_delivery', $array['action']);
        $this->assertArrayHasKey('delivery_data', $array);
        $this->assertArrayHasKey('message', $array);
    }

    /** @test */
    public function to_array_contains_delivery_details()
    {
        $notification = new DeliveryAssignedNotification($this->delivery);
        $array = $notification->toArray($this->courierUser);

        $this->assertEquals($this->delivery->pickup_address, $array['delivery_data']['pickup_address']);
        $this->assertEquals($this->delivery->delivery_address, $array['delivery_data']['delivery_address']);
        $this->assertEquals($this->delivery->delivery_fee, $array['delivery_data']['delivery_fee']);
    }

    /** @test */
    public function notification_can_be_sent()
    {
        Notification::fake();

        $this->courierUser->notify(new DeliveryAssignedNotification($this->delivery));

        Notification::assertSentTo($this->courierUser, DeliveryAssignedNotification::class);
    }
}
