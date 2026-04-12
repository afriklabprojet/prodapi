<?php

namespace Tests\Unit\Services;

use App\Services\BusinessEventService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class BusinessEventServiceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        if (!Schema::hasTable('business_events')) {
            Schema::create('business_events', function ($table) {
                $table->id();
                $table->string('event');
                $table->unsignedBigInteger('user_id')->nullable();
                $table->json('properties')->nullable();
                $table->string('ip_address')->nullable();
                $table->string('user_agent')->nullable();
                $table->timestamp('created_at')->nullable();
            });
        }
    }

    public function test_track_stores_event_in_database(): void
    {
        Log::shouldReceive('channel->info')->once();

        BusinessEventService::track('test_event', 1, ['key' => 'value']);

        $this->assertDatabaseHas('business_events', [
            'event' => 'test_event',
            'user_id' => 1,
        ]);
    }

    public function test_signup_tracks_event(): void
    {
        Log::shouldReceive('channel->info')->once();
        BusinessEventService::signup(1, 'customer', ['source' => 'mobile']);

        $this->assertDatabaseHas('business_events', [
            'event' => 'signup',
            'user_id' => 1,
        ]);
    }

    public function test_login_tracks_event(): void
    {
        Log::shouldReceive('channel->info')->once();
        BusinessEventService::login(1, 'customer');

        $this->assertDatabaseHas('business_events', [
            'event' => 'login',
            'user_id' => 1,
        ]);
    }

    public function test_payment_success_invalidates_cache(): void
    {
        Log::shouldReceive('channel->info')->once();

        Cache::put('revenue:today', 'cached', 300);
        Cache::put('revenue:month', 'cached', 300);
        Cache::put('revenue:stats', 'cached', 300);

        BusinessEventService::paymentSuccess(1, 'REF-001', 5000);

        $this->assertFalse(Cache::has('revenue:today'));
        $this->assertFalse(Cache::has('revenue:month'));
        $this->assertFalse(Cache::has('revenue:stats'));
    }

    public function test_order_created_tracks_event(): void
    {
        Log::shouldReceive('channel->info')->once();
        BusinessEventService::orderCreated(1, 42, 5000, 'mobile_money');

        $this->assertDatabaseHas('business_events', [
            'event' => 'booking_created',
            'user_id' => 1,
        ]);
    }

    public function test_tracking_failure_does_not_throw(): void
    {
        // Force DB error by dropping table
        Schema::dropIfExists('business_events');
        Log::shouldReceive('channel->info')->never();
        Log::shouldReceive('warning')->once();

        // Should not throw
        BusinessEventService::track('test', 1);
        $this->assertTrue(true);
    }

    public function test_payment_initiated_tracks_event(): void
    {
        Log::shouldReceive('channel->info')->once();
        BusinessEventService::paymentInitiated(1, 'REF-002', 3000, 'mobile_money');

        $this->assertDatabaseHas('business_events', ['event' => 'payment_initiated']);
    }

    public function test_payment_failed_tracks_event(): void
    {
        Log::shouldReceive('channel->info')->once();
        BusinessEventService::paymentFailed(1, 'REF-003', 'Insufficient balance');

        $this->assertDatabaseHas('business_events', ['event' => 'payment_failed']);
    }

    public function test_order_delivered_tracks_event(): void
    {
        Log::shouldReceive('channel->info')->once();
        BusinessEventService::orderDelivered(1, 42, 5000);

        $this->assertDatabaseHas('business_events', ['event' => 'order_delivered']);
    }

    public function test_order_cancelled_tracks_event(): void
    {
        Log::shouldReceive('channel->info')->once();
        BusinessEventService::orderCancelled(1, 42, 'Customer request', 'customer');

        $this->assertDatabaseHas('business_events', ['event' => 'order_cancelled']);
    }

    public function test_wallet_topup_tracks_event(): void
    {
        Log::shouldReceive('channel->info')->once();
        BusinessEventService::walletTopup(1, 10000, 'mobile_money');

        $this->assertDatabaseHas('business_events', ['event' => 'wallet_topup']);
    }

    public function test_courier_kyc_submitted_tracks(): void
    {
        Log::shouldReceive('channel->info')->once();
        BusinessEventService::courierKycSubmitted(1);

        $this->assertDatabaseHas('business_events', ['event' => 'kyc_submitted']);
    }

    public function test_ux_friction_tracks_event(): void
    {
        Log::shouldReceive('channel->info')->once();
        BusinessEventService::uxFriction(1, 'checkout', 'slow_loading');

        $this->assertDatabaseHas('business_events', ['event' => 'ux_friction']);
    }

    public function test_api_error_tracks_event(): void
    {
        Log::shouldReceive('channel->info')->once();
        BusinessEventService::apiError(1, '/api/orders', 500, 'SERVER_ERROR');

        $this->assertDatabaseHas('business_events', ['event' => 'api_error']);
    }
}
