<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Ajoute le support de la réassignation automatique des livraisons inactives.
 *
 * - `deliveries.reassigned_at` : timestamp de la réassignation (audit)
 * - statut `'reassigned'` ajouté implicitement (colonne string déjà flexible)
 * - `orders.status` accepte `'pending_assignment'` (déjà varchar libre)
 *
 * Si `deliveries.status` est un ENUM strict, il faudra le passer en string.
 * Ici on présume varchar (compatibilité Laravel).
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::table('deliveries', function (Blueprint $table) {
            if (!Schema::hasColumn('deliveries', 'reassigned_at')) {
                $table->timestamp('reassigned_at')->nullable()->after('auto_cancelled_at');
                $table->index('reassigned_at');
            }
        });
    }

    public function down(): void
    {
        Schema::table('deliveries', function (Blueprint $table) {
            if (Schema::hasColumn('deliveries', 'reassigned_at')) {
                $table->dropIndex(['reassigned_at']);
                $table->dropColumn('reassigned_at');
            }
        });
    }
};
