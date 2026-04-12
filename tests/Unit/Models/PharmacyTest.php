<?php

namespace Tests\Unit\Models;

use App\Models\Pharmacy;
use App\Models\User;
use App\Models\Order;
use App\Models\Product;
use App\Models\PharmacyOnCall;
use App\Models\DutyZone;
use App\Models\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class PharmacyTest extends TestCase
{
    use RefreshDatabase;

    protected $pharmacy;

    protected function setUp(): void
    {
        parent::setUp();

        $this->pharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
            'latitude' => 5.3600,
            'longitude' => -4.0083,
        ]);
    }

    #[Test]
    public function it_has_users_relationship()
    {
        $user = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy->users()->attach($user->id, ['role' => 'owner']);

        $this->assertCount(1, $this->pharmacy->users);
        $this->assertEquals($user->id, $this->pharmacy->users->first()->id);
    }

    #[Test]
    public function it_has_many_orders()
    {
        $user = User::factory()->create(['role' => 'customer']);
        Order::factory()->count(3)->create([
            'pharmacy_id' => $this->pharmacy->id,
            'customer_id' => $user->id,
        ]);

        $this->assertCount(3, $this->pharmacy->orders);
    }

    #[Test]
    public function it_has_duty_zone_relationship()
    {
        $dutyZone = DutyZone::factory()->create();
        $this->pharmacy->update(['duty_zone_id' => $dutyZone->id]);

        $this->pharmacy->refresh();

        $this->assertInstanceOf(DutyZone::class, $this->pharmacy->dutyZone);
        $this->assertEquals($dutyZone->id, $this->pharmacy->dutyZone->id);
    }

    #[Test]
    public function it_has_wallet_relationship()
    {
        $wallet = Wallet::factory()->create([
            'walletable_type' => Pharmacy::class,
            'walletable_id' => $this->pharmacy->id,
        ]);

        $this->assertInstanceOf(Wallet::class, $this->pharmacy->wallet);
        $this->assertEquals($wallet->id, $this->pharmacy->wallet->id);
    }

    #[Test]
    public function is_approved_returns_true_for_approved_pharmacy()
    {
        $this->assertTrue($this->pharmacy->isApproved());
    }

    #[Test]
    public function is_approved_returns_false_for_pending_pharmacy()
    {
        $pending = Pharmacy::factory()->create(['status' => 'pending']);

        $this->assertFalse($pending->isApproved());
    }

    #[Test]
    public function scope_approved_returns_only_approved_pharmacies()
    {
        Pharmacy::factory()->create(['status' => 'pending']);
        Pharmacy::factory()->create(['status' => 'rejected']);

        $approved = Pharmacy::approved()->get();

        $this->assertEquals(1, $approved->count());
        $this->assertEquals('approved', $approved->first()->status);
    }

    #[Test]
    public function scope_pending_returns_only_pending_pharmacies()
    {
        Pharmacy::factory()->create(['status' => 'pending']);
        Pharmacy::factory()->create(['status' => 'rejected']);

        $pending = Pharmacy::pending()->get();

        $this->assertEquals(1, $pending->count());
        $this->assertEquals('pending', $pending->first()->status);
    }

    #[Test]
    public function scope_near_location_finds_nearby_pharmacies()
    {
        // Create a pharmacy very close
        $nearbyPharmacy = Pharmacy::factory()->create([
            'status' => 'approved',
            'latitude' => 5.3601,
            'longitude' => -4.0084,
        ]);

        // Create a pharmacy far away
        Pharmacy::factory()->create([
            'status' => 'approved',
            'latitude' => 10.0000,
            'longitude' => -5.0000,
        ]);

        $nearby = Pharmacy::approved()
            ->nearLocation(5.3600, -4.0083, 5)
            ->get();

        // Should find the original pharmacy and the nearby one
        $this->assertGreaterThanOrEqual(2, $nearby->count());
    }

    #[Test]
    public function scope_near_location_rejects_invalid_coordinates()
    {
        $result = Pharmacy::nearLocation(100, -4.0083)->get(); // Invalid latitude

        $this->assertEquals(0, $result->count());
    }

    #[Test]
    public function it_soft_deletes()
    {
        $this->pharmacy->delete();

        $this->assertSoftDeleted($this->pharmacy);
        $this->assertNull(Pharmacy::find($this->pharmacy->id));
        $this->assertNotNull(Pharmacy::withTrashed()->find($this->pharmacy->id));
    }

    #[Test]
    public function it_casts_coordinates_to_float()
    {
        $this->assertIsFloat($this->pharmacy->latitude);
        $this->assertIsFloat($this->pharmacy->longitude);
    }

    #[Test]
    public function it_casts_commission_rates_to_decimal()
    {
        $pharmacy = Pharmacy::factory()->create([
            'commission_rate_platform' => 0.1234,
            'commission_rate_pharmacy' => 0.5678,
        ]);

        $this->assertEquals('0.1234', $pharmacy->commission_rate_platform);
        $this->assertEquals('0.5678', $pharmacy->commission_rate_pharmacy);
    }

    #[Test]
    public function it_has_fillable_attributes()
    {
        $pharmacy = new Pharmacy();
        
        $this->assertContains('name', $pharmacy->getFillable());
        $this->assertContains('phone', $pharmacy->getFillable());
        $this->assertContains('address', $pharmacy->getFillable());
        $this->assertContains('city', $pharmacy->getFillable());
        $this->assertContains('status', $pharmacy->getFillable());
        $this->assertContains('latitude', $pharmacy->getFillable());
        $this->assertContains('longitude', $pharmacy->getFillable());
    }

    #[Test]
    public function it_casts_approved_at_to_datetime()
    {
        $pharmacy = Pharmacy::factory()->create([
            'approved_at' => now(),
        ]);

        $this->assertInstanceOf(\Carbon\Carbon::class, $pharmacy->approved_at);
    }

    #[Test]
    public function it_casts_is_featured_to_boolean()
    {
        $pharmacy = Pharmacy::factory()->create([
            'is_featured' => 1,
        ]);

        $this->assertIsBool($pharmacy->is_featured);
        $this->assertTrue($pharmacy->is_featured);
    }

    #[Test]
    public function it_stores_rejection_reason()
    {
        $pharmacy = Pharmacy::factory()->create([
            'status' => 'rejected',
            'rejection_reason' => 'Invalid license',
        ]);

        $this->assertEquals('rejected', $pharmacy->status);
        $this->assertEquals('Invalid license', $pharmacy->rejection_reason);
    }

    #[Test]
    public function it_stores_withdrawal_settings()
    {
        $pharmacy = Pharmacy::factory()->create([
            'withdrawal_threshold' => 50000,
            'auto_withdraw_enabled' => true,
        ]);

        $this->assertEquals(50000, $pharmacy->withdrawal_threshold);
        $this->assertTrue($pharmacy->auto_withdraw_enabled);
    }

    #[Test]
    public function pivot_table_stores_user_role()
    {
        $user = User::factory()->create(['role' => 'pharmacy']);
        $this->pharmacy->users()->attach($user->id, ['role' => 'owner']);

        $attachedUser = $this->pharmacy->users()->first();
        $this->assertEquals('owner', $attachedUser->pivot->role);
    }

    #[Test]
    public function scope_on_duty_returns_pharmacies_currently_on_call()
    {
        // Create a pharmacy on duty
        $onDutyPharmacy = Pharmacy::factory()->create();
        PharmacyOnCall::factory()->create([
            'pharmacy_id' => $onDutyPharmacy->id,
            'start_at' => now()->subHour(),
            'end_at' => now()->addHours(2),
            'is_active' => true,
        ]);

        // Create a pharmacy not on duty (future on call)
        $notOnDutyPharmacy = Pharmacy::factory()->create();
        PharmacyOnCall::factory()->create([
            'pharmacy_id' => $notOnDutyPharmacy->id,
            'start_at' => now()->addDay(),
            'end_at' => now()->addDays(2),
            'is_active' => true,
        ]);

        $onDuty = Pharmacy::onDuty()->get();

        $this->assertTrue($onDuty->contains('id', $onDutyPharmacy->id));
        $this->assertFalse($onDuty->contains('id', $notOnDutyPharmacy->id));
    }

    #[Test]
    public function scope_on_duty_excludes_inactive_on_calls()
    {
        $pharmacy = Pharmacy::factory()->create();
        PharmacyOnCall::factory()->create([
            'pharmacy_id' => $pharmacy->id,
            'start_at' => now()->subHour(),
            'end_at' => now()->addHours(2),
            'is_active' => false,
        ]);

        $onDuty = Pharmacy::onDuty()->get();

        $this->assertFalse($onDuty->contains('id', $pharmacy->id));
    }

    #[Test]
    public function scope_featured_returns_only_featured_pharmacies()
    {
        $featured = Pharmacy::factory()->create(['is_featured' => true]);
        $notFeatured = Pharmacy::factory()->create(['is_featured' => false]);

        $results = Pharmacy::featured()->get();

        $this->assertTrue($results->contains('id', $featured->id));
        $this->assertFalse($results->contains('id', $notFeatured->id));
    }

    #[Test]
    public function it_has_payment_info_relationship()
    {
        $paymentInfo = \App\Models\PaymentInfo::create([
            'pharmacy_id' => $this->pharmacy->id,
            'type' => 'bank',
            'bank_name' => 'Test Bank',
            'holder_name' => 'Test Holder',
            'account_number' => '123456789',
            'is_primary' => true,
        ]);

        $this->assertCount(1, $this->pharmacy->paymentInfo);
        $this->assertEquals($paymentInfo->id, $this->pharmacy->paymentInfo->first()->id);
    }

    #[Test]
    public function it_has_withdrawal_requests_relationship()
    {
        // Create a wallet for the pharmacy first
        $wallet = Wallet::factory()->create([
            'walletable_type' => Pharmacy::class,
            'walletable_id' => $this->pharmacy->id,
            'balance' => 100000,
        ]);

        $request = \App\Models\WithdrawalRequest::create([
            'wallet_id' => $wallet->id,
            'requestable_type' => Pharmacy::class,
            'requestable_id' => $this->pharmacy->id,
            'amount' => 50000,
            'payment_method' => 'bank_transfer',
            'status' => 'pending',
            'reference' => 'WD-' . uniqid(),
        ]);

        $this->assertCount(1, $this->pharmacy->withdrawalRequests);
        $this->assertEquals($request->id, $this->pharmacy->withdrawalRequests->first()->id);
    }

    #[Test]
    public function it_has_statement_preference_relationship()
    {
        $preference = \App\Models\PharmacyStatementPreference::create([
            'pharmacy_id' => $this->pharmacy->id,
            'frequency' => 'weekly',
            'format' => 'pdf',
            'auto_send' => true,
            'email' => 'test@example.com',
        ]);

        $this->assertNotNull($this->pharmacy->statementPreference);
        $this->assertEquals($preference->id, $this->pharmacy->statementPreference->id);
    }

    #[Test]
    public function it_has_ratings_relationship()
    {
        $user = User::factory()->create(['role' => 'customer']);
        $order = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        
        $rating = \App\Models\Rating::create([
            'user_id' => $user->id,
            'order_id' => $order->id,
            'rateable_type' => Pharmacy::class,
            'rateable_id' => $this->pharmacy->id,
            'rating' => 5,
        ]);

        $this->assertCount(1, $this->pharmacy->ratings);
        $this->assertEquals($rating->id, $this->pharmacy->ratings->first()->id);
    }

    #[Test]
    public function average_rating_returns_correct_value()
    {
        $user = User::factory()->create(['role' => 'customer']);
        $order1 = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
        ]);
        $order2 = Order::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        \App\Models\Rating::create([
            'user_id' => $user->id,
            'order_id' => $order1->id,
            'rateable_type' => Pharmacy::class,
            'rateable_id' => $this->pharmacy->id,
            'rating' => 5,
        ]);

        \App\Models\Rating::create([
            'user_id' => $user->id,
            'order_id' => $order2->id,
            'rateable_type' => Pharmacy::class,
            'rateable_id' => $this->pharmacy->id,
            'rating' => 3,
        ]);

        $this->assertEquals(4.0, $this->pharmacy->averageRating());
    }

    #[Test]
    public function average_rating_returns_zero_when_no_ratings()
    {
        $this->assertEquals(0.0, $this->pharmacy->averageRating());
    }

    #[Test]
    public function has_pin_configured_returns_true_when_pin_is_set()
    {
        $this->pharmacy->withdrawal_pin = 'hashed_pin';
        $this->pharmacy->save();

        $this->assertTrue($this->pharmacy->hasPinConfigured());
    }

    #[Test]
    public function has_pin_configured_returns_false_when_no_pin()
    {
        $this->pharmacy->withdrawal_pin = null;
        $this->pharmacy->save();

        $this->assertFalse($this->pharmacy->hasPinConfigured());
    }

    #[Test]
    public function set_withdrawal_pin_hashes_and_stores_pin()
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $this->assertNotNull($this->pharmacy->withdrawal_pin);
        $this->assertNotEquals('1234', $this->pharmacy->withdrawal_pin);
        $this->assertTrue(\Illuminate\Support\Facades\Hash::check('1234', $this->pharmacy->withdrawal_pin));
    }

    #[Test]
    public function verify_withdrawal_pin_returns_true_for_correct_pin()
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $this->assertTrue($this->pharmacy->verifyWithdrawalPin('1234'));
    }

    #[Test]
    public function verify_withdrawal_pin_returns_false_for_incorrect_pin()
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $this->assertFalse($this->pharmacy->verifyWithdrawalPin('9999'));
    }

    #[Test]
    public function verify_withdrawal_pin_increments_attempts_on_failure()
    {
        $this->pharmacy->setWithdrawalPin('1234');

        $this->pharmacy->verifyWithdrawalPin('9999');
        $this->pharmacy->refresh();

        $this->assertEquals(1, $this->pharmacy->pin_attempts);
    }

    #[Test]
    public function verify_withdrawal_pin_locks_after_five_failed_attempts()
    {
        $this->pharmacy->setWithdrawalPin('1234');

        for ($i = 0; $i < 5; $i++) {
            $this->pharmacy->verifyWithdrawalPin('9999');
        }

        $this->pharmacy->refresh();

        $this->assertTrue($this->pharmacy->isPinLocked());
        $this->assertNotNull($this->pharmacy->pin_locked_until);
    }

    #[Test]
    public function verify_withdrawal_pin_returns_false_when_locked()
    {
        // Set PIN directly via forceFill
        $hashedPin = \Illuminate\Support\Facades\Hash::make('1234');
        $this->pharmacy->forceFill([
            'withdrawal_pin' => $hashedPin,
            'pin_locked_until' => now()->addMinutes(30),
        ])->save();
        $this->pharmacy->refresh();

        $this->assertFalse($this->pharmacy->verifyWithdrawalPin('1234'));
    }

    #[Test]
    public function is_pin_locked_returns_false_when_not_locked()
    {
        $this->pharmacy->forceFill(['pin_locked_until' => null, 'pin_attempts' => 0])->save();
        $this->pharmacy->refresh();

        $this->assertFalse($this->pharmacy->isPinLocked());
    }

    #[Test]
    public function is_pin_locked_returns_true_when_locked()
    {
        $this->pharmacy->forceFill(['pin_locked_until' => now()->addMinutes(30)])->save();
        $this->pharmacy->refresh();

        $this->assertTrue($this->pharmacy->isPinLocked());
    }

    #[Test]
    public function is_pin_locked_resets_attempts_when_lock_expired()
    {
        $this->pharmacy->forceFill(['pin_locked_until' => now()->subMinute(), 'pin_attempts' => 5])->save();
        $this->pharmacy->refresh();

        $this->assertFalse($this->pharmacy->isPinLocked());
        
        $this->pharmacy->refresh();
        $this->assertEquals(0, $this->pharmacy->pin_attempts);
        $this->assertNull($this->pharmacy->pin_locked_until);
    }

    #[Test]
    public function pin_lock_remaining_minutes_returns_null_when_not_locked()
    {
        $this->pharmacy->forceFill(['pin_locked_until' => null])->save();
        $this->pharmacy->refresh();

        $this->assertNull($this->pharmacy->pinLockRemainingMinutes());
    }

    #[Test]
    public function pin_lock_remaining_minutes_returns_correct_value_when_locked()
    {
        $this->pharmacy->forceFill(['pin_locked_until' => now()->addMinutes(25)])->save();
        $this->pharmacy->refresh();

        $remaining = $this->pharmacy->pinLockRemainingMinutes();

        $this->assertIsInt($remaining);
        $this->assertGreaterThanOrEqual(24, $remaining);
        $this->assertLessThanOrEqual(26, $remaining);
    }

    #[Test]
    public function verify_withdrawal_pin_resets_attempts_on_success()
    {
        // Set PIN directly via forceFill
        $hashedPin = \Illuminate\Support\Facades\Hash::make('1234');
        $this->pharmacy->forceFill([
            'withdrawal_pin' => $hashedPin,
            'pin_attempts' => 3,
        ])->save();
        $this->pharmacy->refresh();

        $this->pharmacy->verifyWithdrawalPin('1234');
        $this->pharmacy->refresh();

        $this->assertEquals(0, $this->pharmacy->pin_attempts);
    }

    #[Test]
    public function it_has_on_calls_relationship()
    {
        $onCall = PharmacyOnCall::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $this->assertCount(1, $this->pharmacy->onCalls);
        $this->assertEquals($onCall->id, $this->pharmacy->onCalls->first()->id);
    }

    #[Test]
    public function it_has_products_relationship()
    {
        $product = Product::factory()->create([
            'pharmacy_id' => $this->pharmacy->id,
        ]);

        $this->assertCount(1, $this->pharmacy->products);
        $this->assertEquals($product->id, $this->pharmacy->products->first()->id);
    }

    #[Test]
    public function it_has_delivery_zone_relationship()
    {
        $deliveryZone = \App\Models\DeliveryZone::create([
            'pharmacy_id' => $this->pharmacy->id,
            'polygon' => json_encode([
                ['lat' => 5.36, 'lng' => -4.01],
                ['lat' => 5.37, 'lng' => -4.01],
                ['lat' => 5.37, 'lng' => -4.00],
                ['lat' => 5.36, 'lng' => -4.00],
            ]),
            'is_active' => true,
        ]);

        $this->assertNotNull($this->pharmacy->deliveryZone);
        $this->assertEquals($deliveryZone->id, $this->pharmacy->deliveryZone->id);
    }

    #[Test]
    public function withdrawal_pin_is_guarded()
    {
        $pharmacy = new Pharmacy();
        
        $this->assertContains('withdrawal_pin', $pharmacy->getGuarded());
    }
}
