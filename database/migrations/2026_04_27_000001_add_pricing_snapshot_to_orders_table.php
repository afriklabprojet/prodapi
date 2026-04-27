<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('orders')) {
            return;
        }

        Schema::table('orders', function (Blueprint $table) {
            // Audit complet du pricing utilisé à la création (figé, immuable).
            // Permet de prouver que le client a payé le montant qu'il a vu.
            if (!Schema::hasColumn('orders', 'pricing_snapshot')) {
                $table->json('pricing_snapshot')->nullable()->after('total_amount');
            }
            // Origine du pricing : 'quote' (token signé), 'recompute' (fallback), 'recompute_quote_invalid'.
            if (!Schema::hasColumn('orders', 'pricing_source')) {
                $table->string('pricing_source', 32)->nullable()->after('pricing_snapshot');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('orders')) {
            return;
        }

        Schema::table('orders', function (Blueprint $table) {
            if (Schema::hasColumn('orders', 'pricing_source')) {
                $table->dropColumn('pricing_source');
            }
            if (Schema::hasColumn('orders', 'pricing_snapshot')) {
                $table->dropColumn('pricing_snapshot');
            }
        });
    }
};
