<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('deliveries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('courier_id')->nullable()->constrained()->nullOnDelete();
            $table->enum('status', [
                'pending', 'assigned', 'accepted', 'picked_up', 
                'in_transit', 'arrived', 'delivered', 'failed', 'cancelled'
            ])->default('pending')->index();
            $table->decimal('pickup_latitude', 10, 8)->nullable();
            $table->decimal('pickup_longitude', 11, 8)->nullable();
            $table->decimal('dropoff_latitude', 10, 8)->nullable();
            $table->decimal('dropoff_longitude', 11, 8)->nullable();
            $table->decimal('delivery_latitude', 10, 8)->nullable();
            $table->decimal('delivery_longitude', 11, 8)->nullable();
            $table->string('pickup_address')->nullable();
            $table->string('delivery_address')->nullable();
            $table->decimal('estimated_distance', 8, 2)->nullable();
            $table->integer('estimated_duration')->nullable();
            $table->decimal('delivery_fee', 12, 2)->default(0);
            $table->timestamp('assigned_at')->nullable();
            $table->timestamp('accepted_at')->nullable();
            $table->timestamp('picked_up_at')->nullable();
            $table->timestamp('delivered_at')->nullable();
            $table->text('delivery_notes')->nullable();
            $table->string('delivery_proof_image')->nullable();
            $table->text('failure_reason')->nullable();
            
            // Waiting timeout fields
            $table->timestamp('waiting_started_at')->nullable()->index();
            $table->timestamp('waiting_ended_at')->nullable();
            $table->integer('waiting_fee')->default(0);
            $table->timestamp('auto_cancelled_at')->nullable();
            $table->string('cancellation_reason')->nullable();
            
            $table->timestamps();

            $table->index(['courier_id', 'status']);
            $table->index('order_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('deliveries');
    }
};
