<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Test data seeder — ONLY for local/testing environments.
 * Never run in production.
 */
class TestDataSeeder extends Seeder
{
    public function run(): void
    {
        // Test customer
        User::firstOrCreate(
            ['phone' => '+2250700000001'],
            [
                'name' => 'Client Test',
                'email' => 'client@drlpharma.com',
                'password' => Hash::make('testpassword123'),
                'role' => 'customer',
                'email_verified_at' => now(),
                'phone_verified_at' => now(),
            ]
        );

        // Additional test customers
        $existingCustomers = User::where('role', 'customer')->count();
        if ($existingCustomers < 6) {
            User::factory(6 - $existingCustomers)->customer()->create();
        }

        // Pharmacies, Couriers, Products, Orders
        $this->call([
            PharmacySeeder::class,
            CourierSeeder::class,
            ProductSeeder::class,
            OrderAndDeliverySeeder::class,
        ]);
    }
}
