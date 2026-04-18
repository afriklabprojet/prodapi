<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('orders', 'promo_code_id')) {
            return;
        }

        Schema::table('orders', function (Blueprint $table) {
            $table->unsignedBigInteger('promo_code_id')->nullable()->after('customer_phone');
            $table->decimal('promo_discount', 10, 2)->default(0)->after('promo_code_id');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['promo_code_id', 'promo_discount']);
        });
    }
};
