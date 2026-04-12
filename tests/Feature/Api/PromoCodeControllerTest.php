<?php

namespace Tests\Feature\Api;

use App\Models\Customer;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class PromoCodeControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $this->user->id]);
    }

    private function createPromoCode(array $overrides = []): int
    {
        return DB::table('promo_codes')->insertGetId(array_merge([
            'code' => 'WELCOME10',
            'description' => 'Bienvenue 10%',
            'type' => 'percentage',
            'value' => 10,
            'max_discount' => 2000,
            'min_order_amount' => 1000,
            'max_uses' => 100,
            'max_uses_per_user' => 3,
            'current_uses' => 0,
            'is_active' => true,
            'starts_at' => now()->subDay(),
            'expires_at' => now()->addMonth(),
            'created_at' => now(),
            'updated_at' => now(),
        ], $overrides));
    }

    public function test_customer_can_validate_active_promo_code(): void
    {
        $this->createPromoCode();

        $response = $this->actingAs($this->user)->postJson('/api/customer/promo-codes/validate', [
            'code' => 'WELCOME10',
            'order_amount' => 5000,
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.code', 'WELCOME10')
            ->assertJsonPath('data.discount', 500); // 10% of 5000
    }

    public function test_discount_capped_at_max(): void
    {
        $this->createPromoCode(['max_discount' => 1000]);

        $response = $this->actingAs($this->user)->postJson('/api/customer/promo-codes/validate', [
            'code' => 'WELCOME10',
            'order_amount' => 50000,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.discount', 1000); // capped at max_discount
    }

    public function test_fixed_discount_applied(): void
    {
        $this->createPromoCode([
            'code' => 'FIX500',
            'type' => 'fixed',
            'value' => 500,
            'max_discount' => null,
        ]);

        $response = $this->actingAs($this->user)->postJson('/api/customer/promo-codes/validate', [
            'code' => 'FIX500',
            'order_amount' => 3000,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.discount', 500);
    }

    public function test_fixed_discount_capped_at_order_amount(): void
    {
        $this->createPromoCode([
            'code' => 'FIX5000',
            'type' => 'fixed',
            'value' => 5000,
            'max_discount' => null,
            'min_order_amount' => 0,
        ]);

        $response = $this->actingAs($this->user)->postJson('/api/customer/promo-codes/validate', [
            'code' => 'FIX5000',
            'order_amount' => 2000,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.discount', 2000); // capped at order amount
    }

    public function test_invalid_promo_code_returns_422(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/customer/promo-codes/validate', [
            'code' => 'NONEXIST',
            'order_amount' => 5000,
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_expired_promo_code_returns_422(): void
    {
        $this->createPromoCode(['expires_at' => now()->subDay()]);

        $response = $this->actingAs($this->user)->postJson('/api/customer/promo-codes/validate', [
            'code' => 'WELCOME10',
            'order_amount' => 5000,
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_not_yet_active_promo_returns_422(): void
    {
        $this->createPromoCode(['starts_at' => now()->addDays(5)]);

        $response = $this->actingAs($this->user)->postJson('/api/customer/promo-codes/validate', [
            'code' => 'WELCOME10',
            'order_amount' => 5000,
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_max_uses_reached_returns_422(): void
    {
        $this->createPromoCode(['max_uses' => 5, 'current_uses' => 5]);

        $response = $this->actingAs($this->user)->postJson('/api/customer/promo-codes/validate', [
            'code' => 'WELCOME10',
            'order_amount' => 5000,
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_min_order_amount_not_met_returns_422(): void
    {
        $this->createPromoCode(['min_order_amount' => 10000]);

        $response = $this->actingAs($this->user)->postJson('/api/customer/promo-codes/validate', [
            'code' => 'WELCOME10',
            'order_amount' => 5000,
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_per_user_max_uses_enforced(): void
    {
        $promoId = $this->createPromoCode(['max_uses_per_user' => 1]);

        DB::table('promo_code_usages')->insert([
            'promo_code_id' => $promoId,
            'user_id' => $this->user->id,
            'used_at' => now(),
        ]);

        $response = $this->actingAs($this->user)->postJson('/api/customer/promo-codes/validate', [
            'code' => 'WELCOME10',
            'order_amount' => 5000,
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_validate_requires_code(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/customer/promo-codes/validate', [
            'order_amount' => 5000,
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('code');
    }

    public function test_validate_requires_order_amount(): void
    {
        $response = $this->actingAs($this->user)->postJson('/api/customer/promo-codes/validate', [
            'code' => 'WELCOME10',
        ]);

        $response->assertStatus(422)->assertJsonValidationErrors('order_amount');
    }

    public function test_unauthenticated_cannot_validate(): void
    {
        $response = $this->postJson('/api/customer/promo-codes/validate', [
            'code' => 'WELCOME10',
            'order_amount' => 5000,
        ]);

        $response->assertStatus(401);
    }
}
