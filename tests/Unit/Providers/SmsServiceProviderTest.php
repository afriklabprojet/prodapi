<?php

namespace Tests\Unit\Providers;

use App\Providers\SmsServiceProvider;
use App\Services\SmsService;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class SmsServiceProviderTest extends TestCase
{
    #[Test]
    public function it_registers_sms_service_as_singleton()
    {
        $instance1 = app(SmsService::class);
        $instance2 = app(SmsService::class);

        $this->assertInstanceOf(SmsService::class, $instance1);
        $this->assertSame($instance1, $instance2);
    }
}
