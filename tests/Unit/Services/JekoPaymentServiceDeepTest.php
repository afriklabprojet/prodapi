<?php

namespace Tests\Unit\Services;

use App\Enums\JekoPaymentMethod;
use App\Enums\JekoPaymentStatus;
use App\Jobs\ProcessPaymentResultJob;
use App\Models\JekoPayment;
use App\Models\Order;
use App\Models\User;
use App\Models\Wallet;
use App\Services\JekoPaymentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class JekoPaymentServiceDeepTest extends TestCase
{
    use RefreshDatabase;

    private JekoPaymentService $service;

    protected function setUp(): void
    {
        parent::setUp();
        Log::spy();
        Queue::fake();
        Config::set('services.jeko.api_url', 'https://api.jeko.africa');
        Config::set('services.jeko.api_key', 'test-api-key');
        Config::set('services.jeko.api_key_id', 'test-api-key-id');
        Config::set('services.jeko.store_id', 'test-store-id');
        Config::set('services.jeko.webhook_secret', 'test-webhook-secret');
        Config::set('services.jeko.sandbox_mode', false);
        $this->service = new JekoPaymentService();
    }

    private function callPrivate(string $method, array $args = []): mixed
    {
        $ref = new \ReflectionMethod($this->service, $method);
        $ref->setAccessible(true);
        return $ref->invoke($this->service, ...$args);
    }

    private function makePayment(array $overrides = []): JekoPayment
    {
        return JekoPayment::factory()->create(array_merge([
            'payable_type' => 'App\\Models\\Order',
            'payable_id' => 1,
            'amount_cents' => 50000,
            'status' => JekoPaymentStatus::PENDING,
        ], $overrides));
    }

    private function validSignature(array $payload): string
    {
        return hash_hmac('sha256', json_encode($payload), 'test-webhook-secret');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // isConfigured
    // ═══════════════════════════════════════════════════════════════════════

    public function test_is_configured_with_keys(): void
    {
        $this->assertTrue($this->service->isConfigured());
    }

    public function test_not_configured_without_api_key(): void
    {
        Config::set('services.jeko.api_key', null);
        $s = new JekoPaymentService();
        $this->assertFalse($s->isConfigured());
    }

    public function test_not_configured_without_api_key_id(): void
    {
        Config::set('services.jeko.api_key_id', null);
        $s = new JekoPaymentService();
        $this->assertFalse($s->isConfigured());
    }

    public function test_not_configured_without_store_id(): void
    {
        Config::set('services.jeko.store_id', null);
        $s = new JekoPaymentService();
        $this->assertFalse($s->isConfigured());
    }

    public function test_not_configured_invalid_url(): void
    {
        Config::set('services.jeko.api_url', 'not-a-url');
        $s = new JekoPaymentService();
        $this->assertFalse($s->isConfigured());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // getAvailableMethods
    // ═══════════════════════════════════════════════════════════════════════

    public function test_get_available_methods(): void
    {
        $methods = $this->service->getAvailableMethods();
        $this->assertNotEmpty($methods);
        foreach ($methods as $m) {
            $this->assertArrayHasKey('value', $m);
            $this->assertArrayHasKey('label', $m);
            $this->assertArrayHasKey('icon', $m);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // createRedirectPayment
    // ═══════════════════════════════════════════════════════════════════════

    public function test_create_redirect_payment_min_amount(): void
    {
        $order = Order::factory()->create();
        $this->expectException(\InvalidArgumentException::class);
        $this->service->createRedirectPayment($order, 50, JekoPaymentMethod::WAVE);
    }

    public function test_create_redirect_payment_sandbox(): void
    {
        Config::set('services.jeko.sandbox_mode', true);
        $this->service = new JekoPaymentService();
        $order = Order::factory()->create();

        $payment = $this->service->createRedirectPayment($order, 10000, JekoPaymentMethod::WAVE);
        $this->assertEquals(JekoPaymentStatus::PROCESSING, $payment->status);
        $this->assertStringContains('sandbox/confirm', $payment->redirect_url);
        $this->assertStringStartsWith('SANDBOX-', $payment->jeko_payment_request_id);
    }

    public function test_create_redirect_payment_api_success(): void
    {
        Http::fake([
            '*/partner_api/payment_requests' => Http::response([
                'id' => 'jeko-123',
                'redirectUrl' => 'https://pay.jeko.africa/123',
            ], 200),
        ]);

        $order = Order::factory()->create();
        $user = User::factory()->create();

        $payment = $this->service->createRedirectPayment(
            $order, 10000, JekoPaymentMethod::WAVE, $user, 'Test payment'
        );

        $this->assertEquals(JekoPaymentStatus::PROCESSING, $payment->status);
        $this->assertEquals('jeko-123', $payment->jeko_payment_request_id);
        $this->assertEquals('https://pay.jeko.africa/123', $payment->redirect_url);
    }

    public function test_create_redirect_payment_snake_case_redirect(): void
    {
        Http::fake([
            '*/partner_api/payment_requests' => Http::response([
                'id' => 'jeko-456',
                'redirect_url' => 'https://pay.jeko.africa/456',
            ], 200),
        ]);

        $order = Order::factory()->create();
        $payment = $this->service->createRedirectPayment($order, 10000, JekoPaymentMethod::ORANGE);

        $this->assertEquals('https://pay.jeko.africa/456', $payment->redirect_url);
    }

    public function test_create_redirect_payment_api_error(): void
    {
        Http::fake([
            '*/partner_api/payment_requests' => Http::response([
                'message' => 'Invalid store',
            ], 400),
        ]);

        $order = Order::factory()->create();
        $this->expectException(\Exception::class);
        $this->service->createRedirectPayment($order, 10000, JekoPaymentMethod::WAVE);
    }

    public function test_create_redirect_payment_no_redirect_url(): void
    {
        Http::fake([
            '*/partner_api/payment_requests' => Http::response([
                'id' => 'jeko-no-redirect',
            ], 200),
        ]);

        $order = Order::factory()->create();
        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('redirect_url');
        $this->service->createRedirectPayment($order, 10000, JekoPaymentMethod::WAVE);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // checkPaymentStatus
    // ═══════════════════════════════════════════════════════════════════════

    public function test_check_status_no_jeko_id(): void
    {
        $payment = $this->makePayment(['jeko_payment_request_id' => null]);
        $result = $this->service->checkPaymentStatus($payment);
        $this->assertEquals(JekoPaymentStatus::PENDING, $result->status);
    }

    public function test_check_status_already_final(): void
    {
        $payment = $this->makePayment([
            'jeko_payment_request_id' => 'jeko-1',
            'status' => JekoPaymentStatus::SUCCESS,
        ]);
        Http::fake(); // Should NOT be called
        $result = $this->service->checkPaymentStatus($payment);
        $this->assertEquals(JekoPaymentStatus::SUCCESS, $result->status);
    }

    public function test_check_status_api_success(): void
    {
        $payment = $this->makePayment([
            'jeko_payment_request_id' => 'jeko-abc',
            'status' => JekoPaymentStatus::PROCESSING,
        ]);

        Http::fake([
            '*/partner_api/payment_requests/jeko-abc' => Http::response([
                'status' => 'success',
            ], 200),
        ]);

        $result = $this->service->checkPaymentStatus($payment);
        $this->assertEquals(JekoPaymentStatus::SUCCESS, $result->status);
        Queue::assertPushed(ProcessPaymentResultJob::class);
    }

    public function test_check_status_api_failed(): void
    {
        $payment = $this->makePayment([
            'jeko_payment_request_id' => 'jeko-fail',
            'status' => JekoPaymentStatus::PROCESSING,
        ]);

        Http::fake([
            '*/partner_api/payment_requests/jeko-fail' => Http::response([
                'status' => 'error',
            ], 200),
        ]);

        $result = $this->service->checkPaymentStatus($payment);
        $this->assertEquals(JekoPaymentStatus::FAILED, $result->status);
    }

    public function test_check_status_http_error(): void
    {
        $payment = $this->makePayment([
            'jeko_payment_request_id' => 'jeko-err',
            'status' => JekoPaymentStatus::PROCESSING,
        ]);

        Http::fake(['*' => Http::response('error', 500)]);
        $result = $this->service->checkPaymentStatus($payment);
        $this->assertEquals(JekoPaymentStatus::PROCESSING, $result->status);
    }

    public function test_check_status_exception(): void
    {
        $payment = $this->makePayment([
            'jeko_payment_request_id' => 'jeko-exc',
            'status' => JekoPaymentStatus::PROCESSING,
        ]);

        Http::fake(fn() => throw new \Exception('timeout'));
        $result = $this->service->checkPaymentStatus($payment);
        $this->assertEquals(JekoPaymentStatus::PROCESSING, $result->status);
    }

    public function test_check_status_does_not_redispatch_if_already_success(): void
    {
        $payment = $this->makePayment([
            'jeko_payment_request_id' => 'jeko-already',
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => true,
        ]);

        // Already final, won't even call API
        $this->service->checkPaymentStatus($payment);
        Queue::assertNotPushed(ProcessPaymentResultJob::class);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // validateWebhookSignature
    // ═══════════════════════════════════════════════════════════════════════

    public function test_webhook_signature_valid(): void
    {
        $payload = ['id' => '1', 'status' => 'success'];
        $sig = $this->validSignature($payload);
        $this->assertTrue($this->service->validateWebhookSignature($payload, $sig));
    }

    public function test_webhook_signature_invalid(): void
    {
        $this->assertFalse($this->service->validateWebhookSignature(['x' => 1], 'bad'));
    }

    public function test_webhook_signature_empty(): void
    {
        $this->assertFalse($this->service->validateWebhookSignature(['x' => 1], ''));
    }

    public function test_webhook_signature_no_secret(): void
    {
        Config::set('services.jeko.webhook_secret', null);
        $s = new JekoPaymentService();
        $this->assertFalse($s->validateWebhookSignature(['x' => 1], 'any'));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // validateWebhookTimestamp
    // ═══════════════════════════════════════════════════════════════════════

    public function test_webhook_timestamp_valid_string(): void
    {
        $payload = ['executedAt' => date('Y-m-d H:i:s')];
        $this->assertTrue($this->callPrivate('validateWebhookTimestamp', [$payload]));
    }

    public function test_webhook_timestamp_expired(): void
    {
        $payload = ['executedAt' => date('Y-m-d H:i:s', time() - 600)];
        $this->assertFalse($this->callPrivate('validateWebhookTimestamp', [$payload]));
    }

    public function test_webhook_timestamp_missing(): void
    {
        $this->assertTrue($this->callPrivate('validateWebhookTimestamp', [[]]));
    }

    public function test_webhook_timestamp_numeric(): void
    {
        $payload = ['timestamp' => (string)time()];
        $this->assertTrue($this->callPrivate('validateWebhookTimestamp', [$payload]));
    }

    public function test_webhook_timestamp_invalid_format(): void
    {
        $payload = ['executedAt' => 'not-a-date'];
        // strtotime returns false → returns true (accept if can't parse)
        $this->assertTrue($this->callPrivate('validateWebhookTimestamp', [$payload]));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // validateWebhookAmount
    // ═══════════════════════════════════════════════════════════════════════

    public function test_webhook_amount_matches(): void
    {
        $payment = $this->makePayment(['amount_cents' => 50000]);
        $payload = ['amount' => ['amount' => '50000', 'currency' => 'XOF']];
        $this->assertTrue($this->callPrivate('validateWebhookAmount', [$payment, $payload]));
    }

    public function test_webhook_amount_mismatch(): void
    {
        $payment = $this->makePayment(['amount_cents' => 50000]);
        $payload = ['amount' => ['amount' => '99999', 'currency' => 'XOF']];
        $this->assertFalse($this->callPrivate('validateWebhookAmount', [$payment, $payload]));
        $payment->refresh();
        $this->assertEquals(JekoPaymentStatus::FAILED, $payment->status);
    }

    public function test_webhook_amount_cents_fallback(): void
    {
        $payment = $this->makePayment(['amount_cents' => 30000]);
        $payload = ['amountCents' => 30000];
        $this->assertTrue($this->callPrivate('validateWebhookAmount', [$payment, $payload]));
    }

    public function test_webhook_amount_snake_case_fallback(): void
    {
        $payment = $this->makePayment(['amount_cents' => 20000]);
        $payload = ['amount_cents' => 20000];
        $this->assertTrue($this->callPrivate('validateWebhookAmount', [$payment, $payload]));
    }

    public function test_webhook_amount_missing_accepts(): void
    {
        $payment = $this->makePayment();
        $this->assertTrue($this->callPrivate('validateWebhookAmount', [$payment, []]));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // updatePaymentFromJekoResponse
    // ═══════════════════════════════════════════════════════════════════════

    public function test_update_payment_success_status(): void
    {
        $payment = $this->makePayment();
        $result = $this->callPrivate('updatePaymentFromJekoResponse', [$payment, ['status' => 'success']]);
        $this->assertEquals(JekoPaymentStatus::SUCCESS, $result->status);
        $this->assertNotNull($result->completed_at);
        $this->assertTrue($result->webhook_processed);
    }

    public function test_update_payment_error_status(): void
    {
        $payment = $this->makePayment();
        $result = $this->callPrivate('updatePaymentFromJekoResponse', [$payment, ['status' => 'error']]);
        $this->assertEquals(JekoPaymentStatus::FAILED, $result->status);
        $this->assertNotNull($result->error_message);
    }

    public function test_update_payment_expired_status(): void
    {
        $payment = $this->makePayment();
        $result = $this->callPrivate('updatePaymentFromJekoResponse', [$payment, ['status' => 'expired']]);
        $this->assertEquals(JekoPaymentStatus::EXPIRED, $result->status);
    }

    public function test_update_payment_pending_status(): void
    {
        $payment = $this->makePayment();
        $result = $this->callPrivate('updatePaymentFromJekoResponse', [$payment, ['status' => 'pending']]);
        $this->assertEquals(JekoPaymentStatus::PROCESSING, $result->status);
    }

    public function test_update_payment_cancelled_status(): void
    {
        $payment = $this->makePayment();
        $result = $this->callPrivate('updatePaymentFromJekoResponse', [$payment, ['status' => 'cancelled']]);
        $this->assertEquals(JekoPaymentStatus::FAILED, $result->status);
    }

    public function test_update_payment_unknown_status(): void
    {
        $payment = $this->makePayment();
        $result = $this->callPrivate('updatePaymentFromJekoResponse', [$payment, ['status' => 'unknown']]);
        $this->assertEquals(JekoPaymentStatus::PROCESSING, $result->status);
    }

    public function test_update_payment_with_transaction_data(): void
    {
        $payment = $this->makePayment();
        $result = $this->callPrivate('updatePaymentFromJekoResponse', [$payment, [
            'status' => 'success',
            'counterpartLabel' => 'John Doe',
            'paymentMethod' => 'wave',
            'executedAt' => '2025-01-01 12:00:00',
        ]]);
        $this->assertNotNull($result->transaction_data);
        $this->assertEquals('John Doe', $result->transaction_data['counterpartLabel']);
    }

    public function test_update_payment_with_error_message(): void
    {
        $payment = $this->makePayment();
        $result = $this->callPrivate('updatePaymentFromJekoResponse', [$payment, [
            'status' => 'error',
            'error' => ['message' => 'Insufficient funds'],
        ]]);
        $this->assertEquals('Insufficient funds', $result->error_message);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // handleWebhook
    // ═══════════════════════════════════════════════════════════════════════

    public function test_webhook_invalid_signature(): void
    {
        $this->assertFalse($this->service->handleWebhook(['id' => '1'], 'badsig'));
    }

    public function test_webhook_no_reference(): void
    {
        $payload = ['status' => 'success'];
        $sig = $this->validSignature($payload);
        $this->assertFalse($this->service->handleWebhook($payload, $sig));
    }

    public function test_webhook_payment_not_found(): void
    {
        $payload = [
            'status' => 'success',
            'apiTransactionableDetails' => ['reference' => 'NONEXISTENT', 'id' => null],
            'executedAt' => date('Y-m-d H:i:s'),
        ];
        $sig = $this->validSignature($payload);
        $this->assertFalse($this->service->handleWebhook($payload, $sig));
    }

    public function test_webhook_success_payment(): void
    {
        $payment = $this->makePayment();
        $payload = [
            'status' => 'success',
            'apiTransactionableDetails' => ['reference' => $payment->reference, 'id' => 'j-1'],
            'executedAt' => date('Y-m-d H:i:s'),
            'amount' => ['amount' => (string)$payment->amount_cents, 'currency' => 'XOF'],
        ];
        $sig = $this->validSignature($payload);

        $this->assertTrue($this->service->handleWebhook($payload, $sig));
        $payment->refresh();
        $this->assertEquals(JekoPaymentStatus::SUCCESS, $payment->status);
        Queue::assertPushed(ProcessPaymentResultJob::class);
    }

    public function test_webhook_idempotent(): void
    {
        $payment = $this->makePayment(['webhook_processed' => true]);
        $payload = [
            'status' => 'success',
            'apiTransactionableDetails' => ['reference' => $payment->reference, 'id' => 'j-2'],
            'executedAt' => date('Y-m-d H:i:s'),
        ];
        $sig = $this->validSignature($payload);

        $this->assertTrue($this->service->handleWebhook($payload, $sig));
        Queue::assertNotPushed(ProcessPaymentResultJob::class);
    }

    public function test_webhook_amount_mismatch_blocks(): void
    {
        $payment = $this->makePayment(['amount_cents' => 50000]);
        $payload = [
            'status' => 'success',
            'apiTransactionableDetails' => ['reference' => $payment->reference, 'id' => 'j-3'],
            'executedAt' => date('Y-m-d H:i:s'),
            'amount' => ['amount' => '9999', 'currency' => 'XOF'],
        ];
        $sig = $this->validSignature($payload);

        $this->assertFalse($this->service->handleWebhook($payload, $sig));
        Queue::assertNotPushed(ProcessPaymentResultJob::class);
    }

    public function test_webhook_via_transaction_details(): void
    {
        $payment = $this->makePayment();
        $payload = [
            'status' => 'success',
            'transactionDetails' => ['reference' => $payment->reference, 'id' => 'j-4'],
            'executedAt' => date('Y-m-d H:i:s'),
        ];
        $sig = $this->validSignature($payload);

        $this->assertTrue($this->service->handleWebhook($payload, $sig));
    }

    public function test_webhook_find_by_jeko_id(): void
    {
        $payment = $this->makePayment(['jeko_payment_request_id' => 'jeko-find-me']);
        $payload = [
            'id' => 'jeko-find-me',
            'status' => 'success',
            'apiTransactionableDetails' => ['reference' => null, 'id' => 'jeko-find-me'],
            'executedAt' => date('Y-m-d H:i:s'),
        ];
        $sig = $this->validSignature($payload);

        $this->assertTrue($this->service->handleWebhook($payload, $sig));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // createPayout
    // ═══════════════════════════════════════════════════════════════════════

    public function test_create_payout_min_amount(): void
    {
        $wallet = $this->createWalletModel();
        $this->expectException(\InvalidArgumentException::class);
        $this->service->createPayout($wallet, 100, '+22901234567', JekoPaymentMethod::WAVE);
    }

    public function test_create_payout_sandbox(): void
    {
        Config::set('services.jeko.sandbox_mode', true);
        $this->service = new JekoPaymentService();

        $wallet = $this->createWalletModel();
        $payment = $this->service->createPayout($wallet, 50000, '+22901234567', JekoPaymentMethod::WAVE);

        $this->assertTrue($payment->is_payout);
        $this->assertEquals(JekoPaymentStatus::PROCESSING, $payment->status);
        $this->assertStringStartsWith('SANDBOX_PAYOUT_', $payment->jeko_payment_request_id);
    }

    public function test_create_payout_api_success(): void
    {
        Http::fake([
            '*/partner_api/contacts' => Http::response(['id' => 'contact-1'], 200),
            '*/partner_api/transfers' => Http::response([
                'id' => 'transfer-1',
                'status' => 'pending',
                'fees' => ['amount' => 500],
            ], 200),
        ]);

        $wallet = $this->createWalletModel();
        $user = User::factory()->create();
        $payment = $this->service->createPayout(
            $wallet, 50000, '+22901234567', JekoPaymentMethod::WAVE, $user, 'Test payout'
        );

        $this->assertTrue($payment->is_payout);
        $this->assertEquals('transfer-1', $payment->jeko_payment_request_id);
        $this->assertEquals(JekoPaymentStatus::PROCESSING, $payment->status);
    }

    public function test_create_payout_contact_creation_fails(): void
    {
        Http::fake([
            '*/partner_api/contacts' => Http::response(['message' => 'Invalid phone'], 400),
        ]);

        $wallet = $this->createWalletModel();
        $this->expectException(\Exception::class);
        $this->service->createPayout($wallet, 50000, '+22901234567', JekoPaymentMethod::WAVE);
    }

    public function test_create_payout_transfer_fails(): void
    {
        Http::fake([
            '*/partner_api/contacts' => Http::response(['id' => 'c-1'], 200),
            '*/partner_api/transfers' => Http::response(['message' => 'Insufficient balance'], 400),
        ]);

        $wallet = $this->createWalletModel();
        $this->expectException(\Exception::class);
        $this->service->createPayout($wallet, 50000, '+22901234567', JekoPaymentMethod::WAVE);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // createBankPayout
    // ═══════════════════════════════════════════════════════════════════════

    public function test_create_bank_payout_throws(): void
    {
        $wallet = $this->createWalletModel();
        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('virements bancaires');
        $this->service->createBankPayout($wallet, 50000, ['account' => '123']);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // confirmSandboxPayment
    // ═══════════════════════════════════════════════════════════════════════

    public function test_confirm_sandbox_payment_not_found(): void
    {
        $this->expectException(\Exception::class);
        $this->service->confirmSandboxPayment('NONEXISTENT');
    }

    public function test_confirm_sandbox_payment_already_final(): void
    {
        $payment = $this->makePayment(['status' => JekoPaymentStatus::SUCCESS]);
        $result = $this->service->confirmSandboxPayment($payment->reference);
        $this->assertEquals(JekoPaymentStatus::SUCCESS, $result->status);
    }

    public function test_confirm_sandbox_payment_success(): void
    {
        $payment = $this->makePayment(['status' => JekoPaymentStatus::PROCESSING]);
        $result = $this->service->confirmSandboxPayment($payment->reference);

        $this->assertEquals(JekoPaymentStatus::SUCCESS, $result->status);
        $this->assertNotNull($result->completed_at);
        Queue::assertPushed(ProcessPaymentResultJob::class);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // confirmSandboxPayout
    // ═══════════════════════════════════════════════════════════════════════

    public function test_confirm_sandbox_payout_not_found(): void
    {
        $this->expectException(\Exception::class);
        $this->service->confirmSandboxPayout('NOPE');
    }

    public function test_confirm_sandbox_payout_not_payout(): void
    {
        $payment = $this->makePayment(['is_payout' => false]);
        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('décaissement');
        $this->service->confirmSandboxPayout($payment->reference);
    }

    public function test_confirm_sandbox_payout_already_final(): void
    {
        $payment = $this->makePayment([
            'is_payout' => true,
            'status' => JekoPaymentStatus::SUCCESS,
        ]);
        $result = $this->service->confirmSandboxPayout($payment->reference);
        $this->assertEquals(JekoPaymentStatus::SUCCESS, $result->status);
    }

    public function test_confirm_sandbox_payout_success(): void
    {
        $payment = $this->makePayment([
            'is_payout' => true,
            'status' => JekoPaymentStatus::PROCESSING,
        ]);
        $result = $this->service->confirmSandboxPayout($payment->reference);
        $this->assertEquals(JekoPaymentStatus::SUCCESS, $result->status);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // checkPayoutStatus
    // ═══════════════════════════════════════════════════════════════════════

    public function test_check_payout_status_not_payout(): void
    {
        $payment = $this->makePayment(['is_payout' => false]);
        $result = $this->service->checkPayoutStatus($payment);
        $this->assertEquals(JekoPaymentStatus::PENDING, $result->status);
    }

    public function test_check_payout_status_no_jeko_id(): void
    {
        $payment = $this->makePayment([
            'is_payout' => true,
            'jeko_payment_request_id' => null,
        ]);
        $result = $this->service->checkPayoutStatus($payment);
        $this->assertEquals(JekoPaymentStatus::PENDING, $result->status);
    }

    public function test_check_payout_status_already_final(): void
    {
        $payment = $this->makePayment([
            'is_payout' => true,
            'jeko_payment_request_id' => 'transfer-1',
            'status' => JekoPaymentStatus::SUCCESS,
        ]);
        $result = $this->service->checkPayoutStatus($payment);
        Http::assertNothingSent();
    }

    public function test_check_payout_status_success(): void
    {
        $payment = $this->makePayment([
            'is_payout' => true,
            'jeko_payment_request_id' => 'transfer-chk',
            'status' => JekoPaymentStatus::PROCESSING,
        ]);

        Http::fake([
            '*/partner_api/transfers/transfer-chk' => Http::response(['status' => 'SUCCESS'], 200),
        ]);

        $result = $this->service->checkPayoutStatus($payment);
        $this->assertEquals(JekoPaymentStatus::SUCCESS, $result->status);
    }

    public function test_check_payout_status_sent(): void
    {
        $payment = $this->makePayment([
            'is_payout' => true,
            'jeko_payment_request_id' => 'transfer-sent',
            'status' => JekoPaymentStatus::PROCESSING,
        ]);

        Http::fake([
            '*/partner_api/transfers/transfer-sent' => Http::response(['status' => 'SENT'], 200),
        ]);

        $result = $this->service->checkPayoutStatus($payment);
        $this->assertEquals(JekoPaymentStatus::SUCCESS, $result->status);
    }

    public function test_check_payout_status_failed(): void
    {
        $payment = $this->makePayment([
            'is_payout' => true,
            'jeko_payment_request_id' => 'transfer-fail',
            'status' => JekoPaymentStatus::PROCESSING,
        ]);

        Http::fake([
            '*/partner_api/transfers/transfer-fail' => Http::response([
                'status' => 'FAILED',
                'message' => 'Receiver rejected',
            ], 200),
        ]);

        $result = $this->service->checkPayoutStatus($payment);
        $this->assertEquals(JekoPaymentStatus::FAILED, $result->status);
    }

    public function test_check_payout_status_api_error(): void
    {
        $payment = $this->makePayment([
            'is_payout' => true,
            'jeko_payment_request_id' => 'transfer-err',
            'status' => JekoPaymentStatus::PROCESSING,
        ]);

        Http::fake(['*' => Http::response('error', 500)]);

        $result = $this->service->checkPayoutStatus($payment);
        $this->assertEquals(JekoPaymentStatus::PROCESSING, $result->status);
    }

    public function test_check_payout_status_exception(): void
    {
        $payment = $this->makePayment([
            'is_payout' => true,
            'jeko_payment_request_id' => 'transfer-exc',
            'status' => JekoPaymentStatus::PROCESSING,
        ]);

        Http::fake(fn() => throw new \Exception('timeout'));

        $result = $this->service->checkPayoutStatus($payment);
        $this->assertEquals(JekoPaymentStatus::PROCESSING, $result->status);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // normalizePhoneNumber
    // ═══════════════════════════════════════════════════════════════════════

    public function test_normalize_phone_strips_spaces(): void
    {
        $r = $this->callPrivate('normalizePhoneNumber', ['+229 01 234 567']);
        $this->assertEquals('+22901234567', $r);
    }

    public function test_normalize_phone_adds_prefix(): void
    {
        $r = $this->callPrivate('normalizePhoneNumber', ['01234567']);
        $this->assertEquals('+2291234567', $r);
    }

    public function test_normalize_phone_adds_plus(): void
    {
        $r = $this->callPrivate('normalizePhoneNumber', ['22901234567']);
        $this->assertEquals('+22901234567', $r);
    }

    public function test_normalize_phone_keeps_plus(): void
    {
        $r = $this->callPrivate('normalizePhoneNumber', ['+22901234567']);
        $this->assertEquals('+22901234567', $r);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // createRedirectPayment — RequestException catch (lines 172-178)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_create_redirect_payment_request_exception(): void
    {
        Http::fake(function () {
            throw new \Illuminate\Http\Client\ConnectionException('Connection refused');
        });

        $order = Order::factory()->create();

        $this->expectException(\Exception::class);

        $this->service->createRedirectPayment(
            $order, 50000, JekoPaymentMethod::WAVE,
        );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // checkPaymentStatus — handleSuccessfulPayment dispatch (line 253)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_check_status_newly_success_dispatches_when_not_business_processed(): void
    {
        $payment = $this->makePayment([
            'jeko_payment_request_id' => 'jeko-new-success',
            'status' => JekoPaymentStatus::PROCESSING,
            'business_processed' => false,
        ]);

        Http::fake([
            '*/partner_api/payment_requests/jeko-new-success' => Http::response([
                'status' => 'success',
            ], 200),
        ]);

        $result = $this->service->checkPaymentStatus($payment);
        $this->assertEquals(JekoPaymentStatus::SUCCESS, $result->status);
        Queue::assertPushed(ProcessPaymentResultJob::class, function ($job) use ($payment) {
            return true;
        });
    }

    public function test_check_status_already_business_processed_no_redispatch(): void
    {
        $payment = $this->makePayment([
            'jeko_payment_request_id' => 'jeko-bp',
            'status' => JekoPaymentStatus::PROCESSING,
            'business_processed' => true,
        ]);

        Http::fake([
            '*/partner_api/payment_requests/jeko-bp' => Http::response([
                'status' => 'success',
            ], 200),
        ]);

        $result = $this->service->checkPaymentStatus($payment);
        $this->assertEquals(JekoPaymentStatus::SUCCESS, $result->status);
        // business_processed=true should prevent re-dispatch
        Queue::assertNotPushed(ProcessPaymentResultJob::class);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // handleWebhook — payout failed path (line 317)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_webhook_failed_payout_triggers_refund(): void
    {
        $wallet = $this->createWalletModel();
        $payment = $this->makePayment([
            'payable_type' => Wallet::class,
            'payable_id' => $wallet->id,
            'is_payout' => true,
            'amount_cents' => 50000,
            'status' => JekoPaymentStatus::PROCESSING,
        ]);

        $payload = [
            'status' => 'error',
            'apiTransactionableDetails' => ['reference' => $payment->reference, 'id' => 'j-fail-payout'],
            'executedAt' => date('Y-m-d H:i:s'),
            'amount' => ['amount' => '50000', 'currency' => 'XOF'],
        ];
        $sig = $this->validSignature($payload);

        $this->assertTrue($this->service->handleWebhook($payload, $sig));

        $payment->refresh();
        $this->assertEquals(JekoPaymentStatus::FAILED, $payment->status);

        // Verify wallet was credited (refund)
        $refundRef = 'REFUND-' . $payment->reference;
        $this->assertTrue(
            $wallet->transactions()->where('reference', $refundRef)->exists()
        );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // handleFailedPayout — private method (lines 542-610)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_handle_failed_payout_payable_not_wallet(): void
    {
        $order = Order::factory()->create();
        $payment = $this->makePayment([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'is_payout' => true,
            'status' => JekoPaymentStatus::FAILED,
        ]);

        // Should log warning and return without error
        $this->callPrivate('handleFailedPayout', [$payment]);
        Log::shouldHaveReceived('warning')->withArgs(fn ($msg) => str_contains($msg, 'payable is not a Wallet'));
    }

    public function test_handle_failed_payout_already_refunded_idempotent(): void
    {
        $wallet = $this->createWalletModel();
        $payment = $this->makePayment([
            'payable_type' => Wallet::class,
            'payable_id' => $wallet->id,
            'is_payout' => true,
            'amount_cents' => 30000,
            'status' => JekoPaymentStatus::FAILED,
            'error_message' => 'Transfer failed',
        ]);

        // Pre-create the refund transaction to simulate idempotent check
        $refundRef = 'REFUND-' . $payment->reference;
        $wallet->transactions()->create([
            'type' => 'CREDIT',
            'amount' => 300.00,
            'balance_after' => $wallet->balance + 300,
            'reference' => $refundRef,
            'description' => 'Existing refund',
        ]);

        $this->callPrivate('handleFailedPayout', [$payment]);
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, 'idempotent'));

        // Should NOT have created another refund transaction
        $this->assertEquals(1, $wallet->transactions()->where('reference', $refundRef)->count());
    }

    public function test_handle_failed_payout_refunds_wallet_successfully(): void
    {
        $wallet = $this->createWalletModel();
        $payment = $this->makePayment([
            'payable_type' => Wallet::class,
            'payable_id' => $wallet->id,
            'is_payout' => true,
            'amount_cents' => 100000, // 1000 XOF
            'status' => JekoPaymentStatus::FAILED,
            'error_message' => 'Receiver rejected',
        ]);

        $balanceBefore = (float) $wallet->balance;
        $this->callPrivate('handleFailedPayout', [$payment]);

        $wallet->refresh();
        $refundRef = 'REFUND-' . $payment->reference;
        $refund = $wallet->transactions()->where('reference', $refundRef)->first();

        $this->assertNotNull($refund);
        $this->assertEquals('CREDIT', $refund->type);
        $this->assertEquals(1000.00, (float) $refund->amount);
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, 'wallet refunded'));
    }

    public function test_handle_failed_payout_marks_debit_as_refunded(): void
    {
        $wallet = $this->createWalletModel();
        $payment = $this->makePayment([
            'payable_type' => Wallet::class,
            'payable_id' => $wallet->id,
            'is_payout' => true,
            'amount_cents' => 50000, // 500 XOF
            'status' => JekoPaymentStatus::FAILED,
            'error_message' => 'Failed transfer',
        ]);

        // Create the original debit transaction that matches
        $debit = $wallet->transactions()->create([
            'type' => 'DEBIT',
            'amount' => 500.00,
            'balance_after' => $wallet->balance - 500,
            'reference' => 'DEBIT-' . $payment->reference,
            'description' => 'Withdrawal',
            'category' => 'withdrawal',
            'status' => 'processing',
            'metadata' => json_encode(['original_payment_reference' => $payment->reference]),
        ]);

        $this->callPrivate('handleFailedPayout', [$payment]);

        $debit->refresh();
        $this->assertEquals('refunded', $debit->status);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // handleOrderPayment — private method (lines 620-680)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_handle_order_payment_marks_order_paid(): void
    {
        $order = Order::factory()->create(['payment_status' => 'pending']);
        $payment = $this->makePayment([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
        ]);

        $this->callPrivate('handleOrderPayment', [$order, $payment]);

        $order->refresh();
        $this->assertEquals('paid', $order->payment_status);
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, 'Order Marked as Paid'));
    }

    public function test_handle_order_payment_already_paid_idempotent(): void
    {
        $order = Order::factory()->create(['payment_status' => 'paid']);
        $payment = $this->makePayment([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
        ]);

        $this->callPrivate('handleOrderPayment', [$order, $payment]);
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, 'already paid'));
    }

    public function test_handle_order_payment_dispatches_notifications(): void
    {
        $pharmacy = \App\Models\Pharmacy::factory()->create();
        $pharmacyUser = User::factory()->create();
        $pharmacy->users()->attach($pharmacyUser);

        $order = Order::factory()->create([
            'payment_status' => 'pending',
            'pharmacy_id' => $pharmacy->id,
        ]);
        $payment = $this->makePayment([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
        ]);

        $this->callPrivate('handleOrderPayment', [$order, $payment]);

        Queue::assertPushed(\App\Jobs\SendNotificationJob::class);
    }

    public function test_handle_order_payment_no_pharmacy_users_no_crash(): void
    {
        // Pharmacy with no attached users
        $pharmacy = \App\Models\Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'payment_status' => 'pending',
            'pharmacy_id' => $pharmacy->id,
        ]);
        $payment = $this->makePayment([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
        ]);

        // Should not throw even if pharmacy has no users
        $this->callPrivate('handleOrderPayment', [$order, $payment]);
        $order->refresh();
        $this->assertEquals('paid', $order->payment_status);
        Queue::assertNotPushed(\App\Jobs\SendNotificationJob::class);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // handleWalletTopup — private method (lines 680-730)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_handle_wallet_topup_already_credited_idempotent(): void
    {
        $wallet = $this->createWalletModel();
        $payment = $this->makePayment([
            'payable_type' => Wallet::class,
            'payable_id' => $wallet->id,
            'amount_cents' => 50000,
            'payment_method' => JekoPaymentMethod::WAVE,
        ]);

        // Pre-create transaction with same reference
        $wallet->transactions()->create([
            'type' => 'CREDIT',
            'amount' => 500.00,
            'balance_after' => $wallet->balance + 500,
            'reference' => $payment->reference,
            'description' => 'Already credited',
        ]);

        $this->callPrivate('handleWalletTopup', [$wallet, $payment]);
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, 'already credited'));
    }

    public function test_handle_wallet_topup_credits_wallet(): void
    {
        $courier = \App\Models\Courier::factory()->create();
        $wallet = Wallet::firstOrCreate(
            ['walletable_type' => \App\Models\Courier::class, 'walletable_id' => $courier->id],
            ['balance' => 10000, 'currency' => 'XOF']
        );
        $payment = $this->makePayment([
            'payable_type' => Wallet::class,
            'payable_id' => $wallet->id,
            'amount_cents' => 50000,
            'payment_method' => JekoPaymentMethod::WAVE,
        ]);

        // Mock WalletService to avoid complex side effects
        $walletServiceMock = \Mockery::mock(\App\Services\WalletService::class)->makePartial();
        $walletServiceMock->shouldReceive('topUp')->once()->with(
            \Mockery::type(\App\Models\Courier::class),
            \Mockery::any(),
            \Mockery::any(),
            \Mockery::any()
        );
        $this->app->instance(\App\Services\WalletService::class, $walletServiceMock);

        $this->callPrivate('handleWalletTopup', [$wallet, $payment]);
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, 'Wallet Topped Up'));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // createPayout — RequestException catch (lines 936-942)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_create_payout_request_exception(): void
    {
        Http::fake(function ($request) {
            // Let contact creation succeed but transfer throws
            if (str_contains($request->url(), 'contacts')) {
                return Http::response(['id' => 'contact-ok'], 200);
            }
            throw new \Illuminate\Http\Client\ConnectionException('Connection timeout');
        });

        $wallet = $this->createWalletModel();
        $this->expectException(\Exception::class);

        $this->service->createPayout($wallet, 50000, '+22901234567', JekoPaymentMethod::WAVE);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // handleSuccessfulPayout — protected method (lines 1051-1080)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_handle_successful_payout_no_payable(): void
    {
        // Use a valid model type but with an ID that doesn't exist
        $payment = $this->makePayment([
            'payable_type' => Wallet::class,
            'payable_id' => 999999,
            'is_payout' => true,
            'status' => JekoPaymentStatus::SUCCESS,
        ]);

        $this->callPrivate('handleSuccessfulPayout', [$payment]);
        Log::shouldHaveReceived('warning')->withArgs(fn ($msg) => str_contains($msg, 'no payable found'));
    }

    public function test_handle_successful_payout_withdrawal_request_completed(): void
    {
        $wallet = $this->createWalletModel();
        $wr = \App\Models\WithdrawalRequest::create([
            'wallet_id' => $wallet->id,
            'amount' => 5000,
            'payment_method' => 'wave',
            'status' => 'processing',
            'reference' => 'WR-' . uniqid(),
        ]);

        $user = User::factory()->create();
        $payment = $this->makePayment([
            'payable_type' => \App\Models\WithdrawalRequest::class,
            'payable_id' => $wr->id,
            'is_payout' => true,
            'status' => JekoPaymentStatus::SUCCESS,
            'user_id' => $user->id,
        ]);

        // Use Notification::fake to catch the notification
        \Illuminate\Support\Facades\Notification::fake();

        $this->callPrivate('handleSuccessfulPayout', [$payment]);

        $wr->refresh();
        $this->assertEquals('completed', $wr->status);
        $this->assertNotNull($wr->completed_at);
        $this->assertEquals($payment->reference, $wr->jeko_reference);
        Log::shouldHaveReceived('info')->withArgs(fn ($msg) => str_contains($msg, 'Withdrawal completed'));
    }

    public function test_handle_successful_payout_sends_notification_to_user(): void
    {
        $wallet = $this->createWalletModel();
        $user = User::factory()->create();
        $payment = $this->makePayment([
            'payable_type' => Wallet::class,
            'payable_id' => $wallet->id,
            'is_payout' => true,
            'status' => JekoPaymentStatus::SUCCESS,
            'user_id' => $user->id,
            'amount_cents' => 50000,
        ]);

        \Illuminate\Support\Facades\Notification::fake();

        $this->callPrivate('handleSuccessfulPayout', [$payment]);

        \Illuminate\Support\Facades\Notification::assertSentTo(
            $user,
            \App\Notifications\PayoutCompletedNotification::class
        );
    }

    public function test_handle_successful_payout_notification_failure_does_not_throw(): void
    {
        $wallet = $this->createWalletModel();
        $user = \Mockery::mock(User::class)->makePartial();
        $user->shouldReceive('notify')->andThrow(new \Exception('Notification channel down'));
        $user->id = 999;

        // Create payment and link user via fresh query
        $realUser = User::factory()->create();
        $payment = $this->makePayment([
            'payable_type' => Wallet::class,
            'payable_id' => $wallet->id,
            'is_payout' => true,
            'status' => JekoPaymentStatus::SUCCESS,
            'user_id' => $realUser->id,
        ]);

        // Replace the user relation to use our mock
        $payment->setRelation('user', $user);

        $this->callPrivate('handleSuccessfulPayout', [$payment]);
        Log::shouldHaveReceived('warning')->withArgs(fn ($msg) => str_contains($msg, 'Failed to send payout notification'));
    }

    public function test_handle_successful_payout_no_user_no_notification(): void
    {
        $wallet = $this->createWalletModel();
        $payment = $this->makePayment([
            'payable_type' => Wallet::class,
            'payable_id' => $wallet->id,
            'is_payout' => true,
            'status' => JekoPaymentStatus::SUCCESS,
            'user_id' => null,
        ]);

        \Illuminate\Support\Facades\Notification::fake();
        $this->callPrivate('handleSuccessfulPayout', [$payment]);
        \Illuminate\Support\Facades\Notification::assertNothingSent();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // checkPayoutStatus — handleSuccessfulPayout integration (lines 1117-1120)
    // ═══════════════════════════════════════════════════════════════════════

    public function test_check_payout_status_success_calls_handle_successful_payout(): void
    {
        $wallet = $this->createWalletModel();
        $user = User::factory()->create();
        $payment = $this->makePayment([
            'is_payout' => true,
            'jeko_payment_request_id' => 'transfer-success-handle',
            'status' => JekoPaymentStatus::PROCESSING,
            'payable_type' => Wallet::class,
            'payable_id' => $wallet->id,
            'user_id' => $user->id,
        ]);

        Http::fake([
            '*/partner_api/transfers/transfer-success-handle' => Http::response(['status' => 'SUCCESS'], 200),
        ]);

        \Illuminate\Support\Facades\Notification::fake();
        $result = $this->service->checkPayoutStatus($payment);

        $this->assertEquals(JekoPaymentStatus::SUCCESS, $result->status);
        \Illuminate\Support\Facades\Notification::assertSentTo(
            $user,
            \App\Notifications\PayoutCompletedNotification::class
        );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // helpers
    // ═══════════════════════════════════════════════════════════════════════

    private function assertStringContains(string $needle, ?string $haystack): void
    {
        $this->assertNotNull($haystack);
        $this->assertStringContainsString($needle, $haystack);
    }

    private function createWalletModel(): Wallet
    {
        // Create a wallet-like model. If Wallet factory doesn't exist, use raw creation.
        if (class_exists(\Database\Factories\WalletFactory::class)) {
            return Wallet::factory()->create();
        }
        
        // Fallback: create user and wallet manually
        $user = User::factory()->create();
        return Wallet::firstOrCreate(
            ['walletable_type' => User::class, 'walletable_id' => $user->id],
            ['balance' => 100000, 'currency' => 'XOF']
        );
    }
}
