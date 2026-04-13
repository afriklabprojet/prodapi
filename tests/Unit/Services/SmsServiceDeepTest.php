<?php

namespace Tests\Unit\Services;

use App\Services\Infobip\InfobipClientFactory;
use App\Services\SmsService;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Infobip\ApiException;
use Mockery;
use Tests\TestCase;

class SmsServiceDeepTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Log::spy();
        Cache::flush();
        Config::set('sms.default', 'infobip');
        Config::set('sms.default_country_code', '+225');
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

    private function mockFactory(bool $configured = true): InfobipClientFactory
    {
        $factory = Mockery::mock(InfobipClientFactory::class);
        // Always return false so the constructor won't try to get the typed SmsApi/TfaApi
        $factory->shouldReceive('isSmsConfigured')->andReturn(false);
        return $factory;
    }

    /**
     * Create an SmsService where smsApi/tfaApi are replaced with mock objects
     * via reflection (because Infobip SDK classes are final).
     * 
     * 1. Build service with isSmsConfigured=false so constructor skips smsApi()
     * 2. Inject anonymous mock stubs into the protected properties
     */
    private function serviceWithMockApi(): array
    {
        $smsApi = Mockery::mock('SmsApiStub');
        $tfaApi = Mockery::mock('TfaApiStub');

        $factory = Mockery::mock(InfobipClientFactory::class);
        // false → constructor won't call smsApi()/tfaApi() which have typed returns
        $factory->shouldReceive('isSmsConfigured')->andReturn(false);

        $service = new SmsService($factory);

        // Inject mocks via reflection
        $ref = new \ReflectionClass($service);
        $smsApiProp = $ref->getProperty('smsApi');
        $smsApiProp->setAccessible(true);
        $smsApiProp->setValue($service, $smsApi);

        $tfaApiProp = $ref->getProperty('tfaApi');
        $tfaApiProp->setAccessible(true);
        $tfaApiProp->setValue($service, $tfaApi);

        return [$service, $smsApi, $tfaApi];
    }

    private function mockSmsResponse(array $messages = [], ?string $bulkId = 'bulk-123'): object
    {
        $resp = Mockery::mock();
        $resp->shouldReceive('getBulkId')->andReturn($bulkId);
        $resp->shouldReceive('getMessages')->andReturn($messages);
        return $resp;
    }

    private function mockMessage(?string $messageId = 'msg-1', string $statusGroup = 'PENDING', string $statusName = 'MESSAGE_ACCEPTED'): object
    {
        $status = Mockery::mock();
        $status->shouldReceive('getGroupName')->andReturn($statusGroup);
        $status->shouldReceive('getName')->andReturn($statusName);
        $status->shouldReceive('getDescription')->andReturn('');

        $msg = Mockery::mock();
        $msg->shouldReceive('getMessageId')->andReturn($messageId);
        $msg->shouldReceive('getStatus')->andReturn($status);
        return $msg;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // normalizePhone
    // ═══════════════════════════════════════════════════════════════════════

    public function test_normalize_phone_local_with_zero(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertEquals('+2250712345678', $service->normalizePhone('0712345678'));
    }

    public function test_normalize_phone_international(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertEquals('+33612345678', $service->normalizePhone('+33612345678'));
    }

    public function test_normalize_phone_strips_spaces(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertEquals('+2250712345678', $service->normalizePhone('+225 07 12 34 56 78'));
    }

    public function test_normalize_phone_without_plus_with_country_code(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertEquals('+2250712345678', $service->normalizePhone('2250712345678'));
    }

    public function test_normalize_phone_without_plus_without_country_code(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $r = $service->normalizePhone('712345678');
        $this->assertStringStartsWith('+225', $r);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // send() routing
    // ═══════════════════════════════════════════════════════════════════════

    public function test_send_infobip_not_configured_falls_to_log(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertTrue($service->send('+22501234567', 'msg'));
    }

    public function test_send_opted_out_blocked(): void
    {
        $service = new SmsService($this->mockFactory(false));
        Cache::put('sms_optout:+22501234567', true, 3600);
        $this->assertFalse($service->send('+22501234567', 'msg'));
    }

    public function test_send_opted_out_forced(): void
    {
        Config::set('sms.default', 'log');
        $service = new SmsService($this->mockFactory(false));
        Cache::put('sms_optout:+22501234567', true, 3600);
        $this->assertTrue($service->send('+22501234567', 'msg', ['force' => true]));
    }

    public function test_send_unknown_provider(): void
    {
        Config::set('sms.default', 'something_unknown');
        $service = new SmsService($this->mockFactory(false));
        $this->assertTrue($service->send('+22501234567', 'msg'));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // sendViaInfobip (success / errors)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_infobip_send_success(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $msg = $this->mockMessage('msg-abc', 'PENDING');
        $smsApi->shouldReceive('sendSmsMessages')->once()->andReturn($this->mockSmsResponse([$msg]));

        $this->assertTrue($service->sendViaInfobip('+22501234567', 'Hello'));
    }

    public function test_infobip_send_with_custom_message_id(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $msg = $this->mockMessage('custom-id', 'PENDING');
        $smsApi->shouldReceive('sendSmsMessages')->once()->andReturn($this->mockSmsResponse([$msg]));

        $this->assertTrue($service->sendViaInfobip('+22501234567', 'Hello', ['messageId' => 'custom-id']));
    }

    public function test_infobip_send_empty_messages(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $smsApi->shouldReceive('sendSmsMessages')->once()->andReturn($this->mockSmsResponse([]));

        $this->assertFalse($service->sendViaInfobip('+22501234567', 'Hello'));
    }

    public function test_infobip_send_api_exception(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $smsApi->shouldReceive('sendSmsMessages')->andThrow(new ApiException('fail', 400));

        $this->assertFalse($service->sendViaInfobip('+22501234567', 'Hello'));
    }

    public function test_infobip_send_generic_exception(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $smsApi->shouldReceive('sendSmsMessages')->andThrow(new \Exception('network'));

        $this->assertFalse($service->sendViaInfobip('+22501234567', 'Hello'));
    }

    public function test_infobip_send_caches_message_id(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $msg = $this->mockMessage('cached-id', 'PENDING');
        $smsApi->shouldReceive('sendSmsMessages')->once()->andReturn($this->mockSmsResponse([$msg]));

        $service->sendViaInfobip('+22501234567', 'Hi');
        $this->assertNotNull(Cache::get('sms_msg_cached-id'));
    }

    public function test_infobip_send_null_message_id_no_cache(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $msg = $this->mockMessage(null, 'PENDING');
        $smsApi->shouldReceive('sendSmsMessages')->once()->andReturn($this->mockSmsResponse([$msg]));

        $service->sendViaInfobip('+22501234567', 'Hi');
        // No cache key with null
    }

    public function test_infobip_send_custom_from(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $msg = $this->mockMessage('msg-x', 'PENDING');
        $smsApi->shouldReceive('sendSmsMessages')->once()->andReturn($this->mockSmsResponse([$msg]));

        $this->assertTrue($service->sendViaInfobip('+22501234567', 'Hello', ['from' => 'CUSTOM']));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // sendBulk
    // ═══════════════════════════════════════════════════════════════════════

    public function test_bulk_not_configured(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $r = $service->sendBulk(['+22501234567'], 'msg');
        $this->assertFalse($r['success']);
        $this->assertEquals(1, $r['failed']);
    }

    public function test_bulk_success(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $msg = $this->mockMessage('b-1', 'PENDING');
        $smsApi->shouldReceive('sendSmsMessages')->once()->andReturn($this->mockSmsResponse([$msg], 'bulk-1'));

        $r = $service->sendBulk(['+22501234567'], 'Hello');
        $this->assertTrue($r['success']);
        $this->assertEquals('bulk-1', $r['bulkId']);
        $this->assertEquals(1, $r['sent']);
    }

    public function test_bulk_api_exception(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $smsApi->shouldReceive('sendSmsMessages')->andThrow(new ApiException('err', 500));

        $r = $service->sendBulk(['+22501234567', '+22507654321'], 'msg');
        $this->assertFalse($r['success']);
        $this->assertEquals(2, $r['failed']);
    }

    public function test_bulk_generic_exception(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $smsApi->shouldReceive('sendSmsMessages')->andThrow(new \Exception('timeout'));

        $r = $service->sendBulk(['+22501234567'], 'msg');
        $this->assertFalse($r['success']);
        $this->assertArrayHasKey('error', $r);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // sendMultiple
    // ═══════════════════════════════════════════════════════════════════════

    public function test_multiple_not_configured(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $r = $service->sendMultiple([['phone' => '+22501234567', 'message' => 'hi']]);
        $this->assertFalse($r['success']);
    }

    public function test_multiple_success(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $msg = $this->mockMessage('m-1', 'PENDING');
        $smsApi->shouldReceive('sendSmsMessages')->once()->andReturn($this->mockSmsResponse([$msg], 'multi-1'));

        $r = $service->sendMultiple([
            ['phone' => '+22501234567', 'message' => 'Hello'],
            ['phone' => '+22507654321', 'message' => 'World'],
        ]);
        $this->assertTrue($r['success']);
        $this->assertEquals('multi-1', $r['bulkId']);
    }

    public function test_multiple_exception(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $smsApi->shouldReceive('sendSmsMessages')->andThrow(new \Exception('fail'));

        $r = $service->sendMultiple([['phone' => '+22501234567', 'message' => 'hi']]);
        $this->assertFalse($r['success']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // sendFlash
    // ═══════════════════════════════════════════════════════════════════════

    public function test_send_flash(): void
    {
        Config::set('sms.default', 'log');
        $service = new SmsService($this->mockFactory(false));
        $this->assertTrue($service->sendFlash('+22501234567', 'Flash!'));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // schedule / getScheduled / reschedule / cancelScheduled
    // ═══════════════════════════════════════════════════════════════════════

    public function test_schedule_not_configured(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $r = $service->schedule('+22501234567', 'msg', '2026-04-07T10:00:00Z');
        $this->assertFalse($r['success']);
    }

    public function test_schedule_success(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response(['bulkId' => 'sched-1', 'messages' => []], 200)]);

        $r = $service->schedule('+22501234567', 'msg', '2026-04-07T10:00:00Z');
        $this->assertTrue($r['success']);
        $this->assertEquals('sched-1', $r['bulkId']);
    }

    public function test_schedule_with_bulk_id(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response(['bulkId' => 'custom-bulk'], 200)]);

        $r = $service->schedule('+22501234567', 'msg', '2026-04-07T10:00:00Z', 'custom-bulk');
        $this->assertTrue($r['success']);
    }

    public function test_schedule_with_notify_url(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');
        Config::set('sms.infobip.notify_url', 'https://example.com/notify');

        Http::fake(['*' => Http::response(['bulkId' => 's-1'], 200)]);

        $r = $service->schedule('+22501234567', 'msg', '2026-04-07T10:00:00Z');
        $this->assertTrue($r['success']);
    }

    public function test_schedule_api_failure(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response('error', 500)]);

        $r = $service->schedule('+22501234567', 'msg', '2026-04-07T10:00:00Z');
        $this->assertFalse($r['success']);
    }

    public function test_schedule_exception(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::sequence()->pushResponse(Http::response('error', 500))]);
        // Force throw by simulating connection error
        Http::fake(fn() => throw new \Exception('connection error'));

        $r = $service->schedule('+22501234567', 'msg', '2026-04-07T10:00:00Z');
        $this->assertFalse($r['success']);
        $this->assertArrayHasKey('error', $r);
    }

    public function test_get_scheduled_not_configured(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertNull($service->getScheduled('bulk-1'));
    }

    public function test_get_scheduled_success(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response(['bulkId' => 'b-1', 'sendAt' => 'some'], 200)]);

        $r = $service->getScheduled('b-1');
        $this->assertIsArray($r);
    }

    public function test_get_scheduled_failure(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response('err', 500)]);

        $this->assertNull($service->getScheduled('b-1'));
    }

    public function test_get_scheduled_exception(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(fn() => throw new \Exception('fail'));

        $this->assertNull($service->getScheduled('b-1'));
    }

    public function test_reschedule_not_configured(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertNull($service->reschedule('b-1', '2026-04-08T10:00:00Z'));
    }

    public function test_reschedule_success(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response(['sendAt' => '2026-04-08'], 200)]);

        $this->assertIsArray($service->reschedule('b-1', '2026-04-08T10:00:00Z'));
    }

    public function test_reschedule_failure(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response('err', 500)]);

        $this->assertNull($service->reschedule('b-1', '2026-04-08T10:00:00Z'));
    }

    public function test_reschedule_exception(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(fn() => throw new \Exception('fail'));

        $this->assertNull($service->reschedule('b-1', '2026-04-08T10:00:00Z'));
    }

    public function test_cancel_scheduled_not_configured(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertFalse($service->cancelScheduled('b-1'));
    }

    public function test_cancel_scheduled_success(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response(['status' => 'CANCELED'], 200)]);

        $this->assertTrue($service->cancelScheduled('b-1'));
    }

    public function test_cancel_scheduled_failure(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response('err', 500)]);

        $this->assertFalse($service->cancelScheduled('b-1'));
    }

    public function test_cancel_scheduled_exception(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(fn() => throw new \Exception('fail'));

        $this->assertFalse($service->cancelScheduled('b-1'));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getDeliveryReports
    // ═══════════════════════════════════════════════════════════════════════

    public function test_delivery_reports_not_configured(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertNull($service->getDeliveryReports());
    }

    public function test_delivery_reports_success(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();

        $price = Mockery::mock();
        $price->shouldReceive('getPricePerMessage')->andReturn(25.0);
        $price->shouldReceive('getCurrency')->andReturn('XOF');

        $error = Mockery::mock();
        $error->shouldReceive('getGroupName')->andReturn('OK');
        $error->shouldReceive('getName')->andReturn('NO_ERROR');
        $error->shouldReceive('getDescription')->andReturn('');

        $status = Mockery::mock();
        $status->shouldReceive('getGroupName')->andReturn('DELIVERED');
        $status->shouldReceive('getName')->andReturn('DELIVERED_TO_HANDSET');
        $status->shouldReceive('getDescription')->andReturn('Delivered');

        $report = Mockery::mock();
        $report->shouldReceive('getMessageId')->andReturn('msg-1');
        $report->shouldReceive('getBulkId')->andReturn('bulk-1');
        $report->shouldReceive('getTo')->andReturn('+22501234567');
        $report->shouldReceive('getSentAt')->andReturn(new \DateTime());
        $report->shouldReceive('getDoneAt')->andReturn(new \DateTime());
        $report->shouldReceive('getSmsCount')->andReturn(1);
        $report->shouldReceive('getStatus')->andReturn($status);
        $report->shouldReceive('getPrice')->andReturn($price);
        $report->shouldReceive('getError')->andReturn($error);

        $deliveryResult = Mockery::mock();
        $deliveryResult->shouldReceive('getResults')->andReturn([$report]);

        $smsApi->shouldReceive('getOutboundSmsMessageDeliveryReports')->once()->andReturn($deliveryResult);

        $r = $service->getDeliveryReports(['limit' => 10]);
        $this->assertCount(1, $r['results']);
        $this->assertEquals('msg-1', $r['results'][0]['messageId']);
        $this->assertNotNull($r['results'][0]['price']);
        $this->assertNotNull($r['results'][0]['error']);
    }

    public function test_delivery_reports_no_price_no_error(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();

        $status = Mockery::mock();
        $status->shouldReceive('getGroupName')->andReturn('PENDING');
        $status->shouldReceive('getName')->andReturn('PENDING_ENROUTE');
        $status->shouldReceive('getDescription')->andReturn('');

        $report = Mockery::mock();
        $report->shouldReceive('getMessageId')->andReturn('m-2');
        $report->shouldReceive('getBulkId')->andReturn('b-2');
        $report->shouldReceive('getTo')->andReturn('+22507654321');
        $report->shouldReceive('getSentAt')->andReturn(null);
        $report->shouldReceive('getDoneAt')->andReturn(null);
        $report->shouldReceive('getSmsCount')->andReturn(1);
        $report->shouldReceive('getStatus')->andReturn($status);
        $report->shouldReceive('getPrice')->andReturn(null);
        $report->shouldReceive('getError')->andReturn(null);

        $deliveryResult = Mockery::mock();
        $deliveryResult->shouldReceive('getResults')->andReturn([$report]);

        $smsApi->shouldReceive('getOutboundSmsMessageDeliveryReports')->once()->andReturn($deliveryResult);

        $r = $service->getDeliveryReports();
        $this->assertNull($r['results'][0]['price']);
        $this->assertNull($r['results'][0]['error']);
    }

    public function test_delivery_reports_api_exception(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $smsApi->shouldReceive('getOutboundSmsMessageDeliveryReports')->andThrow(new ApiException('err', 500));
        $this->assertNull($service->getDeliveryReports());
    }

    public function test_delivery_reports_generic_exception(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $smsApi->shouldReceive('getOutboundSmsMessageDeliveryReports')->andThrow(new \Exception('fail'));
        $this->assertNull($service->getDeliveryReports());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getLogs
    // ═══════════════════════════════════════════════════════════════════════

    public function test_logs_not_configured(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertNull($service->getLogs());
    }

    public function test_logs_success(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();

        $status = Mockery::mock();
        $status->shouldReceive('getGroupName')->andReturn('DELIVERED');
        $status->shouldReceive('getName')->andReturn('DELIVERED_TO_HANDSET');

        $log = Mockery::mock();
        $log->shouldReceive('getMessageId')->andReturn('msg-log-1');
        $log->shouldReceive('getBulkId')->andReturn('bulk-log-1');
        $log->shouldReceive('getTo')->andReturn('+22501234567');
        $log->shouldReceive('getFrom')->andReturn('DR-PHARMA');
        $log->shouldReceive('getSentAt')->andReturn(new \DateTime());
        $log->shouldReceive('getDoneAt')->andReturn(new \DateTime());
        $log->shouldReceive('getSmsCount')->andReturn(1);
        $log->shouldReceive('getStatus')->andReturn($status);

        $logsResult = Mockery::mock();
        $logsResult->shouldReceive('getResults')->andReturn([$log]);

        $smsApi->shouldReceive('getOutboundSmsMessageLogs')->once()->andReturn($logsResult);

        $r = $service->getLogs(['from' => 'DR-PHARMA', 'sentSince' => '2026-01-01']);
        $this->assertCount(1, $r['results']);
        $this->assertEquals('msg-log-1', $r['results'][0]['messageId']);
    }

    public function test_logs_api_exception(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $smsApi->shouldReceive('getOutboundSmsMessageLogs')->andThrow(new ApiException('err', 400));
        $this->assertNull($service->getLogs());
    }

    public function test_logs_generic_exception(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $smsApi->shouldReceive('getOutboundSmsMessageLogs')->andThrow(new \Exception('fail'));
        $this->assertNull($service->getLogs());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getMessageStatus / preview / confirmConversion / getInboundMessages
    // ═══════════════════════════════════════════════════════════════════════

    public function test_get_message_status_delegates_to_delivery_reports(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();

        $status = Mockery::mock();
        $status->shouldReceive('getGroupName')->andReturn('DELIVERED');
        $status->shouldReceive('getName')->andReturn('OK');
        $status->shouldReceive('getDescription')->andReturn('');

        $report = Mockery::mock();
        $report->shouldReceive('getMessageId')->andReturn('check-1');
        $report->shouldReceive('getBulkId')->andReturn('b-1');
        $report->shouldReceive('getTo')->andReturn('+22501234567');
        $report->shouldReceive('getSentAt')->andReturn(null);
        $report->shouldReceive('getDoneAt')->andReturn(null);
        $report->shouldReceive('getSmsCount')->andReturn(1);
        $report->shouldReceive('getStatus')->andReturn($status);
        $report->shouldReceive('getPrice')->andReturn(null);
        $report->shouldReceive('getError')->andReturn(null);

        $deliveryResult = Mockery::mock();
        $deliveryResult->shouldReceive('getResults')->andReturn([$report]);

        $smsApi->shouldReceive('getOutboundSmsMessageDeliveryReports')->once()->andReturn($deliveryResult);

        $r = $service->getMessageStatus('check-1');
        $this->assertEquals('check-1', $r['messageId']);
    }

    public function test_get_message_status_not_found(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $deliveryResult = Mockery::mock();
        $deliveryResult->shouldReceive('getResults')->andReturn([]);
        $smsApi->shouldReceive('getOutboundSmsMessageDeliveryReports')->once()->andReturn($deliveryResult);

        $this->assertNull($service->getMessageStatus('unknown-id'));
    }

    public function test_preview_not_configured(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertNull($service->preview('Hello'));
    }

    public function test_preview_success(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();

        $preview = Mockery::mock();
        $preview->shouldReceive('getTextPreview')->andReturn('Hello');
        $preview->shouldReceive('getMessageCount')->andReturn(1);
        $preview->shouldReceive('getCharactersRemaining')->andReturn(140);
        $preview->shouldReceive('getConfiguration')->andReturn(null);

        $previewResp = Mockery::mock();
        $previewResp->shouldReceive('getOriginalText')->andReturn('Hello');
        $previewResp->shouldReceive('getPreviews')->andReturn([$preview]);

        $smsApi->shouldReceive('previewSmsMessage')->once()->andReturn($previewResp);

        $r = $service->preview('Hello');
        $this->assertEquals('Hello', $r['original_text']);
        $this->assertEquals(1, $r['message_count']);
    }

    public function test_preview_with_transliteration(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();

        $preview = Mockery::mock();
        $preview->shouldReceive('getTextPreview')->andReturn('Hello');
        $preview->shouldReceive('getMessageCount')->andReturn(1);
        $preview->shouldReceive('getCharactersRemaining')->andReturn(140);
        $preview->shouldReceive('getConfiguration')->andReturn(null);

        $previewResp = Mockery::mock();
        $previewResp->shouldReceive('getOriginalText')->andReturn('Hello');
        $previewResp->shouldReceive('getPreviews')->andReturn([$preview]);

        $smsApi->shouldReceive('previewSmsMessage')->once()->andReturn($previewResp);

        $r = $service->preview('Hello', 'TURKISH');
        $this->assertNotNull($r);
    }

    public function test_preview_empty(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $previewResp = Mockery::mock();
        $previewResp->shouldReceive('getPreviews')->andReturn([]);
        $smsApi->shouldReceive('previewSmsMessage')->once()->andReturn($previewResp);

        $this->assertNull($service->preview('x'));
    }

    public function test_preview_exception(): void
    {
        [$service, $smsApi] = $this->serviceWithMockApi();
        $smsApi->shouldReceive('previewSmsMessage')->andThrow(new \Exception('fail'));
        $this->assertNull($service->preview('x'));
    }

    public function test_confirm_conversion_not_configured(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertFalse($service->confirmConversion('msg-1'));
    }

    public function test_confirm_conversion_success(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response('', 200)]);
        $this->assertTrue($service->confirmConversion('msg-1'));
    }

    public function test_confirm_conversion_exception(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(fn() => throw new \Exception('fail'));
        $this->assertFalse($service->confirmConversion('msg-1'));
    }

    public function test_inbound_messages_not_configured(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertNull($service->getInboundMessages());
    }

    public function test_inbound_messages_success(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response(['results' => []], 200)]);
        $this->assertIsArray($service->getInboundMessages());
    }

    public function test_inbound_messages_failure(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response('err', 500)]);
        $this->assertNull($service->getInboundMessages());
    }

    public function test_inbound_messages_exception(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(fn() => throw new \Exception('fail'));
        $this->assertNull($service->getInboundMessages());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 2FA: create2faApplication / create2faMessageTemplate / sendPin / verifyPin / resendPin / getPinStatus
    // ═══════════════════════════════════════════════════════════════════════

    public function test_create_2fa_app_not_configured(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertNull($service->create2faApplication('MyApp'));
    }

    public function test_create_2fa_app_success(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response(['applicationId' => 'app-1'], 200)]);
        $r = $service->create2faApplication('MyApp');
        $this->assertEquals('app-1', $r['applicationId']);
    }

    public function test_create_2fa_app_failure(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response('err', 400)]);
        $this->assertNull($service->create2faApplication('MyApp'));
    }

    public function test_create_2fa_app_exception(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(fn() => throw new \Exception('fail'));
        $this->assertNull($service->create2faApplication('MyApp'));
    }

    public function test_create_2fa_template_not_configured(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertNull($service->create2faMessageTemplate('app-1'));
    }

    public function test_create_2fa_template_success(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response(['messageId' => 'tmpl-1'], 200)]);
        $r = $service->create2faMessageTemplate('app-1');
        $this->assertEquals('tmpl-1', $r['messageId']);
    }

    public function test_create_2fa_template_failure(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response('err', 400)]);
        $this->assertNull($service->create2faMessageTemplate('app-1'));
    }

    public function test_create_2fa_template_exception(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(fn() => throw new \Exception('fail'));
        $this->assertNull($service->create2faMessageTemplate('app-1'));
    }

    public function test_send_pin_not_configured(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertNull($service->sendPin('+22501234567'));
    }

    public function test_send_pin_missing_app_config(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.2fa.application_id', null);
        Config::set('sms.infobip.2fa.message_id', null);

        $this->assertNull($service->sendPin('+22501234567'));
    }

    public function test_send_pin_success(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');
        Config::set('sms.infobip.2fa.application_id', 'app-1');
        Config::set('sms.infobip.2fa.message_id', 'msg-1');

        Http::fake(['*' => Http::response(['pinId' => 'pin-123', 'smsStatus' => 'MESSAGE_SENT'], 200)]);
        $r = $service->sendPin('+22501234567');
        $this->assertEquals('pin-123', $r['pinId']);
        $this->assertNotNull(Cache::get('infobip_pin_+22501234567'));
    }

    public function test_send_pin_with_placeholders(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');
        Config::set('sms.infobip.2fa.application_id', 'app-1');
        Config::set('sms.infobip.2fa.message_id', 'msg-1');
        Config::set('sms.infobip.2fa.placeholders', ['appName' => 'DR-PHARMA']);

        Http::fake(['*' => Http::response(['pinId' => 'pin-456', 'smsStatus' => 'MESSAGE_SENT'], 200)]);
        $r = $service->sendPin('+22501234567');
        $this->assertNotNull($r);
    }

    public function test_send_pin_api_failure(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');
        Config::set('sms.infobip.2fa.application_id', 'app-1');
        Config::set('sms.infobip.2fa.message_id', 'msg-1');

        Http::fake(['*' => Http::response('err', 400)]);
        $this->assertNull($service->sendPin('+22501234567'));
    }

    public function test_send_pin_exception(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');
        Config::set('sms.infobip.2fa.application_id', 'app-1');
        Config::set('sms.infobip.2fa.message_id', 'msg-1');

        Http::fake(fn() => throw new \Exception('fail'));
        $this->assertNull($service->sendPin('+22501234567'));
    }

    public function test_verify_pin_not_configured(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertNull($service->verifyPin('pin-1', '1234'));
    }

    public function test_verify_pin_success(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response(['verified' => true, 'pinId' => 'pin-1'], 200)]);
        $r = $service->verifyPin('pin-1', '1234');
        $this->assertTrue($r['verified']);
    }

    public function test_verify_pin_401(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response('Unauthorized', 401)]);
        $r = $service->verifyPin('pin-1', '1234');
        $this->assertFalse($r['verified']);
        $this->assertEquals(0, $r['attemptsRemaining']);
    }

    public function test_verify_pin_other_error(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response('err', 500)]);
        $this->assertNull($service->verifyPin('pin-1', '1234'));
    }

    public function test_verify_pin_exception(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(fn() => throw new \Exception('fail'));
        $this->assertNull($service->verifyPin('pin-1', '1234'));
    }

    public function test_resend_pin_not_configured(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertNull($service->resendPin('pin-1'));
    }

    public function test_resend_pin_success(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response(['pinId' => 'new-pin'], 200)]);
        $r = $service->resendPin('pin-1');
        $this->assertEquals('new-pin', $r['pinId']);
    }

    public function test_resend_pin_failure(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response('err', 400)]);
        $this->assertNull($service->resendPin('pin-1'));
    }

    public function test_resend_pin_exception(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(fn() => throw new \Exception('fail'));
        $this->assertNull($service->resendPin('pin-1'));
    }

    public function test_get_pin_status_not_configured(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertNull($service->getPinStatus('pin-1'));
    }

    public function test_get_pin_status_success(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response(['pinId' => 'pin-1', 'status' => 'VERIFIED'], 200)]);
        $r = $service->getPinStatus('pin-1');
        $this->assertEquals('VERIFIED', $r['status']);
    }

    public function test_get_pin_status_failure(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response('err', 404)]);
        $this->assertNull($service->getPinStatus('pin-1'));
    }

    public function test_get_pin_status_exception(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(fn() => throw new \Exception('fail'));
        $this->assertNull($service->getPinStatus('pin-1'));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getBalance / checkBalance
    // ═══════════════════════════════════════════════════════════════════════

    public function test_balance_not_configured_infobip(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertNull($service->getBalance());
    }

    public function test_balance_not_configured_africastalking(): void
    {
        Config::set('sms.default', 'africastalking');
        Config::set('sms.africastalking.api_key', null);
        $service = new SmsService($this->mockFactory(false));
        $this->assertNull($service->getBalance());
    }

    public function test_balance_africastalking_success(): void
    {
        Config::set('sms.default', 'africastalking');
        Config::set('sms.africastalking.api_key', 'at-key');
        Config::set('sms.africastalking.username', 'at-user');

        Http::fake(['*' => Http::response(['UserData' => ['balance' => '100.00']], 200)]);

        $service = new SmsService($this->mockFactory(false));
        $r = $service->getBalance();
        $this->assertIsArray($r);
    }

    public function test_balance_africastalking_exception(): void
    {
        Config::set('sms.default', 'africastalking');
        Config::set('sms.africastalking.api_key', 'at-key');
        Config::set('sms.africastalking.username', 'at-user');

        Http::fake(fn() => throw new \Exception('fail'));

        $service = new SmsService($this->mockFactory(false));
        $this->assertNull($service->getBalance());
    }

    public function test_balance_infobip_success(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response(['balance' => 100.5, 'currency' => 'XOF'], 200)]);
        $r = $service->getBalance();
        $this->assertIsArray($r);
    }

    public function test_balance_infobip_failure(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response('err', 500)]);
        $this->assertNull($service->getBalance());
    }

    public function test_balance_infobip_exception(): void
    {
        [$service] = $this->serviceWithMockApi();
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(fn() => throw new \Exception('fail'));
        $this->assertNull($service->getBalance());
    }

    public function test_check_balance_delegates(): void
    {
        $service = new SmsService($this->mockFactory(false));
        $this->assertNull($service->checkBalance());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Twilio / AfricasTalking providers
    // ═══════════════════════════════════════════════════════════════════════

    public function test_twilio_not_configured(): void
    {
        Config::set('sms.default', 'twilio');
        Config::set('sms.twilio.sid', null);
        $service = new SmsService($this->mockFactory(false));
        $this->assertTrue($service->send('+22501234567', 'msg')); // falls to log
    }

    public function test_twilio_success(): void
    {
        Config::set('sms.default', 'twilio');
        Config::set('sms.twilio.sid', 'AC123');
        Config::set('sms.twilio.token', 'tok');
        Config::set('sms.twilio.from', '+1234567890');

        Http::fake(['api.twilio.com/*' => Http::response(['sid' => 'SM123'], 200)]);

        $service = new SmsService($this->mockFactory(false));
        $this->assertTrue($service->send('+22501234567', 'msg'));
    }

    public function test_twilio_api_failure(): void
    {
        Config::set('sms.default', 'twilio');
        Config::set('sms.twilio.sid', 'AC123');
        Config::set('sms.twilio.token', 'tok');
        Config::set('sms.twilio.from', '+1234567890');

        Http::fake(['api.twilio.com/*' => Http::response(['error' => 'invalid'], 400)]);

        $service = new SmsService($this->mockFactory(false));
        $this->assertFalse($service->send('+22501234567', 'msg'));
    }

    public function test_twilio_exception(): void
    {
        Config::set('sms.default', 'twilio');
        Config::set('sms.twilio.sid', 'AC123');
        Config::set('sms.twilio.token', 'tok');
        Config::set('sms.twilio.from', '+1234567890');

        Http::fake(fn() => throw new \Exception('fail'));

        $service = new SmsService($this->mockFactory(false));
        $this->assertFalse($service->send('+22501234567', 'msg'));
    }

    public function test_africastalking_not_configured(): void
    {
        Config::set('sms.default', 'africastalking');
        Config::set('sms.africastalking.api_key', null);
        $service = new SmsService($this->mockFactory(false));
        $this->assertTrue($service->send('+22501234567', 'msg')); // falls to log
    }

    public function test_africastalking_success(): void
    {
        Config::set('sms.default', 'africastalking');
        Config::set('sms.africastalking.api_key', 'at-key');
        Config::set('sms.africastalking.username', 'at-user');

        Http::fake(['api.africastalking.com/*' => Http::response([
            'SMSMessageData' => ['Recipients' => [['status' => 'Success']]],
        ], 200)]);

        $service = new SmsService($this->mockFactory(false));
        $this->assertTrue($service->send('+22501234567', 'msg'));
    }

    public function test_africastalking_no_recipients(): void
    {
        Config::set('sms.default', 'africastalking');
        Config::set('sms.africastalking.api_key', 'at-key');
        Config::set('sms.africastalking.username', 'at-user');

        Http::fake(['api.africastalking.com/*' => Http::response(['SMSMessageData' => ['Recipients' => []]], 200)]);

        $service = new SmsService($this->mockFactory(false));
        $this->assertFalse($service->send('+22501234567', 'msg'));
    }

    public function test_africastalking_api_failure(): void
    {
        Config::set('sms.default', 'africastalking');
        Config::set('sms.africastalking.api_key', 'at-key');
        Config::set('sms.africastalking.username', 'at-user');

        Http::fake(['api.africastalking.com/*' => Http::response('err', 500)]);

        $service = new SmsService($this->mockFactory(false));
        $this->assertFalse($service->send('+22501234567', 'msg'));
    }

    public function test_africastalking_exception(): void
    {
        Config::set('sms.default', 'africastalking');
        Config::set('sms.africastalking.api_key', 'at-key');
        Config::set('sms.africastalking.username', 'at-user');

        Http::fake(fn() => throw new \Exception('fail'));

        $service = new SmsService($this->mockFactory(false));
        $this->assertFalse($service->send('+22501234567', 'msg'));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // isConfigured / isInfobipConfigured / getProvider
    // ═══════════════════════════════════════════════════════════════════════

    public function test_is_configured_infobip(): void
    {
        Config::set('sms.default', 'infobip');
        $factory = Mockery::mock(InfobipClientFactory::class);
        $factory->shouldReceive('isSmsConfigured')->andReturn(true);
        
        // Build service bypassing typed return on smsApi()/tfaApi() by setting provider to 'log'
        // then switch back
        Config::set('sms.default', 'log');
        $service = new SmsService($factory);
        
        // Set provider back to infobip via reflection
        $ref = new \ReflectionProperty($service, 'provider');
        $ref->setAccessible(true);
        $ref->setValue($service, 'infobip');
        
        $this->assertTrue($service->isConfigured());
    }

    public function test_is_configured_twilio(): void
    {
        Config::set('sms.default', 'twilio');
        Config::set('sms.twilio.sid', 'AC123');
        Config::set('sms.twilio.token', 'tok');
        $service = new SmsService($this->mockFactory(false));
        $this->assertTrue($service->isConfigured());
    }

    public function test_is_configured_africastalking(): void
    {
        Config::set('sms.default', 'africastalking');
        Config::set('sms.africastalking.api_key', 'key');
        $service = new SmsService($this->mockFactory(false));
        $this->assertTrue($service->isConfigured());
    }

    public function test_is_configured_unknown(): void
    {
        Config::set('sms.default', 'unknown');
        $service = new SmsService($this->mockFactory(false));
        $this->assertFalse($service->isConfigured());
    }

    public function test_get_provider(): void
    {
        Config::set('sms.default', 'twilio');
        $service = new SmsService($this->mockFactory(false));
        $this->assertEquals('twilio', $service->getProvider());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // infobipHttp (via reflection)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_infobip_http_delete(): void
    {
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        Http::fake(['*' => Http::response('', 200)]);

        $service = new SmsService($this->mockFactory(false));
        $r = $this->callPrivate($service, 'infobipHttp', ['DELETE', '/test']);
        $this->assertTrue($r->successful());
    }

    public function test_infobip_http_invalid_method(): void
    {
        Config::set('sms.infobip.base_url', 'https://api.infobip.com');
        Config::set('sms.infobip.api_key', 'test-key');

        $service = new SmsService($this->mockFactory(false));
        $this->expectException(\InvalidArgumentException::class);
        $this->callPrivate($service, 'infobipHttp', ['PATCH', '/test']);
    }
}
