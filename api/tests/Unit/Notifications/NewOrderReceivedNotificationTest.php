<?php

namespace Tests\Unit\Notifications;

use App\Channels\FcmChannel;
use App\Channels\SmsChannel;
use App\Channels\WhatsAppChannel;
use App\Models\Customer;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use App\Notifications\NewOrderReceivedNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NewOrderReceivedNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected Order $order;
    protected User $pharmacyUser;

    protected function setUp(): void
    {
        parent::setUp();

        $this->pharmacyUser = User::factory()->create([
            'role' => 'pharmacy',
            'phone' => '+213600000001',
            'fcm_token' => 'test-fcm-token',
        ]);

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $pharmacy->users()->attach($this->pharmacyUser->id);

        $customerUser = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $customerUser->id]);

        $this->order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $customerUser->id,
            'reference' => 'DR-RCV-001',
            'total_amount' => 3500,
        ]);
    }

    public function test_can_be_constructed(): void
    {
        $notification = new NewOrderReceivedNotification($this->order);
        $this->assertInstanceOf(NewOrderReceivedNotification::class, $notification);
        $this->assertEquals($this->order->id, $notification->order->id);
    }

    public function test_via_includes_database(): void
    {
        $notification = new NewOrderReceivedNotification($this->order);
        $channels = $notification->via($this->pharmacyUser);
        $this->assertContains('database', $channels);
    }

    public function test_via_includes_fcm(): void
    {
        $notification = new NewOrderReceivedNotification($this->order);
        $channels = $notification->via($this->pharmacyUser);
        $this->assertContains(FcmChannel::class, $channels);
    }

    public function test_via_includes_sms_when_phone_present(): void
    {
        $notification = new NewOrderReceivedNotification($this->order);
        $channels = $notification->via($this->pharmacyUser);
        $this->assertContains(SmsChannel::class, $channels);
    }

    public function test_via_excludes_sms_when_no_phone(): void
    {
        $userNoPhone = User::factory()->create(['role' => 'pharmacy', 'phone' => null]);

        config(['whatsapp.notifications.order_status' => false]);

        $notification = new NewOrderReceivedNotification($this->order);
        $channels = $notification->via($userNoPhone);
        $this->assertNotContains(SmsChannel::class, $channels);
        $this->assertNotContains(WhatsAppChannel::class, $channels);
    }

    public function test_to_database_returns_array(): void
    {
        $notification = new NewOrderReceivedNotification($this->order);
        $data = $notification->toDatabase($this->pharmacyUser);

        $this->assertIsArray($data);
        $this->assertEquals('new_order_received', $data['type']);
    }

    public function test_to_database_contains_order_reference(): void
    {
        $notification = new NewOrderReceivedNotification($this->order);
        $data = $notification->toDatabase($this->pharmacyUser);

        $this->assertEquals('DR-RCV-001', $data['order_reference']);
    }

    public function test_to_database_contains_order_id(): void
    {
        $notification = new NewOrderReceivedNotification($this->order);
        $data = $notification->toDatabase($this->pharmacyUser);

        $this->assertEquals($this->order->id, $data['order_id']);
    }

    public function test_to_database_contains_total_amount(): void
    {
        $notification = new NewOrderReceivedNotification($this->order);
        $data = $notification->toDatabase($this->pharmacyUser);

        $this->assertEquals(3500, $data['total_amount']);
    }

    public function test_to_database_contains_has_prescription_flag(): void
    {
        $notification = new NewOrderReceivedNotification($this->order);
        $data = $notification->toDatabase($this->pharmacyUser);

        $this->assertArrayHasKey('has_prescription', $data);
    }

    public function test_to_fcm_returns_array(): void
    {
        config(['whatsapp.notifications.order_status' => false]);

        $notification = new NewOrderReceivedNotification($this->order);
        $data = $notification->toFcm($this->pharmacyUser);

        $this->assertIsArray($data);
        $this->assertArrayHasKey('title', $data);
        $this->assertArrayHasKey('body', $data);
    }
}
