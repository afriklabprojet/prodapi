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
        // Points de tracking détaillés pour le suivi temps réel
        Schema::create('delivery_tracking_points', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delivery_id')->constrained()->onDelete('cascade');
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->integer('speed')->nullable(); // km/h
            $table->integer('heading')->nullable(); // degrés (0-360)
            $table->integer('accuracy')->nullable(); // mètres
            $table->string('event_type')->nullable(); // location_update, pickup, dropoff, pause, resume
            $table->timestamp('recorded_at');
            
            $table->index(['delivery_id', 'recorded_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('delivery_tracking_points');
    }
};
