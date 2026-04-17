<?php

namespace Tests\Unit\Notifications;

use App\Channels\FcmChannel;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\TeamInvitation;
use App\Models\User;
use App\Notifications\CourierCancelledDeliveryNotification;
use App\Notifications\KycStatusNotification;
use App\Notifications\LowStockAlertNotification;
use App\Notifications\NewChatMessageNotification;
use App\Notifications\PaymentFailedNotification;
use App\Notifications\PayoutCompletedNotification;
use App\Notifications\PrescriptionRejectedNotification;
use App\Notifications\TeamInvitationNotification;
use Tests\TestCase;

class NotificationsExtendedTest extends TestCase
{
    public function test_kyc_status_notification_via_includes_database(): void
    {
        $notification = new KycStatusNotification('verified');
        $user = new User();
        $channels = $notification->via($user);
        $this->assertContains('database', $channels);
    }

    public function test_kyc_status_notification_to_array(): void
    {
        $notification = new KycStatusNotification('verified');
        $user = new User();
        $data = $notification->toArray($user);
        $this->assertIsArray($data);
        $this->assertArrayHasKey('type', $data);
    }

    public function test_kyc_status_with_rejection_reason(): void
    {
        $notification = new KycStatusNotification('rejected', 'Document flou');
        $user = new User();
        $data = $notification->toArray($user);
        $this->assertIsArray($data);
    }

    public function test_low_stock_alert_notification(): void
    {
        $products = [
            ['name' => 'Paracetamol', 'stock' => 2],
            ['name' => 'Ibuprofen', 'stock' => 1],
        ];
        $notification = new LowStockAlertNotification($products);
        $user = new User();
        $channels = $notification->via($user);
        $this->assertContains('database', $channels);
    }

    public function test_low_stock_alert_to_array(): void
    {
        $notification = new LowStockAlertNotification([['name' => 'Test', 'stock' => 1]]);
        $user = new User();
        $data = $notification->toArray($user);
        $this->assertIsArray($data);
    }

    public function test_new_chat_message_notification(): void
    {
        $delivery = new Delivery();
        $delivery->id = 1;
        $notification = new NewChatMessageNotification($delivery, 'John', 'courier', 'Hello');
        $user = new User();
        $channels = $notification->via($user);
        $this->assertContains(FcmChannel::class, $channels);
        $this->assertContains('database', $channels);
    }

    public function test_new_chat_message_to_array(): void
    {
        $delivery = new Delivery();
        $delivery->id = 1;
        $notification = new NewChatMessageNotification($delivery, 'John', 'courier', 'Hello');
        $user = new User();
        $data = $notification->toArray($user);
        $this->assertIsArray($data);
    }

    public function test_payment_failed_notification(): void
    {
        $order = new Order();
        $order->id = 1;
        $order->reference = 'CMD-TEST';
        $notification = new PaymentFailedNotification($order, 'Insufficient funds');
        $user = new User();
        $channels = $notification->via($user);
        $this->assertContains('database', $channels);
    }

    public function test_payment_failed_to_array(): void
    {
        $order = new Order();
        $order->id = 1;
        $order->reference = 'CMD-TEST';
        $notification = new PaymentFailedNotification($order, 'Insufficient funds');
        $user = new User();
        $data = $notification->toArray($user);
        $this->assertIsArray($data);
    }

    public function test_payout_completed_notification(): void
    {
        $notification = new PayoutCompletedNotification(10000, 'PAY-001');
        $user = new User();
        $channels = $notification->via($user);
        $this->assertContains('database', $channels);
    }

    public function test_payout_completed_to_array(): void
    {
        $notification = new PayoutCompletedNotification(10000, 'PAY-001');
        $user = new User();
        $data = $notification->toArray($user);
        $this->assertIsArray($data);
    }

    public function test_courier_cancelled_delivery_notification(): void
    {
        $delivery = new Delivery();
        $delivery->id = 1;
        $notification = new CourierCancelledDeliveryNotification($delivery, 'Accident');
        $user = new User();
        $channels = $notification->via($user);
        $this->assertContains('database', $channels);
    }

    public function test_courier_cancelled_delivery_to_array(): void
    {
        $order = new Order();
        $order->id = 10;
        $order->reference = 'CMD-CANCEL';

        $delivery = new Delivery();
        $delivery->id = 1;
        $delivery->setRelation('order', $order);

        $notification = new CourierCancelledDeliveryNotification($delivery, 'Accident');
        $user = new User();
        $data = $notification->toArray($user);
        $this->assertIsArray($data);
        $this->assertEquals('courier_cancelled', $data['type']);
    }

    public function test_prescription_rejected_notification(): void
    {
        $order = new Order();
        $order->id = 1;
        $order->reference = 'CMD-TEST';
        $notification = new PrescriptionRejectedNotification($order, 'Document illisible');
        $user = new User();
        $channels = $notification->via($user);
        $this->assertContains('database', $channels);
    }

    public function test_prescription_rejected_to_array(): void
    {
        $pharmacy = new \App\Models\Pharmacy();
        $pharmacy->id = 1;
        $pharmacy->name = 'Test Pharmacie';

        $order = new Order();
        $order->id = 1;
        $order->reference = 'CMD-TEST';
        $order->setRelation('pharmacy', $pharmacy);

        $notification = new PrescriptionRejectedNotification($order, 'Document illisible');
        $user = new User();
        $data = $notification->toArray($user);
        $this->assertIsArray($data);
        $this->assertEquals('prescription_rejected', $data['type']);
        $this->assertEquals('Document illisible', $data['reason']);
    }
}
