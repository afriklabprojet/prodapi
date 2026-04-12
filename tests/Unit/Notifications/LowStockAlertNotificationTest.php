<?php

namespace Tests\Unit\Notifications;

use App\Notifications\LowStockAlertNotification;
use App\Models\User;
use App\Channels\FcmChannel;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class LowStockAlertNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected array $products;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create([
            'email' => 'pharma@test.com',
            'fcm_token' => 'test_fcm_token',
        ]);

        $this->products = [
            ['name' => 'Paracétamol 500mg', 'quantity' => 3, 'threshold' => 10],
            ['name' => 'Amoxicilline 250mg', 'quantity' => 1, 'threshold' => 5],
        ];
    }

    #[Test]
    public function via_includes_database()
    {
        $notification = new LowStockAlertNotification($this->products);
        $channels = $notification->via($this->user);

        $this->assertContains('database', $channels);
    }

    #[Test]
    public function via_includes_fcm_when_user_has_token()
    {
        $notification = new LowStockAlertNotification($this->products);
        $channels = $notification->via($this->user);

        $this->assertContains(FcmChannel::class, $channels);
    }

    #[Test]
    public function via_includes_mail_when_user_has_email()
    {
        $notification = new LowStockAlertNotification($this->products);
        $channels = $notification->via($this->user);

        $this->assertContains('mail', $channels);
    }

    #[Test]
    public function to_fcm_single_product()
    {
        $singleProduct = [['name' => 'Paracétamol', 'quantity' => 2, 'threshold' => 10]];
        $notification = new LowStockAlertNotification($singleProduct);
        $fcm = $notification->toFcm($this->user);

        $this->assertArrayHasKey('title', $fcm);
        $this->assertArrayHasKey('body', $fcm);
        $this->assertEquals('low_stock', $fcm['data']['type']);
        $this->assertStringContainsString('Paracétamol', $fcm['body']);
    }

    #[Test]
    public function to_fcm_multiple_products()
    {
        $notification = new LowStockAlertNotification($this->products);
        $fcm = $notification->toFcm($this->user);

        $this->assertEquals('2', $fcm['data']['product_count']);
        $this->assertStringContainsString('2 produits', $fcm['body']);
    }

    #[Test]
    public function to_mail_returns_mail_message()
    {
        $notification = new LowStockAlertNotification($this->products);
        $mail = $notification->toMail($this->user);

        $this->assertInstanceOf(MailMessage::class, $mail);
    }

    #[Test]
    public function to_array_returns_correct_structure()
    {
        $notification = new LowStockAlertNotification($this->products);
        $array = $notification->toArray($this->user);

        $this->assertEquals('low_stock', $array['type']);
        $this->assertCount(2, $array['products']);
        $this->assertArrayHasKey('message', $array);
    }

    #[Test]
    public function notification_can_be_sent()
    {
        Notification::fake();

        $this->user->notify(new LowStockAlertNotification($this->products));

        Notification::assertSentTo($this->user, LowStockAlertNotification::class);
    }
}
