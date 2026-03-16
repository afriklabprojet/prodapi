<?php

namespace Tests\Unit\Notifications;

use App\Notifications\CourierArrivedNotification;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use App\Models\Courier;
use App\Models\Customer;
use App\Channels\FcmChannel;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class CourierArrivedNotificationTest extends TestCase
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
            'status' => 'in_delivery',
            'reference' => 'CMD-ARRIVED-001',
        ]);

        $this->delivery = Delivery::factory()->create([
            'order_id' => $this->order->id,
            'courier_id' => $courier->id,
            'status' => 'arrived',
            'waiting_started_at' => Carbon::now(),
        ]);
    }

    /** @test */
    public function it_can_be_constructed_with_all_parameters()
    {
        $notification = new CourierArrivedNotification(
            $this->delivery,
            30, // timeout minutes
            10, // free minutes
            100, // fee per minute
            'customer'
        );

        $this->assertInstanceOf(CourierArrivedNotification::class, $notification);
        $this->assertEquals($this->delivery->id, $notification->delivery->id);
        $this->assertEquals(30, $notification->timeoutMinutes);
        $this->assertEquals(10, $notification->freeMinutes);
        $this->assertEquals(100, $notification->feePerMinute);
        $this->assertEquals('customer', $notification->recipientType);
    }

    /** @test */
    public function via_returns_database_and_fcm_channels()
    {
        $notification = new CourierArrivedNotification($this->delivery, 30, 10, 100, 'customer');
        $channels = $notification->via($this->customerUser);

        $this->assertContains('database', $channels);
        $this->assertContains(FcmChannel::class, $channels);
    }

    /** @test */
    public function to_array_returns_correct_structure_for_customer()
    {
        $notification = new CourierArrivedNotification($this->delivery, 30, 10, 100, 'customer');
        $array = $notification->toArray($this->customerUser);

        $this->assertArrayHasKey('title', $array);
        $this->assertArrayHasKey('message', $array);
        $this->assertEquals('courier_arrived', $array['type']);
        $this->assertEquals($this->order->id, $array['order_id']);
        $this->assertEquals($this->delivery->id, $array['delivery_id']);
        $this->assertEquals(30, $array['timeout_minutes']);
        $this->assertEquals(10, $array['free_minutes']);
        $this->assertEquals(100, $array['fee_per_minute']);
        $this->assertEquals('customer', $array['recipient_type']);
    }

    /** @test */
    public function customer_message_contains_warning_about_fees()
    {
        $notification = new CourierArrivedNotification($this->delivery, 30, 10, 100, 'customer');
        $array = $notification->toArray($this->customerUser);

        $this->assertStringContainsString('Livreur arrivé', $array['title']);
        $this->assertStringContainsString('30 minutes', $array['message']);
        $this->assertStringContainsString('10 minutes gratuites', $array['message']);
        $this->assertStringContainsString('100 FCFA/min', $array['message']);
    }

    /** @test */
    public function courier_message_contains_waiting_info()
    {
        $notification = new CourierArrivedNotification($this->delivery, 30, 10, 100, 'courier');
        $array = $notification->toArray($this->courierUser);

        $this->assertStringContainsString('Minuterie', $array['title']);
        $this->assertStringContainsString('30 minutes', $array['message']);
    }

    /** @test */
    public function pharmacy_message_contains_relevant_info()
    {
        $notification = new CourierArrivedNotification($this->delivery, 30, 10, 100, 'pharmacy');
        $array = $notification->toArray($this->pharmacyUser);

        $this->assertStringContainsString('Livreur arrivé chez le client', $array['title']);
        $this->assertStringContainsString('30 minutes', $array['message']);
    }

    /** @test */
    public function to_fcm_returns_correct_structure()
    {
        $notification = new CourierArrivedNotification($this->delivery, 30, 10, 100, 'customer');
        $fcm = $notification->toFcm($this->customerUser);

        $this->assertArrayHasKey('title', $fcm);
        $this->assertArrayHasKey('body', $fcm);
        $this->assertArrayHasKey('data', $fcm);
    }

    /** @test */
    public function to_fcm_data_contains_countdown_info()
    {
        $notification = new CourierArrivedNotification($this->delivery, 30, 10, 100, 'customer');
        $fcm = $notification->toFcm($this->customerUser);

        $this->assertEquals('courier_arrived', $fcm['data']['type']);
        $this->assertEquals((string) $this->delivery->id, $fcm['data']['delivery_id']);
        $this->assertEquals('30', $fcm['data']['timeout_minutes']);
        $this->assertEquals('10', $fcm['data']['free_minutes']);
        $this->assertEquals('100', $fcm['data']['fee_per_minute']);
        $this->assertEquals('true', $fcm['data']['show_countdown']);
        $this->assertEquals('1800', $fcm['data']['countdown_seconds']); // 30 * 60
    }

    /** @test */
    public function notification_can_be_sent_to_customer()
    {
        Notification::fake();

        $this->customerUser->notify(new CourierArrivedNotification($this->delivery, 30, 10, 100, 'customer'));

        Notification::assertSentTo($this->customerUser, CourierArrivedNotification::class);
    }

    /** @test */
    public function notification_can_be_sent_to_courier()
    {
        Notification::fake();

        $this->courierUser->notify(new CourierArrivedNotification($this->delivery, 30, 10, 100, 'courier'));

        Notification::assertSentTo($this->courierUser, CourierArrivedNotification::class);
    }

    /** @test */
    public function notification_can_be_sent_to_pharmacy()
    {
        Notification::fake();

        $this->pharmacyUser->notify(new CourierArrivedNotification($this->delivery, 30, 10, 100, 'pharmacy'));

        Notification::assertSentTo($this->pharmacyUser, CourierArrivedNotification::class);
    }

    /** @test */
    public function default_recipient_type_returns_generic_message()
    {
        $notification = new CourierArrivedNotification($this->delivery, 30, 10, 100, 'unknown');
        $array = $notification->toArray($this->customerUser);

        $this->assertEquals('Livreur arrivé', $array['title']);
    }
}
