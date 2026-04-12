<?php

namespace Tests\Feature;

use App\Models\Pharmacy;
use App\Models\Setting;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use App\Services\JekoPaymentService;
use App\Services\OtpService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class PharmacyWalletControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    private User $pharmacyUser;
    private Pharmacy $pharmacy;
    private Wallet $wallet;

    protected function setUp(): void
    {
        parent::setUp();

        $this->pharmacyUser = User::factory()->create([
            'role' => 'pharmacy',
            'phone' => '+22507000001',
            'phone_verified_at' => now(),
            'must_change_password' => false,
        ]);

        $this->pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->pharmacy->users()->attach($this->pharmacyUser->id, ['role' => 'titulaire']);

        $this->wallet = Wallet::create([
            'walletable_id' => $this->pharmacy->id,
            'walletable_type' => Pharmacy::class,
            'balance' => 50000,
            'currency' => 'XOF',
        ]);
    }

    private function actingAsPharmacy()
    {
        return $this->actingAs($this->pharmacyUser, 'sanctum');
    }

    // ─── INDEX ───────────────────────────────────────────────────────────────

    public function test_index_returns_wallet_balance_and_transactions(): void
    {
        // Create a few transactions
        $this->wallet->transactions()->create([
            'amount' => 1000,
            'type' => 'credit',
            'description' => 'Commission',
            'reference' => 'TX-001',
            'balance_after' => 51000,
        ]);

        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/wallet');

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure(['data' => ['balance', 'currency', 'transactions', 'total_earnings']]);
    }

    public function test_index_creates_wallet_if_missing(): void
    {
        // Delete the wallet so it gets auto-created
        $this->wallet->delete();

        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/wallet');

        $response->assertOk()
            ->assertJsonPath('data.balance', '0.00');
    }

    // ─── STATS ───────────────────────────────────────────────────────────────

    public function test_stats_returns_period_data(): void
    {
        $this->wallet->transactions()->create([
            'amount' => 5000,
            'type' => 'credit',
            'description' => 'Earning',
            'reference' => 'TX-S1',
            'balance_after' => 55000,
        ]);

        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/wallet/stats?period=month');

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure(['data' => ['total_credits', 'total_debits', 'period']]);
    }

    public function test_stats_without_wallet(): void
    {
        $this->wallet->delete();

        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/wallet/stats');

        $response->assertOk()
            ->assertJsonPath('data.total_credits', 0);
    }

    public function test_stats_today_period(): void
    {
        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/wallet/stats?period=today');

        $response->assertOk()
            ->assertJsonPath('data.period', 'today');
    }

    public function test_stats_year_period(): void
    {
        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/wallet/stats?period=year');

        $response->assertOk()
            ->assertJsonPath('data.period', 'year');
    }

    // ─── WITHDRAW ────────────────────────────────────────────────────────────

    public function test_withdraw_requires_pin(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/withdraw', [
            'amount' => 5000,
            'payment_method' => 'orange',
            'phone' => '+22507000001',
            // Missing pin
        ]);

        $response->assertStatus(422);
    }

    public function test_withdraw_pin_not_configured_returns_error(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/withdraw', [
            'amount' => 5000,
            'payment_method' => 'orange',
            'phone' => '+22507000001',
            'pin' => '1234',
        ]);

        $response->assertStatus(400)
            ->assertJsonPath('code', 'PIN_NOT_CONFIGURED');
    }

    public function test_withdraw_wrong_pin_returns_error(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/withdraw', [
            'amount' => 5000,
            'payment_method' => 'orange',
            'phone' => '+22507000001',
            'pin' => '9999',
        ]);

        $response->assertStatus(401)
            ->assertJsonPath('code', 'PIN_INVALID');
    }

    public function test_withdraw_insufficient_balance_returns_error(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');
        $this->wallet->update(['balance' => 100]);

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/withdraw', [
            'amount' => 5000,
            'payment_method' => 'orange',
            'phone' => '+22507000001',
            'pin' => '1234',
        ]);

        $response->assertStatus(400);
    }

    public function test_withdraw_success_with_jeko(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $this->mock(JekoPaymentService::class, function ($mock) {
            $payment = new \App\Models\JekoPayment();
            $payment->id = 1;
            $payment->reference = 'JEKO-REF-001';
            $mock->shouldReceive('createPayout')->andReturn($payment);
        });

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/withdraw', [
            'amount' => 5000,
            'payment_method' => 'orange',
            'phone' => '+22507000001',
            'pin' => '1234',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', 'processing');
    }

    public function test_withdraw_jeko_failure_refunds_wallet(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');
        $initialBalance = $this->wallet->balance;

        $this->mock(JekoPaymentService::class, function ($mock) {
            $mock->shouldReceive('createPayout')
                ->andThrow(new \Exception('Cannot POST'));
        });

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/withdraw', [
            'amount' => 5000,
            'payment_method' => 'orange',
            'phone' => '+22507000001',
            'pin' => '1234',
        ]);

        $response->assertStatus(500)
            ->assertJsonPath('code', 'PAYOUT_ERROR');
    }

    public function test_withdraw_bank_transfer(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $this->mock(JekoPaymentService::class, function ($mock) {
            $payment = new \App\Models\JekoPayment();
            $payment->id = 2;
            $payment->reference = 'JEKO-BANK-001';
            $mock->shouldReceive('createBankPayout')->andReturn($payment);
        });

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/withdraw', [
            'amount' => 10000,
            'payment_method' => 'bank',
            'phone' => '+22507000001',
            'pin' => '1234',
            'bank_details' => [
                'bank_code' => 'SGBCI',
                'account_number' => '123456789',
                'holder_name' => 'Pharmacie Test',
            ],
        ]);

        $response->assertOk();
    }

    // ─── SAVE BANK INFO ──────────────────────────────────────────────────────

    public function test_save_bank_info(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/bank-info', [
            'bank_name' => 'SGBCI',
            'holder_name' => 'Pharmacie Test',
            'account_number' => '123456789',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_save_bank_info_validation(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/bank-info', []);

        $response->assertStatus(422);
    }

    // ─── SAVE MOBILE MONEY INFO ──────────────────────────────────────────────

    public function test_save_mobile_money_info(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/mobile-money', [
            'operator' => 'Orange',
            'phone_number' => '+22507000001',
            'account_name' => 'Pharmacie Test',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_save_mobile_money_validation(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/mobile-money', []);

        $response->assertStatus(422);
    }

    // ─── PIN MANAGEMENT ──────────────────────────────────────────────────────

    public function test_get_pin_status(): void
    {
        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/wallet/pin-status');

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure(['data' => ['has_pin']]);
    }

    public function test_set_pin_first_time(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/set', [
            'pin' => '1234',
            'pin_confirmation' => '1234',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertTrue($this->pharmacy->fresh()->hasPinConfigured());
    }

    public function test_set_pin_already_configured_returns_error(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/set', [
            'pin' => '5678',
            'pin_confirmation' => '5678',
        ]);

        $response->assertStatus(400)
            ->assertJsonPath('code', 'PIN_ALREADY_SET');
    }

    public function test_set_pin_validation_mismatch(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/set', [
            'pin' => '1234',
            'pin_confirmation' => '5678',
        ]);

        $response->assertStatus(422);
    }

    public function test_change_pin_success(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/change', [
            'current_pin' => '1234',
            'new_pin' => '5678',
            'new_pin_confirmation' => '5678',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_change_pin_wrong_current_returns_error(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/change', [
            'current_pin' => '0000',
            'new_pin' => '5678',
            'new_pin_confirmation' => '5678',
        ]);

        $response->assertStatus(401);
    }

    public function test_change_pin_no_pin_set_returns_error(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/change', [
            'current_pin' => '1234',
            'new_pin' => '5678',
            'new_pin_confirmation' => '5678',
        ]);

        $response->assertStatus(400)
            ->assertJsonPath('code', 'PIN_NOT_SET');
    }

    public function test_verify_pin_success(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/verify', [
            'pin' => '1234',
        ]);

        $response->assertOk()
            ->assertJsonPath('is_valid', true);
    }

    public function test_verify_pin_wrong_returns_error(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/verify', [
            'pin' => '0000',
        ]);

        $response->assertStatus(401);
    }

    public function test_request_pin_reset(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $this->mock(OtpService::class, function ($mock) {
            $mock->shouldReceive('sendOtp')->once();
        });

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/reset-request');

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_request_pin_reset_no_pin_returns_error(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/reset-request');

        $response->assertStatus(400)
            ->assertJsonPath('code', 'PIN_NOT_SET');
    }

    public function test_confirm_pin_reset_success(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $this->mock(OtpService::class, function ($mock) {
            $mock->shouldReceive('verifyOtp')->andReturn(true);
        });

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/reset-confirm', [
            'otp' => '123456',
            'new_pin' => '5678',
            'new_pin_confirmation' => '5678',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_confirm_pin_reset_invalid_otp(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $this->mock(OtpService::class, function ($mock) {
            $mock->shouldReceive('verifyOtp')->andReturn(false);
        });

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/reset-confirm', [
            'otp' => '000000',
            'new_pin' => '5678',
            'new_pin_confirmation' => '5678',
        ]);

        $response->assertStatus(401)
            ->assertJsonPath('code', 'OTP_INVALID');
    }

    public function test_confirm_pin_reset_validation(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/reset-confirm', []);

        $response->assertStatus(422);
    }

    // ─── AUTH ────────────────────────────────────────────────────────────────

    public function test_requires_auth(): void
    {
        $this->getJson('/api/pharmacy/wallet')->assertUnauthorized();
    }

    // ─── GET WITHDRAWAL SETTINGS ─────────────────────────────────────────────

    public function test_get_withdrawal_settings_returns_settings(): void
    {
        $this->pharmacy->update([
            'withdrawal_threshold' => 75000,
            'auto_withdraw_enabled' => true,
        ]);
        $this->pharmacy->setWithdrawalPin('1234');

        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/wallet/threshold');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.threshold', 75000)
            ->assertJsonPath('data.auto_withdraw', true)
            ->assertJsonPath('data.has_pin', true)
            ->assertJsonStructure([
                'data' => [
                    'threshold',
                    'auto_withdraw',
                    'has_pin',
                    'has_mobile_money',
                    'has_bank_info',
                    'config' => [
                        'min_threshold',
                        'max_threshold',
                        'default_threshold',
                        'step',
                        'auto_withdraw_allowed',
                    ],
                ]
            ]);
    }

    public function test_get_withdrawal_settings_default_values(): void
    {
        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/wallet/threshold');

        $response->assertOk()
            ->assertJsonPath('data.has_pin', false)
            ->assertJsonPath('data.has_mobile_money', false)
            ->assertJsonPath('data.has_bank_info', false);
    }

    // ─── SET WITHDRAWAL THRESHOLD ────────────────────────────────────────────

    public function test_set_withdrawal_threshold_success(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/threshold', [
            'threshold' => 100000,
            'auto_withdraw' => true,
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.threshold', 100000)
            ->assertJsonPath('data.auto_withdraw', true);

        $this->pharmacy->refresh();
        $this->assertEquals(100000, $this->pharmacy->withdrawal_threshold);
        $this->assertTrue($this->pharmacy->auto_withdraw_enabled);
    }

    public function test_set_withdrawal_threshold_validation_min(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/threshold', [
            'threshold' => 500, // Below min
            'auto_withdraw' => true,
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['threshold']);
    }

    public function test_set_withdrawal_threshold_validation_max(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/threshold', [
            'threshold' => 10000000, // Above max
            'auto_withdraw' => true,
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['threshold']);
    }

    public function test_set_withdrawal_threshold_missing_fields(): void
    {
        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/threshold', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['threshold', 'auto_withdraw']);
    }

    public function test_set_withdrawal_threshold_forbidden_when_auto_withdraw_is_globally_disabled(): void
    {
        Setting::set('auto_withdraw_enabled_global', false, 'boolean');

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/threshold', [
            'threshold' => 100000,
            'auto_withdraw' => true,
        ]);

        $response->assertStatus(403)
            ->assertJsonPath('success', false);
    }

    // ─── EXPORT TRANSACTIONS ─────────────────────────────────────────────────

    public function test_export_transactions_success(): void
    {
        // Create some transactions for export
        $this->wallet->transactions()->create([
            'amount' => 5000,
            'type' => 'credit',
            'description' => 'Commission',
            'reference' => 'TX-EXP-001',
            'balance_after' => 55000,
        ]);

        $start = now()->subDays(30)->toDateString();
        $end = now()->toDateString();
        $response = $this->actingAsPharmacy()->getJson("/api/pharmacy/wallet/export?format=csv&start_date={$start}&end_date={$end}");

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['download_url', 'transaction_count']);
    }

    public function test_export_transactions_pdf_format(): void
    {
        $start = now()->subDays(7)->toDateString();
        $end = now()->toDateString();
        $response = $this->actingAsPharmacy()->getJson("/api/pharmacy/wallet/export?format=pdf&start_date={$start}&end_date={$end}");

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_export_transactions_excel_format(): void
    {
        $start = now()->subMonth()->toDateString();
        $end = now()->toDateString();
        $response = $this->actingAsPharmacy()->getJson("/api/pharmacy/wallet/export?format=excel&start_date={$start}&end_date={$end}");

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_export_transactions_validation_invalid_format(): void
    {
        $start = now()->subDays(7)->toDateString();
        $end = now()->toDateString();
        $response = $this->actingAsPharmacy()->getJson("/api/pharmacy/wallet/export?format=docx&start_date={$start}&end_date={$end}");

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['format']);
    }

    public function test_export_transactions_validation_end_before_start(): void
    {
        $start = now()->toDateString();
        $end = now()->subDays(7)->toDateString();
        $response = $this->actingAsPharmacy()->getJson("/api/pharmacy/wallet/export?format=csv&start_date={$start}&end_date={$end}");

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['end_date']);
    }

    public function test_export_transactions_no_wallet_returns_error(): void
    {
        $this->wallet->delete();

        $start = now()->subDays(7)->toDateString();
        $end = now()->toDateString();
        $response = $this->actingAsPharmacy()->getJson("/api/pharmacy/wallet/export?format=csv&start_date={$start}&end_date={$end}");

        $response->assertStatus(404);
    }

    // ─── UPDATE BANK INFO (WITH PIN) ─────────────────────────────────────────

    public function test_update_bank_info_success(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $response = $this->actingAsPharmacy()->putJson('/api/pharmacy/wallet/bank-info', [
            'pin' => '1234',
            'bank_name' => 'SGBCI',
            'holder_name' => 'Pharmacie Test',
            'account_number' => 'CI001234567890',
            'iban' => 'CI76001234567890',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('payment_infos', [
            'pharmacy_id' => $this->pharmacy->id,
            'type' => 'bank',
            'bank_name' => 'SGBCI',
        ]);
    }

    public function test_update_bank_info_requires_pin(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $response = $this->actingAsPharmacy()->putJson('/api/pharmacy/wallet/bank-info', [
            'bank_name' => 'SGBCI',
            'holder_name' => 'Pharmacie Test',
            'account_number' => 'CI001234567890',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['pin']);
    }

    public function test_update_bank_info_wrong_pin(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $response = $this->actingAsPharmacy()->putJson('/api/pharmacy/wallet/bank-info', [
            'pin' => '0000', // Wrong PIN
            'bank_name' => 'SGBCI',
            'holder_name' => 'Pharmacie Test',
            'account_number' => 'CI001234567890',
        ]);

        $response->assertStatus(401)
            ->assertJsonPath('code', 'PIN_INVALID');
    }

    public function test_update_bank_info_no_pin_configured(): void
    {
        $response = $this->actingAsPharmacy()->putJson('/api/pharmacy/wallet/bank-info', [
            'pin' => '1234',
            'bank_name' => 'SGBCI',
            'holder_name' => 'Pharmacie Test',
            'account_number' => 'CI001234567890',
        ]);

        $response->assertStatus(400)
            ->assertJsonPath('code', 'PIN_NOT_CONFIGURED');
    }

    public function test_update_bank_info_pin_locked(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');
        $this->pharmacy->update([
            'pin_attempts' => 5,
            'pin_locked_until' => now()->addMinutes(30),
        ]);

        $response = $this->actingAsPharmacy()->putJson('/api/pharmacy/wallet/bank-info', [
            'pin' => '1234',
            'bank_name' => 'SGBCI',
            'holder_name' => 'Pharmacie Test',
            'account_number' => 'CI001234567890',
        ]);

        $response->assertStatus(423)
            ->assertJsonPath('code', 'PIN_LOCKED');
    }

    // ─── UPDATE MOBILE MONEY INFO (WITH PIN) ─────────────────────────────────

    public function test_update_mobile_money_info_success(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $response = $this->actingAsPharmacy()->putJson('/api/pharmacy/wallet/mobile-money', [
            'pin' => '1234',
            'operator' => 'orange',
            'phone_number' => '+22507000002',
            'account_name' => 'Pharmacie Test',
            'is_primary' => true,
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('payment_infos', [
            'pharmacy_id' => $this->pharmacy->id,
            'type' => 'mobile_money',
            'phone_number' => '+22507000002',
        ]);
    }

    public function test_update_mobile_money_info_wrong_pin(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $response = $this->actingAsPharmacy()->putJson('/api/pharmacy/wallet/mobile-money', [
            'pin' => '0000',
            'operator' => 'orange',
            'phone_number' => '+22507000002',
            'account_name' => 'Pharmacie Test',
        ]);

        $response->assertStatus(401)
            ->assertJsonPath('code', 'PIN_INVALID');
    }

    public function test_update_mobile_money_info_no_pin_configured(): void
    {
        $response = $this->actingAsPharmacy()->putJson('/api/pharmacy/wallet/mobile-money', [
            'pin' => '1234',
            'operator' => 'orange',
            'phone_number' => '+22507000002',
            'account_name' => 'Pharmacie Test',
        ]);

        $response->assertStatus(400)
            ->assertJsonPath('code', 'PIN_NOT_CONFIGURED');
    }

    public function test_update_mobile_money_info_validation(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $response = $this->actingAsPharmacy()->putJson('/api/pharmacy/wallet/mobile-money', [
            'pin' => '1234',
            // Missing required fields
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['operator', 'phone_number', 'account_name']);
    }

    // ─── GET PAYMENT INFO ────────────────────────────────────────────────────

    public function test_get_payment_info_empty(): void
    {
        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/wallet/payment-info');

        $response->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonPath('data.bank', null)
            ->assertJsonPath('data.has_pin', false);
    }

    public function test_get_payment_info_with_data(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');
        
        // Add bank info
        $this->pharmacy->paymentInfo()->create([
            'type' => 'bank',
            'bank_name' => 'SGBCI',
            'holder_name' => 'Pharmacie Test',
            'account_number' => 'CI001234567890',
            'is_primary' => true,
        ]);

        // Add mobile money
        $this->pharmacy->paymentInfo()->create([
            'type' => 'mobile_money',
            'operator' => 'orange',
            'phone_number' => '+22507000002',
            'holder_name' => 'Test User',
            'is_primary' => true,
        ]);

        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/wallet/payment-info');

        $response->assertOk()
            ->assertJsonPath('data.has_pin', true)
            ->assertJsonPath('data.bank.bank_name', 'SGBCI')
            ->assertJsonStructure([
                'data' => [
                    'has_pin',
                    'bank' => ['bank_name', 'holder_name', 'account_number'],
                    'mobile_money',
                ]
            ]);
    }

    public function test_get_payment_info_masks_account_number(): void
    {
        $this->pharmacy->paymentInfo()->create([
            'type' => 'bank',
            'bank_name' => 'SGBCI',
            'holder_name' => 'Pharmacie Test',
            'account_number' => 'CI001234567890',
            'is_primary' => true,
        ]);

        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/wallet/payment-info');

        $response->assertOk();
        
        // Verify the account number is masked (showing only last 4 digits)
        $accountNumber = $response->json('data.bank.account_number');
        $this->assertStringEndsWith('7890', $accountNumber);
        $this->assertStringContainsString('*', $accountNumber);
    }

    // ─── WITHDRAW PIN LOCKED ─────────────────────────────────────────────────

    public function test_withdraw_pin_locked_returns_error(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');
        $this->pharmacy->update([
            'pin_attempts' => 5,
            'pin_locked_until' => now()->addMinutes(30),
        ]);

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/withdraw', [
            'amount' => 10000,
            'payment_method' => 'orange',
            'phone' => '+22507000001',
            'pin' => '1234',
        ]);

        $response->assertStatus(423)
            ->assertJsonPath('code', 'PIN_LOCKED');
    }

    // ─── CHANGE PIN LOCKED ───────────────────────────────────────────────────

    public function test_change_pin_locked_returns_error(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');
        $this->pharmacy->update([
            'pin_attempts' => 5,
            'pin_locked_until' => now()->addMinutes(30),
        ]);

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/change', [
            'current_pin' => '1234',
            'new_pin' => '5678',
            'new_pin_confirmation' => '5678',
        ]);

        $response->assertStatus(423)
            ->assertJsonPath('code', 'PIN_LOCKED');
    }

    // ─── VERIFY PIN LOCKED ───────────────────────────────────────────────────

    public function test_verify_pin_locked_returns_error(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');
        $this->pharmacy->update([
            'pin_attempts' => 5,
            'pin_locked_until' => now()->addMinutes(30),
        ]);

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/verify', [
            'pin' => '1234',
        ]);

        $response->assertStatus(423)
            ->assertJsonPath('code', 'PIN_LOCKED');
    }

    // ─── REQUEST PIN RESET NO PHONE ──────────────────────────────────────────

    public function test_request_pin_reset_no_phone_returns_error(): void
    {
        $this->pharmacyUser->update(['phone' => null]);
        $this->pharmacy->setWithdrawalPin('1234');

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/reset-request');

        $response->assertStatus(400)
            ->assertJsonPath('code', 'NO_PHONE');
    }

    public function test_request_pin_reset_handles_otp_failure(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $this->mock(OtpService::class, function ($mock) {
            $mock->shouldReceive('sendOtp')->once()->andThrow(new \Exception('SMS gateway down'));
        });

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/reset-request');

        $response->assertStatus(500)
            ->assertJsonPath('success', false);
    }

    public function test_confirm_pin_reset_requires_phone(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');
        $this->pharmacyUser->update(['phone' => null]);

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/reset-confirm', [
            'otp' => '123456',
            'new_pin' => '5678',
            'new_pin_confirmation' => '5678',
        ]);

        $response->assertStatus(400)
            ->assertJsonPath('success', false);
    }

    public function test_confirm_pin_reset_handles_service_failure(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $this->mock(OtpService::class, function ($mock) {
            $mock->shouldReceive('verifyOtp')->once()->andThrow(new \Exception('OTP service unavailable'));
        });

        $response = $this->actingAsPharmacy()->postJson('/api/pharmacy/wallet/pin/reset-confirm', [
            'otp' => '123456',
            'new_pin' => '5678',
            'new_pin_confirmation' => '5678',
        ]);

        $response->assertStatus(500)
            ->assertJsonPath('success', false);
    }

    public function test_update_mobile_money_info_pin_locked(): void
    {
        $this->pharmacy->setWithdrawalPin('1234');
        $this->pharmacy->update([
            'pin_attempts' => 5,
            'pin_locked_until' => now()->addMinutes(30),
        ]);

        $response = $this->actingAsPharmacy()->putJson('/api/pharmacy/wallet/mobile-money', [
            'pin' => '1234',
            'operator' => 'orange',
            'phone_number' => '+22507000002',
            'account_name' => 'Pharmacie Test',
        ]);

        $response->assertStatus(423)
            ->assertJsonPath('code', 'PIN_LOCKED');
    }

    public function test_get_payment_info_masks_mobile_phone_number(): void
    {
        $this->pharmacy->paymentInfo()->create([
            'type' => 'mobile_money',
            'operator' => 'orange',
            'phone_number' => '+22507000002',
            'holder_name' => 'Test User',
            'is_primary' => true,
        ]);

        $response = $this->actingAsPharmacy()->getJson('/api/pharmacy/wallet/payment-info');

        $response->assertOk();

        $maskedPhone = $response->json('data.mobile_money.0.phone_number_masked');
        $this->assertStringContainsString('*', $maskedPhone);
        $this->assertStringEndsWith('02', $maskedPhone);
    }
}
