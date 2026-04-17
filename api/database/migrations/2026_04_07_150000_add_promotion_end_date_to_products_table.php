<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('products', 'promotion_end_date')) {
            Schema::table('products', function (Blueprint $table) {
                $table->date('promotion_end_date')->nullable()->after('discount_price');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('products', 'promotion_end_date')) {
            Schema::table('products', function (Blueprint $table) {
                $table->dropColumn('promotion_end_date');
            });
        }
    }
};
