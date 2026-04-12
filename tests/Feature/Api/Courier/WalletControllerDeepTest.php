<?php

namespace Tests\Feature\Api\Courier;

use App\Enums\JekoPaymentStatus;
use App\Models\User;
use App\Models\Courier;
use App\Models\JekoPayment;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

/**
 * Deep tests for Courier WalletController
 * @group deep
 */
class WalletControllerDeepTest extends TestCase
{
    use RefreshDatabase;

    protected User $courierUser;
    protected Courier $courier;
    protected Wallet $wallet;

    protected function setUp(): void
    {
        parent::setUp();

        $this->courierUser = User::factory()->create(['role' => 'courier']);
        $this->courier = Courier::factory()->create([
            'user_id' => $this->courierUser->id,
            'status' => 'available',
        ]);
        $this->wallet = Wallet::factory()->create([
            'walletable_type' => Courier::class,
            'walletable_id' => $this->courier->id,
            'balance' => 10000,
        ]);
    }

    // ==================== INDEX ====================

    #[Test]
    public function index_returns_wallet_balance_info()
    {
        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->getJson('/api/courier/wallet');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'balance',
                    'currency',
                    'can_deliver',
                    'transactions',
                ],
            ]);
    }

    #[Test]
    public function index_includes_recent_transactions()
    {
        WalletTransaction::factory()->count(5)->create([
            'wallet_id' => $this->wallet->id,
            'type' => 'CREDIT',
            'amount' => 1000,
            'status' => 'completed',
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->getJson('/api/courier/wallet');

        $response->assertOk();
        $this->assertNotEmpty($response->json('data.transactions'));
    }

    #[Test]
    public function index_includes_statistics()
    {
        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->getJson('/api/courier/wallet');

        $response->assertOk();
        $this->assertArrayHasKey('statistics', $response->json('data'));
    }

    #[Test]
    public function index_returns_correct_balance()
    {
        $this->wallet->update(['balance' => 15000]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->getJson('/api/courier/wallet');

        $response->assertOk()
            ->assertJsonPath('data.balance', 15000);
    }

    // ==================== TOP UP ====================

    #[Test]
    public function topup_succeeds_with_valid_jeko_payment()
    {
        JekoPayment::factory()->create([
            'user_id' => $this->courierUser->id,
            'reference' => 'PAY-VALID-123',
            'amount_cents' => 500000, // 5000 XOF
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/topup', [
                'amount' => 5000,
                'payment_method' => 'orange',
                'payment_reference' => 'PAY-VALID-123',
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true);
    }

    #[Test]
    public function topup_fails_with_invalid_payment_reference()
    {
        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/topup', [
                'amount' => 5000,
                'payment_method' => 'orange',
                'payment_reference' => 'INVALID-REF',
            ]);

        $response->assertStatus(400)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Référence de paiement invalide');
    }

    #[Test]
    public function topup_fails_with_unconfirmed_payment()
    {
        JekoPayment::factory()->create([
            'user_id' => $this->courierUser->id,
            'reference' => 'PAY-PENDING',
            'amount_cents' => 500000,
            'status' => JekoPaymentStatus::PENDING,
            'business_processed' => false,
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/topup', [
                'amount' => 5000,
                'payment_method' => 'orange',
                'payment_reference' => 'PAY-PENDING',
            ]);

        $response->assertStatus(400)
            ->assertJsonPath('message', 'Ce paiement n\'a pas été confirmé');
    }

    #[Test]
    public function topup_fails_with_already_processed_payment()
    {
        JekoPayment::factory()->create([
            'user_id' => $this->courierUser->id,
            'reference' => 'PAY-PROCESSED',
            'amount_cents' => 500000,
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => true,
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/topup', [
                'amount' => 5000,
                'payment_method' => 'orange',
                'payment_reference' => 'PAY-PROCESSED',
            ]);

        $response->assertStatus(409)
            ->assertJsonPath('message', 'Ce paiement a déjà été traité');
    }

    #[Test]
    public function topup_fails_with_amount_mismatch()
    {
        JekoPayment::factory()->create([
            'user_id' => $this->courierUser->id,
            'reference' => 'PAY-MISMATCH',
            'amount_cents' => 500000, // 5000 XOF
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/topup', [
                'amount' => 10000, // Different amount
                'payment_method' => 'orange',
                'payment_reference' => 'PAY-MISMATCH',
            ]);

        $response->assertStatus(400)
            ->assertJsonPath('message', 'Montant incohérent avec le paiement');
    }

    #[Test]
    public function topup_fails_with_other_user_payment()
    {
        $otherUser = User::factory()->create(['role' => 'courier']);
        JekoPayment::factory()->create([
            'user_id' => $otherUser->id,
            'reference' => 'PAY-OTHER-USER',
            'amount_cents' => 500000,
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/topup', [
                'amount' => 5000,
                'payment_method' => 'orange',
                'payment_reference' => 'PAY-OTHER-USER',
            ]);

        $response->assertStatus(400)
            ->assertJsonPath('message', 'Référence de paiement invalide');
    }

    #[Test]
    public function topup_normalizes_orange_money_payment_method()
    {
        JekoPayment::factory()->create([
            'user_id' => $this->courierUser->id,
            'reference' => 'PAY-ORANGE',
            'amount_cents' => 500000,
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/topup', [
                'amount' => 5000,
                'payment_method' => 'orange_money', // Should normalize to 'orange'
                'payment_reference' => 'PAY-ORANGE',
            ]);

        $response->assertOk();
    }

    #[Test]
    public function topup_normalizes_mtn_money_payment_method()
    {
        JekoPayment::factory()->create([
            'user_id' => $this->courierUser->id,
            'reference' => 'PAY-MTN',
            'amount_cents' => 500000,
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/topup', [
                'amount' => 5000,
                'payment_method' => 'mtn_money', // Should normalize to 'mtn'
                'payment_reference' => 'PAY-MTN',
            ]);

        $response->assertOk();
    }

    #[Test]
    public function topup_validates_payment_reference_required()
    {
        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/topup', [
                'amount' => 5000,
                'payment_method' => 'orange',
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['payment_reference']);
    }

    #[Test]
    public function topup_accepts_wave_payment_method()
    {
        JekoPayment::factory()->create([
            'user_id' => $this->courierUser->id,
            'reference' => 'PAY-WAVE',
            'amount_cents' => 500000,
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/topup', [
                'amount' => 5000,
                'payment_method' => 'wave',
                'payment_reference' => 'PAY-WAVE',
            ]);

        $response->assertOk();
    }

    #[Test]
    public function topup_accepts_djamo_payment_method()
    {
        JekoPayment::factory()->create([
            'user_id' => $this->courierUser->id,
            'reference' => 'PAY-DJAMO',
            'amount_cents' => 500000,
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/topup', [
                'amount' => 5000,
                'payment_method' => 'djamo',
                'payment_reference' => 'PAY-DJAMO',
            ]);

        $response->assertOk();
    }

    // ==================== WITHDRAW ====================

    #[Test]
    public function withdraw_succeeds_with_sufficient_balance()
    {
        $this->wallet->update(['balance' => 10000]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/withdraw', [
                'amount' => 5000,
                'payment_method' => 'orange',
                'phone_number' => '+22507654321',
            ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'transaction' => ['id', 'amount', 'reference', 'status'],
                    'wallet' => ['balance', 'available_balance'],
                ],
            ]);
    }

    #[Test]
    public function withdraw_normalizes_payment_methods()
    {
        $this->wallet->update(['balance' => 10000]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/withdraw', [
                'amount' => 1000,
                'payment_method' => 'moov_money', // Should normalize to 'moov'
                'phone_number' => '+22507654321',
            ]);

        $response->assertOk();
    }

    #[Test]
    public function withdraw_validates_phone_number_max_length()
    {
        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/withdraw', [
                'amount' => 1000,
                'payment_method' => 'orange',
                'phone_number' => '+123456789012345678901', // 21 chars, max is 20
            ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['phone_number']);
    }

    #[Test]
    public function withdraw_accepts_phone_without_plus()
    {
        $this->wallet->update(['balance' => 10000]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/withdraw', [
                'amount' => 1000,
                'payment_method' => 'orange',
                'phone_number' => '22507654321',
            ]);

        $response->assertOk();
    }

    #[Test]
    public function withdraw_accepts_phone_with_plus()
    {
        $this->wallet->update(['balance' => 10000]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/withdraw', [
                'amount' => 1000,
                'payment_method' => 'orange',
                'phone_number' => '+22507654321',
            ]);

        $response->assertOk();
    }

    // ==================== CAN DELIVER ====================

    #[Test]
    public function can_deliver_returns_true_when_sufficient_balance()
    {
        $this->wallet->update(['balance' => 10000]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->getJson('/api/courier/wallet/can-deliver');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'can_deliver',
                    'balance',
                    'commission_amount',
                    'minimum_balance',
                ],
            ]);
    }

    #[Test]
    public function can_deliver_returns_false_when_insufficient_balance()
    {
        $this->wallet->update(['balance' => 0]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->getJson('/api/courier/wallet/can-deliver');

        $response->assertOk()
            ->assertJsonPath('data.can_deliver', false);
    }

    #[Test]
    public function can_deliver_returns_commission_info()
    {
        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->getJson('/api/courier/wallet/can-deliver');

        $response->assertOk();
        $this->assertNotNull($response->json('data.commission_amount'));
    }

    // ==================== EARNINGS HISTORY ====================

    #[Test]
    public function earnings_history_returns_paginated_transactions()
    {
        WalletTransaction::factory()->count(10)->create([
            'wallet_id' => $this->wallet->id,
            'type' => 'CREDIT',
            'status' => 'completed',
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->getJson('/api/courier/wallet/earnings-history');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'transactions',
                    'totals' => ['count', 'credits', 'debits'],
                    'pagination' => ['limit', 'returned'],
                ],
            ]);
    }

    #[Test]
    public function earnings_history_respects_limit_parameter()
    {
        WalletTransaction::factory()->count(20)->create([
            'wallet_id' => $this->wallet->id,
            'type' => 'CREDIT',
            'status' => 'completed',
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->getJson('/api/courier/wallet/earnings-history?limit=5');

        $response->assertOk();
        $this->assertLessThanOrEqual(5, $response->json('data.pagination.returned'));
    }

    #[Test]
    public function earnings_history_caps_limit_at_100()
    {
        WalletTransaction::factory()->count(10)->create([
            'wallet_id' => $this->wallet->id,
            'type' => 'CREDIT',
            'status' => 'completed',
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->getJson('/api/courier/wallet/earnings-history?limit=200');

        $response->assertOk();
        $this->assertLessThanOrEqual(100, $response->json('data.pagination.limit'));
    }

    #[Test]
    public function earnings_history_calculates_totals()
    {
        WalletTransaction::factory()->count(3)->create([
            'wallet_id' => $this->wallet->id,
            'type' => 'CREDIT',
            'amount' => 1000,
            'status' => 'completed',
        ]);
        WalletTransaction::factory()->count(2)->create([
            'wallet_id' => $this->wallet->id,
            'type' => 'DEBIT',
            'amount' => 500,
            'status' => 'completed',
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->getJson('/api/courier/wallet/earnings-history');

        $response->assertOk();
        $totals = $response->json('data.totals');
        $this->assertEquals(5, $totals['count']);
        $this->assertEquals(3000, $totals['credits']);
        $this->assertEquals(1000, $totals['debits']);
    }

    #[Test]
    public function earnings_history_empty_when_no_transactions()
    {
        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->getJson('/api/courier/wallet/earnings-history');

        $response->assertOk();
        $this->assertEmpty($response->json('data.transactions'));
    }

    // ==================== AUTHORIZATION ====================

    #[Test]
    public function user_without_courier_profile_cannot_access_wallet()
    {
        /** @var User $userWithoutCourier */
        $userWithoutCourier = User::factory()->create(['role' => 'courier']);
        // Don't create a courier profile

        $response = $this->actingAs($userWithoutCourier, 'sanctum')
            ->getJson('/api/courier/wallet');

        $response->assertStatus(403)
            ->assertJsonPath('message', 'Profil livreur introuvable. Veuillez compléter votre inscription.');
    }

    #[Test]
    public function user_without_courier_profile_cannot_topup()
    {
        /** @var User $userWithoutCourier */
        $userWithoutCourier = User::factory()->create(['role' => 'courier']);

        $response = $this->actingAs($userWithoutCourier, 'sanctum')
            ->postJson('/api/courier/wallet/topup', [
                'amount' => 5000,
                'payment_method' => 'orange',
                'payment_reference' => 'PAY-123',
            ]);

        $response->assertStatus(403);
    }

    #[Test]
    public function user_without_courier_profile_cannot_withdraw()
    {
        /** @var User $userWithoutCourier */
        $userWithoutCourier = User::factory()->create(['role' => 'courier']);

        $response = $this->actingAs($userWithoutCourier, 'sanctum')
            ->postJson('/api/courier/wallet/withdraw', [
                'amount' => 1000,
                'payment_method' => 'orange',
                'phone_number' => '+22507654321',
            ]);

        $response->assertStatus(403);
    }

    #[Test]
    public function user_without_courier_profile_cannot_check_can_deliver()
    {
        /** @var User $userWithoutCourier */
        $userWithoutCourier = User::factory()->create(['role' => 'courier']);

        $response = $this->actingAs($userWithoutCourier, 'sanctum')
            ->getJson('/api/courier/wallet/can-deliver');

        $response->assertStatus(403);
    }

    #[Test]
    public function user_without_courier_profile_cannot_access_earnings_history()
    {
        /** @var User $userWithoutCourier */
        $userWithoutCourier = User::factory()->create(['role' => 'courier']);

        $response = $this->actingAs($userWithoutCourier, 'sanctum')
            ->getJson('/api/courier/wallet/earnings-history');

        $response->assertStatus(403);
    }

    #[Test]
    public function pharmacy_user_cannot_access_courier_wallet()
    {
        /** @var User $pharmacyUser */
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);

        $response = $this->actingAs($pharmacyUser, 'sanctum')
            ->getJson('/api/courier/wallet');

        $response->assertStatus(403);
    }

    #[Test]
    public function customer_user_cannot_access_courier_wallet()
    {
        /** @var User $customerUser */
        $customerUser = User::factory()->create(['role' => 'customer']);

        $response = $this->actingAs($customerUser, 'sanctum')
            ->getJson('/api/courier/wallet');

        $response->assertStatus(403);
    }

    #[Test]
    public function unauthenticated_cannot_access_wallet()
    {
        $response = $this->getJson('/api/courier/wallet');

        $response->assertUnauthorized();
    }

    // ==================== EDGE CASES ====================

    #[Test]
    public function index_handles_wallet_with_zero_balance()
    {
        $this->wallet->update(['balance' => 0]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->getJson('/api/courier/wallet');

        $response->assertOk()
            ->assertJsonPath('data.balance', 0);
    }

    #[Test]
    public function topup_handles_exact_minimum_amount()
    {
        JekoPayment::factory()->create([
            'user_id' => $this->courierUser->id,
            'reference' => 'PAY-MIN',
            'amount_cents' => 10000, // 100 XOF (minimum)
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/topup', [
                'amount' => 100,
                'payment_method' => 'orange',
                'payment_reference' => 'PAY-MIN',
            ]);

        $response->assertOk();
    }

    #[Test]
    public function topup_handles_exact_maximum_amount()
    {
        JekoPayment::factory()->create([
            'user_id' => $this->courierUser->id,
            'reference' => 'PAY-MAX',
            'amount_cents' => 100000000, // 1000000 XOF (maximum)
            'status' => JekoPaymentStatus::SUCCESS,
            'business_processed' => false,
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/topup', [
                'amount' => 1000000,
                'payment_method' => 'orange',
                'payment_reference' => 'PAY-MAX',
            ]);

        $response->assertOk();
    }

    #[Test]
    public function withdraw_handles_exact_minimum_amount()
    {
        $this->wallet->update(['balance' => 10000]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->postJson('/api/courier/wallet/withdraw', [
                'amount' => 500, // Minimum
                'payment_method' => 'orange',
                'phone_number' => '+22507654321',
            ]);

        $response->assertOk();
    }

    #[Test]
    public function transactions_include_delivery_references()
    {
        WalletTransaction::factory()->create([
            'wallet_id' => $this->wallet->id,
            'type' => 'CREDIT',
            'category' => 'delivery_earning',
            'delivery_id' => 123,
            'status' => 'completed',
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->getJson('/api/courier/wallet');

        $response->assertOk();
        $transactions = $response->json('data.transactions');
        $hasDeliveryId = collect($transactions)->first(fn($tx) => isset($tx['delivery_id']));
        $this->assertNotNull($hasDeliveryId);
    }

    #[Test]
    public function index_formats_transaction_dates_as_iso8601()
    {
        WalletTransaction::factory()->create([
            'wallet_id' => $this->wallet->id,
            'type' => 'CREDIT',
            'status' => 'completed',
        ]);

        $response = $this->actingAs($this->courierUser, 'sanctum')
            ->getJson('/api/courier/wallet');

        $response->assertOk();
        $transactions = $response->json('data.transactions');
        if (!empty($transactions)) {
            $this->assertMatchesRegularExpression(
                '/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$/',
                $transactions[0]['created_at']
            );
        }
    }
}
