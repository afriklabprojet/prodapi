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
        Schema::table('couriers', function (Blueprint $table) {
            // Gamification & métriques avancées
            $table->unsignedInteger('total_xp')->default(0)->after('completed_deliveries');
            $table->unsignedInteger('current_streak_days')->default(0)->after('total_xp');
            $table->date('last_active_date')->nullable()->after('current_streak_days');
            $table->json('badges')->nullable()->after('last_active_date');
            $table->string('tier')->default('bronze')->after('badges'); // bronze, silver, gold, champion
            
            // Métriques de performance
            $table->decimal('acceptance_rate', 5, 2)->nullable()->after('tier');
            $table->decimal('completion_rate', 5, 2)->nullable()->after('acceptance_rate');
            $table->decimal('on_time_rate', 5, 2)->nullable()->after('completion_rate');
            $table->integer('avg_response_time_seconds')->nullable()->after('on_time_rate');
            $table->decimal('reliability_score', 5, 2)->nullable()->after('avg_response_time_seconds');
            
            // Speed factor pour les ETA
            $table->decimal('avg_delivery_speed_factor', 4, 2)->default(1.0)->after('reliability_score');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('couriers', function (Blueprint $table) {
            $table->dropColumn([
                'total_xp',
                'current_streak_days',
                'last_active_date',
                'badges',
                'tier',
                'acceptance_rate',
                'completion_rate',
                'on_time_rate',
                'avg_response_time_seconds',
                'reliability_score',
                'avg_delivery_speed_factor',
            ]);
        });
    }
};
