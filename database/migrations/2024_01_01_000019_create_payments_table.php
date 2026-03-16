<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->enum('provider', ['jeko', 'cash']);
            $table->string('reference')->unique()->index();
            $table->string('provider_transaction_id')->nullable();
            $table->decimal('amount', 12, 2);
            $table->string('currency')->default('XOF');
            $table->enum('status', ['SUCCESS', 'FAILED'])->default('SUCCESS');
            $table->string('payment_method')->nullable();
            $table->timestamp('confirmed_at');
            $table->timestamps();

            $table->index(['order_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
