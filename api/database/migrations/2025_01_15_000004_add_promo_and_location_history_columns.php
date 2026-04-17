<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Ajouter promo_code_id et discount sur les commandes si pas encore présent
        if (Schema::hasTable('orders')) {
            if (!Schema::hasColumn('orders', 'promo_code_id')) {
                Schema::table('orders', function (Blueprint $table) {
                    $table->foreignId('promo_code_id')->nullable()
                        ->constrained('promo_codes')->onDelete('set null');
                    $table->decimal('promo_discount', 10, 2)->default(0);
                });
            }
        }

        // Ajouter delivery_location_history sur les deliveries
        if (Schema::hasTable('deliveries')) {
            if (!Schema::hasColumn('deliveries', 'location_history')) {
                Schema::table('deliveries', function (Blueprint $table) {
                    $table->json('location_history')->nullable()
                        ->comment('Historique de positions [{lat,lng,timestamp}]');
                });
            }
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('orders')) {
            Schema::table('orders', function (Blueprint $table) {
                if (Schema::hasColumn('orders', 'promo_discount')) {
                    $table->dropColumn('promo_discount');
                }
                if (Schema::hasColumn('orders', 'promo_code_id')) {
                    $table->dropForeign(['promo_code_id']);
                    $table->dropColumn('promo_code_id');
                }
            });
        }

        if (Schema::hasTable('deliveries')) {
            Schema::table('deliveries', function (Blueprint $table) {
                if (Schema::hasColumn('deliveries', 'location_history')) {
                    $table->dropColumn('location_history');
                }
            });
        }
    }
};
