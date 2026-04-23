<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Categories per-pharmacy (audit 2026-04, option B).
 *
 * - Ajoute `pharmacy_id` nullable sur `categories` :
 *     NULL  = catégorie globale (gérée admin/seeder)
 *     int   = catégorie privée d'une pharmacie
 * - Drop de l'unicité globale sur `slug` (les pharmacies peuvent avoir un slug
 *   identique dans leur scope respectif).
 * - Unicité composite (pharmacy_id, slug) via index standard + validation app
 *   (MySQL traite plusieurs NULL comme distincts — les collisions globales sont
 *   prévenues au niveau applicatif dans le controller admin).
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('categories')) {
            return;
        }

        Schema::table('categories', function (Blueprint $table) {
            if (!Schema::hasColumn('categories', 'pharmacy_id')) {
                $table->foreignId('pharmacy_id')
                    ->nullable()
                    ->after('id')
                    ->constrained()
                    ->cascadeOnDelete();
            }
        });

        // Drop unique on slug (si existe) — nom d'index Laravel par défaut : <table>_<col>_unique
        Schema::table('categories', function (Blueprint $table) {
            try {
                $table->dropUnique('categories_slug_unique');
            } catch (\Throwable $e) {
                // index peut avoir un autre nom ou déjà absent — non bloquant
            }
        });

        // Index composite pour lookup + unicité app-level (pharmacy_id, slug)
        Schema::table('categories', function (Blueprint $table) {
            $table->index(['pharmacy_id', 'slug'], 'categories_pharmacy_slug_idx');
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('categories')) {
            return;
        }

        Schema::table('categories', function (Blueprint $table) {
            try {
                $table->dropIndex('categories_pharmacy_slug_idx');
            } catch (\Throwable $e) {
                // non bloquant
            }
        });

        Schema::table('categories', function (Blueprint $table) {
            if (Schema::hasColumn('categories', 'pharmacy_id')) {
                $table->dropConstrainedForeignId('pharmacy_id');
            }
        });

        Schema::table('categories', function (Blueprint $table) {
            try {
                $table->unique('slug');
            } catch (\Throwable $e) {
                // non bloquant
            }
        });
    }
};
