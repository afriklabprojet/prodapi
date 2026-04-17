<?php

namespace Database\Seeders;

use App\Models\DutyZone;
use Illuminate\Database\Seeder;

class DutyZoneSeeder extends Seeder
{
    public function run(): void
    {
        $zones = [
            [
                'name' => 'Abidjan Centre',
                'city' => 'Abidjan',
                'description' => 'Zone de garde couvrant le Plateau, Adjamé et Attécoubé',
                'is_active' => true,
                'latitude' => 5.3590,
                'longitude' => -4.0088,
                'radius' => 8.0,
            ],
            [
                'name' => 'Abidjan Cocody',
                'city' => 'Abidjan',
                'description' => 'Zone de garde couvrant Cocody, Bingerville et Riviera',
                'is_active' => true,
                'latitude' => 5.3670,
                'longitude' => -3.9681,
                'radius' => 10.0,
            ],
            [
                'name' => 'Abidjan Yopougon',
                'city' => 'Abidjan',
                'description' => 'Zone de garde couvrant Yopougon et Songon',
                'is_active' => true,
                'latitude' => 5.3500,
                'longitude' => -4.0750,
                'radius' => 10.0,
            ],
            [
                'name' => 'Abidjan Marcory-Koumassi',
                'city' => 'Abidjan',
                'description' => 'Zone de garde couvrant Marcory, Koumassi et Port-Bouët',
                'is_active' => true,
                'latitude' => 5.3000,
                'longitude' => -3.9900,
                'radius' => 9.0,
            ],
            [
                'name' => 'Abidjan Abobo',
                'city' => 'Abidjan',
                'description' => 'Zone de garde couvrant Abobo et Anyama',
                'is_active' => true,
                'latitude' => 5.4227,
                'longitude' => -4.0130,
                'radius' => 10.0,
            ],
            [
                'name' => 'Abidjan Treichville',
                'city' => 'Abidjan',
                'description' => 'Zone de garde couvrant Treichville et Zone 4',
                'is_active' => true,
                'latitude' => 5.3035,
                'longitude' => -4.0080,
                'radius' => 5.0,
            ],
        ];

        foreach ($zones as $zone) {
            DutyZone::updateOrCreate(
                ['name' => $zone['name'], 'city' => $zone['city']],
                $zone
            );
        }
    }
}
