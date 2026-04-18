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
        // Table principale des offres de livraison (broadcast)
        Schema::create('delivery_offers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->onDelete('cascade');
            $table->foreignId('accepted_by_courier_id')->nullable()->constrained('couriers')->nullOnDelete();
            $table->enum('status', ['pending', 'accepted', 'expired', 'no_courier_found', 'cancelled'])->default('pending');
            $table->unsignedTinyInteger('broadcast_level')->default(0);
            $table->integer('base_fee')->default(0);
            $table->integer('bonus_fee')->default(0);
            $table->timestamp('expires_at')->nullable();
            $table->timestamp('accepted_at')->nullable();
            $table->timestamps();
            
            $table->index(['status', 'expires_at']);
            $table->index(['order_id', 'status']);
        });

        // Table pivot: livreurs ciblés par une offre
        Schema::create('delivery_offer_courier', function (Blueprint $table) {
            $table->id();
            $table->foreignId('delivery_offer_id')->constrained()->onDelete('cascade');
            $table->foreignId('courier_id')->constrained()->onDelete('cascade');
            $table->enum('status', ['notified', 'viewed', 'accepted', 'rejected', 'expired'])->default('notified');
            $table->timestamp('notified_at')->nullable();
            $table->timestamp('viewed_at')->nullable();
            $table->timestamp('responded_at')->nullable();
            $table->string('rejection_reason')->nullable();
            
            $table->unique(['delivery_offer_id', 'courier_id']);
            $table->index(['courier_id', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('delivery_offer_courier');
        Schema::dropIfExists('delivery_offers');
    }
};
