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
        // Table des lots de commandes (batching multi-commandes)
        Schema::create('order_batches', function (Blueprint $table) {
            $table->id();
            $table->foreignId('courier_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('delivery_offer_id')->nullable()->constrained()->nullOnDelete();
            $table->enum('status', ['pending', 'assigned', 'in_progress', 'completed', 'cancelled'])->default('pending');
            $table->unsignedTinyInteger('total_orders')->default(0);
            $table->integer('total_fee')->default(0);
            $table->integer('batch_bonus')->default(0);
            $table->json('optimized_route')->nullable();
            $table->decimal('total_distance', 8, 2)->nullable();
            $table->integer('estimated_total_time')->nullable(); // minutes
            $table->timestamps();
            
            $table->index(['status', 'courier_id']);
        });

        // Table pivot: commandes dans un lot
        Schema::create('order_batch_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_batch_id')->constrained()->onDelete('cascade');
            $table->foreignId('order_id')->constrained()->onDelete('cascade');
            $table->unsignedTinyInteger('sequence')->default(0);
            $table->timestamp('estimated_arrival')->nullable();
            $table->timestamp('actual_arrival')->nullable();
            $table->enum('status', ['pending', 'picked_up', 'delivered', 'failed'])->default('pending');
            $table->timestamps();
            
            $table->unique(['order_batch_id', 'order_id']);
            $table->index(['order_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('order_batch_items');
        Schema::dropIfExists('order_batches');
    }
};
