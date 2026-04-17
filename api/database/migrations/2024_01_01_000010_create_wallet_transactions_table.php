<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('wallet_transactions')) { return; }

        Schema::create('wallet_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('wallet_id')->constrained()->cascadeOnDelete();
            $table->string('type'); // credit, debit
            $table->decimal('amount', 14, 2);
            $table->decimal('balance_after', 14, 2);
            $table->string('reference')->unique();
            $table->text('description')->nullable();
            $table->json('metadata')->nullable();
            $table->string('category')->nullable(); // topup, order_payment, refund, withdrawal, delivery_earning, bonus
            $table->unsignedBigInteger('delivery_id')->nullable();
            $table->string('status')->default('completed');
            $table->string('payment_method')->nullable();
            $table->timestamps();

            $table->index(['wallet_id', 'type']);
            $table->index(['wallet_id', 'category']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wallet_transactions');
    }
};
