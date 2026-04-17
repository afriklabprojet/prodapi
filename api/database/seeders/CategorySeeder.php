<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            [
                'name' => 'Médicaments',
                'slug' => 'medicaments',
                'description' => 'Tous les médicaments génériques et de marque',
                'icon' => 'pill',
                'is_active' => true,
                'order' => 1,
            ],
            [
                'name' => 'Parapharmacie',
                'slug' => 'parapharmacie',
                'description' => 'Produits de beauté, hygiène et soins',
                'icon' => 'sparkles',
                'is_active' => true,
                'order' => 2,
            ],
            [
                'name' => 'Vitamines & Suppléments',
                'slug' => 'vitamines-supplements',
                'description' => 'Vitamines, minéraux et compléments alimentaires',
                'icon' => 'heart-pulse',
                'is_active' => true,
                'order' => 3,
            ],
            [
                'name' => 'Matériel médical',
                'slug' => 'materiel-medical',
                'description' => 'Tensiomètres, thermomètres, glucomètres et accessoires',
                'icon' => 'stethoscope',
                'is_active' => true,
                'order' => 4,
            ],
            [
                'name' => 'Mère & Bébé',
                'slug' => 'mere-bebe',
                'description' => 'Produits pour la maternité, nourrissons et jeunes enfants',
                'icon' => 'baby',
                'is_active' => true,
                'order' => 5,
            ],
            [
                'name' => 'Hygiène & Santé',
                'slug' => 'hygiene-sante',
                'description' => 'Produits d\'hygiène corporelle et bucco-dentaire',
                'icon' => 'shield-check',
                'is_active' => true,
                'order' => 6,
            ],
            [
                'name' => 'Nutrition',
                'slug' => 'nutrition',
                'description' => 'Compléments nutritionnels et aliments santé',
                'icon' => 'salad',
                'is_active' => true,
                'order' => 7,
            ],
            [
                'name' => 'Dermatologie',
                'slug' => 'dermatologie',
                'description' => 'Crèmes, lotions et soins pour la peau',
                'icon' => 'sun',
                'is_active' => true,
                'order' => 8,
            ],
            [
                'name' => 'Ophtalmologie',
                'slug' => 'ophtalmologie',
                'description' => 'Collyres, solutions oculaires et lunettes',
                'icon' => 'eye',
                'is_active' => true,
                'order' => 9,
            ],
            [
                'name' => 'Premiers secours',
                'slug' => 'premiers-secours',
                'description' => 'Pansements, antiseptiques et matériel de premiers soins',
                'icon' => 'first-aid',
                'is_active' => true,
                'order' => 10,
            ],
        ];

        foreach ($categories as $category) {
            Category::updateOrCreate(
                ['slug' => $category['slug']],
                $category
            );
        }
    }
}
