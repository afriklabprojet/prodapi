<?php

namespace Tests\Unit\Notifications;

use App\Channels\FcmChannel;
use App\Channels\SmsChannel;
use App\Models\Courier;
use App\Models\Customer;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use App\Notifications\OrderDeliveredToPharmacyNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OrderDeliveredToPharmacyNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected Order $order;
    protected Delivery $delivery;
    protected User $pharmacyUser;

    protected function setUp(): void
    {
        parent::setUp();

        $this->pharmacyUser = User::factory()->create([
            'role' => 'pharmacy',
            'phone' => '+213600000002',
            'email' => 'pharmacy@test.com',
            'fcm_token' => 'fcm-token-pharmacy',
        ]);

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $pharmacy->users()->attach($this->pharmacyUser->id);

        $customerUser = User::factory()->create(['role' => 'customer', 'name' => 'Ahmed Benali']);
        Customer::factory()->create(['user_id' => $customerUser->id]);

        $courierUser = User::factory()->create(['role' => 'courier', 'name' => 'Karim Livreur']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);

        $this->order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $customerUser->id,
            'reference' => 'DR-DEL-001',
            'total_amount' => 7500,
        ]);

        $this->delivery = Delivery::factory()->create([
            'order_id' => $this->order->id,
            'courier_id' => $courier->id,
        ]);
    }

    public function test_can_be_constructed(): void
    {
        $notification = new OrderDeliveredToPharmacyNotification($this->order, $this->delivery);
        $this->assertInstanceOf(OrderDeliveredToPharmacyNotification::class, $notification);
    }

    public function test_via_includes_database(): void
    {
        $notification = new OrderDeliveredToPharmacyNotification($this->order, $this->delivery);
        $channels = $notification->via($this->pharmacyUser);
        $this->assertContains('database', $channels);
    }

    public function test_via_includes_mail_when_email_present(): void
    {
        $notification = new OrderDeliveredToPharmacyNotification($this->order, $this->delivery);
        $channels = $notification->via($this->pharmacyUser);
        $this->assertContains('mail', $channels);
    }

    public function test_via_includes_fcm_when_token_present(): void
    {
        $notification = new OrderDeliveredToPharmacyNotification($this->order, $this->delivery);
        $channels = $notification->via($this->pharmacyUser);
        $this->assertContains(FcmChannel::class, $channels);
    }

    public function test_via_includes_sms_when_phone_present(): void
    {
        $notification = new OrderDeliveredToPharmacyNotification($this->order, $this->delivery);
        $channels = $notification->via($this->pharmacyUser);
        $this->assertContains(SmsChannel::class, $channels);
    }

    public function test_via_excludes_mail_when_no_email(): void
    {
        $userNoEmail = User::factory()->create([
            'role' => 'pharmacy',
            'email' => null,
            'phone' => null,
            'fcm_token' => null,
        ]);

        $notification = new OrderDeliveredToPharmacyNotification($this->order, $this->delivery);
        $channels = $notification->via($userNoEmail);
        $this->assertNotContains('mail', $channels);
    }

    public function test_to_array_returns_correct_type(): void
    {
        $notification = new OrderDeliveredToPharmacyNotification($this->order, $this->delivery);
        $data = $notification->toArray($this->pharmacyUser);

        $this->assertEquals('order_delivered', $data['type']);
    }

    public function test_to_array_contains_order_reference(): void
    {
        $notification = new OrderDeliveredToPharmacyNotification($this->order, $this->delivery);
        $data = $notification->toArray($this->pharmacyUser);

        $this->assertEquals('DR-DEL-001', $data['order_reference']);
    }

    public function test_to_array_contains_delivery_id(): void
    {
        $notification = new OrderDeliveredToPharmacyNotification($this->order, $this->delivery);
        $data = $notification->toArray($this->pharmacyUser);

        $this->assertEquals($this->delivery->id, $data['delivery_id']);
    }

    public function test_to_array_contains_total_amount(): void
    {
        $notification = new OrderDeliveredToPharmacyNotification($this->order, $this->delivery);
        $data = $notification->toArray($this->pharmacyUser);

        $this->assertEquals(7500, $data['total_amount']);
    }

    public function test_to_array_contains_delivered_at(): void
    {
        $notification = new OrderDeliveredToPharmacyNotification($this->order, $this->delivery);
        $data = $notification->toArray($this->pharmacyUser);

        $this->assertArrayHasKey('delivered_at', $data);
        $this->assertNotNull($data['delivered_at']);
    }

    public function test_to_fcm_returns_array_with_title(): void
    {
        $notification = new OrderDeliveredToPharmacyNotification($this->order, $this->delivery);
        $data = $notification->toFcm($this->pharmacyUser);

        $this->assertIsArray($data);
        $this->assertArrayHasKey('title', $data);
        $this->assertArrayHasKey('body', $data);
        $this->assertArrayHasKey('data', $data);
    }

    public function test_to_fcm_data_contains_correct_type(): void
    {
        $notification = new OrderDeliveredToPharmacyNotification($this->order, $this->delivery);
        $data = $notification->toFcm($this->pharmacyUser);

        $this->assertEquals('order_delivered', $data['data']['type']);
    }
}
