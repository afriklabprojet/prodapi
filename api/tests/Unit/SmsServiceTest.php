<?php

namespace Tests\Unit;

use App\Services\SmsService;
use Tests\TestCase;
use ReflectionClass;

class SmsServiceTest extends TestCase
{
    /**
     * Test phone number normalization with local number
     */
    public function test_normalizes_local_phone_number_starting_with_zero(): void
    {
        $service = new SmsService();
        $reflection = new ReflectionClass($service);
        $method = $reflection->getMethod('normalizePhone');
        $method->setAccessible(true);

        $result = $method->invoke($service, '0712345678');
        
        $this->assertStringStartsWith('+', $result);
        $this->assertStringContainsString('712345678', $result);
    }

    /**
     * Test phone number normalization removes special characters
     */
    public function test_normalizes_phone_number_removes_special_characters(): void
    {
        $service = new SmsService();
        $reflection = new ReflectionClass($service);
        $method = $reflection->getMethod('normalizePhone');
        $method->setAccessible(true);

        $result = $method->invoke($service, '+225 07 12 34 56 78');
        
        $this->assertEquals('+2250712345678', $result);
    }

    /**
     * Test phone number with international prefix preserved
     */
    public function test_preserves_international_prefix(): void
    {
        $service = new SmsService();
        $reflection = new ReflectionClass($service);
        $method = $reflection->getMethod('normalizePhone');
        $method->setAccessible(true);

        $result = $method->invoke($service, '+33612345678');
        
        $this->assertEquals('+33612345678', $result);
    }
}
