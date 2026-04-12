<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('commission_lines')) { return; }

        Schema::create('commission_lines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('commission_id')->constrained()->cascadeOnDelete();
            $table->string('actor_type');
            $table->unsignedBigInteger('actor_id');
            $table->decimal('rate', 5, 2);
            $table->decimal('amount', 14, 2);
            $table->timestamps();

            $table->index(['actor_type', 'actor_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('commission_lines');
    }
};
