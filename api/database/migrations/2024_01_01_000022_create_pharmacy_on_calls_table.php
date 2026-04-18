<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('pharmacy_on_calls')) { return; }

        Schema::create('pharmacy_on_calls', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pharmacy_id')->constrained()->cascadeOnDelete();
            $table->foreignId('duty_zone_id')->constrained()->cascadeOnDelete();
            $table->timestamp('start_at');
            $table->timestamp('end_at');
            $table->string('type')->default('night');
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['duty_zone_id', 'start_at', 'end_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pharmacy_on_calls');
    }
};
