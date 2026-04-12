<?php

namespace Tests\Unit\Policies;

use App\Models\Courier;
use App\Models\Pharmacy;
use App\Models\User;
use App\Models\Wallet;
use App\Policies\WalletPolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class WalletPolicyTest extends TestCase
{
    use RefreshDatabase;

    private WalletPolicy $policy;

    protected function setUp(): void
    {
        parent::setUp();
        $this->policy = new WalletPolicy();
    }

    #[Test]
    public function admin_can_view_any_wallets(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $this->assertTrue($this->policy->viewAny($admin));
    }

    #[Test]
    public function non_admin_cannot_view_any_wallets(): void
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $pharmacy = User::factory()->create(['role' => 'pharmacy']);

        $this->assertFalse($this->policy->viewAny($customer));
        $this->assertFalse($this->policy->viewAny($pharmacy));
    }

    #[Test]
    public function admin_can_view_any_wallet(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $pharmacy = Pharmacy::factory()->create();
        $wallet = Wallet::factory()->create([
            'walletable_type' => Pharmacy::class,
            'walletable_id' => $pharmacy->id,
        ]);

        $this->assertTrue($this->policy->view($admin, $wallet));
    }

    #[Test]
    public function courier_can_view_own_wallet(): void
    {
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);
        $wallet = Wallet::factory()->create([
            'walletable_type' => Courier::class,
            'walletable_id' => $courier->id,
        ]);

        $this->assertTrue($this->policy->view($courierUser, $wallet));
    }

    #[Test]
    public function courier_cannot_view_other_courier_wallet(): void
    {
        $courierUser1 = User::factory()->create(['role' => 'courier']);
        $courier1 = Courier::factory()->create(['user_id' => $courierUser1->id]);

        $courierUser2 = User::factory()->create(['role' => 'courier']);
        $courier2 = Courier::factory()->create(['user_id' => $courierUser2->id]);
        $wallet2 = Wallet::factory()->create([
            'walletable_type' => Courier::class,
            'walletable_id' => $courier2->id,
        ]);

        $this->assertFalse($this->policy->view($courierUser1, $wallet2));
    }

    #[Test]
    public function pharmacy_owner_can_view_pharmacy_wallet(): void
    {
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::factory()->create();
        $pharmacyUser->pharmacies()->attach($pharmacy->id, ['role' => 'owner']);
        
        $wallet = Wallet::factory()->create([
            'walletable_type' => Pharmacy::class,
            'walletable_id' => $pharmacy->id,
        ]);

        $this->assertTrue($this->policy->view($pharmacyUser, $wallet));
    }

    #[Test]
    public function pharmacy_owner_cannot_view_other_pharmacy_wallet(): void
    {
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $ownPharmacy = Pharmacy::factory()->create();
        $pharmacyUser->pharmacies()->attach($ownPharmacy->id, ['role' => 'owner']);
        
        $otherPharmacy = Pharmacy::factory()->create();
        $wallet = Wallet::factory()->create([
            'walletable_type' => Pharmacy::class,
            'walletable_id' => $otherPharmacy->id,
        ]);

        $this->assertFalse($this->policy->view($pharmacyUser, $wallet));
    }

    #[Test]
    public function wallet_owner_can_view_transactions(): void
    {
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);
        $wallet = Wallet::factory()->create([
            'walletable_type' => Courier::class,
            'walletable_id' => $courier->id,
        ]);

        $this->assertTrue($this->policy->viewTransactions($courierUser, $wallet));
    }

    #[Test]
    public function wallet_owner_can_top_up(): void
    {
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);
        $wallet = Wallet::factory()->create([
            'walletable_type' => Courier::class,
            'walletable_id' => $courier->id,
        ]);

        $this->assertTrue($this->policy->topUp($courierUser, $wallet));
    }

    #[Test]
    public function non_owner_cannot_top_up_wallet(): void
    {
        $courierUser1 = User::factory()->create(['role' => 'courier']);
        $courier1 = Courier::factory()->create(['user_id' => $courierUser1->id]);

        $courierUser2 = User::factory()->create(['role' => 'courier']);
        $courier2 = Courier::factory()->create(['user_id' => $courierUser2->id]);
        $wallet2 = Wallet::factory()->create([
            'walletable_type' => Courier::class,
            'walletable_id' => $courier2->id,
        ]);

        $this->assertFalse($this->policy->topUp($courierUser1, $wallet2));
    }

    #[Test]
    public function wallet_owner_can_withdraw(): void
    {
        $pharmacyUser = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::factory()->create();
        $pharmacyUser->pharmacies()->attach($pharmacy->id, ['role' => 'owner']);
        
        $wallet = Wallet::factory()->create([
            'walletable_type' => Pharmacy::class,
            'walletable_id' => $pharmacy->id,
        ]);

        $this->assertTrue($this->policy->withdraw($pharmacyUser, $wallet));
    }

    #[Test]
    public function non_owner_cannot_withdraw(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $pharmacy = Pharmacy::factory()->create();
        $wallet = Wallet::factory()->create([
            'walletable_type' => Pharmacy::class,
            'walletable_id' => $pharmacy->id,
        ]);

        // Admin can view but not withdraw
        $this->assertFalse($this->policy->withdraw($admin, $wallet));
    }

    #[Test]
    public function admin_can_update_wallet_settings(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $pharmacy = Pharmacy::factory()->create();
        $wallet = Wallet::factory()->create([
            'walletable_type' => Pharmacy::class,
            'walletable_id' => $pharmacy->id,
        ]);

        $this->assertTrue($this->policy->updateSettings($admin, $wallet));
    }

    #[Test]
    public function wallet_owner_can_update_settings(): void
    {
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);
        $wallet = Wallet::factory()->create([
            'walletable_type' => Courier::class,
            'walletable_id' => $courier->id,
        ]);

        $this->assertTrue($this->policy->updateSettings($courierUser, $wallet));
    }

    #[Test]
    public function wallet_owner_can_export(): void
    {
        $courierUser = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $courierUser->id]);
        $wallet = Wallet::factory()->create([
            'walletable_type' => Courier::class,
            'walletable_id' => $courier->id,
        ]);

        $this->assertTrue($this->policy->export($courierUser, $wallet));
    }
}
