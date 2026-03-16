<?php

namespace Tests\Unit\Notifications;

use App\Notifications\CourierArrivedAtClientNotification;
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

class CourierArrivedAtClientNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected $delivery;
    protected $order;
    protected $pharmacyUser;
    protected $courier;

    protected function setUp(): void
    {
        parent::setUp();

        $pharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
            'name' => 'Pharmacie Test',
        ]);
        
        $this->pharmacyUser = User::factory()->create([
            'role' => 'pharmacy',
            'fcm_token' => 'pharmacy_fcm_token',
        ]);

        $customerUser = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $customerUser->id]);

        $courierUser = User::factory()->create([
            'role' => 'courier',
            'name' => 'Jean Coursier',
        ]);

        $this->courier = Courier::factory()->create([
            'user_id' => $courierUser->id,
            'status' => 'busy',
        ]);

        $this->order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $customerUser->id,
            'status' => 'in_delivery',
            'reference' => 'CMD-CLIENT-001',
        ]);

        $this->delivery = Delivery::factory()->create([
            'order_id' => $this->order->id,
            'courier_id' => $this->courier->id,
            'status' => 'arrived',
            'waiting_started_at' => Carbon::now(),
        ]);
    }

    /** @test */
    public function it_can_be_constructed_with_all_parameters()
    {
        $notification = new CourierArrivedAtClientNotification(
            $this->delivery,
            30, // timeout minutes
            100 // fee per minute
        );

        $this->assertInstanceOf(CourierArrivedAtClientNotification::class, $notification);
        $this->assertEquals($this->delivery->id, $notification->delivery->id);
        $this->assertEquals(30, $notification->timeoutMinutes);
        $this->assertEquals(100, $notification->feePerMinute);
    }

    /** @test */
    public function via_returns_database_and_fcm_channels()
    {
        $notification = new CourierArrivedAtClientNotification($this->delivery, 30, 100);
        $channels = $notification->via($this->pharmacyUser);

        $this->assertContains('database', $channels);
        $this->assertContains(FcmChannel::class, $channels);
    }

    /** @test */
    public function to_database_returns_correct_structure()
    {
        $notification = new CourierArrivedAtClientNotification($this->delivery, 30, 100);
        $data = $notification->toDatabase($this->pharmacyUser);

        $this->assertEquals('courier_arrived_at_client', $data['type']);
        $this->assertEquals($this->delivery->id, $data['delivery_id']);
        $this->assertEquals($this->order->id, $data['order_id']);
        $this->assertEquals($this->order->reference, $data['order_reference']);
        $this->assertEquals(30, $data['timeout_minutes']);
        $this->assertEquals(100, $data['fee_per_minute']);
    }

    /** @test */
    public function to_database_contains_message_with_order_reference()
    {
        $notification = new CourierArrivedAtClientNotification($this->delivery, 30, 100);
        $data = $notification->toDatabase($this->pharmacyUser);

        $this->assertStringContainsString('coursier est arrivé', $data['message']);
        $this->assertStringContainsString($this->order->reference, $data['message']);
    }

    /** @test */
    public function to_database_contains_warning_about_timeout()
    {
        $notification = new CourierArrivedAtClientNotification($this->delivery, 30, 100);
        $data = $notification->toDatabase($this->pharmacyUser);

        $this->assertStringContainsString('30 minutes', $data['warning']);
    }

    /** @test */
    public function to_database_contains_countdown_started_at()
    {
        $notification = new CourierArrivedAtClientNotification($this->delivery, 30, 100);
        $data = $notification->toDatabase($this->pharmacyUser);

        $this->assertArrayHasKey('countdown_started_at', $data);
    }

    /** @test */
    public function to_fcm_returns_correct_structure()
    {
        $notification = new CourierArrivedAtClientNotification($this->delivery, 30, 100);
        $fcm = $notification->toFcm($this->pharmacyUser);

        $this->assertArrayHasKey('title', $fcm);
        $this->assertArrayHasKey('body', $fcm);
        $this->assertArrayHasKey('data', $fcm);
        $this->assertEquals('Coursier arrivé chez le client', $fcm['title']);
    }

    /** @test */
    public function to_fcm_body_contains_countdown_info()
    {
        $notification = new CourierArrivedAtClientNotification($this->delivery, 30, 100);
        $fcm = $notification->toFcm($this->pharmacyUser);

        $this->assertStringContainsString($this->order->reference, $fcm['body']);
        $this->assertStringContainsString('30 minutes', $fcm['body']);
    }

    /** @test */
    public function to_fcm_data_contains_all_required_fields()
    {
        $notification = new CourierArrivedAtClientNotification($this->delivery, 30, 100);
        $fcm = $notification->toFcm($this->pharmacyUser);

        $this->assertEquals('courier_arrived_at_client', $fcm['data']['type']);
        $this->assertEquals((string) $this->delivery->id, $fcm['data']['delivery_id']);
        $this->assertEquals((string) $this->order->id, $fcm['data']['order_id']);
        $this->assertEquals($this->order->reference, $fcm['data']['order_reference']);
        $this->assertEquals('30', $fcm['data']['timeout_minutes']);
        $this->assertEquals('100', $fcm['data']['fee_per_minute']);
        $this->assertEquals('ORDER_DETAIL', $fcm['data']['click_action']);
    }

    /** @test */
    public function notification_can_be_sent()
    {
        Notification::fake();

        $this->pharmacyUser->notify(new CourierArrivedAtClientNotification($this->delivery, 30, 100));

        Notification::assertSentTo($this->pharmacyUser, CourierArrivedAtClientNotification::class);
    }

    /** @test */
    public function notification_implements_should_queue()
    {
        $notification = new CourierArrivedAtClientNotification($this->delivery, 30, 100);

        $this->assertInstanceOf(\Illuminate\Contracts\Queue\ShouldQueue::class, $notification);
    }
}
