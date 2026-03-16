<?php

namespace Database\Seeders;

use App\Models\Pharmacy;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class PharmacySeeder extends Seeder
{
    public function run(): void
    {
        $pharmacies = [
            [
                'name' => 'Pharmacie du Plateau',
                'email' => 'plateau@drlpharma.com',
                'phone' => '+2250700000010',
                'address' => 'Avenue Franchet d\'Esperey, Plateau',
                'city' => 'Abidjan',
                'latitude' => 5.3167,
                'longitude' => -4.0167,
            ],
            [
                'name' => 'Pharmacie Cocody',
                'email' => 'cocody@drlpharma.com',
                'phone' => '+2250700000011',
                'address' => 'Boulevard de France, Cocody',
                'city' => 'Abidjan',
                'latitude' => 5.3599,
                'longitude' => -3.9833,
            ],
            [
                'name' => 'Pharmacie Marcory',
                'email' => 'marcory@drlpharma.com',
                'phone' => '+2250700000012',
                'address' => 'Zone 4, Marcory',
                'city' => 'Abidjan',
                'latitude' => 5.3000,
                'longitude' => -3.9833,
            ],
        ];

        foreach ($pharmacies as $pharmacyData) {
            // Create pharmacy user
            $user = User::create([
                'name' => $pharmacyData['name'],
                'email' => $pharmacyData['email'],
                'phone' => $pharmacyData['phone'],
                'password' => Hash::make('password'),
                'role' => 'pharmacy',
                'email_verified_at' => now(),
            ]);

            // Create pharmacy
            $pharmacy = Pharmacy::create([
                'name' => $pharmacyData['name'],
                'email' => $pharmacyData['email'],
                'phone' => $pharmacyData['phone'],
                'address' => $pharmacyData['address'],
                'city' => $pharmacyData['city'],
                'latitude' => $pharmacyData['latitude'],
                'longitude' => $pharmacyData['longitude'],
                'status' => 'approved', // Remplace is_active et is_verified
                'approved_at' => now(),
                'commission_rate_platform' => 0.10,
                'commission_rate_pharmacy' => 0.85,
                'commission_rate_courier' => 0.05,
            ]);

            // Attach user to pharmacy
            $pharmacy->users()->attach($user->id);

            // Create wallet for pharmacy (polymorphic relation)
            Wallet::create([
                'walletable_type' => Pharmacy::class,
                'walletable_id' => $pharmacy->id,
                'balance' => 0,
                'currency' => 'XOF',
            ]);
        }
    }
}
