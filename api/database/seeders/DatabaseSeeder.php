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
        $this->call([
            UserSeeder::class,
            DutyZoneSeeder::class,
            SettingsSeeder::class,
            CategorySeeder::class,
        ]);

        // Test data: only in local/testing environments
        if (app()->environment('local', 'testing')) {
            $this->call([
                TestDataSeeder::class,
            ]);
        }
    }
}
