<?php

namespace Tests\Unit\Models;

use App\Models\Customer;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use PHPUnit\Framework\Attributes\Test;

class CustomerTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function it_belongs_to_a_user()
    {
        $user = User::factory()->create(['role' => 'customer']);
        $customer = Customer::factory()->create(['user_id' => $user->id]);

        $this->assertInstanceOf(User::class, $customer->user);
        $this->assertEquals($user->id, $customer->user->id);
    }

    #[Test]
    public function it_has_wallet_relationship()
    {
        $user = User::factory()->create(['role' => 'customer']);
        $customer = Customer::factory()->create(['user_id' => $user->id]);

        Wallet::factory()->create([
            'walletable_type' => Customer::class,
            'walletable_id' => $customer->id,
        ]);

        $this->assertInstanceOf(Wallet::class, $customer->wallet);
    }

    #[Test]
    public function it_can_be_created_with_factory()
    {
        $user = User::factory()->create(['role' => 'customer']);
        $customer = Customer::factory()->create(['user_id' => $user->id]);

        $this->assertDatabaseHas('customers', ['user_id' => $user->id]);
        $this->assertEquals($user->id, $customer->user_id);
    }
}
