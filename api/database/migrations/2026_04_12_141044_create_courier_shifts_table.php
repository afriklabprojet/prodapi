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
        // Shifts réservés par les livreurs
        Schema::create('courier_shifts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('courier_id')->constrained()->onDelete('cascade');
            $table->foreignId('slot_id')->constrained('courier_shift_slots')->onDelete('cascade');
            $table->string('zone_id');
            $table->date('date');
            $table->time('start_time');
            $table->time('end_time');
            $table->time('actual_start_time')->nullable();
            $table->time('actual_end_time')->nullable();
            $table->integer('guaranteed_bonus')->default(0);
            $table->integer('earned_bonus')->default(0);
            $table->enum('status', ['confirmed', 'in_progress', 'completed', 'cancelled', 'no_show'])->default('confirmed');
            $table->integer('deliveries_completed')->default(0);
            $table->integer('violations_count')->default(0);
            $table->json('violations')->nullable();
            $table->timestamps();
            
            $table->index(['courier_id', 'date']);
            $table->index(['zone_id', 'date', 'status']);
        });

        // Table de progression des challenges
        Schema::create('courier_challenge_progress', function (Blueprint $table) {
            $table->id();
            $table->foreignId('courier_id')->constrained()->onDelete('cascade');
            $table->string('challenge_type'); // daily_streak, peak_hour_hero, perfect_rating, etc.
            $table->date('period_date'); // Pour daily/weekly
            $table->unsignedInteger('current_progress')->default(0);
            $table->unsignedTinyInteger('tier_reached')->default(0);
            $table->integer('rewards_earned')->default(0);
            $table->timestamps();
            
            $table->unique(['courier_id', 'challenge_type', 'period_date'], 'ccp_courier_challenge_period_unique');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('courier_challenge_progress');
        Schema::dropIfExists('courier_shifts');
    }
};
