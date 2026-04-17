<?php

namespace Tests\Unit\Notifications;

use App\Notifications\NewChatMessageNotification;
use App\Models\User;
use App\Models\Delivery;
use App\Models\Order;
use App\Models\Courier;
use App\Models\Customer;
use App\Models\Pharmacy;
use App\Channels\FcmChannel;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class NewChatMessageNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Delivery $delivery;

    protected function setUp(): void
    {
        parent::setUp();

        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $customerUser = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $customerUser->id]);

        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);

        $order = Order::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $customerUser->id,
        ]);

        $this->delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $courier->id,
            'status' => 'in_transit',
        ]);

        $this->user = User::factory()->create([
            'fcm_token' => 'test_fcm_token',
            'phone' => '+22500000000',
        ]);
    }

    #[Test]
    public function via_includes_fcm_and_database()
    {
        $notification = new NewChatMessageNotification($this->delivery, 'John', 'courier', 'Bonjour');
        $channels = $notification->via($this->user);

        $this->assertContains(FcmChannel::class, $channels);
        $this->assertContains('database', $channels);
    }

    #[Test]
    public function to_fcm_returns_correct_structure()
    {
        $notification = new NewChatMessageNotification($this->delivery, 'John', 'courier', 'Je suis en route');
        $fcm = $notification->toFcm($this->user);

        $this->assertArrayHasKey('title', $fcm);
        $this->assertArrayHasKey('body', $fcm);
        $this->assertArrayHasKey('data', $fcm);
        $this->assertEquals('chat_message', $fcm['data']['type']);
        $this->assertEquals((string) $this->delivery->id, $fcm['data']['delivery_id']);
        $this->assertEquals('courier', $fcm['data']['sender_type']);
        $this->assertStringContainsString('Livreur', $fcm['title']);
    }

    #[Test]
    public function to_fcm_truncates_long_messages()
    {
        $longMessage = str_repeat('A', 200);
        $notification = new NewChatMessageNotification($this->delivery, 'John', 'courier', $longMessage);
        $fcm = $notification->toFcm($this->user);

        $this->assertStringContainsString('...', $fcm['body']);
    }

    #[Test]
    public function to_fcm_sender_labels()
    {
        $notification = new NewChatMessageNotification($this->delivery, 'Pharma', 'pharmacy', 'Commande prête');
        $fcm = $notification->toFcm($this->user);
        $this->assertStringContainsString('Pharmacie', $fcm['title']);

        $notification = new NewChatMessageNotification($this->delivery, 'Ali', 'client', 'Merci');
        $fcm = $notification->toFcm($this->user);
        $this->assertStringContainsString('Client', $fcm['title']);
    }

    #[Test]
    public function to_array_returns_correct_structure()
    {
        $notification = new NewChatMessageNotification($this->delivery, 'John', 'courier', 'Bonjour');
        $array = $notification->toArray($this->user);

        $this->assertEquals('chat_message', $array['type']);
        $this->assertEquals($this->delivery->id, $array['delivery_id']);
        $this->assertEquals('courier', $array['sender_type']);
        $this->assertEquals('John', $array['sender_name']);
        $this->assertEquals('Bonjour', $array['message']);
        $this->assertArrayHasKey('message_preview', $array);
    }

    #[Test]
    public function to_whatsapp_returns_correct_structure()
    {
        $notification = new NewChatMessageNotification($this->delivery, 'John', 'courier', 'Bonjour');
        $wa = $notification->toWhatsApp($this->user);

        $this->assertEquals('template', $wa['type']);
        $this->assertEquals('new_chat_message', $wa['template_name']);
        $this->assertCount(3, $wa['placeholders']);
        $this->assertEquals('Livreur', $wa['placeholders'][0]);
    }

    #[Test]
    public function notification_can_be_sent()
    {
        Notification::fake();

        $this->user->notify(new NewChatMessageNotification($this->delivery, 'John', 'courier', 'Test'));

        Notification::assertSentTo($this->user, NewChatMessageNotification::class);
    }
}
