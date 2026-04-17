<?php

namespace Tests\Unit\Services\Infobip;

use App\Services\Infobip\InfobipClientFactory;
use Infobip\Api\SmsApi;
use Infobip\Api\TfaApi;
use Infobip\Api\WhatsAppApi;
use Infobip\Configuration;
use Tests\TestCase;

class InfobipClientFactoryTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        config([
            'sms.infobip.base_url' => 'https://sms.api.infobip.com',
            'sms.infobip.api_key' => 'test-sms-key',
            'whatsapp.base_url' => 'https://wa.api.infobip.com',
            'whatsapp.api_key' => 'test-wa-key',
        ]);
    }

    public function test_factory_instantiates(): void
    {
        $factory = new InfobipClientFactory();
        $this->assertInstanceOf(InfobipClientFactory::class, $factory);
    }

    public function test_sms_api_returns_sms_api_instance(): void
    {
        $factory = new InfobipClientFactory();
        $this->assertInstanceOf(SmsApi::class, $factory->smsApi());
    }

    public function test_whatsapp_api_returns_whatsapp_api_instance(): void
    {
        $factory = new InfobipClientFactory();
        $this->assertInstanceOf(WhatsAppApi::class, $factory->whatsAppApi());
    }

    public function test_tfa_api_returns_tfa_api_instance(): void
    {
        $factory = new InfobipClientFactory();
        $this->assertInstanceOf(TfaApi::class, $factory->tfaApi());
    }

    public function test_sms_api_is_singleton(): void
    {
        $factory = new InfobipClientFactory();
        $first = $factory->smsApi();
        $second = $factory->smsApi();
        $this->assertSame($first, $second);
    }

    public function test_whatsapp_api_is_singleton(): void
    {
        $factory = new InfobipClientFactory();
        $first = $factory->whatsAppApi();
        $second = $factory->whatsAppApi();
        $this->assertSame($first, $second);
    }

    public function test_tfa_api_is_singleton(): void
    {
        $factory = new InfobipClientFactory();
        $first = $factory->tfaApi();
        $second = $factory->tfaApi();
        $this->assertSame($first, $second);
    }

    public function test_get_sms_configuration_returns_configuration(): void
    {
        $factory = new InfobipClientFactory();
        $this->assertInstanceOf(Configuration::class, $factory->getSmsConfiguration());
    }

    public function test_get_whatsapp_configuration_returns_configuration(): void
    {
        $factory = new InfobipClientFactory();
        $this->assertInstanceOf(Configuration::class, $factory->getWhatsAppConfiguration());
    }

    public function test_factory_works_with_empty_config(): void
    {
        config([
            'sms.infobip.base_url' => '',
            'sms.infobip.api_key' => '',
            'whatsapp.base_url' => '',
            'whatsapp.api_key' => '',
        ]);

        $factory = new InfobipClientFactory();
        $this->assertInstanceOf(InfobipClientFactory::class, $factory);
    }
}
