<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // Admin user - uses env variable or a secure default
        $adminPassword = env('ADMIN_DEFAULT_PASSWORD', 'DrPh@rm@2026$ecure!');

        // Admin principal
        User::firstOrCreate(
            ['email' => 'admin@drlpharma.com'],
            [
                'name' => 'Admin DR-PHARMA',
                'phone' => '+2250700000000',
                'password' => Hash::make($adminPassword),
                'role' => 'admin',
                'email_verified_at' => now(),
                'phone_verified_at' => now(),
                'must_change_password' => true,
            ]
        );

        // Admin secondaire (compte personnel)
        User::firstOrCreate(
            ['email' => 'drlnegoce@gmail.com'],
            [
                'name' => 'DRL Negoce Admin',
                'phone' => '+2250700000001',
                'password' => Hash::make($adminPassword),
                'role' => 'admin',
                'email_verified_at' => now(),
                'phone_verified_at' => now(),
                'must_change_password' => true,
            ]
        );
    }
}
