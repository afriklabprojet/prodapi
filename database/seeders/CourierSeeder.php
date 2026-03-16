<?php

namespace Database\Seeders;

use App\Models\Courier;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class CourierSeeder extends Seeder
{
    public function run(): void
    {
        $couriers = [
            [
                'name' => 'Kouassi Jean',
                'email' => 'coursier1@drlpharma.com',
                'phone' => '+2250700000020',
                'vehicle_type' => 'motorcycle',
            ],
            [
                'name' => 'Koné Ibrahim',
                'email' => 'coursier2@drlpharma.com',
                'phone' => '+2250700000021',
                'vehicle_type' => 'motorcycle',
            ],
            [
                'name' => 'Traoré Moussa',
                'email' => 'coursier3@drlpharma.com',
                'phone' => '+2250700000022',
                'vehicle_type' => 'bicycle',
            ],
        ];

        foreach ($couriers as $courierData) {
            // Create courier user
            $user = User::create([
                'name' => $courierData['name'],
                'email' => $courierData['email'],
                'phone' => $courierData['phone'],
                'password' => Hash::make('password'),
                'role' => 'courier',
                'email_verified_at' => now(),
            ]);

            // Create courier profile
            $courier = Courier::create([
                'user_id' => $user->id,
                'name' => $courierData['name'],
                'phone' => $courierData['phone'],
                'vehicle_type' => $courierData['vehicle_type'],
                'vehicle_number' => strtoupper(fake()->bothify('??-####-??')),
                'license_number' => strtoupper(fake()->bothify('CI-####-####')),
                'status' => 'available',
                'kyc_status' => 'approved',
                'latitude' => 5.3167 + (rand(-100, 100) / 10000),
                'longitude' => -4.0167 + (rand(-100, 100) / 10000),
                'rating' => 4.5,
                'completed_deliveries' => rand(10, 100),
            ]);

            // Create wallet for courier (polymorphic relation)
            Wallet::create([
                'walletable_type' => Courier::class,
                'walletable_id' => $courier->id,
                'balance' => rand(5000, 50000),
                'currency' => 'XOF',
            ]);
        }
    }
}
