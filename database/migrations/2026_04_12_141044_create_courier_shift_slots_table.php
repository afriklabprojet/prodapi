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
        // Créneaux de shift disponibles par zone
        Schema::create('courier_shift_slots', function (Blueprint $table) {
            $table->id();
            $table->string('zone_id')->index();
            $table->date('date');
            $table->string('shift_type'); // morning, lunch, afternoon, dinner, night
            $table->time('start_time');
            $table->time('end_time');
            $table->unsignedInteger('capacity')->default(10);
            $table->unsignedInteger('booked_count')->default(0);
            $table->integer('bonus_amount')->default(0);
            $table->enum('status', ['open', 'full', 'closed'])->default('open');
            $table->timestamps();
            
            $table->index(['zone_id', 'date', 'status']);
            $table->unique(['zone_id', 'date', 'shift_type']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::disableForeignKeyConstraints();
        Schema::dropIfExists('courier_shift_slots');
        Schema::enableForeignKeyConstraints();
    }
};
