<?php

namespace Tests\Feature;

use App\Models\Courier;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Product;
use App\Models\User;
use App\Notifications\DeliveryAssignedNotification;
use App\Notifications\NewOrderNotification;
use App\Notifications\OrderStatusNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class RealTimeScenarioTest extends TestCase
{
    use RefreshDatabase;

    protected $pharmacyUser;
    protected $pharmacy;
    protected $client;
    protected $courier;
    protected $courierUser;
    protected $product;

    protected function setUp(): void
    {
        parent::setUp();

        // 1. Setup Pharmacy
        $this->pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
            'latitude' => 5.3600,
            'longitude' => -4.0083,
        ]);
        $this->pharmacy->users()->attach($this->pharmacyUser->id, ['role' => 'owner']);

        // 2. Setup Client
        $this->client = User::factory()->create(['role' => 'customer']);

        // 3. Setup Courier (Available and nearby)
        $this->courierUser = User::factory()->create(['role' => 'courier']);
        $this->courier = Courier::factory()->create([
            'user_id' => $this->courierUser->id,
            'status' => 'available',
            'latitude' => 5.3600 + 0.001, // Slightly offset
            'longitude' => -4.0083 + 0.001,
        ]);

        // 4. Setup Product
        $this->product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
            'price' => 1000,
            'stock_quantity' => 50,
            'is_available' => true,
        ]);
    }

    /** @test */
    public function new_order_sends_notification_to_pharmacy()
    {
        Notification::fake();

        // Simulate Order Creation via API or direct factory
        // Using factory creates the model and triggers 'created' observer
        $order = Order::factory()->create([
            'customer_id' => $this->client->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'pending',
            'delivery_latitude' => 5.3700,
            'delivery_longitude' => -4.0200,
        ]);

        Notification::assertSentTo(
            [$this->pharmacyUser],
            NewOrderNotification::class,
            function ($notification, $channels) use ($order) {
                return $notification->order->id === $order->id;
            }
        );
    }

    /** @test */
    public function order_confirmation_sends_notification_to_client()
    {
        Notification::fake();

        $order = Order::factory()->create([
            'customer_id' => $this->client->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'pending',
        ]);

        // Pharmacy confirms the order
        // This should trigger 'updated' observer
        $order->update(['status' => 'confirmed']);

        Notification::assertSentTo(
            [$this->client],
            OrderStatusNotification::class,
            function ($notification, $channels) {
                return $notification->status === 'confirmed';
            }
        );
    }

    /** @test */
    public function order_ready_triggers_assignment_and_notifies_courier()
    {
        Notification::fake();

        $order = Order::factory()->create([
            'customer_id' => $this->client->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'confirmed',
            'delivery_latitude' => 5.3700,
            'delivery_longitude' => -4.0200,
        ]);

        // Pharmacy marks order as Ready
        // This triggers handleReady -> attempts assignment
        $order->update(['status' => 'ready']);

        // Assert Courier Assignment
        $this->assertDatabaseHas('deliveries', [
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
            'status' => 'pending',
        ]);

        // Assert Notification to Courier
        Notification::assertSentTo(
            [$this->courierUser],
            DeliveryAssignedNotification::class
        );
    }
}
