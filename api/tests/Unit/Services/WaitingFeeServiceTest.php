<?php

namespace Tests\Unit\Services;

use App\Models\Delivery;
use App\Services\WaitingFeeService;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class WaitingFeeServiceTest extends TestCase
{
    private WaitingFeeService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new WaitingFeeService();

        config([
            'services.waiting_fee.timeout_minutes' => 15,
            'services.waiting_fee.fee_per_minute' => 100,
            'services.waiting_fee.free_minutes' => 5,
        ]);
    }

    public function test_get_settings_returns_config_values(): void
    {
        $settings = $this->service->getSettings();

        $this->assertSame(15, $settings['timeout_minutes']);
        $this->assertSame(100, $settings['fee_per_minute']);
        $this->assertSame(5, $settings['free_minutes']);
    }

    public function test_get_waiting_settings_alias(): void
    {
        $settings = $this->service->getWaitingSettings();
        $this->assertSame($this->service->getSettings(), $settings);
    }

    public function test_get_waiting_info_when_not_waiting(): void
    {
        $delivery = new Delivery();
        $delivery->waiting_started_at = null;

        $info = $this->service->getWaitingInfo($delivery);

        $this->assertFalse($info['is_waiting']);
        $this->assertSame(0, $info['waiting_minutes']);
        $this->assertSame(0, $info['waiting_fee']);
        $this->assertFalse($info['is_timed_out']);
        $this->assertSame(5, $info['remaining_free_minutes']);
        $this->assertSame(15, $info['remaining_timeout_minutes']);
    }

    public function test_get_waiting_info_within_free_minutes(): void
    {
        $delivery = new Delivery();
        $delivery->waiting_started_at = Carbon::now()->subMinutes(3);

        $info = $this->service->getWaitingInfo($delivery);

        $this->assertTrue($info['is_waiting']);
        $this->assertSame(3, $info['waiting_minutes']);
        $this->assertSame(0, $info['waiting_fee']); // Still in free minutes
        $this->assertFalse($info['is_timed_out']);
        $this->assertSame(2, $info['remaining_free_minutes']);
    }

    public function test_get_waiting_info_after_free_minutes(): void
    {
        $delivery = new Delivery();
        $delivery->waiting_started_at = Carbon::now()->subMinutes(10);

        $info = $this->service->getWaitingInfo($delivery);

        $this->assertTrue($info['is_waiting']);
        $this->assertSame(10, $info['waiting_minutes']);
        $this->assertSame(500, $info['waiting_fee']); // (10-5) * 100
        $this->assertFalse($info['is_timed_out']);
        $this->assertSame(0, $info['remaining_free_minutes']);
        $this->assertSame(5, $info['remaining_timeout_minutes']);
    }

    public function test_get_waiting_info_timed_out(): void
    {
        $delivery = new Delivery();
        $delivery->waiting_started_at = Carbon::now()->subMinutes(20);

        $info = $this->service->getWaitingInfo($delivery);

        $this->assertTrue($info['is_waiting']);
        $this->assertTrue($info['is_timed_out']);
        $this->assertSame(1500, $info['waiting_fee']); // (20-5) * 100
        $this->assertSame(0, $info['remaining_timeout_minutes']);
    }

    public function test_calculate_fee_returns_waiting_fee(): void
    {
        $delivery = new Delivery();
        $delivery->waiting_started_at = Carbon::now()->subMinutes(8);

        $fee = $this->service->calculateFee($delivery);
        $this->assertSame(300, $fee); // (8-5) * 100
    }

    public function test_calculate_fee_zero_when_not_waiting(): void
    {
        $delivery = new Delivery();
        $delivery->waiting_started_at = null;

        $fee = $this->service->calculateFee($delivery);
        $this->assertSame(0, $fee);
    }

    public function test_get_waiting_info_at_exact_timeout(): void
    {
        $delivery = new Delivery();
        $delivery->waiting_started_at = Carbon::now()->subMinutes(15);

        $info = $this->service->getWaitingInfo($delivery);

        $this->assertTrue($info['is_timed_out']);
        $this->assertSame(1000, $info['waiting_fee']); // (15-5) * 100
    }

    public function test_custom_config_values(): void
    {
        config([
            'services.waiting_fee.timeout_minutes' => 30,
            'services.waiting_fee.fee_per_minute' => 200,
            'services.waiting_fee.free_minutes' => 10,
        ]);

        $settings = $this->service->getSettings();
        $this->assertSame(30, $settings['timeout_minutes']);
        $this->assertSame(200, $settings['fee_per_minute']);
        $this->assertSame(10, $settings['free_minutes']);
    }

    public function test_waiting_info_returns_all_keys(): void
    {
        $delivery = new Delivery();
        $delivery->waiting_started_at = null;

        $info = $this->service->getWaitingInfo($delivery);

        $expectedKeys = [
            'is_waiting', 'waiting_started_at', 'waiting_minutes',
            'free_minutes', 'fee_per_minute', 'timeout_minutes',
            'waiting_fee', 'is_timed_out', 'remaining_free_minutes',
            'remaining_timeout_minutes',
        ];

        foreach ($expectedKeys as $key) {
            $this->assertArrayHasKey($key, $info, "Missing key: {$key}");
        }
    }
}
