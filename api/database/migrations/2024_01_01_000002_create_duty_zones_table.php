<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Guard idempotent: ne pas recréer si la table existe déjà (production)
        if (Schema::hasTable('duty_zones')) {
            return;
        }
        Schema::create('duty_zones', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('city');
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->decimal('radius', 8, 2)->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('duty_zones');
    }
};
