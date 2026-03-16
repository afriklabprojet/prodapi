<?php

namespace Database\Seeders;

use App\Models\Setting;
use Illuminate\Database\Seeder;

class SettingsSeeder extends Seeder
{
    public function run(): void
    {
        $settings = [
            // Delivery settings
            ['key' => 'delivery_base_fee', 'value' => '500', 'type' => 'integer'],
            ['key' => 'delivery_fee_per_km', 'value' => '100', 'type' => 'integer'],
            ['key' => 'delivery_max_distance_km', 'value' => '20', 'type' => 'integer'],
            ['key' => 'delivery_timeout_minutes', 'value' => '30', 'type' => 'integer'],
            
            // Commission settings
            ['key' => 'platform_commission_rate', 'value' => '0.10', 'type' => 'float'],
            ['key' => 'pharmacy_default_commission_rate', 'value' => '0.05', 'type' => 'float'],
            ['key' => 'courier_commission_rate', 'value' => '0.80', 'type' => 'float'],
            
            // Payment settings
            ['key' => 'minimum_order_amount', 'value' => '1000', 'type' => 'integer'],
            ['key' => 'minimum_withdrawal_amount', 'value' => '5000', 'type' => 'integer'],
            ['key' => 'payment_timeout_minutes', 'value' => '15', 'type' => 'integer'],
            
            // App settings
            ['key' => 'app_name', 'value' => 'DR-PHARMA', 'type' => 'string'],
            ['key' => 'app_version', 'value' => '1.0.0', 'type' => 'string'],
            ['key' => 'support_email', 'value' => 'support@drlpharma.com', 'type' => 'string'],
            ['key' => 'support_phone', 'value' => '+2250701159572', 'type' => 'string'],
        ];

        foreach ($settings as $setting) {
            Setting::updateOrCreate(
                ['key' => $setting['key']],
                $setting
            );
        }
    }
}
