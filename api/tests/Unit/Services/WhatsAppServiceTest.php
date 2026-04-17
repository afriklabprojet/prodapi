<?php

namespace Tests\Unit\Services;

use App\Services\Infobip\InfobipClientFactory;
use App\Services\WhatsAppService;
use GuzzleHttp\Client;
use GuzzleHttp\Handler\MockHandler;
use GuzzleHttp\HandlerStack;
use GuzzleHttp\Middleware;
use GuzzleHttp\Psr7\Response as GuzzleResponse;
use GuzzleHttp\Psr7\Request as GuzzleRequest;
use GuzzleHttp\Exception\RequestException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Infobip\Api\WhatsAppApi;
use Infobip\Configuration;
use Mockery;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class WhatsAppServiceTest extends TestCase
{
    protected array $httpHistory = [];

    protected function getConfiguredService(array $responses = []): WhatsAppService
    {
        config([
            'whatsapp.enabled' => true,
            'whatsapp.base_url' => 'https://test.api.infobip.com',
            'whatsapp.api_key' => 'test_api_key_123',
            'whatsapp.sender_number' => '2250100000000',
            'whatsapp.default_language' => 'fr',
            'whatsapp.default_country_code' => '+225',
        ]);

        $this->httpHistory = [];
        $mockHandler = new MockHandler($responses);
        $handlerStack = HandlerStack::create($mockHandler);
        $handlerStack->push(Middleware::history($this->httpHistory));
        $mockClient = new Client(['handler' => $handlerStack]);

        $config = new Configuration(
            host: 'https://test.api.infobip.com',
            apiKey: 'test_api_key_123',
        );
        $realApi = new WhatsAppApi(config: $config, client: $mockClient);

        $mockFactory = Mockery::mock(InfobipClientFactory::class);
        $mockFactory->shouldReceive('whatsAppApi')->andReturn($realApi);
        $mockFactory->shouldReceive('isWhatsAppConfigured')->andReturn(true);

        $this->app->instance(InfobipClientFactory::class, $mockFactory);

        return app(WhatsAppService::class);
    }

    protected function jsonResponse(array $data, int $status = 200): GuzzleResponse
    {
        return new GuzzleResponse($status, ['Content-Type' => 'application/json'], json_encode($data));
    }

    protected function singleMessageResponse(string $messageId = 'msg-123'): GuzzleResponse
    {
        return $this->jsonResponse([
            'to' => '+2250700000000',
            'messageCount' => 1,
            'messageId' => $messageId,
            'status' => ['groupId' => 1, 'groupName' => 'PENDING', 'id' => 7, 'name' => 'PENDING_ENROUTE'],
        ]);
    }

    protected function bulkMessageResponse(string $messageId = 'tpl-123'): GuzzleResponse
    {
        return $this->jsonResponse([
            'messages' => [[
                'to' => '+2250700000000',
                'messageCount' => 1,
                'messageId' => $messageId,
                'status' => ['groupId' => 1, 'groupName' => 'PENDING'],
            ]],
            'bulkId' => 'bulk-456',
        ]);
    }

    #[Test]
    public function it_reports_not_configured_when_disabled()
    {
        config(['whatsapp.enabled' => false]);
        $service = app(WhatsAppService::class);

        $this->assertFalse($service->isConfigured());
    }

    #[Test]
    public function it_reports_not_configured_when_missing_credentials()
    {
        config([
            'whatsapp.enabled' => true,
            'whatsapp.base_url' => '',
            'whatsapp.api_key' => '',
        ]);
        $service = app(WhatsAppService::class);

        $this->assertFalse($service->isConfigured());
    }

    #[Test]
    public function it_reports_configured_with_valid_credentials()
    {
        $service = $this->getConfiguredService();

        $this->assertTrue($service->isConfigured());
    }

    #[Test]
    public function it_normalizes_local_phone_numbers()
    {
        $service = $this->getConfiguredService();

        $this->assertEquals('+225712345678', $service->normalizePhone('0712345678'));
    }

    #[Test]
    public function it_normalizes_phone_without_plus()
    {
        $service = $this->getConfiguredService();

        $this->assertEquals('+2250712345678', $service->normalizePhone('2250712345678'));
    }

    #[Test]
    public function it_keeps_international_format_phone()
    {
        $service = $this->getConfiguredService();

        $this->assertEquals('+2250712345678', $service->normalizePhone('+2250712345678'));
    }

    #[Test]
    public function it_removes_spaces_and_dashes_from_phone()
    {
        $service = $this->getConfiguredService();

        $this->assertEquals('+2250712345678', $service->normalizePhone('+225 07 12 34 56 78'));
    }

    #[Test]
    public function it_sends_text_message_successfully()
    {
        $service = $this->getConfiguredService([
            $this->singleMessageResponse('txt-123'),
        ]);

        $result = $service->sendText('+2250700000000', 'Bonjour!');

        $this->assertTrue($result);
        $this->assertCount(1, $this->httpHistory);
        $body = json_decode($this->httpHistory[0]['request']->getBody()->getContents(), true);
        $this->assertEquals('2250100000000', $body['from']);
        $this->assertEquals('+2250700000000', $body['to']);
        $this->assertEquals('Bonjour!', $body['content']['text']);
    }

    #[Test]
    public function it_sends_template_message_successfully()
    {
        $service = $this->getConfiguredService([
            $this->bulkMessageResponse('tpl-123'),
        ]);

        $result = $service->sendTemplate(
            to: '+2250700000000',
            templateName: 'order_confirmed',
            language: 'fr',
            placeholders: ['Jean', 'CMD-001', 'Pharmacie du Plateau'],
        );

        $this->assertTrue($result);
        $this->assertCount(1, $this->httpHistory);
        $body = json_decode($this->httpHistory[0]['request']->getBody()->getContents(), true);
        $message = $body['messages'][0];
        $this->assertEquals('order_confirmed', $message['content']['templateName']);
        $this->assertEquals('fr', $message['content']['language']);
        $this->assertEquals(['Jean', 'CMD-001', 'Pharmacie du Plateau'], $message['content']['templateData']['body']['placeholders']);
    }

    #[Test]
    public function it_sends_template_with_header_and_buttons()
    {
        $service = $this->getConfiguredService([
            $this->bulkMessageResponse('tpl-789'),
        ]);

        $result = $service->sendTemplate(
            to: '+2250700000000',
            templateName: 'order_confirmed',
            placeholders: ['Jean', 'CMD-001'],
            header: ['type' => 'TEXT', 'placeholder' => 'Commande CMD-001'],
            buttons: [['type' => 'QUICK_REPLY', 'parameter' => 'confirm']],
        );

        $this->assertTrue($result);
        $body = json_decode($this->httpHistory[0]['request']->getBody()->getContents(), true);
        $tplData = $body['messages'][0]['content']['templateData'];
        $this->assertArrayHasKey('header', $tplData);
        $this->assertArrayHasKey('buttons', $tplData);
    }

    #[Test]
    public function it_sends_image_message_successfully()
    {
        $service = $this->getConfiguredService([
            $this->singleMessageResponse('img-123'),
        ]);

        $result = $service->sendImage(
            to: '+2250700000000',
            imageUrl: 'https://example.com/prescription.jpg',
            caption: 'Votre ordonnance',
        );

        $this->assertTrue($result);
        $body = json_decode($this->httpHistory[0]['request']->getBody()->getContents(), true);
        $this->assertEquals('https://example.com/prescription.jpg', $body['content']['mediaUrl']);
        $this->assertEquals('Votre ordonnance', $body['content']['caption']);
    }

    #[Test]
    public function it_sends_document_message_successfully()
    {
        $service = $this->getConfiguredService([
            $this->singleMessageResponse('doc-123'),
        ]);

        $result = $service->sendDocument(
            to: '+2250700000000',
            documentUrl: 'https://example.com/facture.pdf',
            filename: 'facture_CMD001.pdf',
            caption: 'Facture de votre commande',
        );

        $this->assertTrue($result);
        $body = json_decode($this->httpHistory[0]['request']->getBody()->getContents(), true);
        $this->assertEquals('https://example.com/facture.pdf', $body['content']['mediaUrl']);
        $this->assertEquals('facture_CMD001.pdf', $body['content']['filename']);
    }

    #[Test]
    public function it_sends_location_message_successfully()
    {
        $service = $this->getConfiguredService([
            $this->singleMessageResponse('loc-123'),
        ]);

        $result = $service->sendLocation(
            to: '+2250700000000',
            latitude: 5.3411,
            longitude: -4.0280,
            name: 'Pharmacie du Plateau',
            address: 'Rue du Commerce, Abidjan',
        );

        $this->assertTrue($result);
        $body = json_decode($this->httpHistory[0]['request']->getBody()->getContents(), true);
        $this->assertEquals(5.3411, $body['content']['latitude']);
        $this->assertEquals(-4.0280, $body['content']['longitude']);
        $this->assertEquals('Pharmacie du Plateau', $body['content']['name']);
    }

    #[Test]
    public function it_sends_order_status_message_successfully()
    {
        $service = $this->getConfiguredService();

        Http::fake([
            'test.api.infobip.com/whatsapp/1/message/interactive/order-status' => Http::response([
                'messageId' => 'os-123',
                'status' => ['groupName' => 'PENDING'],
            ], 200),
        ]);

        $result = $service->sendOrderStatus(
            to: '+2250700000000',
            orderReference: 'CMD-20260216-001',
            status: 'confirmed',
            description: 'Votre commande a été confirmée par la pharmacie.',
        );

        $this->assertTrue($result);

        Http::assertSent(function ($request) {
            return str_contains($request->url(), '/order-status')
                && $request['content']['action']['status'] === 'PROCESSING';
        });
    }

    #[Test]
    public function it_maps_order_statuses_correctly()
    {
        $service = $this->getConfiguredService();

        $statusMappings = [
            'confirmed' => 'PROCESSING',
            'preparing' => 'PROCESSING',
            'ready_for_pickup' => 'PARTIALLY_SHIPPED',
            'assigned' => 'SHIPPED',
            'on_the_way' => 'SHIPPED',
            'delivered' => 'COMPLETED',
            'cancelled' => 'CANCELED',
        ];

        foreach ($statusMappings as $appStatus => $whatsappStatus) {
            Http::fake([
                'test.api.infobip.com/*' => Http::response([
                    'messageId' => "os-{$appStatus}",
                    'status' => ['groupName' => 'PENDING'],
                ], 200),
            ]);

            $service->sendOrderStatus(
                to: '+2250700000000',
                orderReference: 'CMD-TEST',
                status: $appStatus,
                description: 'Test',
            );

            Http::assertSent(function ($request) use ($whatsappStatus) {
                return $request['content']['action']['status'] === $whatsappStatus;
            });
        }
    }

    #[Test]
    public function it_handles_api_error_on_text_message()
    {
        $service = $this->getConfiguredService([
            $this->jsonResponse([
                'requestError' => [
                    'serviceException' => [
                        'messageId' => 'UNAUTHORIZED',
                        'text' => 'Invalid login details',
                    ],
                ],
            ], 401),
        ]);

        $result = $service->sendText('+2250700000000', 'Test message');

        $this->assertFalse($result);
    }

    #[Test]
    public function it_handles_network_exception()
    {
        $service = $this->getConfiguredService([
            new RequestException(
                'Connection timeout',
                new GuzzleRequest('POST', 'https://test.api.infobip.com/whatsapp/1/message/text'),
            ),
        ]);

        $result = $service->sendText('+2250700000000', 'Test message');

        $this->assertFalse($result);
    }

    #[Test]
    public function it_falls_back_to_log_when_not_configured()
    {
        config([
            'whatsapp.enabled' => false,
        ]);

        $service = app(WhatsAppService::class);

        Log::shouldReceive('info')
            ->once()
            ->with(\Mockery::pattern('/log only/'), \Mockery::type('array'));

        $result = $service->sendText('+2250700000000', 'Test');

        $this->assertTrue($result);
    }

    #[Test]
    public function it_includes_sms_failover_when_configured()
    {
        config([
            'whatsapp.enabled' => true,
            'whatsapp.base_url' => 'https://test.api.infobip.com',
            'whatsapp.api_key' => 'test_api_key_123',
            'whatsapp.sender_number' => '2250100000000',
            'whatsapp.sms_failover.enabled' => true,
            'whatsapp.sms_failover.sender' => 'DR-PHARMA',
            'whatsapp.templates.order_confirmed.sms_fallback' => 'DR-PHARMA: Bonjour {1}, votre commande {2} a été confirmée par {3}.',
            'whatsapp.default_country_code' => '+225',
        ]);

        $this->httpHistory = [];
        $mockHandler = new MockHandler([
            $this->bulkMessageResponse('tpl-fail'),
        ]);
        $handlerStack = HandlerStack::create($mockHandler);
        $handlerStack->push(Middleware::history($this->httpHistory));
        $mockClient = new Client(['handler' => $handlerStack]);

        $config = new Configuration(
            host: 'https://test.api.infobip.com',
            apiKey: 'test_api_key_123',
        );
        $realApi = new WhatsAppApi(config: $config, client: $mockClient);

        $mockFactory = Mockery::mock(InfobipClientFactory::class);
        $mockFactory->shouldReceive('whatsAppApi')->andReturn($realApi);
        $mockFactory->shouldReceive('isWhatsAppConfigured')->andReturn(true);

        $this->app->instance(InfobipClientFactory::class, $mockFactory);

        $service = app(WhatsAppService::class);

        $service->sendTemplate(
            to: '+2250700000000',
            templateName: 'order_confirmed',
            placeholders: ['Jean', 'CMD-001', 'Pharmacie Test'],
        );

        $this->assertCount(1, $this->httpHistory);
        $body = json_decode($this->httpHistory[0]['request']->getBody()->getContents(), true);
        $this->assertArrayHasKey('smsFailover', $body['messages'][0]);
        $this->assertEquals('DR-PHARMA', $body['messages'][0]['smsFailover']['from']);
        $this->assertStringContainsString('Jean', $body['messages'][0]['smsFailover']['text']);
    }
}
