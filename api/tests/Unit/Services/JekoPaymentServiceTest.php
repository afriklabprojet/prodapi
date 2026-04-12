<?php

namespace Tests\Unit\Services;

use App\Enums\JekoPaymentMethod;
use App\Enums\JekoPaymentStatus;
use App\Models\JekoPayment;
use App\Models\Order;
use App\Models\Wallet;
use App\Models\Courier;
use App\Models\Customer;
use App\Models\Pharmacy;
use App\Models\User;
use App\Services\JekoPaymentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class JekoPaymentServiceTest extends TestCase
{
    use RefreshDatabase;

    protected JekoPaymentService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new JekoPaymentService();
        
        // Allow Log facade calls by default (tests that need specific assertions will override)
        Log::spy();
    }

    // =================================================================
    // Configuration Tests
    // =================================================================

    #[Test]
    public function it_detects_unconfigured_jeko_service()
    {
        config(['services.jeko.api_key' => null]);
        config(['services.jeko.api_key_id' => null]);
        config(['services.jeko.store_id' => null]);

        $service = new JekoPaymentService();
        $this->assertFalse($service->isConfigured());
    }

    #[Test]
    public function it_detects_configured_jeko_service()
    {
        config(['services.jeko.api_key' => 'test-key']);
        config(['services.jeko.api_key_id' => 'test-key-id']);
        config(['services.jeko.store_id' => 'test-store']);
        config(['services.jeko.api_url' => 'https://api.jeko.africa']);

        $service = new JekoPaymentService();
        $this->assertTrue($service->isConfigured());
    }

    #[Test]
    public function it_uses_default_api_url_when_not_configured()
    {
        config(['services.jeko.api_url' => null]);

        $service = new JekoPaymentService();
        // Service should not crash and defaults should be applied
        $this->assertInstanceOf(JekoPaymentService::class, $service);
    }

    // =================================================================
    // getAvailableMethods Tests
    // =================================================================

    #[Test]
    public function it_returns_available_payment_methods()
    {
        $methods = $this->service->getAvailableMethods();

        $this->assertIsArray($methods);
        $this->assertNotEmpty($methods);
        
        // Check structure
        $firstMethod = $methods[0];
        $this->assertArrayHasKey('value', $firstMethod);
        $this->assertArrayHasKey('label', $firstMethod);
        $this->assertArrayHasKey('icon', $firstMethod);
    }

    #[Test]
    public function it_includes_all_payment_methods()
    {
        $methods = $this->service->getAvailableMethods();
        $values = array_column($methods, 'value');

        $expectedMethods = ['wave', 'orange', 'mtn', 'moov', 'djamo'];
        foreach ($expectedMethods as $expected) {
            $this->assertContains($expected, $values);
        }
    }

    // =================================================================
    // Redirect Payment (Sandbox Mode)
    // =================================================================

    #[Test]
    public function it_creates_redirect_payment_in_sandbox_mode()
    {
        // Force sandbox mode
        config(['services.jeko.sandbox_mode' => true]);
        config(['services.jeko.api_key' => null]);

        $service = new JekoPaymentService();

        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
            'total_amount' => 5000,
        ]);

        $payment = $service->createRedirectPayment(
            $order,
            500000, // 5000 XOF in cents
            JekoPaymentMethod::WAVE,
            $customer->user,
            'Test payment'
        );

        $this->assertInstanceOf(JekoPayment::class, $payment);
        $this->assertEquals(500000, $payment->amount_cents);
        $this->assertEquals(JekoPaymentStatus::PROCESSING, $payment->status);
        $this->assertNotNull($payment->reference);
        $this->assertStringContains('SANDBOX-', $payment->jeko_payment_request_id);
    }

    #[Test]
    public function it_rejects_payment_below_minimum_amount()
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('Le montant minimum est de 100 centimes');

        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $this->service->createRedirectPayment(
            $order,
            50, // Below minimum
            JekoPaymentMethod::WAVE
        );
    }

    #[Test]
    public function it_sets_success_and_error_urls_on_payment()
    {
        config(['services.jeko.sandbox_mode' => true]);
        config(['app.url' => 'https://test.example.com']);

        $service = new JekoPaymentService();

        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $payment = $service->createRedirectPayment(
            $order,
            100000,
            JekoPaymentMethod::ORANGE
        );

        $this->assertStringContains('callback/success', $payment->success_url);
        $this->assertStringContains('callback/error', $payment->error_url);
        $this->assertStringContains($payment->reference, $payment->success_url);
    }

    // =================================================================
    // Webhook Signature Validation
    // =================================================================

    #[Test]
    public function it_validates_correct_webhook_signature()
    {
        $webhookSecret = 'test-webhook-secret';
        config(['services.jeko.webhook_secret' => $webhookSecret]);

        $service = new JekoPaymentService();

        $payload = ['status' => 'success', 'id' => 'test-123'];
        $signature = hash_hmac('sha256', json_encode($payload), $webhookSecret);

        $this->assertTrue($service->validateWebhookSignature($payload, $signature));
    }

    #[Test]
    public function it_rejects_invalid_webhook_signature()
    {
        config(['services.jeko.webhook_secret' => 'real-secret']);

        $service = new JekoPaymentService();

        $payload = ['status' => 'success', 'id' => 'test-123'];
        $invalidSignature = hash_hmac('sha256', json_encode($payload), 'wrong-secret');

        $this->assertFalse($service->validateWebhookSignature($payload, $invalidSignature));
    }

    #[Test]
    public function it_rejects_empty_signature()
    {
        config(['services.jeko.webhook_secret' => 'test-secret']);

        $service = new JekoPaymentService();
        $payload = ['status' => 'success'];

        $this->assertFalse($service->validateWebhookSignature($payload, ''));
    }

    #[Test]
    public function it_rejects_webhook_when_secret_not_configured()
    {
        config(['services.jeko.webhook_secret' => null]);

        $service = new JekoPaymentService();
        $payload = ['status' => 'success'];

        // Log::spy() already in setUp, just assert the return value
        $this->assertFalse($service->validateWebhookSignature($payload, 'any-signature'));
        
        // Verify critical log was called
        Log::shouldHaveReceived('critical')->once();
    }

    // =================================================================
    // Check Payment Status
    // =================================================================

    #[Test]
    public function it_skips_status_check_for_finalized_payments()
    {
        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'status' => JekoPaymentStatus::SUCCESS,
            'jeko_payment_request_id' => 'jeko-123',
        ]);

        // Should return the same payment without making API call
        $result = $this->service->checkPaymentStatus($payment);

        $this->assertEquals($payment->id, $result->id);
        $this->assertEquals(JekoPaymentStatus::SUCCESS, $result->status);
    }

    #[Test]
    public function it_skips_status_check_without_jeko_id()
    {
        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'status' => JekoPaymentStatus::PENDING,
            'jeko_payment_request_id' => null,
        ]);

        $result = $this->service->checkPaymentStatus($payment);

        $this->assertEquals($payment->id, $result->id);
    }

    // =================================================================
    // Webhook Handling
    // =================================================================

    #[Test]
    public function it_rejects_webhook_with_invalid_signature()
    {
        config(['services.jeko.webhook_secret' => 'real-secret']);

        $service = new JekoPaymentService();

        $payload = ['status' => 'success'];
        $badSignature = 'invalid-signature';

        $result = $service->handleWebhook($payload, $badSignature);

        $this->assertFalse($result);
    }

    #[Test]
    public function it_rejects_webhook_without_reference()
    {
        $webhookSecret = 'test-secret';
        config(['services.jeko.webhook_secret' => $webhookSecret]);

        $service = new JekoPaymentService();

        $payload = ['status' => 'success'];
        $signature = hash_hmac('sha256', json_encode($payload), $webhookSecret);

        $result = $service->handleWebhook($payload, $signature);

        $this->assertFalse($result);
        
        // Verify warning was logged
        Log::shouldHaveReceived('warning')->atLeast()->once();
    }

    #[Test]
    public function it_rejects_webhook_for_unknown_payment()
    {
        $webhookSecret = 'test-secret';
        config(['services.jeko.webhook_secret' => $webhookSecret]);

        $service = new JekoPaymentService();

        $payload = [
            'status' => 'success',
            'apiTransactionableDetails' => [
                'reference' => 'UNKNOWN-REF-123',
            ],
        ];
        $signature = hash_hmac('sha256', json_encode($payload), $webhookSecret);

        $result = $service->handleWebhook($payload, $signature);

        $this->assertFalse($result);

        // Verify warning was logged
        Log::shouldHaveReceived('warning')->atLeast()->once();
    }

    #[Test]
    public function it_processes_successful_webhook_payment()
    {
        $webhookSecret = 'test-secret';
        config(['services.jeko.webhook_secret' => $webhookSecret]);

        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'status' => JekoPaymentStatus::PROCESSING,
            'amount_cents' => 50000,
        ]);

        $service = new JekoPaymentService();

        $payload = [
            'status' => 'success',
            'apiTransactionableDetails' => [
                'reference' => $payment->reference,
            ],
            'amount' => [
                'amount' => '50000',
                'currency' => 'XOF',
            ],
        ];
        $signature = hash_hmac('sha256', json_encode($payload), $webhookSecret);

        // Mock the async job dispatch
        \Illuminate\Support\Facades\Queue::fake();

        $result = $service->handleWebhook($payload, $signature);

        $this->assertTrue($result);
        
        $payment->refresh();
        $this->assertEquals(JekoPaymentStatus::SUCCESS, $payment->status);
        $this->assertTrue($payment->webhook_processed);
    }

    #[Test]
    public function it_handles_webhook_idempotently()
    {
        $webhookSecret = 'test-secret';
        config(['services.jeko.webhook_secret' => $webhookSecret]);

        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        // Already processed payment
        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'status' => JekoPaymentStatus::SUCCESS,
            'webhook_processed' => true,
        ]);

        $service = new JekoPaymentService();

        $payload = [
            'status' => 'success',
            'apiTransactionableDetails' => [
                'reference' => $payment->reference,
            ],
        ];
        $signature = hash_hmac('sha256', json_encode($payload), $webhookSecret);

        $result = $service->handleWebhook($payload, $signature);

        // Should return true (idempotent success)
        $this->assertTrue($result);
        
        // Verify info log was called
        Log::shouldHaveReceived('info')->atLeast()->once();
    }

    #[Test]
    public function it_rejects_webhook_with_amount_mismatch()
    {
        $webhookSecret = 'test-secret';
        config(['services.jeko.webhook_secret' => $webhookSecret]);

        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'status' => JekoPaymentStatus::PROCESSING,
            'amount_cents' => 50000, // Expected amount
        ]);

        $service = new JekoPaymentService();

        $payload = [
            'status' => 'success',
            'apiTransactionableDetails' => [
                'reference' => $payment->reference,
            ],
            'amount' => [
                'amount' => '99999', // Mismatched amount - potential fraud
                'currency' => 'XOF',
            ],
        ];
        $signature = hash_hmac('sha256', json_encode($payload), $webhookSecret);

        $result = $service->handleWebhook($payload, $signature);

        $this->assertFalse($result);

        $payment->refresh();
        $this->assertEquals(JekoPaymentStatus::FAILED, $payment->status);
        $this->assertStringContains('incohérent', $payment->error_message);
        
        // Verify critical log was called
        Log::shouldHaveReceived('critical')->atLeast()->once();
    }

    #[Test]
    public function it_rejects_expired_webhook_timestamp()
    {
        $webhookSecret = 'test-secret';
        config(['services.jeko.webhook_secret' => $webhookSecret]);

        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'status' => JekoPaymentStatus::PROCESSING,
        ]);

        $service = new JekoPaymentService();

        // Payload with old timestamp (10 minutes ago)
        $payload = [
            'status' => 'success',
            'apiTransactionableDetails' => [
                'reference' => $payment->reference,
            ],
            'executedAt' => date('Y-m-d H:i:s', strtotime('-10 minutes')),
        ];
        $signature = hash_hmac('sha256', json_encode($payload), $webhookSecret);

        $result = $service->handleWebhook($payload, $signature);

        $this->assertFalse($result);
        
        // Verify warning was logged about replay attack
        Log::shouldHaveReceived('warning')->atLeast()->once();
    }

    // =================================================================
    // Sandbox Payment Confirmation
    // =================================================================

    #[Test]
    public function it_confirms_sandbox_payment()
    {
        config(['services.jeko.sandbox_mode' => true]);

        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'status' => JekoPaymentStatus::PROCESSING,
        ]);

        \Illuminate\Support\Facades\Queue::fake();

        $service = new JekoPaymentService();
        $result = $service->confirmSandboxPayment($payment->reference);

        $this->assertEquals(JekoPaymentStatus::SUCCESS, $result->status);
        $this->assertTrue($result->webhook_processed);
        $this->assertNotNull($result->completed_at);
    }

    #[Test]
    public function it_throws_exception_for_unknown_sandbox_payment()
    {
        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Paiement non trouvé');

        $this->service->confirmSandboxPayment('UNKNOWN-REF');
    }

    #[Test]
    public function it_returns_finalized_payment_unchanged_on_confirm()
    {
        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'status' => JekoPaymentStatus::SUCCESS,
            'completed_at' => now(),
        ]);

        $result = $this->service->confirmSandboxPayment($payment->reference);

        $this->assertEquals(JekoPaymentStatus::SUCCESS, $result->status);
    }

    // =================================================================
    // Production API Calls (Mocked)
    // =================================================================

    #[Test]
    public function it_creates_redirect_payment_via_api()
    {
        config([
            'services.jeko.api_key' => 'test-key',
            'services.jeko.api_key_id' => 'test-key-id',
            'services.jeko.store_id' => 'test-store',
            'services.jeko.api_url' => 'https://api.jeko.africa',
            'services.jeko.sandbox_mode' => false,
        ]);

        Http::fake([
            'api.jeko.africa/*' => Http::response([
                'id' => 'jeko-payment-123',
                'redirectUrl' => 'https://pay.jeko.africa/redirect/123',
                'status' => 'pending',
            ], 200),
        ]);

        $service = new JekoPaymentService();

        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $payment = $service->createRedirectPayment(
            $order,
            100000,
            JekoPaymentMethod::WAVE
        );

        $this->assertInstanceOf(JekoPayment::class, $payment);
        $this->assertEquals('jeko-payment-123', $payment->jeko_payment_request_id);
        $this->assertEquals('https://pay.jeko.africa/redirect/123', $payment->redirect_url);
        $this->assertEquals(JekoPaymentStatus::PROCESSING, $payment->status);

        Http::assertSent(function ($request) {
            return $request->hasHeader('X-API-KEY', 'test-key')
                && $request->hasHeader('X-API-KEY-ID', 'test-key-id')
                && str_contains($request->url(), 'payment_requests');
        });
    }

    #[Test]
    public function it_handles_api_error_response()
    {
        config([
            'services.jeko.api_key' => 'test-key',
            'services.jeko.api_key_id' => 'test-key-id',
            'services.jeko.store_id' => 'test-store',
            'services.jeko.api_url' => 'https://api.jeko.africa',
            'services.jeko.sandbox_mode' => false,
        ]);

        Http::fake([
            'api.jeko.africa/*' => Http::response([
                'message' => 'Invalid store ID',
            ], 400),
        ]);

        $service = new JekoPaymentService();

        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('Invalid store ID');

        $service->createRedirectPayment(
            $order,
            100000,
            JekoPaymentMethod::WAVE
        );
    }

    #[Test]
    public function it_handles_missing_redirect_url_in_response()
    {
        config([
            'services.jeko.api_key' => 'test-key',
            'services.jeko.api_key_id' => 'test-key-id',
            'services.jeko.store_id' => 'test-store',
            'services.jeko.api_url' => 'https://api.jeko.africa',
            'services.jeko.sandbox_mode' => false,
        ]);

        Http::fake([
            'api.jeko.africa/*' => Http::response([
                'id' => 'jeko-123',
                // Missing redirectUrl
            ], 200),
        ]);

        $service = new JekoPaymentService();

        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $this->expectException(\Exception::class);
        $this->expectExceptionMessage('redirect_url');

        $service->createRedirectPayment(
            $order,
            100000,
            JekoPaymentMethod::WAVE
        );
    }

    #[Test]
    public function it_checks_payment_status_via_api()
    {
        config([
            'services.jeko.api_key' => 'test-key',
            'services.jeko.api_key_id' => 'test-key-id',
            'services.jeko.store_id' => 'test-store',
            'services.jeko.api_url' => 'https://api.jeko.africa',
        ]);

        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'status' => JekoPaymentStatus::PROCESSING,
            'jeko_payment_request_id' => 'jeko-check-123',
        ]);

        Http::fake([
            'api.jeko.africa/partner_api/payment_requests/jeko-check-123' => Http::response([
                'id' => 'jeko-check-123',
                'status' => 'success',
            ], 200),
        ]);

        \Illuminate\Support\Facades\Queue::fake();

        $service = new JekoPaymentService();
        $result = $service->checkPaymentStatus($payment);

        $this->assertEquals(JekoPaymentStatus::SUCCESS, $result->status);
    }

    #[Test]
    public function it_handles_failed_status_check_gracefully()
    {
        config([
            'services.jeko.api_key' => 'test-key',
            'services.jeko.api_key_id' => 'test-key-id',
            'services.jeko.store_id' => 'test-store',
            'services.jeko.api_url' => 'https://api.jeko.africa',
        ]);

        $customer = Customer::factory()->create();
        $pharmacy = Pharmacy::factory()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'pharmacy_id' => $pharmacy->id,
        ]);

        $payment = JekoPayment::factory()->create([
            'payable_type' => Order::class,
            'payable_id' => $order->id,
            'status' => JekoPaymentStatus::PROCESSING,
            'jeko_payment_request_id' => 'jeko-fail-123',
        ]);

        Http::fake([
            'api.jeko.africa/*' => Http::response([], 500),
        ]);

        $service = new JekoPaymentService();
        $result = $service->checkPaymentStatus($payment);

        // Should return original payment without crashing
        $this->assertEquals(JekoPaymentStatus::PROCESSING, $result->status);
    }

    // =================================================================
    // Helper assertion
    // =================================================================

    protected function assertStringContains(string $needle, ?string $haystack): void
    {
        $this->assertNotNull($haystack);
        $this->assertTrue(
            str_contains($haystack, $needle),
            "Failed asserting that '$haystack' contains '$needle'"
        );
    }
}
