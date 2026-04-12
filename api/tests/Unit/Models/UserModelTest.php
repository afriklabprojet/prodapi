<?php

namespace Tests\Unit\Models;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserModelTest extends TestCase
{
    use RefreshDatabase;

    public function test_fillable_fields(): void
    {
        $user = new User();
        $this->assertContains('name', $user->getFillable());
        $this->assertContains('email', $user->getFillable());
        $this->assertContains('phone', $user->getFillable());
        $this->assertContains('role', $user->getFillable());
        $this->assertContains('fcm_token', $user->getFillable());
        $this->assertContains('must_change_password', $user->getFillable());
    }

    public function test_hidden_fields(): void
    {
        $user = new User();
        $hidden = $user->getHidden();
        $this->assertContains('password', $hidden);
        $this->assertContains('remember_token', $hidden);
    }

    public function test_casts(): void
    {
        $user = new User();
        $casts = $user->getCasts();
        $this->assertArrayHasKey('must_change_password', $casts);
        $this->assertArrayHasKey('notification_preferences', $casts);
    }

    public function test_is_admin(): void
    {
        $user = User::factory()->create(['role' => 'admin']);
        $this->assertTrue($user->isAdmin());
        $this->assertFalse($user->isCustomer());
    }

    public function test_is_customer(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        $this->assertTrue($user->isCustomer());
        $this->assertFalse($user->isAdmin());
    }

    public function test_is_courier(): void
    {
        $user = User::factory()->create(['role' => 'courier']);
        $this->assertTrue($user->isCourier());
        $this->assertFalse($user->isCustomer());
    }

    public function test_is_pharmacy(): void
    {
        $user = User::factory()->create(['role' => 'pharmacy']);
        $this->assertTrue($user->isPharmacy());
        $this->assertFalse($user->isAdmin());
    }

    public function test_has_orders_relationship(): void
    {
        $user = User::factory()->create(['role' => 'customer']);
        $this->assertNotNull($user->orders());
    }

    public function test_has_prescriptions_relationship(): void
    {
        $user = User::factory()->create();
        $this->assertNotNull($user->prescriptions());
    }

    public function test_has_addresses_relationship(): void
    {
        $user = User::factory()->create();
        $this->assertNotNull($user->addresses());
    }

    public function test_has_courier_relationship(): void
    {
        $user = User::factory()->create(['role' => 'courier']);
        $this->assertNotNull($user->courier());
    }

    public function test_has_pharmacies_relationship(): void
    {
        $user = User::factory()->create(['role' => 'pharmacy']);
        $this->assertNotNull($user->pharmacies());
    }
}
