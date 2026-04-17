<?php

namespace Tests\Unit\Models;

use App\Models\Order;
use App\Models\PaymentIntent;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class PaymentIntentTest extends TestCase
{
    use RefreshDatabase;

    private Order $order;

    protected function setUp(): void
    {
        parent::setUp();
        $this->order = Order::factory()->create();
    }

    #[Test]
    public function it_has_fillable_attributes(): void
    {
        $model = new PaymentIntent();
        $fillable = $model->getFillable();

        $this->assertContains('order_id', $fillable);
        $this->assertContains('provider', $fillable);
        $this->assertContains('reference', $fillable);
        $this->assertContains('provider_reference', $fillable);
        $this->assertContains('provider_transaction_id', $fillable);
        $this->assertContains('amount', $fillable);
        $this->assertContains('currency', $fillable);
        $this->assertContains('status', $fillable);
        $this->assertContains('provider_payment_url', $fillable);
        $this->assertContains('raw_response', $fillable);
        $this->assertContains('raw_webhook', $fillable);
        $this->assertContains('confirmed_at', $fillable);
    }

    #[Test]
    public function it_casts_amount_as_decimal(): void
    {
        $model = new PaymentIntent();
        $casts = $model->getCasts();

        $this->assertSame('decimal:2', $casts['amount']);
    }

    #[Test]
    public function it_casts_raw_response_as_array(): void
    {
        $model = new PaymentIntent();
        $casts = $model->getCasts();

        $this->assertSame('array', $casts['raw_response']);
    }

    #[Test]
    public function it_casts_raw_webhook_as_array(): void
    {
        $model = new PaymentIntent();
        $casts = $model->getCasts();

        $this->assertSame('array', $casts['raw_webhook']);
    }

    #[Test]
    public function it_casts_confirmed_at_as_datetime(): void
    {
        $model = new PaymentIntent();
        $casts = $model->getCasts();

        $this->assertSame('datetime', $casts['confirmed_at']);
    }

    #[Test]
    public function it_has_order_relationship(): void
    {
        $model = new PaymentIntent();
        $relation = $model->order();

        $this->assertInstanceOf(BelongsTo::class, $relation);
    }

    #[Test]
    public function it_can_be_created_with_factory(): void
    {
        $intent = PaymentIntent::factory()->create([
            'order_id' => $this->order->id,
        ]);

        $this->assertDatabaseHas('payment_intents', ['id' => $intent->id]);
    }

    #[Test]
    public function it_can_store_raw_response(): void
    {
        $rawResponse = [
            'transaction_id' => 'TXN123',
            'status' => 'success',
            'amount' => 5000,
        ];

        $intent = PaymentIntent::factory()->create([
            'order_id' => $this->order->id,
            'raw_response' => $rawResponse,
        ]);

        $intent->refresh();
        $this->assertEquals($rawResponse, $intent->raw_response);
    }

    #[Test]
    public function it_can_store_raw_webhook(): void
    {
        $rawWebhook = [
            'event' => 'payment.confirmed',
            'data' => ['amount' => 5000],
        ];

        $intent = PaymentIntent::factory()->create([
            'order_id' => $this->order->id,
            'raw_webhook' => $rawWebhook,
        ]);

        $intent->refresh();
        $this->assertEquals($rawWebhook, $intent->raw_webhook);
    }

    #[Test]
    public function it_can_access_order_through_relationship(): void
    {
        $intent = PaymentIntent::factory()->create([
            'order_id' => $this->order->id,
        ]);

        $this->assertEquals($this->order->id, $intent->order->id);
    }

    #[Test]
    public function it_can_be_confirmed(): void
    {
        $intent = PaymentIntent::factory()->create([
            'order_id' => $this->order->id,
            'status' => 'PENDING',
            'confirmed_at' => null,
        ]);

        $intent->update([
            'status' => 'SUCCESS',
            'confirmed_at' => now(),
        ]);

        $intent->refresh();

        $this->assertEquals('SUCCESS', $intent->status);
        $this->assertNotNull($intent->confirmed_at);
    }
}
