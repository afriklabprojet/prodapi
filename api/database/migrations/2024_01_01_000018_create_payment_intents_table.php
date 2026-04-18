<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('payment_intents')) { return; }

        Schema::create('payment_intents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->enum('provider', ['jeko']);
            $table->string('reference')->unique()->index();
            $table->string('provider_reference')->nullable()->index();
            $table->string('provider_transaction_id')->nullable();
            $table->decimal('amount', 12, 2);
            $table->string('currency')->default('XOF');
            $table->enum('status', ['PENDING', 'SUCCESS', 'FAILED', 'CANCELLED'])->default('PENDING');
            $table->text('provider_payment_url')->nullable();
            $table->json('raw_response')->nullable();
            $table->json('raw_webhook')->nullable();
            $table->timestamp('confirmed_at')->nullable();
            $table->timestamps();

            $table->index(['provider', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_intents');
    }
};
