<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Categories strictement par pharmacie (audit 2026-04, révision finale).
 *
 * - Supprime toutes les catégories globales (pharmacy_id NULL).
 *   Les produits qui y étaient rattachés voient leur category_id mis à NULL
 *   (FK déjà en SET NULL côté products si présent, sinon ignoré).
 * - Rend `pharmacy_id` NOT NULL sur `categories`.
 *
 * Plus aucune catégorie globale : chaque pharmacie gère ses propres catégories.
 * L'admin est en lecture seule.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('categories') || !Schema::hasColumn('categories', 'pharmacy_id')) {
            return;
        }

        // Détacher les produits rattachés à une catégorie globale
        if (Schema::hasTable('products') && Schema::hasColumn('products', 'category_id')) {
            $globalIds = DB::table('categories')->whereNull('pharmacy_id')->pluck('id');
            if ($globalIds->isNotEmpty()) {
                DB::table('products')->whereIn('category_id', $globalIds)->update(['category_id' => null]);
            }
        }

        // Supprimer définitivement les catégories globales
        DB::table('categories')->whereNull('pharmacy_id')->delete();

        // Rendre pharmacy_id NOT NULL
        Schema::table('categories', function (Blueprint $table) {
            $table->foreignId('pharmacy_id')->nullable(false)->change();
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('categories') || !Schema::hasColumn('categories', 'pharmacy_id')) {
            return;
        }

        Schema::table('categories', function (Blueprint $table) {
            $table->foreignId('pharmacy_id')->nullable()->change();
        });
    }
};
