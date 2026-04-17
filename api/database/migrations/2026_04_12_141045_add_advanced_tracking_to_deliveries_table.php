<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('deliveries', function (Blueprint $table) {
            // ETA avancé
            $table->integer('original_eta_seconds')->nullable()->after('estimated_duration');
            $table->integer('current_eta_seconds')->nullable()->after('original_eta_seconds');
            $table->timestamp('last_eta_update')->nullable()->after('current_eta_seconds');
            
            // Route et stops
            $table->json('route_polyline')->nullable()->after('last_eta_update');
            $table->integer('total_stops')->default(1)->after('route_polyline');
            $table->integer('current_stop')->default(0)->after('total_stops');
            
            // Batching
            $table->foreignId('order_batch_id')->nullable()->after('order_id')->constrained()->nullOnDelete();
            
            // Surge/Dynamic pricing
            $table->decimal('surge_multiplier', 3, 2)->default(1.0)->after('delivery_fee');
            $table->integer('surge_fee')->default(0)->after('surge_multiplier');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('deliveries', function (Blueprint $table) {
            $table->dropForeign(['order_batch_id']);
            $table->dropColumn([
                'original_eta_seconds',
                'current_eta_seconds',
                'last_eta_update',
                'route_polyline',
                'total_stops',
                'current_stop',
                'order_batch_id',
                'surge_multiplier',
                'surge_fee',
            ]);
        });
    }
};
