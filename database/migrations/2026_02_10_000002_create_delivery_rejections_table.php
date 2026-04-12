<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('delivery_rejections')) { return; }

        Schema::create('delivery_rejections', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delivery_id')->constrained()->cascadeOnDelete();
            $table->foreignId('courier_id')->constrained()->cascadeOnDelete();
            $table->string('reason')->nullable();
            $table->timestamp('rejected_at')->useCurrent();

            $table->unique(['delivery_id', 'courier_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('delivery_rejections');
    }
};
