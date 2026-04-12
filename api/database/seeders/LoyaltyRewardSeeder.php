<?php

namespace Database\Seeders;

use App\Models\LoyaltyReward;
use Illuminate\Database\Seeder;

class LoyaltyRewardSeeder extends Seeder
{
    public function run(): void
    {
        $rewards = [
            [
                'name' => 'Livraison gratuite',
                'description' => 'Livraison offerte sur votre prochaine commande',
                'type' => 'free_delivery',
                'points_cost' => 200,
                'value' => 0,
                'value_type' => 'fixed',
                'min_tier' => 'bronze',
            ],
            [
                'name' => 'Réduction 500 FCFA',
                'description' => '500 FCFA de réduction sur votre prochaine commande',
                'type' => 'discount',
                'points_cost' => 300,
                'value' => 500,
                'value_type' => 'fixed',
                'min_tier' => 'bronze',
            ],
            [
                'name' => 'Réduction 1 000 FCFA',
                'description' => '1 000 FCFA de réduction sur votre prochaine commande',
                'type' => 'discount',
                'points_cost' => 500,
                'value' => 1000,
                'value_type' => 'fixed',
                'min_tier' => 'silver',
            ],
            [
                'name' => 'Réduction 10%',
                'description' => '10% de réduction sur votre prochaine commande',
                'type' => 'discount',
                'points_cost' => 800,
                'value' => 10,
                'value_type' => 'percentage',
                'min_tier' => 'silver',
            ],
            [
                'name' => 'Réduction 2 500 FCFA',
                'description' => '2 500 FCFA de réduction sur votre prochaine commande',
                'type' => 'discount',
                'points_cost' => 1000,
                'value' => 2500,
                'value_type' => 'fixed',
                'min_tier' => 'gold',
            ],
            [
                'name' => 'Réduction 15%',
                'description' => '15% de réduction sur votre prochaine commande',
                'type' => 'discount',
                'points_cost' => 1500,
                'value' => 15,
                'value_type' => 'percentage',
                'min_tier' => 'gold',
            ],
            [
                'name' => 'Kit Bien-être',
                'description' => 'Un kit bien-être offert (trousse de premiers soins)',
                'type' => 'gift',
                'points_cost' => 3000,
                'value' => 5000,
                'value_type' => 'fixed',
                'min_tier' => 'platinum',
            ],
            [
                'name' => 'Réduction 5 000 FCFA',
                'description' => '5 000 FCFA de réduction sur votre prochaine commande',
                'type' => 'discount',
                'points_cost' => 2000,
                'value' => 5000,
                'value_type' => 'fixed',
                'min_tier' => 'platinum',
            ],
        ];

        foreach ($rewards as $reward) {
            LoyaltyReward::firstOrCreate(
                ['name' => $reward['name']],
                $reward,
            );
        }
    }
}
