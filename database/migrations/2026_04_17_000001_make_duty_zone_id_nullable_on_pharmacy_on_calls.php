<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('pharmacy_on_calls', function (Blueprint $table) {
            // Drop FK si existe (nom par défaut Laravel)
            try {
                $table->dropForeign(['duty_zone_id']);
            } catch (\Throwable $e) {
                // ignore si déjà absente
            }
            $table->unsignedBigInteger('duty_zone_id')->nullable()->change();
            $table->foreign('duty_zone_id')
                ->references('id')->on('duty_zones')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('pharmacy_on_calls', function (Blueprint $table) {
            try {
                $table->dropForeign(['duty_zone_id']);
            } catch (\Throwable $e) {
                // ignore
            }
            $table->unsignedBigInteger('duty_zone_id')->nullable(false)->change();
            $table->foreign('duty_zone_id')
                ->references('id')->on('duty_zones')
                ->cascadeOnDelete();
        });
    }
};
