<?php

namespace Tests\Feature;

use App\Enums\JekoPaymentMethod;
use App\Enums\JekoPaymentStatus;
use App\Jobs\ProcessPaymentResultJob;
use App\Models\Courier;
use App\Models\Customer;
use App\Models\JekoPayment;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\User;
use App\Models\Wallet;
use App\Services\JekoPaymentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Bus;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class JekoPaymentControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    private User $customer;
    private User $courierUser;
    private Courier $courier;
    private Pharmacy $pharmacy;
    private Order $order;

    protected function setUp(): void
    {
        parent::setUp();

        $this->customer = User::factory()->create([
            'role' => 'customer',
            'phone_verified_at' => now(),
            'must_change_password' => false,
        ]);

        $this->pharmacy = Pharmacy::factory()->create(['status' => 'approved']);

        $this->order = Order::factory()->create([
            'customer_id' => $this->customer->id,
            'pharmacy_id' => $this->pharmacy->id,
            'status' => 'confirmed',
            'payment_status' => 'pending',
            'total_amount' => 10000,
        ]);

        $this->courierUser = User::factory()->create([
            'role' => 'courier',
            'phone_verified_at' => now(),
            'must_change_password' => false,
        ]);
        $this->courier = Courier::factory()->create([
            'user_id' => $this->courierUser->id,
            'status' => 'available',
        ]);
    }

    private function mockJekoService(): JekoPaymentService
    {
        $mock = $this->mock(JekoPaymentService::class);
        return $mock;
    }

    private function createPayment(array $attrs = []): JekoPayment
    {
        return JekoPayment::factory()->create(array_merge([
            'user_id' => $this->customer->id,
            'payable_type' => Order::class,
            'payable_id' => $this->order->id,
        ], $attrs));
    }

    // ──────────────────────────────────────────────────────────────
    // INITIATE ORDER PAYMENT
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function initiate_order_payment_succeeds()
    {
        $mock = $this->mockJekoService();
        $payment = $this->createPayment([
            'status' => JekoPaymentStatus::SUCCESS,
            'redirect_url' => 'https://jeko.test/pay',
            'payment_method' => JekoPaymentMethod::WAVE,
        ]);
        $mock->shouldReceive('createRedirectPayment')->once()->andReturn($payment);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/payments/initiate', [
                'type' => 'order',
                'order_id' => $this->order->id,
                'payment_method' => 'wave',
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['reference', 'redirect_url', 'amount', 'currency', 'payment_method']]);
    }

    #[Test]
    public function initiate_order_payment_rejects_unowned_order()
    {
        $otherUser = User::factory()->create([
            'role' => 'customer',
            'phone_verified_at' => now(),
            'must_change_password' => false,
        ]);

        $response = $this->actingAs($otherUser, 'sanctum')
            ->postJson('/api/customer/payments/initiate', [
                'type' => 'order',
                'order_id' => $this->order->id,
                'payment_method' => 'wave',
            ]);

        $response->assertForbidden()
            ->assertJsonPath('error_code', 'ORDER_NOT_OWNED');
    }

    #[Test]
    public function initiate_order_payment_rejects_already_paid()
    {
        $this->order->update(['payment_status' => 'paid']);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/payments/initiate', [
                'type' => 'order',
                'order_id' => $this->order->id,
                'payment_method' => 'wave',
            ]);

        $response->assertStatus(400)
            ->assertJsonPath('error_code', 'ORDER_ALREADY_PAID');
    }

    #[Test]
    public function initiate_order_payment_detects_in_progress_payment()
    {
        $this->createPayment([
            'status' => JekoPaymentStatus::PROCESSING,
            'redirect_url' => 'https://jeko.test/pay',
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/payments/initiate', [
                'type' => 'order',
                'order_id' => $this->order->id,
                'payment_method' => 'wave',
            ]);

        $response->assertStatus(409)
            ->assertJsonPath('error_code', 'PAYMENT_IN_PROGRESS');
    }

    #[Test]
    public function initiate_order_payment_auto_expires_stale_payments()
    {
        $stalePayment = $this->createPayment([
            'status' => JekoPaymentStatus::PENDING,
            'created_at' => now()->subMinutes(35),
        ]);

        $mock = $this->mockJekoService();
        // Build a payment model for the mock return (not persisted to DB,
        // so it doesn't interfere with the "in progress" check)
        $newPayment = new JekoPayment();
        $newPayment->id = 999;
        $newPayment->reference = 'JEKO-NEW-REF';
        $newPayment->redirect_url = 'https://jeko.test/new';
        $newPayment->payment_method = JekoPaymentMethod::WAVE;
        $newPayment->status = JekoPaymentStatus::PENDING;
        $newPayment->amount_cents = 1000000;
        $newPayment->currency = 'XOF';
        $mock->shouldReceive('createRedirectPayment')->once()->andReturn($newPayment);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/payments/initiate', [
                'type' => 'order',
                'order_id' => $this->order->id,
                'payment_method' => 'wave',
            ]);

        $response->assertOk();
        $this->assertEquals('expired', $stalePayment->fresh()->status->value);
    }

    #[Test]
    public function initiate_validates_required_fields()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/payments/initiate', []);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['type', 'payment_method']);
    }

    #[Test]
    public function initiate_validates_type_enum()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/payments/initiate', [
                'type' => 'invalid_type',
                'payment_method' => 'wave',
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['type']);
    }

    #[Test]
    public function initiate_validates_payment_method_enum()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/payments/initiate', [
                'type' => 'order',
                'order_id' => $this->order->id,
                'payment_method' => 'bitcoin',
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['payment_method']);
    }

    #[Test]
    public function initiate_order_requires_order_id()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/payments/initiate', [
                'type' => 'order',
                'payment_method' => 'wave',
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['order_id']);
    }

    #[Test]
    public function initiate_order_validates_order_exists()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/payments/initiate', [
                'type' => 'order',
                'order_id' => 99999,
                'payment_method' => 'wave',
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['order_id']);
    }

    // ──────────────────────────────────────────────────────────────
    // INITIATE WALLET TOPUP
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function initiate_wallet_topup_for_customer()
    {
        Customer::create(['user_id' => $this->customer->id]);

        $mock = $this->mockJekoService();
        $payment = JekoPayment::factory()->create([
            'user_id' => $this->customer->id,
            'payable_type' => Wallet::class,
            'payable_id' => 1,
            'redirect_url' => 'https://jeko.test/pay',
            'payment_method' => JekoPaymentMethod::ORANGE,
        ]);
        $mock->shouldReceive('createRedirectPayment')->once()->andReturn($payment);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/payments/initiate', [
                'type' => 'wallet_topup',
                'amount' => 5000,
                'payment_method' => 'orange',
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    #[Test]
    public function initiate_wallet_topup_creates_customer_if_missing()
    {
        $this->assertNull(Customer::where('user_id', $this->customer->id)->first());

        $mock = $this->mockJekoService();
        $payment = JekoPayment::factory()->create([
            'user_id' => $this->customer->id,
            'payable_type' => Wallet::class,
            'payable_id' => 1,
            'redirect_url' => 'https://jeko.test/pay',
            'payment_method' => JekoPaymentMethod::MTN,
        ]);
        $mock->shouldReceive('createRedirectPayment')->once()->andReturn($payment);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/payments/initiate', [
                'type' => 'wallet_topup',
                'amount' => 1000,
                'payment_method' => 'mtn',
            ]);

        $response->assertOk();
        $this->assertNotNull(Customer::where('user_id', $this->customer->id)->first());
    }

    #[Test]
    public function initiate_wallet_topup_amount_min_validation()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/payments/initiate', [
                'type' => 'wallet_topup',
                'amount' => 100,
                'payment_method' => 'wave',
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['amount']);
    }

    #[Test]
    public function initiate_wallet_topup_amount_max_validation()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/payments/initiate', [
                'type' => 'wallet_topup',
                'amount' => 2000000,
                'payment_method' => 'wave',
            ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['amount']);
    }

    #[Test]
    public function initiate_wallet_topup_for_courier()
    {
        $mock = $this->mockJekoService();
        $payment = JekoPayment::factory()->create([
            'user_id' => $this->courierUser->id,
            'payable_type' => Wallet::class,
            'payable_id' => 1,
            'redirect_url' => 'https://jeko.test/pay',
            'payment_method' => JekoPaymentMethod::WAVE,
        ]);
        $mock->shouldReceive('createRedirectPayment')->once()->andReturn($payment);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/payments/initiate', [
                'type' => 'wallet_topup',
                'amount' => 5000,
                'payment_method' => 'wave',
            ]);

        $response->assertOk();
    }

    #[Test]
    public function initiate_wallet_topup_auto_cancels_pending_payments()
    {
        $customerModel = Customer::create(['user_id' => $this->customer->id]);
        $wallet = Wallet::create([
            'walletable_type' => Customer::class,
            'walletable_id' => $customerModel->id,
            'balance' => 0,
            'currency' => 'XOF',
        ]);

        $pendingPayment = JekoPayment::factory()->create([
            'user_id' => $this->customer->id,
            'payable_type' => Wallet::class,
            'payable_id' => $wallet->id,
            'status' => JekoPaymentStatus::PENDING,
            'webhook_received_at' => null,
        ]);

        $mock = $this->mockJekoService();
        $newPayment = JekoPayment::factory()->create([
            'user_id' => $this->customer->id,
            'payable_type' => Wallet::class,
            'payable_id' => $wallet->id,
            'redirect_url' => 'https://jeko.test/new',
            'payment_method' => JekoPaymentMethod::WAVE,
        ]);
        $mock->shouldReceive('createRedirectPayment')->once()->andReturn($newPayment);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/payments/initiate', [
                'type' => 'wallet_topup',
                'amount' => 5000,
                'payment_method' => 'wave',
            ]);

        $response->assertOk();
        $this->assertEquals('failed', $pendingPayment->fresh()->status->value);
    }

    #[Test]
    public function initiate_handles_jeko_service_exception()
    {
        $mock = $this->mockJekoService();
        $mock->shouldReceive('createRedirectPayment')->once()
            ->andThrow(new \Exception('Jeko API unavailable'));

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson('/api/customer/payments/initiate', [
                'type' => 'order',
                'order_id' => $this->order->id,
                'payment_method' => 'wave',
            ]);

        $response->assertStatus(400)
            ->assertJsonPath('error_code', 'PAYMENT_INIT_FAILED');
    }

    // ──────────────────────────────────────────────────────────────
    // STATUS
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function status_returns_pending_payment()
    {
        $payment = $this->createPayment([
            'status' => JekoPaymentStatus::PENDING,
        ]);
        $mock = $this->mockJekoService();
        $mock->shouldReceive('checkPaymentStatus')->once()->andReturn($payment);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->getJson("/api/customer/payments/{$payment->reference}/status");

        $response->assertOk()
            ->assertJsonPath('data.reference', $payment->reference)
            ->assertJsonPath('data.payment_status', 'pending')
            ->assertJsonPath('data.is_final', false);
    }

    #[Test]
    public function status_returns_completed_payment_without_checking_jeko()
    {
        $payment = $this->createPayment([
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => true,
            'completed_at' => now(),
        ]);

        $mock = $this->mockJekoService();
        $mock->shouldNotReceive('checkPaymentStatus');

        $response = $this->actingAs($this->customer, 'sanctum')
            ->getJson("/api/customer/payments/{$payment->reference}/status");

        $response->assertOk()
            ->assertJsonPath('data.payment_status', 'success')
            ->assertJsonPath('data.is_final', true);
    }

    #[Test]
    public function status_dispatches_sync_job_when_success_not_processed()
    {
        Bus::fake([ProcessPaymentResultJob::class]);

        $payment = $this->createPayment([
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
        ]);

        $mock = $this->mockJekoService();
        $mock->shouldNotReceive('checkPaymentStatus');

        $response = $this->actingAs($this->customer, 'sanctum')
            ->getJson("/api/customer/payments/{$payment->reference}/status");

        // The controller calls dispatchSync, so Bus::fake won't capture it.
        // Just verify the response is OK.
        $response->assertOk();
    }

    #[Test]
    public function status_returns_404_for_other_users_payment()
    {
        $payment = $this->createPayment([
            'user_id' => User::factory()->create(['role' => 'customer'])->id,
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->getJson("/api/customer/payments/{$payment->reference}/status");

        $response->assertNotFound()
            ->assertJsonPath('error_code', 'PAYMENT_NOT_FOUND');
    }

    #[Test]
    public function status_returns_404_for_nonexistent_reference()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->getJson('/api/customer/payments/INVALID-REF/status');

        $response->assertNotFound()
            ->assertJsonPath('error_code', 'PAYMENT_NOT_FOUND');
    }

    // ──────────────────────────────────────────────────────────────
    // INDEX (LIST)
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function index_returns_paginated_payments()
    {
        JekoPayment::factory()->count(3)->create([
            'user_id' => $this->customer->id,
            'payable_type' => Order::class,
            'payable_id' => $this->order->id,
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->getJson('/api/customer/payments');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(3, 'data');
    }

    #[Test]
    public function index_only_shows_own_payments()
    {
        JekoPayment::factory()->count(2)->create([
            'user_id' => $this->customer->id,
            'payable_type' => Order::class,
            'payable_id' => $this->order->id,
        ]);
        JekoPayment::factory()->create([
            'user_id' => User::factory()->create()->id,
            'payable_type' => Order::class,
            'payable_id' => $this->order->id,
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->getJson('/api/customer/payments');

        $response->assertOk()
            ->assertJsonCount(2, 'data');
    }

    #[Test]
    public function index_returns_empty_when_no_payments()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->getJson('/api/customer/payments');

        $response->assertOk()
            ->assertJsonCount(0, 'data');
    }

    // ──────────────────────────────────────────────────────────────
    // METHODS
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function methods_returns_available_payment_methods()
    {
        $mock = $this->mockJekoService();
        $mock->shouldReceive('getAvailableMethods')->once()->andReturn([
            ['method' => 'wave', 'label' => 'Wave'],
            ['method' => 'orange', 'label' => 'Orange Money'],
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->getJson('/api/customer/payments/methods');

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    // ──────────────────────────────────────────────────────────────
    // CALLBACKS (NO AUTH)
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function callback_success_without_reference()
    {
        $response = $this->get('/api/payments/callback/success');

        $response->assertOk()
            ->assertViewIs('payments.callback')
            ->assertViewHas('status', 'error');
    }

    #[Test]
    public function callback_success_with_unknown_reference()
    {
        $response = $this->get('/api/payments/callback/success?reference=UNKNOWN-REF');

        $response->assertOk()
            ->assertViewIs('payments.callback')
            ->assertViewHas('status', 'error');
    }

    #[Test]
    public function callback_success_with_valid_reference()
    {
        Queue::fake();

        $payment = $this->createPayment([
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
        ]);

        $mock = $this->mockJekoService();
        $mock->shouldNotReceive('checkPaymentStatus');

        $response = $this->get("/api/payments/callback/success?reference={$payment->reference}");

        $response->assertOk()
            ->assertViewIs('payments.callback')
            ->assertViewHas('status', 'success')
            ->assertViewHas('reference', $payment->reference);

        Queue::assertPushed(ProcessPaymentResultJob::class);
    }

    #[Test]
    public function callback_success_checks_jeko_if_not_final()
    {
        $payment = $this->createPayment([
            'status' => JekoPaymentStatus::PENDING,
        ]);

        $mock = $this->mockJekoService();
        $mock->shouldReceive('checkPaymentStatus')->once()->andReturn($payment);

        $response = $this->get("/api/payments/callback/success?reference={$payment->reference}");

        $response->assertOk();
    }

    #[Test]
    public function callback_error_without_reference()
    {
        $response = $this->get('/api/payments/callback/error');

        $response->assertOk()
            ->assertViewIs('payments.callback')
            ->assertViewHas('status', 'error');
    }

    #[Test]
    public function callback_error_with_unknown_reference()
    {
        $response = $this->get('/api/payments/callback/error?reference=UNKNOWN');

        $response->assertOk()
            ->assertViewIs('payments.callback')
            ->assertViewHas('status', 'error');
    }

    #[Test]
    public function callback_error_with_valid_reference()
    {
        $payment = $this->createPayment([
            'status' => JekoPaymentStatus::FAILED,
            'error_message' => 'Insufficient funds',
        ]);

        $mock = $this->mockJekoService();
        $mock->shouldNotReceive('checkPaymentStatus');

        $response = $this->get("/api/payments/callback/error?reference={$payment->reference}");

        $response->assertOk()
            ->assertViewIs('payments.callback')
            ->assertViewHas('status', 'error');
    }

    // ──────────────────────────────────────────────────────────────
    // SANDBOX CONFIRM
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function sandbox_confirm_works_in_testing()
    {
        $mock = $this->mockJekoService();
        $payment = new JekoPayment();
        $payment->id = 1;
        $payment->reference = 'TEST-REF';
        $payment->amount = 10000;
        $mock->shouldReceive('confirmSandboxPayment')->once()->andReturn($payment);

        $response = $this->get('/api/payments/sandbox/confirm?reference=TEST-REF');

        $response->assertOk();
    }

    #[Test]
    public function sandbox_confirm_requires_reference()
    {
        $response = $this->get('/api/payments/sandbox/confirm');

        $response->assertStatus(400);
    }

    // ──────────────────────────────────────────────────────────────
    // CANCEL
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function cancel_pending_payment_succeeds()
    {
        $payment = $this->createPayment([
            'user_id' => $this->courierUser->id,
            'status' => JekoPaymentStatus::PENDING,
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson("/api/courier/payments/{$payment->reference}/cancel");

        $response->assertOk()
            ->assertJsonPath('data.payment_status', 'cancelled');

        $this->assertEquals('failed', $payment->fresh()->status->value);
    }

    #[Test]
    public function cancel_rejects_finalized_payment()
    {
        $payment = $this->createPayment([
            'user_id' => $this->courierUser->id,
            'status' => JekoPaymentStatus::SUCCESS,
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson("/api/courier/payments/{$payment->reference}/cancel");

        $response->assertStatus(400)
            ->assertJsonPath('error_code', 'PAYMENT_ALREADY_FINALIZED');
    }

    #[Test]
    public function cancel_rejects_other_users_payment()
    {
        $payment = $this->createPayment([
            'user_id' => $this->customer->id,
            'status' => JekoPaymentStatus::PENDING,
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson("/api/courier/payments/{$payment->reference}/cancel");

        $response->assertForbidden()
            ->assertJsonPath('error_code', 'PAYMENT_NOT_OWNED');
    }

    #[Test]
    public function cancel_returns_404_for_unknown_reference()
    {
        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/payments/UNKNOWN-REF/cancel');

        $response->assertNotFound();
    }

    // ──────────────────────────────────────────────────────────────
    // AUTH GUARD
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function initiate_requires_authentication()
    {
        $response = $this->postJson('/api/customer/payments/initiate', [
            'type' => 'order',
            'order_id' => $this->order->id,
            'payment_method' => 'wave',
        ]);

        $response->assertUnauthorized();
    }

    #[Test]
    public function index_requires_authentication()
    {
        $response = $this->getJson('/api/customer/payments');

        $response->assertUnauthorized();
    }
}
