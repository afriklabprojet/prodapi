<?php

namespace Tests\Unit\Channels;

use App\Channels\WhatsAppChannel;
use App\Services\WhatsAppService;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class WhatsAppChannelTest extends TestCase
{
    use RefreshDatabase;

    protected WhatsAppChannel $channel;
    protected WhatsAppService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = app(WhatsAppService::class);
        $this->channel = new WhatsAppChannel($this->service);
    }

    #[Test]
    public function it_does_not_send_if_notification_has_no_toWhatsApp_method()
    {
        $user = User::factory()->create(['phone' => '+2250700000000']);
        $notification = new WhatsAppNotificationWithoutMethod();

        Http::fake();

        $this->channel->send($user, $notification);

        Http::assertNothingSent();
    }

    #[Test]
    public function it_does_not_send_if_toWhatsApp_returns_null()
    {
        $user = User::factory()->create(['phone' => '+2250700000000']);
        $notification = new WhatsAppNotificationReturnsNull();

        Http::fake();

        $this->channel->send($user, $notification);

        Http::assertNothingSent();
    }

    #[Test]
    public function it_does_not_send_if_user_has_no_phone()
    {
        Log::shouldReceive('warning')
            ->once()
            ->with('No phone number found for WhatsApp notification', \Mockery::any());

        $user = User::factory()->create(['phone' => null]);
        $notification = new WhatsAppTextNotification();

        Http::fake();

        $this->channel->send($user, $notification);

        Http::assertNothingSent();
    }

    #[Test]
    public function it_logs_text_message_when_not_configured()
    {
        config(['whatsapp.enabled' => false]);

        Log::shouldReceive('info')
            ->atLeast()->once();

        $user = User::factory()->create(['phone' => '+2250700000000']);
        $notification = new WhatsAppTextNotification();

        $this->channel->send($user, $notification);
    }

    #[Test]
    public function it_sends_text_message_via_infobip()
    {
        // Mock WhatsAppService to verify text message is sent
        $serviceMock = \Mockery::mock(WhatsAppService::class);
        $serviceMock->shouldReceive('isConfigured')->andReturn(true);
        $serviceMock->shouldReceive('sendText')
            ->once()
            ->with(\Mockery::on(fn($phone) => str_contains($phone, '2250700000000')), 'Hello from DR-PHARMA!', false)
            ->andReturn(true);

        $channel = new WhatsAppChannel($serviceMock);

        Log::shouldReceive('info')
            ->atLeast()->once();

        $user = User::factory()->create(['phone' => '+2250700000000']);
        $notification = new WhatsAppTextNotification();

        $channel->send($user, $notification);
    }

    #[Test]
    public function it_sends_template_message_via_infobip()
    {
        // Mock WhatsAppService to verify template message is sent
        $serviceMock = \Mockery::mock(WhatsAppService::class);
        $serviceMock->shouldReceive('isConfigured')->andReturn(true);
        $serviceMock->shouldReceive('sendTemplate')
            ->once()
            ->withArgs(function ($phone, $template, $language, $placeholders) {
                return str_contains($phone, '2250700000000')
                    && $template === 'order_confirmed'
                    && $language === 'fr';
            })
            ->andReturn(true);

        $channel = new WhatsAppChannel($serviceMock);

        Log::shouldReceive('info')
            ->atLeast()->once();

        $user = User::factory()->create(['phone' => '+2250700000000']);
        $notification = new WhatsAppTemplateNotification();

        $channel->send($user, $notification);
    }

    #[Test]
    public function it_handles_api_error_gracefully()
    {
        // Mock WhatsAppService to simulate failure
        $serviceMock = \Mockery::mock(WhatsAppService::class);
        $serviceMock->shouldReceive('isConfigured')->andReturn(true);
        $serviceMock->shouldReceive('sendText')
            ->once()
            ->andThrow(new \Exception('API Error: Invalid API key'));

        $channel = new WhatsAppChannel($serviceMock);

        Log::shouldReceive('error')
            ->atLeast()->once();

        $user = User::factory()->create(['phone' => '+2250700000000']);
        $notification = new WhatsAppTextNotification();

        // Should not throw exception
        $channel->send($user, $notification);
    }

    #[Test]
    public function it_sends_image_message()
    {
        // Mock WhatsAppService to verify image message is sent
        $serviceMock = \Mockery::mock(WhatsAppService::class);
        $serviceMock->shouldReceive('isConfigured')->andReturn(true);
        $serviceMock->shouldReceive('sendImage')
            ->once()
            ->with(\Mockery::on(fn($phone) => str_contains($phone, '2250700000000')), 'https://example.com/photo.jpg', 'Photo ordonnance')
            ->andReturn(true);

        $channel = new WhatsAppChannel($serviceMock);

        Log::shouldReceive('info')
            ->atLeast()->once();

        $user = User::factory()->create(['phone' => '+2250700000000']);
        $notification = new WhatsAppImageNotification();

        $channel->send($user, $notification);
    }

    #[Test]
    public function it_sends_document_message()
    {
        // Mock WhatsAppService to verify document message is sent
        $serviceMock = \Mockery::mock(WhatsAppService::class);
        $serviceMock->shouldReceive('isConfigured')->andReturn(true);
        $serviceMock->shouldReceive('sendDocument')
            ->once()
            ->withArgs(function ($phone, $url, $filename) {
                return str_contains($phone, '2250700000000')
                    && $url === 'https://example.com/invoice.pdf'
                    && $filename === 'facture.pdf';
            })
            ->andReturn(true);

        $channel = new WhatsAppChannel($serviceMock);

        Log::shouldReceive('info')
            ->atLeast()->once();

        $user = User::factory()->create(['phone' => '+2250700000000']);
        $notification = new WhatsAppDocumentNotification();

        $channel->send($user, $notification);
    }
}

// ──────────────────────────────────────────────────────────────────────────────
// Test notification classes
// ──────────────────────────────────────────────────────────────────────────────

class WhatsAppNotificationWithoutMethod extends Notification
{
    public function via($notifiable)
    {
        return [\App\Channels\WhatsAppChannel::class];
    }
}

class WhatsAppNotificationReturnsNull extends Notification
{
    public function via($notifiable)
    {
        return [\App\Channels\WhatsAppChannel::class];
    }

    public function toWhatsApp($notifiable)
    {
        return null;
    }
}

class WhatsAppTextNotification extends Notification
{
    public function via($notifiable)
    {
        return [\App\Channels\WhatsAppChannel::class];
    }

    public function toWhatsApp($notifiable)
    {
        return [
            'type' => 'text',
            'text' => 'Hello from DR-PHARMA!',
        ];
    }
}

class WhatsAppTemplateNotification extends Notification
{
    public function via($notifiable)
    {
        return [\App\Channels\WhatsAppChannel::class];
    }

    public function toWhatsApp($notifiable)
    {
        return [
            'type' => 'template',
            'template_name' => 'order_confirmed',
            'language' => 'fr',
            'placeholders' => ['John', 'CMD-001', 'Pharmacie Test'],
        ];
    }
}

class WhatsAppImageNotification extends Notification
{
    public function via($notifiable)
    {
        return [\App\Channels\WhatsAppChannel::class];
    }

    public function toWhatsApp($notifiable)
    {
        return [
            'type' => 'image',
            'url' => 'https://example.com/photo.jpg',
            'caption' => 'Photo ordonnance',
        ];
    }
}

class WhatsAppDocumentNotification extends Notification
{
    public function via($notifiable)
    {
        return [\App\Channels\WhatsAppChannel::class];
    }

    public function toWhatsApp($notifiable)
    {
        return [
            'type' => 'document',
            'url' => 'https://example.com/invoice.pdf',
            'filename' => 'facture.pdf',
            'caption' => 'Votre facture',
        ];
    }
}
