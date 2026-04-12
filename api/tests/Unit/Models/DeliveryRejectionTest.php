<?php

namespace Tests\Unit\Models;

use App\Models\Courier;
use App\Models\Delivery;
use App\Models\DeliveryRejection;
use App\Models\Order;
use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class DeliveryRejectionTest extends TestCase
{
    use RefreshDatabase;

    private Delivery $delivery;
    private Courier $courier;

    protected function setUp(): void
    {
        parent::setUp();

        $courierUser = User::factory()->create(['role' => 'courier']);
        $this->courier = Courier::factory()->create(['user_id' => $courierUser->id]);
        
        $order = Order::factory()->create();
        $this->delivery = Delivery::factory()->create([
            'order_id' => $order->id,
            'courier_id' => $this->courier->id,
        ]);
    }

    #[Test]
    public function it_uses_correct_table(): void
    {
        $model = new DeliveryRejection();

        $this->assertEquals('delivery_rejections', $model->getTable());
    }

    #[Test]
    public function it_has_no_timestamps(): void
    {
        $model = new DeliveryRejection();

        $this->assertFalse($model->timestamps);
    }

    #[Test]
    public function it_casts_rejected_at_as_datetime(): void
    {
        $model = new DeliveryRejection();
        $casts = $model->getCasts();

        $this->assertSame('datetime', $casts['rejected_at']);
    }

    #[Test]
    public function it_has_delivery_relationship(): void
    {
        $model = new DeliveryRejection();
        $relation = $model->delivery();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_has_courier_relationship(): void
    {
        $model = new DeliveryRejection();
        $relation = $model->courier();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_can_be_created_in_database(): void
    {
        $rejection = DeliveryRejection::create([
            'delivery_id' => $this->delivery->id,
            'courier_id' => $this->courier->id,
            'reason' => 'Too far',
            'rejected_at' => now(),
        ]);

        $this->assertDatabaseHas('delivery_rejections', [
            'delivery_id' => $this->delivery->id,
            'courier_id' => $this->courier->id,
            'reason' => 'Too far',
        ]);
    }

    #[Test]
    public function it_can_access_delivery_through_relationship(): void
    {
        DeliveryRejection::create([
            'delivery_id' => $this->delivery->id,
            'courier_id' => $this->courier->id,
            'reason' => 'Destination too far',
            'rejected_at' => now(),
        ]);

        $rejection = DeliveryRejection::where('delivery_id', $this->delivery->id)->first();

        $this->assertEquals($this->delivery->id, $rejection->delivery->id);
    }

    #[Test]
    public function it_can_access_courier_through_relationship(): void
    {
        DeliveryRejection::create([
            'delivery_id' => $this->delivery->id,
            'courier_id' => $this->courier->id,
            'reason' => 'Not available',
            'rejected_at' => now(),
        ]);

        $rejection = DeliveryRejection::where('courier_id', $this->courier->id)->first();

        $this->assertEquals($this->courier->id, $rejection->courier->id);
    }
}
