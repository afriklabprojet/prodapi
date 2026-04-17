<?php

namespace Tests\Feature\Api\Pharmacy;

use App\Models\Pharmacy;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class WalletControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Pharmacy $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy = Pharmacy::factory()->create(['status' => 'approved']);
        $this->pharmacy->users()->attach($this->user->id, ['role' => 'titulaire']);
        $this->pharmacy->wallet()->create(['balance' => 50000, 'currency' => 'XOF']);
    }

    public function test_pharmacy_can_view_wallet(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/wallet');

        $response->assertOk()->assertJsonPath('status', 'success');
    }

    public function test_pharmacy_can_view_stats(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/wallet/stats?period=month');

        $response->assertOk()->assertJsonPath('status', 'success');
    }

    public function test_pharmacy_can_get_pin_status(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/wallet/pin-status');

        $response->assertOk()->assertJsonPath('status', 'success');
    }

    public function test_pharmacy_can_set_pin(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/wallet/pin/set', [
            'pin' => '1234',
            'pin_confirmation' => '1234',
        ]);

        $response->assertOk()->assertJsonPath('status', 'success');
    }

    public function test_set_pin_validates_digits(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/wallet/pin/set', [
            'pin' => 'abcd',
            'pin_confirmation' => 'abcd',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('pin');
    }

    public function test_pharmacy_can_get_payment_info(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/wallet/payment-info');

        $response->assertOk()->assertJsonPath('status', 'success');
    }

    public function test_pharmacy_can_save_bank_info(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/wallet/bank-info', [
            'bank_name' => 'BICICI',
            'holder_name' => 'Pharmacie Test',
            'account_number' => '0123456789',
        ]);

        $response->assertOk()->assertJsonPath('status', 'success');
    }

    public function test_pharmacy_can_save_mobile_money_info(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/wallet/mobile-money', [
            'operator' => 'orange',
            'phone_number' => '+2250700000000',
            'account_name' => 'Pharmacie Test',
        ]);

        $response->assertOk()->assertJsonPath('status', 'success');
    }

    public function test_pharmacy_can_get_withdrawal_settings(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/pharmacy/wallet/threshold');

        $response->assertOk()->assertJsonPath('status', 'success');
    }

    public function test_withdraw_requires_pin(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/wallet/withdraw', [
            'amount' => 5000,
            'payment_method' => 'orange',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('pin');
    }

    public function test_withdraw_validates_minimum_amount(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/pharmacy/wallet/withdraw', [
            'amount' => 100,
            'payment_method' => 'orange',
            'pin' => '1234',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('amount');
    }

    public function test_unauthenticated_cannot_access_wallet(): void
    {
        $response = $this->getJson('/api/pharmacy/wallet');

        $response->assertStatus(401);
    }
}
