<?php

namespace Tests\Unit\Models;

use App\Models\User;
use App\Models\Customer;
use App\Models\CustomerAddress;
use App\Models\Courier;
use App\Models\Order;
use App\Models\Pharmacy;
use App\Models\Prescription;
use App\Models\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class UserTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_has_fillable_attributes()
    {
        $user = User::factory()->create([
            'name' => 'Jean Dupont',
            'role' => 'customer',
            'phone' => '+22500000001',
        ]);

        $this->assertEquals('Jean Dupont', $user->name);
        $this->assertEquals('customer', $user->role);
        $this->assertEquals('+22500000001', $user->phone);
    }

    #[Test]
    public function it_hides_password_and_remember_token()
    {
        $user = User::factory()->create();
        $array = $user->toArray();

        $this->assertArrayNotHasKey('password', $array);
        $this->assertArrayNotHasKey('remember_token', $array);
    }

    #[Test]
    public function it_casts_attributes_correctly()
    {
        $user = User::factory()->create([
            'must_change_password' => true,
            'notification_preferences' => ['sms' => true, 'email' => false],
        ]);

        $this->assertIsBool($user->must_change_password);
        $this->assertTrue($user->must_change_password);
        $this->assertIsArray($user->notification_preferences);
    }

    #[Test]
    public function is_admin_returns_true_for_admin()
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $customer = User::factory()->create(['role' => 'customer']);

        $this->assertTrue($admin->isAdmin());
        $this->assertFalse($customer->isAdmin());
    }

    #[Test]
    public function is_pharmacy_returns_true_for_pharmacy()
    {
        $pharmacist = User::factory()->create(['role' => 'pharmacy']);
        $customer = User::factory()->create(['role' => 'customer']);

        $this->assertTrue($pharmacist->isPharmacy());
        $this->assertFalse($customer->isPharmacy());
    }

    #[Test]
    public function is_courier_returns_true_for_courier()
    {
        $courier = User::factory()->create(['role' => 'courier']);
        $customer = User::factory()->create(['role' => 'customer']);

        $this->assertTrue($courier->isCourier());
        $this->assertFalse($customer->isCourier());
    }

    #[Test]
    public function is_customer_returns_true_for_customer()
    {
        $customer = User::factory()->create(['role' => 'customer']);
        $admin = User::factory()->create(['role' => 'admin']);

        $this->assertTrue($customer->isCustomer());
        $this->assertFalse($admin->isCustomer());
    }

    #[Test]
    public function it_has_pharmacies_relationship()
    {
        $user = User::factory()->create(['role' => 'pharmacy']);
        $pharmacy = Pharmacy::factory()->create();
        $pharmacy->users()->attach($user->id, ['role' => 'titulaire']);

        $this->assertCount(1, $user->pharmacies);
        $this->assertInstanceOf(Pharmacy::class, $user->pharmacies->first());
        $this->assertEquals('titulaire', $user->pharmacies->first()->pivot->role);
    }

    #[Test]
    public function it_has_courier_relationship()
    {
        $user = User::factory()->create(['role' => 'courier']);
        $courier = Courier::factory()->create(['user_id' => $user->id]);

        $this->assertInstanceOf(Courier::class, $user->courier);
        $this->assertEquals($courier->id, $user->courier->id);
    }

    #[Test]
    public function it_has_customer_relationship()
    {
        $user = User::factory()->create(['role' => 'customer']);
        $customer = Customer::factory()->create(['user_id' => $user->id]);

        $this->assertInstanceOf(Customer::class, $user->customer);
        $this->assertEquals($customer->id, $user->customer->id);
    }

    #[Test]
    public function it_has_orders_relationship()
    {
        $user = User::factory()->create(['role' => 'customer']);
        Customer::factory()->create(['user_id' => $user->id]);
        $pharmacy = Pharmacy::factory()->create(['status' => 'approved']);

        Order::factory()->count(2)->create([
            'pharmacy_id' => $pharmacy->id,
            'customer_id' => $user->id,
        ]);

        $this->assertCount(2, $user->orders);
        $this->assertInstanceOf(Order::class, $user->orders->first());
    }

    #[Test]
    public function it_has_addresses_relationship()
    {
        $user = User::factory()->create(['role' => 'customer']);
        CustomerAddress::factory()->count(2)->create(['user_id' => $user->id]);

        $this->assertCount(2, $user->addresses);
        $this->assertInstanceOf(CustomerAddress::class, $user->addresses->first());
    }

    #[Test]
    public function can_access_panel_only_for_admin()
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $customer = User::factory()->create(['role' => 'customer']);

        $panel = $this->createMock(\Filament\Panel::class);

        $this->assertTrue($admin->canAccessPanel($panel));
        $this->assertFalse($customer->canAccessPanel($panel));
    }
}
