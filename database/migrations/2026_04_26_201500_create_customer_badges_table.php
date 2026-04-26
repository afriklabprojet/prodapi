<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('customer_badges', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('badge_id', 64);
            $table->timestamp('unlocked_at')->useCurrent();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'badge_id']);
            $table->index('badge_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('customer_badges');
    }
};
