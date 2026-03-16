<?php

namespace Tests\Unit\Notifications;

use App\Notifications\DeliveryTimeoutCancelledNotification;
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

class DeliveryTimeoutCancelledNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected $delivery;
    protected $order;
    protected $customerUser;
    protected $courierUser;
    protected $pharmacyUser;

    protected function setUp(): void
    {
        parent::setUp();

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        
        $this->customerUser = User::factory()->create([
            'role' => 'customer',
            'fcm_token' => 'customer_fcm_token',
        ]);
        Customer::factory()->create(['user_id' => $this->customerUser->id]);

        $this->courierUser = User::factory()->create([
            'role' => 'courier',
            'fcm_token' => 'courier_fcm_token',
        ]);

        $courier = Courier::factory()->create([
            'user_id' => $this->courierUser->id,
            'status' => 'busy',
        ]);

        $this->pharmacyUser = User::factory()->create([
            'role' => 'pharmacy',
            'fcm_token' => 'pharmacy_fcm_token',
        ]);

        $this->order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $this->customerUser->id,
            'status' => 'cancelled',
        ]);

        $this->delivery = Delivery::factory()->create([
            'order_id' => $this->order->id,
            'courier_id' => $courier->id,
            'status' => 'cancelled',
        ]);
    }

    /** @test */
    public function it_can_be_constructed_with_all_parameters()
    {
        $notification = new DeliveryTimeoutCancelledNotification(
            $this->delivery,
            25, // waiting minutes
            1500, // waiting fee
            'customer'
        );

        $this->assertInstanceOf(DeliveryTimeoutCancelledNotification::class, $notification);
        $this->assertEquals($this->delivery->id, $notification->delivery->id);
        $this->assertEquals(25, $notification->waitingMinutes);
        $this->assertEquals(1500, $notification->waitingFee);
        $this->assertEquals('customer', $notification->recipientType);
    }

    /** @test */
    public function via_returns_database_and_fcm_channels()
    {
        $notification = new DeliveryTimeoutCancelledNotification($this->delivery, 25, 1500, 'customer');
        $channels = $notification->via($this->customerUser);

        $this->assertContains('database', $channels);
        $this->assertContains(FcmChannel::class, $channels);
    }

    /** @test */
    public function customer_receives_correct_message()
    {
        $notification = new DeliveryTimeoutCancelledNotification($this->delivery, 25, 1500, 'customer');
        $array = $notification->toArray($this->customerUser);

        $this->assertEquals('Livraison annulée', $array['title']);
        $this->assertStringContainsString('25 minutes', $array['message']);
        $this->assertStringContainsString('1500 FCFA', $array['message']);
    }

    /** @test */
    public function courier_receives_correct_message()
    {
        $notification = new DeliveryTimeoutCancelledNotification($this->delivery, 25, 1500, 'courier');
        $array = $notification->toArray($this->courierUser);

        $this->assertEquals('Livraison annulée - Timeout', $array['title']);
        $this->assertStringContainsString('automatiquement', $array['message']);
        $this->assertStringContainsString('nouvelles livraisons', $array['message']);
    }

    /** @test */
    public function pharmacy_receives_correct_message()
    {
        $notification = new DeliveryTimeoutCancelledNotification($this->delivery, 25, 1500, 'pharmacy');
        $array = $notification->toArray($this->pharmacyUser);

        $this->assertEquals('Commande annulée - Client indisponible', $array['title']);
        $this->assertStringContainsString('automatiquement', $array['message']);
        $this->assertStringContainsString('25 minutes', $array['message']);
    }

    /** @test */
    public function default_recipient_returns_generic_message()
    {
        $notification = new DeliveryTimeoutCancelledNotification($this->delivery, 25, 1500, 'unknown');
        $array = $notification->toArray($this->customerUser);

        $this->assertEquals('Livraison annulée', $array['title']);
        $this->assertEquals('Livraison annulée pour timeout', $array['message']);
    }

    /** @test */
    public function to_array_contains_required_data()
    {
        $notification = new DeliveryTimeoutCancelledNotification($this->delivery, 25, 1500, 'customer');
        $array = $notification->toArray($this->customerUser);

        $this->assertEquals('delivery_timeout_cancelled', $array['type']);
        $this->assertEquals($this->order->id, $array['order_id']);
        $this->assertEquals($this->delivery->id, $array['delivery_id']);
        $this->assertEquals(25, $array['waiting_minutes']);
        $this->assertEquals(1500, $array['waiting_fee']);
    }

    /** @test */
    public function to_fcm_returns_correct_structure()
    {
        $notification = new DeliveryTimeoutCancelledNotification($this->delivery, 25, 1500, 'customer');
        $fcm = $notification->toFcm($this->customerUser);

        $this->assertArrayHasKey('title', $fcm);
        $this->assertArrayHasKey('body', $fcm);
        $this->assertArrayHasKey('data', $fcm);
    }

    /** @test */
    public function to_fcm_data_contains_delivery_info()
    {
        $notification = new DeliveryTimeoutCancelledNotification($this->delivery, 25, 1500, 'customer');
        $fcm = $notification->toFcm($this->customerUser);

        $this->assertEquals('delivery_timeout_cancelled', $fcm['data']['type']);
        $this->assertEquals((string) $this->delivery->id, $fcm['data']['delivery_id']);
        $this->assertEquals((string) $this->order->id, $fcm['data']['order_id']);
        $this->assertEquals('25', $fcm['data']['waiting_minutes']);
        $this->assertEquals('1500', $fcm['data']['waiting_fee']);
    }

    /** @test */
    public function notification_can_be_sent_to_customer()
    {
        Notification::fake();

        $this->customerUser->notify(new DeliveryTimeoutCancelledNotification($this->delivery, 25, 1500, 'customer'));

        Notification::assertSentTo($this->customerUser, DeliveryTimeoutCancelledNotification::class);
    }

    /** @test */
    public function notification_can_be_sent_to_courier()
    {
        Notification::fake();

        $this->courierUser->notify(new DeliveryTimeoutCancelledNotification($this->delivery, 25, 1500, 'courier'));

        Notification::assertSentTo($this->courierUser, DeliveryTimeoutCancelledNotification::class);
    }

    /** @test */
    public function notification_can_be_sent_to_pharmacy()
    {
        Notification::fake();

        $this->pharmacyUser->notify(new DeliveryTimeoutCancelledNotification($this->delivery, 25, 1500, 'pharmacy'));

        Notification::assertSentTo($this->pharmacyUser, DeliveryTimeoutCancelledNotification::class);
    }
}
