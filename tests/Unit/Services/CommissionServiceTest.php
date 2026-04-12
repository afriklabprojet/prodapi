<?php

namespace Tests\Unit\Services;

use App\Services\CommissionService;
use Tests\TestCase;

class CommissionServiceTest extends TestCase
{
    private CommissionService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new CommissionService();
    }

    public function test_it_can_be_instantiated(): void
    {
        $this->assertInstanceOf(CommissionService::class, $this->service);
    }

    public function test_normalize_rate_converts_percentage_to_decimal(): void
    {
        $reflection = new \ReflectionClass($this->service);
        $method = $reflection->getMethod('normalizeRate');
        $method->setAccessible(true);

        // Percentage values (>1) should be divided by 100
        $this->assertEquals(0.10, $method->invoke($this->service, 10));
        $this->assertEquals(0.85, $method->invoke($this->service, 85));
        $this->assertEquals(0.05, $method->invoke($this->service, 5));
        $this->assertEquals(1.0, $method->invoke($this->service, 100));
    }

    public function test_normalize_rate_keeps_decimal_values(): void
    {
        $reflection = new \ReflectionClass($this->service);
        $method = $reflection->getMethod('normalizeRate');
        $method->setAccessible(true);

        // Decimal values (<=1) should be kept as-is
        $this->assertEquals(0.10, $method->invoke($this->service, 0.10));
        $this->assertEquals(0.85, $method->invoke($this->service, 0.85));
        $this->assertEquals(0.05, $method->invoke($this->service, 0.05));
        $this->assertEquals(1.0, $method->invoke($this->service, 1.0));
    }

    public function test_normalize_rate_handles_zero(): void
    {
        $reflection = new \ReflectionClass($this->service);
        $method = $reflection->getMethod('normalizeRate');
        $method->setAccessible(true);

        $this->assertEquals(0.0, $method->invoke($this->service, 0));
    }

    public function test_normalize_rate_handles_string_values(): void
    {
        $reflection = new \ReflectionClass($this->service);
        $method = $reflection->getMethod('normalizeRate');
        $method->setAccessible(true);

        $this->assertEquals(0.10, $method->invoke($this->service, '10'));
        $this->assertEquals(0.05, $method->invoke($this->service, '0.05'));
    }
}
