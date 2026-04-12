<?php

namespace Tests\Unit\Models;

use App\Models\PrescriptionDispensing;
use App\Models\PharmacyOnCall;
use App\Models\DutyZone;
use App\Models\BonusMultiplier;
use App\Models\DeliveryZone;
use App\Models\WithdrawalRequest;
use App\Models\LoyaltyRedemption;
use App\Models\PayoutRequest;
use App\Models\PharmacyStatementPreference;
use App\Models\LoyaltyReward;
use App\Models\PaymentInfo;
use App\Models\PaymentIntent;
use App\Models\Challenge;
use Tests\TestCase;

class ModelsExtendedTest extends TestCase
{
    // PrescriptionDispensing
    public function test_prescription_dispensing_fillable(): void
    {
        $model = new PrescriptionDispensing();
        $this->assertContains('prescription_id', $model->getFillable());
        $this->assertContains('pharmacy_id', $model->getFillable());
        $this->assertContains('medication_name', $model->getFillable());
        $this->assertContains('quantity_dispensed', $model->getFillable());
    }

    public function test_prescription_dispensing_casts(): void
    {
        $model = new PrescriptionDispensing();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('dispensed_at', $casts);
        $this->assertArrayHasKey('quantity_prescribed', $casts);
        $this->assertArrayHasKey('quantity_dispensed', $casts);
    }

    public function test_prescription_dispensing_relationships(): void
    {
        $model = new PrescriptionDispensing();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->prescription());
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->pharmacy());
    }

    // PharmacyOnCall
    public function test_pharmacy_on_call_fillable(): void
    {
        $model = new PharmacyOnCall();
        $this->assertContains('pharmacy_id', $model->getFillable());
        $this->assertContains('duty_zone_id', $model->getFillable());
        $this->assertContains('start_at', $model->getFillable());
        $this->assertContains('end_at', $model->getFillable());
        $this->assertContains('type', $model->getFillable());
        $this->assertContains('is_active', $model->getFillable());
    }

    public function test_pharmacy_on_call_casts(): void
    {
        $model = new PharmacyOnCall();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('start_at', $casts);
        $this->assertArrayHasKey('end_at', $casts);
        $this->assertArrayHasKey('is_active', $casts);
    }

    public function test_pharmacy_on_call_relationships(): void
    {
        $model = new PharmacyOnCall();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->pharmacy());
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->dutyZone());
    }

    // DutyZone
    public function test_duty_zone_fillable(): void
    {
        $model = new DutyZone();
        $this->assertContains('name', $model->getFillable());
        $this->assertContains('city', $model->getFillable());
        $this->assertContains('is_active', $model->getFillable());
        $this->assertContains('latitude', $model->getFillable());
        $this->assertContains('longitude', $model->getFillable());
    }

    public function test_duty_zone_casts(): void
    {
        $model = new DutyZone();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('is_active', $casts);
    }

    // BonusMultiplier
    public function test_bonus_multiplier_fillable(): void
    {
        $model = new BonusMultiplier();
        $this->assertContains('name', $model->getFillable());
        $this->assertContains('multiplier', $model->getFillable());
        $this->assertContains('is_active', $model->getFillable());
        $this->assertContains('starts_at', $model->getFillable());
        $this->assertContains('ends_at', $model->getFillable());
    }

    public function test_bonus_multiplier_casts(): void
    {
        $model = new BonusMultiplier();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('conditions', $casts);
        $this->assertArrayHasKey('is_active', $casts);
        $this->assertArrayHasKey('starts_at', $casts);
        $this->assertArrayHasKey('ends_at', $casts);
    }

    // DeliveryZone
    public function test_delivery_zone_fillable(): void
    {
        $model = new DeliveryZone();
        $this->assertContains('pharmacy_id', $model->getFillable());
        $this->assertContains('name', $model->getFillable());
        $this->assertContains('polygon', $model->getFillable());
        $this->assertContains('is_active', $model->getFillable());
    }

    public function test_delivery_zone_casts(): void
    {
        $model = new DeliveryZone();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('polygon', $casts);
        $this->assertArrayHasKey('is_active', $casts);
    }

    public function test_delivery_zone_pharmacy_relationship(): void
    {
        $model = new DeliveryZone();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->pharmacy());
    }

    // WithdrawalRequest
    public function test_withdrawal_request_fillable(): void
    {
        $model = new WithdrawalRequest();
        $this->assertContains('wallet_id', $model->getFillable());
        $this->assertContains('amount', $model->getFillable());
        $this->assertContains('status', $model->getFillable());
        $this->assertContains('reference', $model->getFillable());
    }

    public function test_withdrawal_request_casts(): void
    {
        $model = new WithdrawalRequest();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('account_details', $casts);
        $this->assertArrayHasKey('processed_at', $casts);
        $this->assertArrayHasKey('completed_at', $casts);
    }

    // LoyaltyRedemption
    public function test_loyalty_redemption_fillable(): void
    {
        $model = new LoyaltyRedemption();
        $this->assertContains('user_id', $model->getFillable());
        $this->assertContains('loyalty_reward_id', $model->getFillable());
        $this->assertContains('points_spent', $model->getFillable());
        $this->assertContains('status', $model->getFillable());
    }

    public function test_loyalty_redemption_casts(): void
    {
        $model = new LoyaltyRedemption();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('points_spent', $casts);
        $this->assertArrayHasKey('applied_at', $casts);
        $this->assertArrayHasKey('expires_at', $casts);
    }

    public function test_loyalty_redemption_relationships(): void
    {
        $model = new LoyaltyRedemption();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->user());
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->reward());
    }

    // PayoutRequest
    public function test_payout_request_fillable(): void
    {
        $model = new PayoutRequest();
        $this->assertContains('wallet_id', $model->getFillable());
        $this->assertContains('amount', $model->getFillable());
        $this->assertContains('status', $model->getFillable());
        $this->assertContains('payment_method', $model->getFillable());
    }

    public function test_payout_request_casts(): void
    {
        $model = new PayoutRequest();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('payment_details', $casts);
        $this->assertArrayHasKey('processed_at', $casts);
    }

    public function test_payout_request_wallet_relationship(): void
    {
        $model = new PayoutRequest();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->wallet());
    }

    // PharmacyStatementPreference
    public function test_pharmacy_statement_preference_fillable(): void
    {
        $model = new PharmacyStatementPreference();
        $this->assertContains('pharmacy_id', $model->getFillable());
        $this->assertContains('frequency', $model->getFillable());
        $this->assertContains('format', $model->getFillable());
        $this->assertContains('auto_send', $model->getFillable());
    }

    public function test_pharmacy_statement_preference_casts(): void
    {
        $model = new PharmacyStatementPreference();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('auto_send', $casts);
        $this->assertArrayHasKey('next_send_at', $casts);
        $this->assertArrayHasKey('last_sent_at', $casts);
    }

    public function test_pharmacy_statement_preference_relationship(): void
    {
        $model = new PharmacyStatementPreference();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->pharmacy());
    }

    // LoyaltyReward
    public function test_loyalty_reward_fillable(): void
    {
        $model = new LoyaltyReward();
        $this->assertContains('name', $model->getFillable());
        $this->assertContains('points_cost', $model->getFillable());
        $this->assertContains('is_active', $model->getFillable());
        $this->assertContains('type', $model->getFillable());
    }

    public function test_loyalty_reward_casts(): void
    {
        $model = new LoyaltyReward();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('points_cost', $casts);
        $this->assertArrayHasKey('is_active', $casts);
        $this->assertArrayHasKey('expires_at', $casts);
    }

    public function test_loyalty_reward_redemptions_relationship(): void
    {
        $model = new LoyaltyReward();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\HasMany::class, $model->redemptions());
    }

    // PaymentInfo
    public function test_payment_info_fillable(): void
    {
        $model = new PaymentInfo();
        $this->assertContains('pharmacy_id', $model->getFillable());
        $this->assertContains('type', $model->getFillable());
        $this->assertContains('is_primary', $model->getFillable());
        $this->assertContains('is_verified', $model->getFillable());
    }

    public function test_payment_info_casts(): void
    {
        $model = new PaymentInfo();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('is_primary', $casts);
        $this->assertArrayHasKey('is_verified', $casts);
        $this->assertArrayHasKey('verified_at', $casts);
    }

    public function test_payment_info_pharmacy_relationship(): void
    {
        $model = new PaymentInfo();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->pharmacy());
    }

    // PaymentIntent
    public function test_payment_intent_fillable(): void
    {
        $model = new PaymentIntent();
        $this->assertContains('order_id', $model->getFillable());
        $this->assertContains('provider', $model->getFillable());
        $this->assertContains('reference', $model->getFillable());
        $this->assertContains('amount', $model->getFillable());
        $this->assertContains('status', $model->getFillable());
    }

    public function test_payment_intent_casts(): void
    {
        $model = new PaymentIntent();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('raw_response', $casts);
        $this->assertArrayHasKey('raw_webhook', $casts);
        $this->assertArrayHasKey('confirmed_at', $casts);
    }

    public function test_payment_intent_order_relationship(): void
    {
        $model = new PaymentIntent();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsTo::class, $model->order());
    }

    // Challenge
    public function test_challenge_fillable(): void
    {
        $model = new Challenge();
        $this->assertContains('title', $model->getFillable());
        $this->assertContains('type', $model->getFillable());
        $this->assertContains('target_value', $model->getFillable());
        $this->assertContains('reward_amount', $model->getFillable());
        $this->assertContains('is_active', $model->getFillable());
    }

    public function test_challenge_casts(): void
    {
        $model = new Challenge();
        $casts = $model->getCasts();
        $this->assertArrayHasKey('target_value', $casts);
        $this->assertArrayHasKey('is_active', $casts);
        $this->assertArrayHasKey('starts_at', $casts);
        $this->assertArrayHasKey('ends_at', $casts);
    }

    public function test_challenge_couriers_relationship(): void
    {
        $model = new Challenge();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsToMany::class, $model->couriers());
    }
}
