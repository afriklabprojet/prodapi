<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Always seed: admin user + reference data
        // NOTE: CategorySeeder retiré — chaque pharmacie gère ses propres catégories.
        $this->call([
            UserSeeder::class,
            DutyZoneSeeder::class,
            SettingsSeeder::class,
        ]);

        // Test data: only in local/testing environments
        if (app()->environment('local', 'testing')) {
            $this->call([
                TestDataSeeder::class,
            ]);
        }
    }
}
