<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('delivery_messages')) { return; }

        Schema::create('delivery_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delivery_id')->constrained()->cascadeOnDelete();
            $table->string('sender_type');
            $table->unsignedBigInteger('sender_id');
            $table->string('receiver_type');
            $table->unsignedBigInteger('receiver_id');
            $table->text('message');
            $table->timestamp('read_at')->nullable();
            $table->timestamps();

            $table->index('delivery_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('delivery_messages');
    }
};
