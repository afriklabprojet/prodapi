<?php

namespace Tests\Unit\Models;

use App\Enums\JekoPaymentMethod;
use App\Enums\JekoPaymentStatus;
use App\Models\JekoPayment;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class JekoPaymentTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_auto_generates_uuid_on_creation()
    {
        $payment = JekoPayment::factory()->create([
            'uuid' => null,
        ]);

        $this->assertNotNull($payment->uuid);
        $this->assertTrue(\Illuminate\Support\Str::isUuid($payment->uuid));
    }

    #[Test]
    public function it_auto_generates_reference_on_creation()
    {
        $payment = JekoPayment::factory()->create([
            'reference' => null,
        ]);

        $this->assertNotNull($payment->reference);
        $this->assertStringStartsWith('PAY-', $payment->reference);
    }

    #[Test]
    public function it_belongs_to_user()
    {
        $user = User::factory()->create();
        $payment = JekoPayment::factory()->create(['user_id' => $user->id]);

        $this->assertInstanceOf(User::class, $payment->user);
        $this->assertEquals($user->id, $payment->user->id);
    }

    #[Test]
    public function it_morphs_to_payable()
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = Pharmacy::factory()->create();
        
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);
        
        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
        ]);

        $this->assertInstanceOf(Order::class, $payment->payable);
        $this->assertEquals($order->id, $payment->payable->id);
    }

    #[Test]
    public function it_provides_amount_accessor()
    {
        $payment = JekoPayment::factory()->create([
            'amount_cents' => 150000,
        ]);

        $this->assertEquals(150000, $payment->amount);
    }

    #[Test]
    public function it_scopes_by_reference()
    {
        $payment = JekoPayment::factory()->create([
            'reference' => 'PAY-TEST123',
        ]);
        
        JekoPayment::factory()->create([
            'reference' => 'PAY-OTHER456',
        ]);

        $found = JekoPayment::byReference('PAY-TEST123')->first();

        $this->assertNotNull($found);
        $this->assertEquals($payment->id, $found->id);
    }

    #[Test]
    public function it_scopes_by_jeko_id()
    {
        $payment = JekoPayment::factory()->create([
            'jeko_payment_request_id' => 'JEKO123',
        ]);
        
        JekoPayment::factory()->create([
            'jeko_payment_request_id' => 'JEKO456',
        ]);

        $found = JekoPayment::byJekoId('JEKO123')->first();

        $this->assertNotNull($found);
        $this->assertEquals($payment->id, $found->id);
    }

    #[Test]
    public function it_returns_empty_query_for_null_jeko_id()
    {
        JekoPayment::factory()->create([
            'jeko_payment_request_id' => 'JEKO123',
        ]);

        $found = JekoPayment::byJekoId(null)->get();

        $this->assertEmpty($found);
    }

    #[Test]
    public function it_identifies_final_status()
    {
        $successPayment = JekoPayment::factory()->create([
            'status' => JekoPaymentStatus::SUCCESS,
        ]);
        
        $failedPayment = JekoPayment::factory()->create([
            'status' => JekoPaymentStatus::FAILED,
        ]);
        
        $pendingPayment = JekoPayment::factory()->create([
            'status' => JekoPaymentStatus::PENDING,
        ]);

        $this->assertTrue($successPayment->isFinal());
        $this->assertTrue($failedPayment->isFinal());
        $this->assertFalse($pendingPayment->isFinal());
    }

    #[Test]
    public function it_identifies_success_status()
    {
        $successPayment = JekoPayment::factory()->create([
            'status' => JekoPaymentStatus::SUCCESS,
        ]);
        
        $failedPayment = JekoPayment::factory()->create([
            'status' => JekoPaymentStatus::FAILED,
        ]);

        $this->assertTrue($successPayment->isSuccess());
        $this->assertFalse($failedPayment->isSuccess());
    }

    #[Test]
    public function it_can_be_marked_as_failed()
    {
        $payment = JekoPayment::factory()->create([
            'status' => JekoPaymentStatus::PENDING,
        ]);

        $payment->markAsFailed('Payment declined by bank');

        $payment->refresh();

        $this->assertEquals(JekoPaymentStatus::FAILED, $payment->status);
        $this->assertEquals('Payment declined by bank', $payment->error_message);
        $this->assertNotNull($payment->completed_at);
    }

    #[Test]
    public function it_casts_payment_method_to_enum()
    {
        $payment = JekoPayment::factory()->create([
            'payment_method' => JekoPaymentMethod::WAVE,
        ]);

        $this->assertInstanceOf(JekoPaymentMethod::class, $payment->payment_method);
    }

    #[Test]
    public function it_casts_status_to_enum()
    {
        $payment = JekoPayment::factory()->create([
            'status' => JekoPaymentStatus::PENDING,
        ]);

        $this->assertInstanceOf(JekoPaymentStatus::class, $payment->status);
    }

    #[Test]
    public function it_casts_transaction_data_to_array()
    {
        $data = ['foo' => 'bar', 'baz' => 123];
        $payment = JekoPayment::factory()->create([
            'transaction_data' => $data,
        ]);

        $payment->refresh();

        $this->assertIsArray($payment->transaction_data);
        $this->assertEquals($data, $payment->transaction_data);
    }

    #[Test]
    public function it_casts_bank_details_to_array()
    {
        $details = ['bank' => 'Test Bank', 'account' => '123456'];
        $payment = JekoPayment::factory()->create([
            'bank_details' => $details,
        ]);

        $payment->refresh();

        $this->assertIsArray($payment->bank_details);
        $this->assertEquals($details, $payment->bank_details);
    }

    #[Test]
    public function it_uses_soft_deletes()
    {
        $payment = JekoPayment::factory()->create();
        $paymentId = $payment->id;
        
        $payment->delete();

        $this->assertSoftDeleted('jeko_payments', ['id' => $paymentId]);
        $this->assertNotNull(JekoPayment::withTrashed()->find($paymentId));
    }
}
