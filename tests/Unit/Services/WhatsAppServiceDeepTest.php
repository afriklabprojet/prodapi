<?php

namespace Tests\Unit\Services;

use App\Services\Infobip\InfobipClientFactory;
use App\Services\WhatsAppService;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Infobip\ApiException;
use Mockery;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class WhatsAppServiceDeepTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Log::spy();
        Config::set('whatsapp.enabled', true);
        Config::set('whatsapp.sender_number', '2250000000000');
        Config::set('whatsapp.default_country_code', '+225');
        Config::set('whatsapp.api_key', 'test-api-key');
        Config::set('whatsapp.base_url', 'https://api.infobip.test');
        Config::set('whatsapp.templates', [
            'test_template' => ['sms_fallback' => 'Hello {1}, your code is {2}'],
        ]);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════

    private function callPrivate(object $obj, string $method, array $args = []): mixed
    {
        $ref = new \ReflectionMethod($obj, $method);
        $ref->setAccessible(true);
        return $ref->invoke($obj, ...$args);
    }

    private function mockResponse(): object
    {
        $status = Mockery::mock(\Infobip\Model\WhatsAppSingleMessageStatus::class);
        $status->shouldReceive('getGroupName')->andReturn('PENDING');

        $resp = Mockery::mock(\Infobip\Model\WhatsAppSingleMessageInfo::class);
        $resp->shouldReceive('getMessageId')->andReturn('msg-123');
        $resp->shouldReceive('getStatus')->andReturn($status);

        return $resp;
    }

    private function makeService(bool $enabled = true, bool $configured = true): array
    {
        $whatsAppApi = Mockery::mock('WhatsAppApiStub');
        $factory = Mockery::mock(InfobipClientFactory::class);
        // Return false so constructor skips typed whatsAppApi() call (final class)
        $factory->shouldReceive('isWhatsAppConfigured')->andReturn(false);

        Config::set('whatsapp.enabled', $enabled);

        $service = new WhatsAppService($factory);

        // Inject mock via reflection (same pattern as SmsServiceDeepTest)
        $ref = new \ReflectionClass($service);
        $prop = $ref->getProperty('whatsAppApi');
        $prop->setAccessible(true);
        $prop->setValue($service, $whatsAppApi);

        // Override factory mock for isConfigured() checks
        $factoryProp = $ref->getProperty('factory');
        $factoryProp->setAccessible(true);
        $configuredFactory = Mockery::mock(InfobipClientFactory::class);
        $configuredFactory->shouldReceive('isWhatsAppConfigured')->andReturn($configured);
        $factoryProp->setValue($service, $configuredFactory);

        return [$service, $whatsAppApi, $configuredFactory];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // logOnly (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function log_only_returns_true_and_logs(): void
    {
        [$service] = $this->makeService(true, true);

        $result = $this->callPrivate($service, 'logOnly', ['text', '+2250700000000', ['body' => 'hello']]);

        $this->assertTrue($result);
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, 'log only'));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // handleSdkResponse (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function handle_sdk_response_returns_true_and_logs(): void
    {
        [$service] = $this->makeService();
        $response = $this->mockResponse();

        $result = $this->callPrivate($service, 'handleSdkResponse', [$response, 'text', '+2250700000000', ['extra' => 'data']]);

        $this->assertTrue($result);
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, 'text message sent'));
    }

    #[Test]
    public function handle_sdk_response_with_null_status(): void
    {
        [$service] = $this->makeService();

        $resp = Mockery::mock(\Infobip\Model\WhatsAppSingleMessageInfo::class);
        $resp->shouldReceive('getMessageId')->andReturn('msg-456');
        $resp->shouldReceive('getStatus')->andReturn(null);

        $result = $this->callPrivate($service, 'handleSdkResponse', [$resp, 'template', '+2250700000000']);

        $this->assertTrue($result);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // handleHttpResponse (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function handle_http_response_success(): void
    {
        [$service] = $this->makeService();

        Http::fake(['*' => Http::response(['messageId' => 'id-1', 'status' => ['groupName' => 'PENDING']], 200)]);
        $response = Http::get('https://api.test/test');

        $result = $this->callPrivate($service, 'handleHttpResponse', [$response, 'order_status', '+2250700000000']);

        $this->assertTrue($result);
    }

    #[Test]
    public function handle_http_response_success_with_messages_array(): void
    {
        [$service] = $this->makeService();

        Http::fake(['*' => Http::response([
            'messages' => [['messageId' => 'id-2', 'status' => ['groupName' => 'SENT']]],
        ], 200)]);
        $response = Http::get('https://api.test/test');

        $result = $this->callPrivate($service, 'handleHttpResponse', [$response, 'order_status', '+2250700000000']);

        $this->assertTrue($result);
    }

    #[Test]
    public function handle_http_response_failure(): void
    {
        [$service] = $this->makeService();

        Http::fake(['*' => Http::response(['error' => 'bad request'], 400)]);
        $response = Http::get('https://api.test/test');

        $result = $this->callPrivate($service, 'handleHttpResponse', [$response, 'order_status', '+2250700000000']);

        $this->assertFalse($result);
        Log::shouldHaveReceived('error');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // buildSmsFailoverText (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function build_sms_failover_text_with_template(): void
    {
        [$service] = $this->makeService();

        $text = $this->callPrivate($service, 'buildSmsFailoverText', ['test_template', ['John', '1234']]);

        $this->assertEquals('Hello John, your code is 1234', $text);
    }

    #[Test]
    public function build_sms_failover_text_default(): void
    {
        [$service] = $this->makeService();

        $text = $this->callPrivate($service, 'buildSmsFailoverText', ['unknown_template', ['value']]);

        $this->assertStringContainsString('DR-PHARMA', $text);
        $this->assertStringContainsString('WhatsApp', $text);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // normalizePhone (public)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function normalize_phone_local_10_digits(): void
    {
        [$service] = $this->makeService();
        $this->assertEquals('+225700000000', $service->normalizePhone('0700000000'));
    }

    #[Test]
    public function normalize_phone_removes_non_digit(): void
    {
        [$service] = $this->makeService();
        $this->assertEquals('+225700000000', $service->normalizePhone('07 00 000 000'));
    }

    #[Test]
    public function normalize_phone_international_stays(): void
    {
        [$service] = $this->makeService();
        $this->assertEquals('+2250700000000', $service->normalizePhone('+2250700000000'));
    }

    #[Test]
    public function normalize_phone_without_plus_adds_it(): void
    {
        [$service] = $this->makeService();
        $result = $service->normalizePhone('2250700000000');
        $this->assertEquals('+2250700000000', $result);
    }

    #[Test]
    public function normalize_phone_without_country_code_adds_it(): void
    {
        [$service] = $this->makeService();
        // Not starting with 225 and not starting with 0
        $result = $service->normalizePhone('700000000');
        $this->assertEquals('+225700000000', $result);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // sendText — not configured → logOnly
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function send_text_not_configured_logs_only(): void
    {
        [$service, $api] = $this->makeService(false, false);

        $result = $service->sendText('+2250700000000', 'Hello');

        $this->assertTrue($result);
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, 'log only'));
    }

    #[Test]
    public function send_text_success(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $api->shouldReceive('sendWhatsAppTextMessage')->once()->andReturn($this->mockResponse());

        $result = $service->sendText('+2250700000000', 'Hello World');

        $this->assertTrue($result);
    }

    #[Test]
    public function send_text_api_exception(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $apiEx = new ApiException('API error', 400, [], '{"error":"bad"}');
        $api->shouldReceive('sendWhatsAppTextMessage')->andThrow($apiEx);

        $result = $service->sendText('+2250700000000', 'Hello');

        $this->assertFalse($result);
        Log::shouldHaveReceived('error')->withArgs(fn ($msg) => str_contains($msg, 'API exception'));
    }

    #[Test]
    public function send_text_generic_exception(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $api->shouldReceive('sendWhatsAppTextMessage')->andThrow(new \Exception('Network error'));

        $result = $service->sendText('+2250700000000', 'Hello');

        $this->assertFalse($result);
        Log::shouldHaveReceived('error')->withArgs(fn ($msg) => str_contains($msg, 'exception'));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // sendTemplate
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function send_template_not_configured_logs_only(): void
    {
        [$service, $api] = $this->makeService(false, false);

        $result = $service->sendTemplate('+2250700000000', 'otp', 'fr', ['1234']);

        $this->assertTrue($result);
    }

    #[Test]
    public function send_template_success(): void
    {
        [$service, $api] = $this->makeService(true, true);

        $bulkResp = Mockery::mock('BulkMessageInfoStub');
        $bulkResp->shouldReceive('getMessages')->andReturn([$this->mockResponse()]);
        $api->shouldReceive('sendWhatsAppTemplateMessage')->once()->andReturn($bulkResp);

        $result = $service->sendTemplate('+2250700000000', 'otp', 'fr', ['1234']);

        $this->assertTrue($result);
    }

    #[Test]
    public function send_template_api_exception(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $api->shouldReceive('sendWhatsAppTemplateMessage')->andThrow(new ApiException('fail', 500));

        $result = $service->sendTemplate('+2250700000000', 'otp', 'fr', ['code']);

        $this->assertFalse($result);
    }

    #[Test]
    public function send_template_generic_exception(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $api->shouldReceive('sendWhatsAppTemplateMessage')->andThrow(new \Exception('boom'));

        $result = $service->sendTemplate('+2250700000000', 'otp', 'fr', ['code']);

        $this->assertFalse($result);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // sendImage
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function send_image_not_configured_logs_only(): void
    {
        [$service] = $this->makeService(false, false);

        $result = $service->sendImage('+2250700000000', 'https://img.test/photo.jpg', 'A photo');

        $this->assertTrue($result);
    }

    #[Test]
    public function send_image_success(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $api->shouldReceive('sendWhatsAppImageMessage')->once()->andReturn($this->mockResponse());

        $result = $service->sendImage('+2250700000000', 'https://img.test/photo.jpg');

        $this->assertTrue($result);
    }

    #[Test]
    public function send_image_api_exception(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $api->shouldReceive('sendWhatsAppImageMessage')->andThrow(new ApiException('fail', 400));

        $result = $service->sendImage('+2250700000000', 'https://img.test/photo.jpg');

        $this->assertFalse($result);
    }

    #[Test]
    public function send_image_generic_exception(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $api->shouldReceive('sendWhatsAppImageMessage')->andThrow(new \Exception('boom'));

        $result = $service->sendImage('+2250700000000', 'https://img.test/photo.jpg');

        $this->assertFalse($result);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // sendDocument
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function send_document_not_configured_logs_only(): void
    {
        [$service] = $this->makeService(false, false);

        $result = $service->sendDocument('+2250700000000', 'https://doc.test/file.pdf', 'doc.pdf');

        $this->assertTrue($result);
    }

    #[Test]
    public function send_document_success(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $api->shouldReceive('sendWhatsAppDocumentMessage')->once()->andReturn($this->mockResponse());

        $result = $service->sendDocument('+2250700000000', 'https://doc.test/file.pdf', 'doc.pdf');

        $this->assertTrue($result);
    }

    #[Test]
    public function send_document_api_exception(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $api->shouldReceive('sendWhatsAppDocumentMessage')->andThrow(new ApiException('fail', 500));

        $result = $service->sendDocument('+2250700000000', 'https://doc.test/file.pdf', 'doc.pdf');

        $this->assertFalse($result);
    }

    #[Test]
    public function send_document_generic_exception(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $api->shouldReceive('sendWhatsAppDocumentMessage')->andThrow(new \Exception('boom'));

        $result = $service->sendDocument('+2250700000000', 'https://doc.test/file.pdf', 'doc.pdf');

        $this->assertFalse($result);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // sendLocation
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function send_location_not_configured_logs_only(): void
    {
        [$service] = $this->makeService(false, false);

        $result = $service->sendLocation('+2250700000000', 5.3364, -4.0267, 'Pharmacy', '123 St');

        $this->assertTrue($result);
    }

    #[Test]
    public function send_location_success(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $api->shouldReceive('sendWhatsAppLocationMessage')->once()->andReturn($this->mockResponse());

        $result = $service->sendLocation('+2250700000000', 5.3364, -4.0267, 'Test', 'Address');

        $this->assertTrue($result);
    }

    #[Test]
    public function send_location_api_exception(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $api->shouldReceive('sendWhatsAppLocationMessage')->andThrow(new ApiException('fail', 400));

        $result = $service->sendLocation('+2250700000000', 5.3364, -4.0267);

        $this->assertFalse($result);
    }

    #[Test]
    public function send_location_generic_exception(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $api->shouldReceive('sendWhatsAppLocationMessage')->andThrow(new \Exception('boom'));

        $result = $service->sendLocation('+2250700000000', 5.3364, -4.0267);

        $this->assertFalse($result);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // sendOrderStatus
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function send_order_status_not_configured_logs_only(): void
    {
        [$service] = $this->makeService(false, false);

        $result = $service->sendOrderStatus('+2250700000000', 'ORD-001', 'confirmed', 'Commande confirmée');

        $this->assertTrue($result);
    }

    #[Test]
    public function send_order_status_success(): void
    {
        [$service] = $this->makeService(true, true);

        Http::fake(['*' => Http::response([
            'messages' => [['messageId' => 'mid-1', 'status' => ['groupName' => 'PENDING']]],
        ], 200)]);

        $result = $service->sendOrderStatus('+2250700000000', 'ORD-001', 'confirmed', 'Commande confirmée', [
            ['name' => 'Paracetamol', 'quantity' => 2, 'amount' => 1000],
        ]);

        $this->assertTrue($result);
    }

    #[Test]
    public function send_order_status_http_failure(): void
    {
        [$service] = $this->makeService(true, true);

        Http::fake(['*' => Http::response(['error' => 'fail'], 500)]);

        $result = $service->sendOrderStatus('+2250700000000', 'ORD-001', 'confirmed', 'Commande confirmée');

        $this->assertFalse($result);
    }

    #[Test]
    public function send_order_status_exception(): void
    {
        [$service] = $this->makeService(true, true);

        Http::fake(fn () => throw new \Exception('Network error'));

        $result = $service->sendOrderStatus('+2250700000000', 'ORD-001', 'confirmed', 'Commande confirmée');

        $this->assertFalse($result);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // markAsRead
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function mark_as_read_not_configured_returns_true(): void
    {
        [$service] = $this->makeService(false, false);

        $result = $service->markAsRead('msg-123');

        $this->assertTrue($result);
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, 'markAsRead (log only)'));
    }

    #[Test]
    public function mark_as_read_success(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $api->shouldReceive('markWhatsAppMessageAsRead')->once();

        $result = $service->markAsRead('msg-123');

        $this->assertTrue($result);
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, 'marked as read'));
    }

    #[Test]
    public function mark_as_read_api_exception(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $api->shouldReceive('markWhatsAppMessageAsRead')->andThrow(new ApiException('fail', 400));

        $result = $service->markAsRead('msg-123');

        $this->assertFalse($result);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getTemplates
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function get_templates_not_configured_returns_empty(): void
    {
        [$service] = $this->makeService(false, false);

        $result = $service->getTemplates();

        $this->assertEquals([], $result);
    }

    #[Test]
    public function get_templates_success(): void
    {
        [$service, $api] = $this->makeService(true, true);

        $template = new class {
            public function getName() { return 'otp_verification'; }
            public function getLanguage() { return 'fr'; }
            public function getStatus() { return 'APPROVED'; }
            public function getCategory() { return 'AUTHENTICATION'; }
        };

        $response = new class([$template]) {
            private array $templates;
            public function __construct(array $templates) { $this->templates = $templates; }
            public function getTemplates(): array { return $this->templates; }
        };

        $api->shouldReceive('getWhatsAppTemplates')->once()->andReturn($response);

        $result = $service->getTemplates();

        $this->assertCount(1, $result);
        $this->assertEquals('otp_verification', $result[0]['name']);
        $this->assertEquals('fr', $result[0]['language']);
        $this->assertEquals('APPROVED', $result[0]['status']);
    }

    #[Test]
    public function get_templates_api_exception_returns_empty(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $api->shouldReceive('getWhatsAppTemplates')->andThrow(new ApiException('fail', 500));

        $result = $service->getTemplates();

        $this->assertEquals([], $result);
    }

    #[Test]
    public function get_templates_null_response_returns_empty(): void
    {
        [$service, $api] = $this->makeService(true, true);
        $api->shouldReceive('getWhatsAppTemplates')->andReturn(null);

        $result = $service->getTemplates();

        $this->assertEquals([], $result);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getBaseUrl (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function get_base_url_trims_trailing_slash(): void
    {
        Config::set('whatsapp.base_url', 'https://api.test/');
        [$service] = $this->makeService();

        $url = $this->callPrivate($service, 'getBaseUrl');

        $this->assertEquals('https://api.test', $url);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // infobipHttp (protected)
    // ═══════════════════════════════════════════════════════════════════════

    #[Test]
    public function infobip_http_returns_pending_request(): void
    {
        [$service] = $this->makeService();

        $request = $this->callPrivate($service, 'infobipHttp');

        $this->assertInstanceOf(\Illuminate\Http\Client\PendingRequest::class, $request);
    }
}
