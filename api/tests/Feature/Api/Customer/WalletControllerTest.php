<?php

namespace Tests\Feature\Api\Customer;

use App\Models\Customer;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use App\Services\CustomerWalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class WalletControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Customer $customer;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'customer', 'phone_verified_at' => now()]);
        $this->customer = Customer::factory()->create(['user_id' => $this->user->id]);
    }

    public function test_customer_can_get_wallet_balance(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/customer/wallet');

        $response->assertOk()->assertJsonStructure(['success', 'data']);
    }

    public function test_customer_can_get_transactions(): void
    {
        $response = $this->actingAs($this->user)->getJson('/api/customer/wallet/transactions');

        $response->assertOk()->assertJsonStructure(['success', 'data']);
    }

    public function test_topup_requires_amount(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/customer/wallet/topup', []);

        $response->assertStatus(422);
    }

    public function test_topup_validates_minimum_amount(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/customer/wallet/topup', [
            'amount' => 10,
            'payment_method' => 'wave',
        ]);

        $response->assertStatus(422);
    }

    public function test_topup_validates_payment_method(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/customer/wallet/topup', [
            'amount' => 1000,
            'payment_method' => 'bitcoin',
        ]);

        $response->assertStatus(422);
    }

    public function test_withdraw_requires_fields(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/customer/wallet/withdraw', []);

        $response->assertStatus(422);
    }

    public function test_withdraw_validates_minimum_amount(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/customer/wallet/withdraw', [
            'amount' => 100,
            'payment_method' => 'wave',
            'phone_number' => '+22507000000',
        ]);

        $response->assertStatus(422);
    }

    public function test_unauthenticated_cannot_access_wallet(): void
    {
        $response = $this->getJson('/api/customer/wallet');
        $response->assertStatus(401);
    }

    public function test_non_customer_cannot_access_wallet(): void
    {
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);

        $response = $this->actingAs($pharmacyUser)->getJson('/api/customer/wallet');
        $response->assertStatus(403);
    }
}
