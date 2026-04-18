<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('deliveries', function (Blueprint $table) {
            if (!Schema::hasColumn('deliveries', 'metadata')) {
                $table->json('metadata')->nullable();
            }
            if (!Schema::hasColumn('deliveries', 'location_history')) {
                $table->json('location_history')->nullable();
            }
        });
    }

    public function down(): void
    {
        Schema::table('deliveries', function (Blueprint $table) {
            $table->dropColumn(['metadata', 'location_history']);
        });
    }
};
